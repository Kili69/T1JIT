BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
    $scriptPath = Join-Path $repoRoot "src\C#\Kjitweb\enable-kjitweb-https.ps1"
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $scriptPath, [ref]$tokens, [ref]$parseErrors
    )
    if ($parseErrors.Count -gt 0) { throw ($parseErrors -join "; ") }
    $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $false) | ForEach-Object { . ([scriptblock]::Create($_.Extent.Text)) }
}

Describe "KjitWeb HTTPS conversion plan" {
    It "changes only the scheme and retains other environment values and port 5240" {
        $plan = Get-KjitWebHttpsPlan -Port 5240 -EnvironmentValues @(
            "ASPNETCORE_ENVIRONMENT=Production",
            "ASPNETCORE_URLS=http://*:5240",
            "JustInTimeConfig=C:\Configs\JIT.config",
            "DebugLog__Path=C:\Logs\debug.log"
        )
        $plan.Urls | Should -Be @("https://*:5240/")
        $plan.Environment | Should -Be @(
            "ASPNETCORE_ENVIRONMENT=Production",
            "ASPNETCORE_URLS=https://*:5240/",
            "JustInTimeConfig=C:\Configs\JIT.config",
            "DebugLog__Path=C:\Logs\debug.log"
        )
        $plan.IpPorts | Should -Be @("0.0.0.0:5240", "[::]:5240")
    }

    It "preserves loopback-only IPv4/IPv6 prefixes" {
        $plan = Get-KjitWebHttpsPlan -Port 5240 -EnvironmentValues @(
            "ASPNETCORE_URLS=http://127.0.0.1:5240;http://[::1]:5240"
        )
        $plan.Urls | Should -Be @("https://127.0.0.1:5240/", "https://[::1]:5240/")
    }

    It "rejects invalid or already migrated configuration: <Entry>" -ForEach @(
        @{ Entry = "ASPNETCORE_URLS=https://*:5240" }
        @{ Entry = "ASPNETCORE_URLS=http://*:8080" }
        @{ Entry = "ASPNETCORE_URLS=http://*:5240;http://*:8080" }
        @{ Entry = "ASPNETCORE_URLS=http://*:5240/path" }
        @{ Entry = "ASPNETCORE_URLS=" }
    ) {
        { Get-KjitWebHttpsPlan -Port 5240 -EnvironmentValues @($Entry) } |
            Should -Throw
    }

    It "rejects missing or duplicate URL entries" {
        { Get-KjitWebHttpsPlan -Port 5240 -EnvironmentValues @() } | Should -Throw
        { Get-KjitWebHttpsPlan -Port 5240 -EnvironmentValues @(
            "ASPNETCORE_URLS=http://*:5240", "ASPNETCORE_URLS=http://localhost:5240"
        ) } | Should -Throw
    }

    It "refuses existing TLS bindings: <Line>" -ForEach @(
        @{ Line = '    IP:port                      : 0.0.0.0:5240' }
        @{ Line = '    IP:Port                      : [::]:5240' }
        @{ Line = '    Hostname:port                : server.contoso.local:5240' }
        @{ Line = '    Port                         : 5240' }
        @{ Line = '    Hostname:Port                : server.contoso.local:5240' }
    ) {
        { Get-KjitWebHttpsPlan -Port 5240 -SslCertOutput @($Line) -EnvironmentValues @(
            "ASPNETCORE_URLS=http://*:5240"
        ) } | Should -Throw
    }

    It "does not confuse other ports or the old HTTP ACL with target resources" {
        $plan = Get-KjitWebHttpsPlan -Port 5240 -SslCertOutput @(
            '    IP:port : 0.0.0.0:52400'
        ) -UrlAclOutput @(
            '    Reserved URL : http://*:5240/',
            '        SDDL: D:(A;;GX;;;NS)'
        ) -EnvironmentValues @("ASPNETCORE_URLS=http://*:5240")
        $plan.Urls | Should -Be @("https://*:5240/")
        $plan.HttpReservations.Count | Should -Be 1
        $plan.HttpReservations[0].Sddl | Should -Be "D:(A;;GX;;;NS)"
    }

    It "refuses existing HTTPS reservations independently of localized labels" -ForEach @(
        @{ Label = "Reserved URL" }
        @{ Label = "Reservierte URL" }
    ) {
        { Get-KjitWebHttpsPlan -Port 5240 -UrlAclOutput @(
            "    $Label : https://*:5240/"
        ) -EnvironmentValues @("ASPNETCORE_URLS=http://*:5240") } | Should -Throw '*already exists*'
    }

    It "refuses to remove HTTP reservations without a readable original SDDL" {
        { Get-KjitWebHttpsPlan -Port 5240 -UrlAclOutput @(
            '    Reserved URL : http://*:5240/'
        ) -EnvironmentValues @("ASPNETCORE_URLS=http://*:5240") } | Should -Throw '*original SDDL*'
    }
}

Describe "KjitWeb HTTPS service migration" {
    BeforeEach {
        $script:originalEnvironment = @("ASPNETCORE_URLS=http://*:5240", "JustInTimeConfig=C:\JIT.config")
        $script:urlAclOutput = @("URL Reservations:", "-----------------")
        $script:sslCertOutput = @("SSL Certificate bindings:", "-------------------------")
        $script:netshCalls = [System.Collections.Generic.List[string]]::new()
        $script:writtenEnvironments = [System.Collections.Generic.List[object]]::new()
        $script:failBinding = $false
        $script:failProbe = $false
        $script:failRollback = $false
        $script:failUrl = $false
        $script:failHttpDelete = $false
        $script:initialStatus = "Running"
        $parameters = @{
            DnsName = @("server.contoso.local")
            Port = 5240
            ServiceName = "KjitWeb"
            CertificatePath = (Join-Path $TestDrive "$([guid]::NewGuid()).cer")
        }
        Mock Get-ItemProperty { [pscustomobject]@{ Environment = $script:originalEnvironment } }
        Mock Get-Service { [pscustomobject]@{ Status = $script:initialStatus } }
        Mock Get-CimInstance { [pscustomobject]@{ StartName = "LocalSystem" } }
        Mock New-SelfSignedCertificate {
            [pscustomobject]@{ Thumbprint = "ABC123"; NotAfter = (Get-Date).AddMonths(3) }
        }
        Mock Export-Certificate {} -RemoveParameterType Cert
        Mock Stop-Service {}
        Mock Start-Service {}
        Mock Wait-KjitWebService {}
        Mock Remove-Item {}
        Mock Set-ItemProperty { $script:writtenEnvironments.Add(@($Value)) }
        Mock Invoke-KjitWebNetsh {
            $command = $Arguments -join ' '
            $script:netshCalls.Add($command)
            if ($command -eq "http show urlacl") { return $script:urlAclOutput }
            if ($command -eq "http show sslcert") { return $script:sslCertOutput }
            if ($script:failUrl -and $command -match '^http add urlacl url=https:') {
                throw "HTTPS reservation failed"
            }
            if ($script:failHttpDelete -and $command -match '^http delete urlacl url=http:') {
                throw "HTTP reservation removal failed"
            }
            if ($script:failBinding -and $command -match '^http add sslcert ipport=\[::\]') {
                throw "IPv6 binding failed"
            }
            if ($script:failRollback -and $command -match '^http delete sslcert') {
                throw "Binding cleanup failed"
            }
        }
        Mock Test-KjitWebHttpsEndpoint {
            if ($script:failProbe) { throw "HTTPS verification failed" }
            return "HTTP/1.1 401 Unauthorized"
        }
    }

    It "creates a test certificate, binds both IP families, restarts, verifies, and exports only the public certificate" {
        Enable-KjitWebHttps @parameters
        $script:writtenEnvironments.Count | Should -Be 1
        $script:writtenEnvironments[0] | Should -Be @(
            "ASPNETCORE_URLS=https://*:5240/", "JustInTimeConfig=C:\JIT.config"
        )
        $script:netshCalls | Should -Contain "http add urlacl url=https://*:5240/ sddl=D:(A;;GX;;;S-1-5-18)"
        @($script:netshCalls | Where-Object { $_ -match '^http add sslcert ' }).Count | Should -Be 2
        Should -Invoke New-SelfSignedCertificate -Times 1 -Exactly -ParameterFilter {
            $CertStoreLocation -eq "Cert:\LocalMachine\My" -and
            $Type -eq "SSLServerAuthentication" -and ($KeyExportPolicy -join ',') -eq "NonExportable"
        }
        Should -Invoke Stop-Service -Times 1 -Exactly
        Should -Invoke Start-Service -Times 1 -Exactly
        Should -Invoke Test-KjitWebHttpsEndpoint -Times 1 -Exactly -ParameterFilter {
            $Port -eq 5240 -and $Thumbprint -eq "ABC123" -and $ConnectHost -eq "localhost"
        }
        Should -Invoke Export-Certificate -Times 1 -Exactly -ParameterFilter { $Type -eq "CERT" -and $NoClobber }
    }

    It "refuses existing bindings without stopping the service or creating a certificate" {
        $script:sslCertOutput = @('    IP:port : 0.0.0.0:5240')
        { Enable-KjitWebHttps @parameters } | Should -Throw '*already uses port*'
        Should -Invoke New-SelfSignedCertificate -Times 0 -Exactly
        Should -Invoke Stop-Service -Times 0 -Exactly
        Should -Invoke Set-ItemProperty -Times 0 -Exactly
    }

    It "rejects empty HTTP.sys query output before changing anything" -ForEach @(
        @{ Query = "urlacl" }
        @{ Query = "sslcert" }
    ) {
        if ($Query -eq "urlacl") { $script:urlAclOutput = @() }
        else { $script:sslCertOutput = @() }
        { Enable-KjitWebHttps @parameters } | Should -Throw '*query returned no output*'
        Should -Invoke New-SelfSignedCertificate -Times 0 -Exactly
        Should -Invoke Stop-Service -Times 0 -Exactly
    }

    It "rejects an existing export file without changing anything" {
        New-Item -ItemType File -Path $parameters.CertificatePath | Out-Null
        { Enable-KjitWebHttps @parameters } | Should -Throw '*export already exists*'
        Should -Invoke New-SelfSignedCertificate -Times 0 -Exactly
        Should -Invoke Stop-Service -Times 0 -Exactly
    }

    Context "existing HTTP reservation on the migration port" {
        BeforeEach {
            Mock Get-CimInstance { [pscustomobject]@{ StartName = "NT AUTHORITY\NETWORK SERVICE" } }
            $script:originalSddl = "D:(A;;GX;;;NS)(A;;GX;;;BA)"
            $script:urlAclOutput = @(
                "URL Reservations:",
                "-----------------",
                "    Reserved URL : http://*:5240/",
                "        User: NT AUTHORITY\NETWORK SERVICE",
                "            SDDL: $script:originalSddl",
                "    Reserved URL : http://*:5357/",
                "            SDDL: D:(A;;GX;;;BU)"
            )
        }

        It "stops the service and removes only its HTTP reservation before reserving HTTPS" {
            Enable-KjitWebHttps @parameters
            $script:netshCalls | Should -Not -Contain "http dump"
            $script:netshCalls | Should -Contain "http show urlacl"
            $script:netshCalls | Should -Contain "http show sslcert"
            $deleteIndex = $script:netshCalls.IndexOf("http delete urlacl url=http://*:5240/")
            $addIndex = $script:netshCalls.IndexOf("http add urlacl url=https://*:5240/ sddl=D:(A;;GX;;;S-1-5-20)")
            $deleteIndex | Should -BeGreaterOrEqual 0
            $addIndex | Should -BeGreaterThan $deleteIndex
            $script:netshCalls | Should -Not -Contain "http delete urlacl url=http://*:5357/"
            $script:netshCalls | Should -Not -Contain "http add urlacl url=http://*:5240/ sddl=$script:originalSddl"
            Should -Invoke Stop-Service -Times 1 -Exactly
            Should -Invoke Start-Service -Times 1 -Exactly
        }

        It "restores the original HTTP SDDL when reserving HTTPS fails" {
            $script:failUrl = $true
            { Enable-KjitWebHttps @parameters } | Should -Throw '*HTTPS reservation failed*'
            $script:netshCalls | Should -Contain "http add urlacl url=http://*:5240/ sddl=$script:originalSddl"
            $script:netshCalls | Should -Not -Contain "http delete urlacl url=https://*:5240/"
            Should -Invoke Set-ItemProperty -Times 0 -Exactly
            Should -Invoke Start-Service -Times 1 -Exactly
        }

        It "restores HTTP only after removing newly created HTTPS reservations on failed verification" {
            $script:failProbe = $true
            { Enable-KjitWebHttps @parameters } | Should -Throw '*HTTPS verification failed*'
            $deleteIndex = $script:netshCalls.IndexOf("http delete urlacl url=https://*:5240/")
            $restoreIndex = $script:netshCalls.IndexOf("http add urlacl url=http://*:5240/ sddl=$script:originalSddl")
            $deleteIndex | Should -BeGreaterOrEqual 0
            $restoreIndex | Should -BeGreaterThan $deleteIndex
            $script:writtenEnvironments[-1] | Should -Be $script:originalEnvironment
            Should -Invoke Start-Service -Times 2 -Exactly
        }

        It "does not recreate an HTTP reservation whose removal failed" {
            $script:failHttpDelete = $true
            { Enable-KjitWebHttps @parameters } | Should -Throw '*HTTP reservation removal failed*'
            @($script:netshCalls | Where-Object { $_ -match '^http add ' }).Count | Should -Be 0
            Should -Invoke Set-ItemProperty -Times 0 -Exactly
            Should -Invoke Start-Service -Times 1 -Exactly
        }

        It "keeps a previously stopped service stopped after rollback" {
            $script:initialStatus = "Stopped"
            $script:failUrl = $true
            { Enable-KjitWebHttps @parameters } | Should -Throw '*HTTPS reservation failed*'
            $script:netshCalls | Should -Contain "http add urlacl url=http://*:5240/ sddl=$script:originalSddl"
            Should -Invoke Start-Service -Times 0 -Exactly
        }

        It "refuses existing HTTPS reservations before touching the HTTP reservation" {
            $script:urlAclOutput += "    Reserved URL : https://*:5240/"
            { Enable-KjitWebHttps @parameters } | Should -Throw '*already exists*'
            Should -Invoke New-SelfSignedCertificate -Times 0 -Exactly
            Should -Invoke Stop-Service -Times 0 -Exactly
            @($script:netshCalls | Where-Object { $_ -match '^http (add|delete) ' }).Count | Should -Be 0
        }
    }

    It "removes only newly created resources when adding the second binding fails" {
        $script:failBinding = $true
        { Enable-KjitWebHttps @parameters } | Should -Throw '*IPv6 binding failed*'
        $script:netshCalls | Should -Contain "http delete sslcert ipport=0.0.0.0:5240"
        $script:netshCalls | Should -Not -Contain "http delete sslcert ipport=[::]:5240"
        $script:netshCalls | Should -Contain "http delete urlacl url=https://*:5240/"
        Should -Invoke Remove-Item -Times 1 -Exactly -ParameterFilter { $LiteralPath -eq "Cert:\LocalMachine\My\ABC123" }
        Should -Invoke Stop-Service -Times 0 -Exactly
        Should -Invoke Set-ItemProperty -Times 0 -Exactly
    }

    It "restores the exact previous environment and running state on failed verification" {
        $script:failProbe = $true
        { Enable-KjitWebHttps @parameters } | Should -Throw '*HTTPS verification failed*'
        $script:writtenEnvironments.Count | Should -Be 2
        $script:writtenEnvironments[1] | Should -Be $script:originalEnvironment
        Should -Invoke Start-Service -Times 2 -Exactly
        Should -Invoke Stop-Service -Times 2 -Exactly
        Should -Invoke Export-Certificate -Times 0 -Exactly
        @($script:netshCalls | Where-Object { $_ -match '^http delete sslcert ' }).Count | Should -Be 2
    }

    It "restores a previously stopped service to stopped on failure" {
        $script:initialStatus = "Stopped"
        $script:failProbe = $true
        { Enable-KjitWebHttps @parameters } | Should -Throw
        Should -Invoke Start-Service -Times 1 -Exactly
        Should -Invoke Stop-Service -Times 2 -Exactly
    }

    It "reports incomplete rollback and still attempts remaining cleanup and restart" {
        $script:failProbe = $true
        $script:failRollback = $true
        { Enable-KjitWebHttps @parameters } | Should -Throw '*Rollback incomplete*Binding cleanup failed*'
        $script:netshCalls | Should -Contain "http delete urlacl url=https://*:5240/"
        Should -Invoke Start-Service -Times 2 -Exactly
        Should -Invoke Remove-Item -Times 1 -Exactly
    }

    It "uses the explicit loopback host in the HTTP Host header without widening the binding" {
        $script:originalEnvironment = @("ASPNETCORE_URLS=http://127.0.0.1:5240")
        Enable-KjitWebHttps @parameters
        $script:writtenEnvironments[0] | Should -Be @("ASPNETCORE_URLS=https://127.0.0.1:5240/")
        Should -Invoke Test-KjitWebHttpsEndpoint -Times 1 -Exactly -ParameterFilter {
            $ConnectHost -eq "127.0.0.1" -and $HostHeader -eq "127.0.0.1"
        }
    }

    Context "existing certificate selected by thumbprint" {
        BeforeEach {
            $script:existingThumbprint = "0123456789ABCDEF0123456789ABCDEF01234567"
            $script:existingCertificate = [pscustomobject]@{
                Thumbprint = $script:existingThumbprint
                HasPrivateKey = $true
                NotBefore = (Get-Date).AddDays(-1)
                NotAfter = (Get-Date).AddYears(1)
                EnhancedKeyUsageList = @([pscustomobject]@{ ObjectId = "1.3.6.1.5.5.7.3.1" })
                DnsNameList = @(
                    [pscustomobject]@{ Unicode = "*.contoso.local" },
                    [pscustomobject]@{ Unicode = "jit.contoso.local" }
                )
            }
            $script:existingCertificate | Add-Member -MemberType ScriptMethod -Name Verify -Value { $true }
            Mock Get-Item { $script:existingCertificate } -ParameterFilter {
                $LiteralPath -eq "Cert:\LocalMachine\My\$script:existingThumbprint"
            }
            $existingParameters = @{
                Thumbprint = "01 23 45 67 89 ab cd ef 01 23 45 67 89 ab cd ef 01 23 45 67"
                Port = 5240
                ServiceName = "KjitWeb"
            }
        }

        It "binds the existing certificate without creating, exporting, or deleting a certificate" {
            Enable-KjitWebHttps @existingParameters
            Should -Invoke New-SelfSignedCertificate -Times 0 -Exactly
            Should -Invoke Export-Certificate -Times 0 -Exactly
            @($script:netshCalls | Where-Object {
                $_ -match "^http add sslcert .*certhash=$script:existingThumbprint "
            }).Count | Should -Be 2
            Should -Invoke Test-KjitWebHttpsEndpoint -Times 1 -Exactly -ParameterFilter {
                $DnsName -eq "jit.contoso.local" -and $Thumbprint -eq $script:existingThumbprint
            }
        }

        It "accepts a DNS name covered by a wildcard certificate" {
            Enable-KjitWebHttps @existingParameters -DnsName "server.contoso.local"
            Should -Invoke Test-KjitWebHttpsEndpoint -Times 1 -Exactly -ParameterFilter {
                $DnsName -eq "server.contoso.local" -and $HostHeader -eq "server.contoso.local"
            }
        }

        It "never deletes the existing certificate during rollback" {
            $script:failProbe = $true
            { Enable-KjitWebHttps @existingParameters } | Should -Throw '*HTTPS verification failed*'
            Should -Invoke Remove-Item -Times 0 -Exactly
            $script:writtenEnvironments[-1] | Should -Be $script:originalEnvironment
        }

        It "rejects <Scenario> before changing the service" -ForEach @(
            @{ Scenario = "a missing certificate"; Property = "Missing"; Message = "*was not found*" }
            @{ Scenario = "a certificate without private key"; Property = "HasPrivateKey"; Value = $false; Message = "*no private key*" }
            @{ Scenario = "an expired certificate"; Property = "NotAfter"; Value = (Get-Date).AddDays(-1); Message = "*not currently valid*" }
            @{ Scenario = "a client-only certificate"; Property = "EnhancedKeyUsageList"; Value = @([pscustomobject]@{ ObjectId = "1.3.6.1.5.5.7.3.2" }); Message = "*Server Authentication*" }
            @{ Scenario = "an uncovered DNS name"; Property = "DnsName"; Value = "server.other.local"; Message = "*not covered*" }
            @{ Scenario = "a nested wildcard name"; Property = "DnsName"; Value = "a.b.contoso.local"; Message = "*not covered*" }
            @{ Scenario = "an invalid thumbprint"; Property = "Thumbprint"; Value = "ABC"; Message = "*40 hexadecimal*" }
        ) {
            switch ($Property) {
                "Missing" { $script:existingCertificate = $null }
                "DnsName" { $existingParameters.DnsName = $Value }
                "Thumbprint" { $existingParameters.Thumbprint = $Value }
                default { $script:existingCertificate.$Property = $Value }
            }
            { Enable-KjitWebHttps @existingParameters } | Should -Throw $Message
            Should -Invoke Stop-Service -Times 0 -Exactly
            Should -Invoke Set-ItemProperty -Times 0 -Exactly
            @($script:netshCalls | Where-Object { $_ -match '^http add ' }).Count | Should -Be 0
        }

        It "requires DnsName when the certificate contains only wildcard names" {
            $script:existingCertificate.DnsNameList = @([pscustomobject]@{ Unicode = "*.contoso.local" })
            { Enable-KjitWebHttps @existingParameters } | Should -Throw '*Specify -DnsName*'
        }
    }

    It "connects to an IPv6 literal without URL brackets" {
        $script:originalEnvironment = @("ASPNETCORE_URLS=http://[::1]:5240")
        Enable-KjitWebHttps @parameters
        $script:writtenEnvironments[0] | Should -Be @("ASPNETCORE_URLS=https://[::1]:5240/")
        Should -Invoke Test-KjitWebHttpsEndpoint -Times 1 -Exactly -ParameterFilter {
            $ConnectHost -eq "::1" -and $HostHeader -eq "[::1]"
        }
    }
}

Describe "KjitWeb HTTPS maintenance compatibility" {
    It "requires either -SelfSigned with -DnsName or -Thumbprint" {
        $command = Get-Command -Name $scriptPath
        $sets = @{}
        foreach ($set in $command.ParameterSets) {
            $sets[$set.Name] = @($set.Parameters | Where-Object IsMandatory | ForEach-Object Name | Sort-Object)
        }
        $sets.Keys | Sort-Object | Should -Be @("SelfSigned", "Thumbprint")
        $sets["SelfSigned"] | Should -Be @("DnsName", "SelfSigned")
        $sets["Thumbprint"] | Should -Be @("Thumbprint")
        $command.Parameters["CertificatePath"].ParameterSets.Keys | Should -Be @("SelfSigned")
    }

    It "retains the HTTPS scheme when changing allowed clients" {
        $path = Join-Path $repoRoot "src\C#\Kjitweb\set-kjitweb-allowedclient.ps1"
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
        $definition = $ast.Find({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq "Get-ServiceUrlFromAllowedClient"
        }, $true)
        . ([scriptblock]::Create($definition.Extent.Text))
        Get-ServiceUrlFromAllowedClient -Client localhost -Port 5240 -Scheme https | Should -Be "https://*:5240"
        Get-ServiceUrlFromAllowedClient -Client localhost -Port 5240 | Should -Be "http://*:5240"
    }
}

Describe "KjitWeb HTTPS endpoint verification" {
    BeforeAll {
        Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Net;
using System.Net.Security;
using System.Net.Sockets;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading.Tasks;

public sealed class KjitWebTlsTestServer : IDisposable
{
    private readonly TcpListener listener;
    private readonly RSA key;
    private readonly string responseStatus;
    public readonly X509Certificate2 Certificate;
    public readonly Task Completion;
    public int Port { get { return ((IPEndPoint)listener.LocalEndpoint).Port; } }

    public KjitWebTlsTestServer(string responseStatus = "HTTP/1.1 401 Unauthorized")
    {
        this.responseStatus = responseStatus;
        key = RSA.Create(2048);
        var request = new CertificateRequest("CN=server.contoso.local", key,
            HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
        var names = new SubjectAlternativeNameBuilder();
        names.AddDnsName("server.contoso.local");
        request.CertificateExtensions.Add(names.Build());
        // Schannel requires a non-ephemeral private key; the temporary import is disposed below.
        using (var generated = request.CreateSelfSigned(DateTimeOffset.Now.AddMinutes(-1),
            DateTimeOffset.Now.AddMinutes(5)))
        {
#pragma warning disable SYSLIB0057
            Certificate = new X509Certificate2(generated.Export(X509ContentType.Pfx));
#pragma warning restore SYSLIB0057
        }
        listener = new TcpListener(IPAddress.Loopback, 0);
        listener.Start();
        Completion = Task.Run((Action)Serve);
    }

    private void Serve()
    {
        using (var client = listener.AcceptTcpClient())
        using (var stream = new SslStream(client.GetStream(), false))
        {
            stream.AuthenticateAsServer(Certificate, false,
                System.Security.Authentication.SslProtocols.Tls12, false);
            var reader = new StreamReader(stream);
            string line;
            do { line = reader.ReadLine(); } while (!String.IsNullOrEmpty(line));
            var response = Encoding.ASCII.GetBytes(
                responseStatus + "\r\nContent-Length: 0\r\nConnection: close\r\n\r\n");
            stream.Write(response, 0, response.Length);
        }
    }

    public void Dispose()
    {
        listener.Stop();
        Certificate.Dispose();
        key.Dispose();
    }
}
'@
    }

    It "accepts a real TLS connection with the exact untrusted test certificate and a 401 response" {
        Mock Start-Sleep { throw "TLS verification failed on the first attempt." }
        $server = [KjitWebTlsTestServer]::new()
        try {
            $status = Test-KjitWebHttpsEndpoint -ConnectHost "127.0.0.1" `
                -DnsName "server.contoso.local" -HostHeader "server.contoso.local" `
                -Port $server.Port -Thumbprint $server.Certificate.Thumbprint
            $status | Should -Be "HTTP/1.1 401 Unauthorized"
            $server.Completion.Wait(3000) | Should -BeTrue
        }
        catch {
            if ($server.Completion.IsFaulted) {
                throw "$($_.Exception.Message) Server: $($server.Completion.Exception)"
            }
            throw
        }
        finally {
            $server.Dispose()
        }
    }

    It "rejects <Scenario> over a real TLS connection" -ForEach @(
        @{ Scenario = "a different certificate"; WrongThumbprint = $true; Name = "server.contoso.local"; Status = "HTTP/1.1 401 Unauthorized" }
        @{ Scenario = "a mismatched DNS name"; WrongThumbprint = $false; Name = "wrong.contoso.local"; Status = "HTTP/1.1 401 Unauthorized" }
        @{ Scenario = "an unavailable HTTP service"; WrongThumbprint = $false; Name = "server.contoso.local"; Status = "HTTP/1.1 503 Service Unavailable" }
    ) {
        Mock Start-Sleep { throw "HTTPS verification requested a retry." }
        $server = [KjitWebTlsTestServer]::new($Status)
        try {
            $thumbprint = if ($WrongThumbprint) { "000000" } else { $server.Certificate.Thumbprint }
            {
                Test-KjitWebHttpsEndpoint -ConnectHost "127.0.0.1" `
                    -DnsName $Name -HostHeader "server.contoso.local" `
                    -Port $server.Port -Thumbprint $thumbprint
            } | Should -Throw "*requested a retry*"
        }
        finally {
            $server.Dispose()
        }
    }
}
