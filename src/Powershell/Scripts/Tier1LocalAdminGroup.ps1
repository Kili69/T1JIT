<# 
Script Info

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
<#
.Synopsis
    This script create and maintain the local administrator groups

.DESCRIPTION
    this script run in the context of a GroupManagedServiceAccount and create a domain local group for each 
    server in the Tier1 Management OU
.PARAMETER configurationFile
    The ful qualified path to the configuration file. If this parameter is not available the script 
    will use the JIT.config will use the jit.config in the current directory

.EXAMPLE
    .\Tier1LocalAdminGroup.ps1
    run the script with the configuration file in the current directory
    .\Tier1LocalAdminGroup.ps1 -configurationFile "\\contoso.com\SYSVOL\contoso.com\JIT\jit.config"
    run the script with a dedicated configuration fil

.INPUTS
    -configurationFile
        use a dedicated configuration file. use this parameter if the configuration file is not in the working directory

.OUTPUTS
   none
.NOTES
    Version Tracking
    2021-10-12 
    Version 0.1
        - First internal release
    Version 0.1.2021294
        - Default installation directory changed from c:\Program Files\windowsPowershell\script to %working directory%
        - Added Event logging
    Version 0.1.20231113
        -exit code on error
        -mulit domain-forest support 
        -Domain DNS name on groups replaced with Domain NetBiosName
    Version 0.1.20231204
        - New Event 1004 if a OU doesn't exists
        - Code documentation
    Version 0.1.20240124
        - Bug fix on searchbase
    Version 0.1.20240202
        - Avoid error messages while search for computers in a different OU
        - Addtional Debug messages
    Version 0.1.20240726
        - If the paramter configuration file is not provided, the global environment variable JustInTimeConfig will be used
        instead of the local directory
    Version 0.1.20241227
        by ANdreas Luy
	Fixing minor bugs
    Version 0.1.20260409
        by Kili
        - New groups will be created on the PDC. If the PDC is not available the script will try to connect to any DC with ADWS enabled. 
            If no DC is available the script will terminate with an error 0x3EA
    Version 0.1.20260428
        by Kili
        - fiex a bug while converting ActiveDirectoryObjectcollection to a string 
    Version 0.1.20260907
        - Write an Application event with the per-run debug transcript path at startup.
        - Write computer-search failures to the Application log and debug transcript.
        - Support a global debug directory and one-generation 1 MB log rotation.
        - Register a missing Application event source when permitted and otherwise continue with transcript logging.
        - Ignore configured search-base paths that do not exist in an individual domain.
    Version 0.1.20260908
        - Report LDAP match and Tier 0 exclusion counts in verbose output.
        - Diagnose zero-result searches with computer operating-system and primary-group values.
        - Report configured and resolved debug-log paths.
        - Support ExcludeComputerOU and prevent an empty exclusion path from filtering all computers.


    Event ID
    1000 Information LocalAdmin Group created
    1001 Error Group not created
    1002 Information permanent user removed
    1003 Error removing permanent user
    1004 Warning The Organizational unit doesn't exists
    1100 Error configuration file missing 
    3100 Information Script started; message contains the debug log path
    3101 Error Computer search failed; message contains the debug log path
    
    exit code 
    0x3E8 configuratin file missing
    0x3E9 invalid configuration file version
    0x3EA malformed JSON file
    0x3EB can not connect to a DC on ADWS port
    0x3EC unexpected error while evaluating the PDC
#>
[CmdletBinding ( SupportsShouldProcess)]
Param(
    [Parameter (Mandatory = $false, Position = 0)]
    $configurationFile = $env:JustInTimeConfig
)
#Script Version
$_scriptVersion = "0.1.20260908"
$MinConfigVersionBuild = 20240123
Write-Debug "Script Version $_scriptVersion"
$tcpAdwsPort = 9389

function Resolve-DebugLogDirectory {
    param([string]$ConfigurationSource)

    $defaultPath = [IO.Path]::GetTempPath()
    if ([string]::IsNullOrWhiteSpace($ConfigurationSource) -or
        -not (Test-Path -LiteralPath $ConfigurationSource -PathType Leaf)) {
        return $defaultPath
    }

    try {
        $rawConfiguration = Get-Content -LiteralPath $ConfigurationSource -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $debugLogPathProperty = $rawConfiguration.PSObject.Properties["DebugLogPath"]
        if ($null -eq $debugLogPathProperty -or [string]::IsNullOrWhiteSpace([string]$debugLogPathProperty.Value)) {
            return $defaultPath
        }

        $expandedPath = [Environment]::ExpandEnvironmentVariables([string]$debugLogPathProperty.Value)
        if ([string]::IsNullOrWhiteSpace($expandedPath) -or -not [IO.Path]::IsPathRooted($expandedPath)) {
            return $defaultPath
        }

        return $expandedPath
    }
    catch {
        return $defaultPath
    }
}

function Exit-Tier1LocalAdminGroup {
    param([int]$ExitCode)

    Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
    exit $ExitCode
}

$applicationEventSource = "T1JIT Tier1LocalAdminGroup"
$applicationEventLoggingUnavailable = $false
function Write-Tier1ApplicationEvent {
    param (
        [Parameter(Mandatory)]
        [int]$EventId,
        [Parameter(Mandatory)]
        [ValidateSet("Error", "Information", "Warning")]
        [string]$EntryType,
        [Parameter(Mandatory)]
        [string]$Message
    )

    if ($script:applicationEventLoggingUnavailable) {
        return
    }

    try {
        if (-not [Diagnostics.EventLog]::SourceExists($script:applicationEventSource)) {
            New-EventLog -LogName Application -Source $script:applicationEventSource -ErrorAction Stop
        }

        Write-EventLog -LogName Application -Source $script:applicationEventSource -EventId $EventId -EntryType $EntryType -Message $Message -ErrorAction Stop
    }
    catch {
        $script:applicationEventLoggingUnavailable = $true
        Write-Warning "Application event logging is unavailable for source '$script:applicationEventSource': $($_.Exception.Message) Detailed logging remains available in '$script:debugLogFile'."
    }
}

$debugLogDirectory = Resolve-DebugLogDirectory -ConfigurationSource $configurationFile
if (-not (Test-Path -LiteralPath $debugLogDirectory -PathType Container)) {
    $null = New-Item -Path $debugLogDirectory -ItemType Directory -Force -ErrorAction Stop
}
$debugLogFile = Join-Path $debugLogDirectory "Tier1LocalAdminGroup-$env:COMPUTERNAME.log"
$savedDebugLogFile = [IO.Path]::ChangeExtension($debugLogFile, ".sav")
$maxDebugLogFileSize = 1MB
Get-ChildItem -LiteralPath $debugLogDirectory -Filter "Tier1LocalAdminGroup-$env:COMPUTERNAME*" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -ne $debugLogFile -and $_.FullName -ne $savedDebugLogFile } |
    Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem -LiteralPath $debugLogDirectory -Filter "Tier1LocalAdminGroup-*.log" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^Tier1LocalAdminGroup-\d{8}-\d{6}-\d+\.log$' } |
    Remove-Item -Force -ErrorAction SilentlyContinue
if ((Test-Path -LiteralPath $debugLogFile -PathType Leaf) -and
    (Get-Item -LiteralPath $debugLogFile).Length -ge $maxDebugLogFileSize) {
    Remove-Item -LiteralPath $savedDebugLogFile -Force -ErrorAction SilentlyContinue
    Move-Item -LiteralPath $debugLogFile -Destination $savedDebugLogFile -Force -ErrorAction Stop
}
Start-Transcript -Path $debugLogFile -Append -Force -ErrorAction Stop | Out-Null
Write-Verbose "Configuration source: $configurationFile"
Write-Verbose "Detailed logging: $debugLogFile"
Write-Tier1ApplicationEvent -EventId 3100 -EntryType Information -Message "Tier1LocalAdminGroup.ps1 started. Detailed logging: $debugLogFile"

#Read configuration
#if the configuration file doesnt exists or is malformed terminat the script
try {
        $config = Get-JITconfig -configurationFile $configurationFile
    Write-Verbose "Configured DebugLogPath '$($config.DebugLogPath)' resolves to '$debugLogDirectory' for the current account."
} catch [System.ArgumentException]{
    Write-Error -Message "invalid JSON file $configurationFile"
    Exit-Tier1LocalAdminGroup -ExitCode 0x3EA
}

# Prefer the current multi-value property and fall back to the legacy single OU path.
$excludedComputerOuPaths = @()
if ($null -ne $config.PSObject.Properties["ExcludeComputerOU"]) {
    $excludedComputerOuPaths = @($config.ExcludeComputerOU)
}
elseif ($null -ne $config.PSObject.Properties["LDAPT0ComputerPath"]) {
    $excludedComputerOuPaths = @($config.LDAPT0ComputerPath)
}
$excludedComputerOuPaths = @($excludedComputerOuPaths |
    ForEach-Object { ([string]$_).Trim() } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    Select-Object -Unique)
$excludedComputerOuDescription = if ($excludedComputerOuPaths.Count -gt 0) { $excludedComputerOuPaths -join "; " } else { "<none>" }
Write-Verbose "Configured Tier 0 computer OU exclusion(s): $excludedComputerOuDescription"

[int]$configBuildVersion = [regex]::Match($config.ConfigScriptVersion, "[^\.]+$").Value
if ($configBuildVersion -lt $MinconfigVersionBuild) {
    Write-Output "invalid config version $($config.ConfigScriptVersion)). Configuration build $MinConfigVersionBuild or higher required"
    Exit-Tier1LocalAdminGroup -ExitCode 0x3E9
}
#endregion

#region Evaluate PDC
try{
    $workingDC = (Get-ADDomainController -Discover -Service "PrimaryDC").HostName[0].Tostring()
    if (!(Test-NetConnection -ComputerName $workingDC -Port $tcpAdwsPort -InformationLevel Quiet -ErrorAction SilentlyContinue)) {
        $workingDC = (Get-ADDomainController -Discover -Service ADWS).HostName[0].Tostring()
    }
    if ([string]::IsNullOrEmpty($workingDC)) {
        Write-Error -Message "Can not connect to a DC  on ADWS port. Please check the connectivity and the availability of the AD Webservice"
        Exit-Tier1LocalAdminGroup -ExitCode 0x3EB
    }
} 
catch {
    Write-Error -Message "a unexpected error occured while evaluating the ADWS service $Error"    
    Exit-Tier1LocalAdminGroup -ExitCode 0x3EC
}
#end region
#region Group creation
# In this region the AD groups will be created and users on existing groups will be removed if they are permanent member
#
# if Mulit-Domain Mode is enabled add all domains to the $aryDomainList otherwise add only the current domain to the ary
$aryDomainList = @()
if ($config.EnableMultiDomainSupport) {
    $aryDomainList += (Get-ADForest).Domains
}
else {
    $aryDomainList += (Get-ADdomain).DNSRoot
}
#Region show progress activit init
#This section is not mandatroy. It is only required for the interactive execution of the script to show the progress
$Starttime = Get-Date #Start time of the script to evaluate the runtime of the script
$GroupCount = 0 #Initialize the over all counter of detected computer object 
$Statuscounter = 0 #Initialize the counter a executed groups activites. THis could be creating the group or remove permanent objects from the group
#endregion
Foreach ($Domain in $aryDomainList) {
    #Woring on every domain in the Forest
    Write-Debug "Working on Domain $Domain"
    #The searchbase parameter defines the OU where the script is looking for computer objects. if the value is <DomainRoot> the script searches in the entrie domain from computer objects
    Foreach ($ConfiguredSearchBase in $config.T1Searchbase) {
        $domainDistinguishedName = (Get-ADDomain -Server $Domain).DistinguishedName
        $searchBaseIsFullDn = $ConfiguredSearchBase -like "*DC=*"
        if ($searchBaseIsFullDn) {
            $searchBaseDomain = @($ConfiguredSearchBase -split "," | Where-Object { $_ -match "^\s*DC=" } | ForEach-Object { $_ -replace "(?i)^\s*DC=", "" }) -join "."
            if ($Domain -ine $searchBaseDomain) {
                Write-Verbose "Skipping fully qualified search base '$ConfiguredSearchBase' while processing domain '$Domain'; it belongs to '$searchBaseDomain'."
                continue
            }
            $SearchBase = $ConfiguredSearchBase
        }
        else {
            if ($ConfiguredSearchBase -eq "<DomainRoot>") {
                $SearchBase = $domainDistinguishedName
            }
            else {
                $SearchBase = "$ConfiguredSearchBase,$domainDistinguishedName"
            }
        }
        #Validate the OU exists. It is not mandatory to have the same Tier 1 OU structure in all domains
        if ($SearchBase -like "*$domainDistinguishedName") {
            #Search for computer object in the OU and based on the LDAP filter. While the LDAP filter doesn't support DistinguishedNames the query must work again s the $searchbase
            try {
                Write-Verbose "Searching computers in domain '$Domain' with search base '$SearchBase' and LDAP filter '$($config.LDAPT1Computers)'."
                $ldapMatches = @(Get-ADComputer -LDAPFilter $config.LDAPT1Computers -Properties memberof -SearchBase $SearchBase -Server $Domain -ErrorAction Stop)
                $serverList = @($ldapMatches | Where-Object {
                    $computerDistinguishedName = [string]$_.DistinguishedName
                    $isExcluded = $false
                    foreach ($excludedComputerOuPath in $excludedComputerOuPaths) {
                        if ($computerDistinguishedName.IndexOf($excludedComputerOuPath, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                            $isExcluded = $true
                            break
                        }
                    }
                    -not $isExcluded
                })
                Write-Verbose "LDAP query returned $($ldapMatches.Count) computer(s); $($serverList.Count) remain after applying Tier 0 OU exclusion(s): $excludedComputerOuDescription."

                if ($serverList.Count -eq 0) {
                    if ($ldapMatches.Count -gt 0) {
                        Write-Verbose "All matching computers were excluded because their distinguished names contain one of the configured Tier 0 OU paths."
                    }
                    elseif ($VerbosePreference -ne [Management.Automation.ActionPreference]::SilentlyContinue) {
                        # A broad diagnostic query explains why a valid LDAP filter returned no computers.
                        $computersInSearchBase = @(Get-ADComputer -LDAPFilter "(objectClass=computer)" -Properties OperatingSystem, PrimaryGroupID -SearchBase $SearchBase -Server $Domain -ErrorAction Stop)
                        Write-Verbose "Zero-result diagnostic: search base '$SearchBase' contains $($computersInSearchBase.Count) computer object(s) before applying LDAPT1Computers."
                        foreach ($computer in $computersInSearchBase | Select-Object -First 20) {
                            $operatingSystem = if ([string]::IsNullOrWhiteSpace([string]$computer.OperatingSystem)) { "<not set>" } else { [string]$computer.OperatingSystem }
                            Write-Verbose "Candidate '$($computer.DistinguishedName)': OperatingSystem='$operatingSystem', PrimaryGroupID='$($computer.PrimaryGroupID)'."
                        }
                        if ($computersInSearchBase.Count -gt 20) {
                            Write-Verbose "Zero-result diagnostic limited to the first 20 of $($computersInSearchBase.Count) computer objects."
                        }
                    }
                }
            }
            catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                if ($searchBaseIsFullDn) {
                    Write-Verbose "Skipping fully qualified search base '$SearchBase' because it does not exist in its domain '$Domain'."
                }
                else {
                    Write-Verbose "Skipping relative search base '$ConfiguredSearchBase' because '$SearchBase' does not exist in domain '$Domain'; remaining domains will still be searched."
                }
                continue
            }
            catch {
                $computerSearchError = "Computer search failed for '$SearchBase' in domain '$Domain': $($_.Exception.Message). Detailed logging: $debugLogFile"
                Write-Tier1ApplicationEvent -EventId 3101 -EntryType Error -Message $computerSearchError
                Write-Error $computerSearchError
                continue
            }
            $GroupCount += $serverList.count #Display parameter to show the amount of computer object currently working on.
#            $NBDomain = (Get-ADDomain -Server $Domain).NetbiosName
            $DnsDomain = (Get-ADDomain -Server $Domain).DnsRoot
            Foreach ($Server in $serverList) {
                $Statuscounter ++
                #Show progress for interactive execution
                Write-Progress -Activity "Group Management" -Status "groups completed $Statuscounter" -PercentComplete (($Statuscounter / $GroupCount) * 100)
                #If MulitDomain Support is enabled the NetBIOS domain name will be added between Admin-Prefix and the computer name
                if ($config.EnableMultiDomainSupport) {
                    $GroupName = "$($config.AdminPrefix)$($DnsDomain)$($config.DomainSeparator)$($server.Name)"
                }
                else {
                    $GroupName = "$($config.AdminPreFix)$($Server.Name)"
                }
                #Check the group already exists. If not create a new group otherwise check for the groupmembers
                if (!([bool](Get-ADGroup -Filter { Name -eq $GroupName }))) {   
                    #create the Tier 1 computer group objects if they don't exists
                    try {
                        New-ADGroup -GroupCategory Security -GroupScope DomainLocal -SamAccountName $GroupName -Name $GroupName -Description "Provide Administrators privilege on $($Server.Name)" -Path $config.OU -Server $workingDC
                        Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId 1000 -Message "New Local admin group $GroupName created" -EntryType Information
                        Write-Output "New Local admin group $GroupName created"
                    }
                    catch {
                        Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId 1001 -Message "Error creating Local Admin group $groupname : $Error[0]"  -EntryType Error
                        Write-Output "Error creating Local Admin group $groupname : $Error[0]"
                    }
                }
                else {
                    #remove any not timebombed object
                    #If the member property doesn't contains a TTL remove them from the group 
                    Foreach ($Member in (Get-ADGroup $GroupName -Property members -ShowMemberTimeToLive).members) {
                        Write-Debug "Removeing permanent users from $GroupName"
                        $Regex = [RegEx]::new("<TTL=\d*>,CN=.")
                        $Match = $Regex.Match($Member)
                        if (!$Match.Success -eq $true) {
                            try {
                                #here is still a bug the member is from a child domain
                                Get-ADGroup $GroupName -Server $workingDC | Remove-ADGroupMember -Members (Get-ADObject -Identity $Member -Server $workingDC) -Confirm:$false
                                Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId 1002 -Message "Removing permanent user $Member from group $GroupName" -EntryType Warning
                                Write-Output "Removing permanent user $Member from group $GroupName"
                            }
                            catch {
                                Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId 1003 -Message "Can not remove permanent user from $GroupName $Error" -EntryType Error
                            }
                        }
                    }
                }
            }
            Write-Progress -Activity "Group Management" -Completed
        } else {
            Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId 1004 -Message "$Domain : The OU $searchbase cound not be found" -EntryType Warning
            Write-Output "$Domain : The OU $searchbase cound not be found"
        }
    }
}
#endregion
Write-Output "working on $GroupCount in $((Get-Date)-$Starttime)"
Stop-Transcript | Out-Null
