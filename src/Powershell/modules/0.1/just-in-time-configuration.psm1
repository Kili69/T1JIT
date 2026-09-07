#requires -PSEdition Desktop

<#
Module Info

Author: Andreas Lucas [MSFT]
Download: 

Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. 
The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims 
all implied warranties including, without limitation, any implied warranties of merchantability 
or of fitness for a particular purpose. The entire risk arising out of the use or performance of 
the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, 
or anyone else involved in the creation, production, or delivery of the scripts be liable for any 
damages whatsoever (including, without limitation, damages for loss of business profits, business 
interruption, loss of business information, or other pecuniary loss) arising out of the use of or 
inability to use the sample scripts or documentation, even if Microsoft has been advised of the 
possibility of such damages
#>

#region Functions
function Add-JitServerOU{
    <#
    .SYNOPSIS
        Adds an Active Directory search base to the JIT server configuration.
    .DESCRIPTION
        Reads the JIT configuration from the file identified by the
        JustInTimeConfig environment variable and determines which domain in the
        current forest owns the supplied distinguished name. If the AD object exists
        and is not already configured, its distinguished name is appended to
        T1Searchbase and the JSON configuration file is rewritten.

        Existing entries are left unchanged. Although the command is intended for
        organizational units, the current validation accepts any AD object whose
        distinguished name can be resolved.
    .PARAMETER OU
        Distinguished name of the search base, including its domain components.
        The value can be supplied through the pipeline.
    .EXAMPLE
        Add-JitServerOU -OU "OU=Member Servers,DC=contoso,DC=com"

        Adds the Member Servers OU to T1Searchbase when it exists and is not already
        configured.
    .EXAMPLE
        "OU=Member Servers,DC=contoso,DC=com" | Add-JitServerOU

        Supplies the distinguished name through the pipeline.
    .INPUTS
        System.String.
    .OUTPUTS
        None.
    .NOTES
        This function is exported by the Just-In-time module. It requires a valid
        JustInTimeConfig environment variable, a readable and writable JSON
        configuration file, and access to the ActiveDirectory module and target
        forest.

        An invalid or unreachable distinguished name causes an ArgumentException.
    #>

    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$OU
    )

    # Load the persisted configuration that will receive the additional search base.
    $config = Get-Content $env:JustInTimeConfig | ConvertFrom-Json

    # Extract the domain DN suffix from the supplied distinguished name.
    $DomainDN = [regex]::Match($OU,"dc=.+").Value

    # Find the forest domain whose distinguished name matches the extracted suffix.
    foreach ($ADDomainDNS in (Get-ADForest).Domains){
        IF ($DomainDN -eq $(Get-ADDomain -Server $ADDomainDNS).DistinguishedName){
            break;
        }
    }

    # Resolve the object in its owning domain before persisting it as a search base.
    if ((Get-ADObject -Filter "DistinguishedName -eq '$OU'" -server $ADDomainDNS)){
        if ($config.T1Searchbase -contains $OU){
            # Keep the operation idempotent and inform interactive callers.
            Write-Host "$OU is already defined" -ForegroundColor Yellow
        } else {
            # Append the DN and rewrite the configuration with the updated array.
            $config.T1Searchbase += $OU
            ConvertTo-Json $config | Out-File $env:JustInTimeConfig -Confirm:$false
        }
    } else {
        # Reject values that do not identify an object in the selected forest domain.
        throw [System.ArgumentException]::new("Invalid DistinguishedName", $OU)
    }
}
function Get-JitServerOU{
    <#
    .SYNOPSIS
        Returns the configured Active Directory search bases for JIT servers.
    .DESCRIPTION
        Reads the JSON configuration file identified by the JustInTimeConfig
        environment variable. The configured T1Searchbase entries are displayed as
        a readable list, while the complete configuration object is written to the
        success pipeline for further processing.
    .EXAMPLE
        Get-JitServerOU

        Displays all configured JIT server search bases and returns the complete
        configuration object.
    .EXAMPLE
        $searchBases = (Get-JitServerOU).T1Searchbase

        Displays the configured search bases and stores them for further processing.
    .OUTPUTS
        System.Management.Automation.PSCustomObject. The complete deserialized JIT
        configuration object.
    .NOTES
        This function is exported by the Just-In-time module. It requires a valid
        JustInTimeConfig environment variable and a readable JSON configuration file.
    #>

    # Keep presentation on the host stream so only the configuration object enters
    # the success pipeline.
    $config = Get-Content $env:JustInTimeConfig | ConvertFrom-Json
    $searchBases = @($config.T1Searchbase)

    Write-Host "Configured JIT server search bases:" -ForegroundColor Cyan
    if ($searchBases.Count -eq 0) {
        Write-Host "  No search bases are configured." -ForegroundColor Yellow
    } else {
        foreach ($searchBase in $searchBases) {
            Write-Host "  - $searchBase"
        }
    }

    return $config
}
function Remove-JITServerOU{
    <#
    .SYNOPSIS
        Removes an Active Directory search base from the JIT server configuration.
    .DESCRIPTION
        Reads the JSON configuration file identified by the JustInTimeConfig
        environment variable. If the supplied distinguished name is present in
        T1Searchbase, the function removes it and all entries with the same ComputerOU
        from the configured delegation file. Both configuration files are rewritten
        when necessary. Missing search-base entries leave the files unchanged and
        produce an informational message.
    .PARAMETER OU
        Distinguished name of the search base to remove. The value can be supplied
        through the pipeline.
    .EXAMPLE
        $removed = Remove-JITServerOU -OU "OU=Member Servers,DC=contoso,DC=com"

        Removes the Member Servers OU and its delegation references, then stores the
        removed configuration data in $removed.
    .EXAMPLE
        "OU=Member Servers,DC=contoso,DC=com" | Remove-JITServerOU

        Supplies the distinguished name through the pipeline.
    .INPUTS
        System.String.
    .OUTPUTS
        System.Management.Automation.PSCustomObject. Returns the removed OU, the
        number of removed delegation references, and the removed delegation entries.
    .NOTES
        This function is exported by the Just-In-time module. It requires a valid
        JustInTimeConfig environment variable and a readable and writable JSON
        configuration file.
    #>

    param(
        [Parameter (Mandatory = $true, ValueFromPipeline = $true)]
        [string]$OU
    )

    # Load the main configuration and preserve the configured spelling of the OU.
    $config = Get-Content -LiteralPath $env:JustInTimeConfig -Raw | ConvertFrom-Json
    if ($config.T1Searchbase -contains $OU){
        $removedOU = @($config.T1Searchbase | Where-Object { $_ -eq $OU })[0]
        $remainingSearchBases = @($config.T1Searchbase | Where-Object { $_ -ne $OU })
        $removedDelegations = @()
        $delegationConfigPath = [string]$config.DelegationConfigPath

        # Remove every delegation that targets the removed server search base.
        if (-not [string]::IsNullOrWhiteSpace($delegationConfigPath) -and
            (Test-Path -LiteralPath $delegationConfigPath -PathType Leaf)) {
            $currentDelegations = @(Get-Content -LiteralPath $delegationConfigPath -Raw | ConvertFrom-Json)
            $removedDelegations = @($currentDelegations | Where-Object { $_.ComputerOU -eq $OU })

            if ($removedDelegations.Count -gt 0) {
                $remainingDelegations = @($currentDelegations | Where-Object { $_.ComputerOU -ne $OU })
                ConvertTo-Json -InputObject $remainingDelegations -Depth 10 |
                    Out-File -LiteralPath $delegationConfigPath -Confirm:$false
            }
        }

        # Persist the server search-base change after stale delegations are removed.
        $config.T1Searchbase = $remainingSearchBases
        ConvertTo-Json -InputObject $config -Depth 10 |
            Out-File -LiteralPath $env:JustInTimeConfig -Confirm:$false

        # Return one object so callers can continue processing the removed data.
        return [PSCustomObject]@{
            OU                             = $removedOU
            RemovedDelegationCount         = $removedDelegations.Count
            RemovedDelegations             = $removedDelegations
        }
    } else {
        Write-Host "$OU is not defined" -ForegroundColor Yellow
    }
}
#endregion


<#
.SYNOPSIS
    Loads the JIT configuration through the KjitCore library.
.DESCRIPTION
    Resolves and loads KjitCore.dll, including its local dependencies, and delegates
    configuration loading to KjitCore.KjitCore.LoadJitConfiguration.

    An explicit ConfigurationFile value takes precedence over the JustInTimeConfig
    environment variable. Existing files are converted to absolute paths. Non-file
    values are passed unchanged as Active Directory configuration common names. If
    neither source is specified, the default common name "Jit-Configuration" is used.
.PARAMETER configurationFile
    Optional configuration file path or Active Directory configuration common name.
.INPUTS
    None. Pipeline input is not supported.
.OUTPUTS
    The configuration object returned by KjitCore.
.EXAMPLE
    Get-JITConfig

    Loads the source in JustInTimeConfig, or the default Active Directory object when
    the environment variable is empty.
.EXAMPLE
    Get-JITConfig -ConfigurationFile .\jit.config

    Loads the configuration from the specified JSON file.
.EXAMPLE
    Get-JITConfig -ConfigurationFile "Jit-Configuration-Test"

    Loads the Active Directory configuration with the specified common name.
.NOTES
    This function is exported by the Just-In-time module. KjitCore.dll must be present
    in a supported module, development, release, or debug location.
#>
function Get-JITconfig{
    param(
        [Parameter (Mandatory=$false, Position=0)]
        [string]$configurationFile
    )
    function Resolve-KjitCoreAssemblyPath {
        <#
        .SYNOPSIS
            Locates the KjitCore assembly used by the module.
        .DESCRIPTION
            Searches known module, source-build, and packaged-output locations in
            precedence order and returns the first existing KjitCore.dll as an
            absolute provider path. This is a private helper for Get-JITconfig.
        .OUTPUTS
            System.String. The absolute path to KjitCore.dll.
        #>

        # Prefer assemblies deployed beside the module before development build outputs.
        $candidates = @(
            (Join-Path -Path $PSScriptRoot -ChildPath "KjitCore.dll"),
            (Join-Path -Path $PSScriptRoot -ChildPath "..\KjitCore.dll"),
            (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\C#\KjitCore\bin\Release\net48\KjitCore.dll"),
            (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\C#\KjitCore\bin\Debug\net48\KjitCore.dll"),
            (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\src\C#\KjitCore\bin\Release\net48\KjitCore.dll"),
            (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\src\C#\KjitCore\bin\Debug\net48\KjitCore.dll"),
            (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\C#\KjitCore\bin\Release\netstandard2.0\KjitCore.dll"),
            (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\C#\KjitCore\bin\Debug\netstandard2.0\KjitCore.dll"),
            (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\src\C#\KjitCore\bin\Release\netstandard2.0\KjitCore.dll"),
            (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\src\C#\KjitCore\bin\Debug\netstandard2.0\KjitCore.dll")
        )

        foreach ($candidate in $candidates) {
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                return (Resolve-Path -LiteralPath $candidate -ErrorAction Stop).ProviderPath
            }
        }

        throw "KjitCore.dll not found. Build KjitCore and ensure the DLL is available."
    }

    function Resolve-JitConfigurationSource {
        <#
        .SYNOPSIS
            Resolves the source passed to the KjitCore configuration loader.
        .DESCRIPTION
            Uses a non blank explicit value first, followed by JustInTimeConfig, and
            finally the Active Directory common name "Jit-Configuration". Existing
            files are returned as absolute paths; other values remain common names.
            This is a private helper for Get-JITconfig.
        .PARAMETER InputValue
            Optional explicit configuration file path or Active Directory common name.
        .OUTPUTS
            System.String. An absolute file path or Active Directory common name.
        #>

        param(
            [string]$InputValue
        )

        # Explicit input always takes precedence over the environment variable.
        if (-not [string]::IsNullOrWhiteSpace($InputValue)) {
            $trimmed = $InputValue.Trim()
            if (Test-Path -LiteralPath $trimmed -PathType Leaf) {
                return (Resolve-Path -LiteralPath $trimmed -ErrorAction Stop).ProviderPath
            }

            return $trimmed
        }

        if ([string]::IsNullOrWhiteSpace($env:JustInTimeConfig)) {
            return "Jit-Configuration"
        }

        $envSource = $env:JustInTimeConfig.Trim()
        if ($envSource -eq "") {
            return "Jit-Configuration"
        }

        if (Test-Path -LiteralPath $envSource -PathType Leaf) {
            return (Resolve-Path -LiteralPath $envSource -ErrorAction Stop).ProviderPath
        }

        return $envSource
    }

    function Import-KjitCoreDependencies {
        <#
        .SYNOPSIS
            Preloads local dependency assemblies required by KjitCore.
        .DESCRIPTION
            Attempts to load known dependencies from the KjitCore assembly directory
            in dependency order. Individual failures are suppressed so the subsequent
            KjitCore load can return the actionable error. This is a private helper for
            Get-JITconfig.
        .PARAMETER KjitCoreAssemblyPath
            Absolute path to KjitCore.dll. Its parent directory is searched.
        .OUTPUTS
            None.
        #>

        param(
            [Parameter(Mandatory = $true)]
            [string]$KjitCoreAssemblyPath
        )

        $assemblyDirectory = Split-Path -Path $KjitCoreAssemblyPath -Parent
        $dependencyOrder = @(
            "System.Runtime.CompilerServices.Unsafe.dll",
            "System.Buffers.dll",
            "System.Memory.dll",
            "System.Text.Encodings.Web.dll",
            "System.Threading.Tasks.Extensions.dll",
            "Microsoft.Bcl.AsyncInterfaces.dll",
            "System.Text.Json.dll"
        )

        foreach ($dependency in $dependencyOrder) {
            $dependencyPath = Join-Path -Path $assemblyDirectory -ChildPath $dependency
            if (Test-Path -LiteralPath $dependencyPath -PathType Leaf) {
                try {
                    Add-Type -Path $dependencyPath -ErrorAction SilentlyContinue
                }
                catch {
                    # Best-effort preload; main assembly load returns the final actionable error.
                }
            }
        }
    }

    # Reject a conflicting KjitCore version that cannot be unloaded from this session.
    $assemblyPath = Resolve-KjitCoreAssemblyPath
    $alreadyLoadedAssembly = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -eq "KjitCore" } | Select-Object -First 1
    if ($null -ne $alreadyLoadedAssembly -and -not [string]::IsNullOrWhiteSpace($alreadyLoadedAssembly.Location)) {
        $loadedPath = (Resolve-Path -LiteralPath $alreadyLoadedAssembly.Location -ErrorAction SilentlyContinue).ProviderPath
        $targetPath = (Resolve-Path -LiteralPath $assemblyPath -ErrorAction SilentlyContinue).ProviderPath
        if ($loadedPath -and $targetPath -and ($loadedPath -ne $targetPath)) {
            throw "KjitCore is already loaded from '$loadedPath'. The module needs '$targetPath'. Start a new PowerShell session and import the module again."
        }
    }

    # Load KjitCore only once per session.
    if (-not ("KjitCore.KjitCore" -as [type])) {
        try {
            Import-KjitCoreDependencies -KjitCoreAssemblyPath $assemblyPath
            Add-Type -Path $assemblyPath -ErrorAction Stop
        }
        catch {
            throw "KjitCore.dll was found at '$assemblyPath' but could not be loaded in this PowerShell host. Use a compatible host/runtime for the current KjitCore build. Details: $($_.Exception.Message)"
        }
    }

    if (-not ("KjitCore.KjitCore" -as [type])) {
        throw "KjitCore type was not loaded successfully."
    }

    # Let KjitCore interpret absolute paths as files and other values as AD common names.
    $source = Resolve-JitConfigurationSource -InputValue $configurationFile
    return [KjitCore.KjitCore]::LoadJitConfiguration($source)
}


