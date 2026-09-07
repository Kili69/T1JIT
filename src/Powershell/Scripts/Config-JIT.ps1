<#
Script Info

.Synopsis
    Installs and configures the Tier 1 JIT solution.

.DESCRIPTION
    Configures the JIT settings, group managed service account, Active Directory
    permissions, event log, and scheduled tasks. On success, the script writes the
    resulting JIT configuration object to the pipeline.

.EXAMPLE
    $configuration = .\Config-JIT.ps1

    Runs the interactive configuration and stores the resulting configuration object.

.EXAMPLE
    $configuration = .\Config-JIT.ps1 -quiet -configurationFile "\\contoso.com\SYSVOL\contoso.com\Just-In-Time\JIT.config" -Verbose

    Runs an unattended configuration with verbose progress information and stores the
    resulting configuration object.

.EXAMPLE
    .\Config-JIT.ps1 -InstallationDirectory "C:\Program Files\Just-In-Time" -WhatIf -Verbose

    Shows the configuration target without applying changes.

.OUTPUTS
    System.Management.Automation.PSCustomObject
.NOTES
    Author: Andreas Lucas [MSFT]

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

    Version Tracking
    2021-10-12 
    Version 0.1
        - First internal release
    Version 0.1.2021294
        - Default installation directory changed from c:\Program Files\windowsPowershell\script to %working directory%
        - New parameter ServerEnumerationTime added. Time for scheduled task to evaluate the existing servers
    Version 0.1.20230612
        - Source code documentation
    Version 0.1.20231029
        - Add a the new parameter DelegationConfigFilePath to the configuration file
        - Existing configuration files will be updated the latest version
    Version 0.1.20231109
        - New parameter to enable of disable the delegation model
    Version 0.1.20231130
        - better validation of input paramters
        - Support of spaces in Tier 0 computer OU
        - Terminate script if the current configuration file is created with a newe config-jit.ps1 script
        - Set full control to the Tier 1 computer Group OU
    Version 0.1.20231201
        - New parameter in config file LDAPT1computers
            This parameter contains the LDAP query to select Tier 1 computers
            This parameter is required in Tier1LocalAdminGroup.ps1
        - Support of WhatIf and Confirm parameters
    Version 0.1.20231204
        - Bug Fix in LDAP query to evaluate the T0 Computer OU
        - The domain separator can be configured in the JIT.config
    Version 0.1.20240116
        - Bug fix creating OU structure
        - Bug fix creating schedule task
    Version 0.1.20240202
        - Bug fix ACL for GMSA
    Version 0.1.20240205
        - Terminate the configuration script, if the AD PAM feature is not enabled
    Version 0.1.20240213
        - by Andreas Luy
        - corrected several inconsistency issues with existing config file
        - simplified/corrected OU creation function 
        - integrated updating delegationconfig location
        - group validation corrected
        - ToDo: use custom form for input
    Version 0.1.20240722
        - bug fixing
    Version 0.1.20240731
        - New Parameter advancedsetup
            The LDAP configuration string will only be visible if this switch is available
        - New Environment variable
            A global environment variable will created to determnine the configuration file. This environment variable will 
            be used in the request and elevate script to read a central configuration without using the config parameter
        - removed all parameters except InstallationDirectory and AdvancedSetup
        - new switch parameter -silent
            This parameter installs the GMSA on the local computer, create the Windows Eventlog and the schedule task
            This parameter can be used if the solution run on multiple servers. this parameter required the JIT.config file 
            JIT.CONFIG can be availabel through
                - Environment variable
                - configurationFile parameter
                - local jit.config
        - Schedule task to elevate users run in paralell 
            The userelevate schedule task run in paralell if multiple request events send to the event log
     Version 0.1.20240801
        - Updated dialog messages
    Version 0.1.20241004
        -New configuration option to use the ManagedBy attribute added to the config
        -New configuration option max concurrent servers
    Version 0.1.20241013
        -Terminate script if it is not running as local administrator
   Version 0.1.20241227
        - by Andreas Luy
	- corrected minor bugs
    Version 0.1.20250830
        - The Just-In-Time configuration folder will be created if it doesn't exist
    Version 0.1.20260428
        - Updated the script to support the new Just-In-Time configuration module and the new delegation model. The script will now create a delegation configuration file based on the provided path and update the JIT.config with the delegation configuration path. The script also includes better validation of input parameters and supports enabling or disabling the delegation model during setup.
    Version 0.1.20260824

        - Added startup version output and improved the PAM feature warning.

.PARAMETER InstallationDirectory
    Base folder containing the installed JIT scripts. The current directory is used when
    this parameter is omitted.
.PARAMETER AdvancedSetup
    Enables prompts for advanced delegation and LDAP configuration properties.
.PARAMETER quiet
    Runs setup without interactive configuration prompts. An existing configuration must
    be available through configurationFile or the JustInTimeConfig environment variable.
.PARAMETER configurationFile
    Full path to an existing JIT.config file used as the configuration source.
.PARAMETER Verbose
    Displays detailed information about the configuration workflow. This is a PowerShell
    common parameter provided by CmdletBinding.
.PARAMETER WhatIf
    Shows the target of the configuration without changing Active Directory, local
    security policy, files, environment variables, event logs, or scheduled tasks. This
    is a PowerShell common parameter provided by SupportsShouldProcess. The planned JIT
    configuration object is still returned.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    #The installation directory to find the JIT.config file
    [Parameter (Mandatory=$false)]
    $InstallationDirectory,
    [Parameter ()]
    [switch]$AdvancedSetup,
    [Parameter ()]
    [switch]$quiet,
    [Parameter (Mandatory=$false)]
    [string]$configurationFile
)

[string]$_scriptVersion = "0.1.20260824"
Write-Host "Config-JIT script version $_scriptVersion"

#region Functions
function Get-JitDefaultConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ScriptVersion,
        [Parameter(Mandatory)]
        [string]$DomainDns,
        [Parameter(Mandatory)]
        [string]$DomainDistinguishedName
    )

    return [pscustomobject][ordered]@{
        ConfigScriptVersion            = $ScriptVersion
        AdminPreFix                    = "Admin_"
        OU                             = "OU=JIT-Administrator Groups,OU=Tier 1,OU=Admin,$DomainDistinguishedName"
        MaxElevatedTime                = 1440
        DefaultElevatedTime            = 60
        ElevateEventID                 = 100
        Tier0ServerGroupName           = "Tier 0 Computers"
        LDAPT0Computers                = "(&(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))"
        LDAPT0ComputerPath             = "OU=Tier 0,OU=Admin"
        LDAPT1Computers                = "(&(OperatingSystem=*Windows*)(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))"
        EventSource                    = "T1Mgmt"
        EventLog                       = "Tier 1 Management"
        GroupManagementTaskRerun       = 5
        GroupManagedServiceAccountName = "T1GroupMgmt"
        Domain                         = $DomainDns
        DelegationConfigPath           = "\\$DomainDns\SYSVOL\$DomainDns\Just-In-time\Tier1delegation.config"
        EnableDelegation               = $true
        EnableMultiDomainSupport       = $true
        T1Searchbase                   = @("<DomainRoot>")
        DomainSeparator                = "#"
        UseManagedByforDelegation      = $true
        MaxConcurrentServer            = 50
    }
}

function Import-JitConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]$DefaultConfiguration,
        [Parameter(Mandatory)]
        [string]$ScriptVersion,
        [string]$ConfigurationFile
    )

    $existingConfigPath = if (-not [string]::IsNullOrWhiteSpace($ConfigurationFile)) {
        $ConfigurationFile
    } elseif (-not [string]::IsNullOrWhiteSpace($env:JustInTimeConfig)) {
        $env:JustInTimeConfig
    }

    if ([string]::IsNullOrWhiteSpace($existingConfigPath)) {
        return $DefaultConfiguration
    }

    if (-not (Test-Path -LiteralPath $existingConfigPath -PathType Leaf)) {
        if (-not [string]::IsNullOrWhiteSpace($ConfigurationFile)) {
            throw [System.IO.FileNotFoundException]::new("The configuration file '$ConfigurationFile' does not exist.", $ConfigurationFile)
        }

        Write-Warning "The configuration file '$existingConfigPath' does not exist. Default values are used."
        return $DefaultConfiguration
    }

    try {
        $existingConfiguration = Get-Content -LiteralPath $existingConfigPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw [System.ArgumentException]::new("The configuration file '$existingConfigPath' is invalid.", $_.Exception)
    }

    $existingVersion = ([regex]::Match([string]$existingConfiguration.ConfigScriptVersion, "\d+$")).Value
    $currentVersion = ([regex]::Match($ScriptVersion, "\d+$")).Value
    if ($existingVersion -and $currentVersion -and ([long]$existingVersion -gt [long]$currentVersion)) {
        throw [System.InvalidOperationException]::new("The configuration file was created by a newer Config-JIT script.")
    }

    foreach ($setting in $existingConfiguration.PSObject.Properties) {
        if ($DefaultConfiguration.PSObject.Properties.Name -contains $setting.Name) {
            $DefaultConfiguration.$($setting.Name) = $setting.Value
        }
    }
    $DefaultConfiguration.ConfigScriptVersion = $ScriptVersion

    return $DefaultConfiguration
}

function Export-JitConfiguration {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration,
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not $PSCmdlet.ShouldProcess($Path, "Save JIT configuration and update the machine environment variable")) {
        return $true
    }

    $parentPath = Split-Path -Path $Path -Parent
    if (-not (Test-Path -LiteralPath $parentPath -PathType Container)) {
        $null = New-Item -Path $parentPath -ItemType Directory -Force -ErrorAction Stop
    }

    $Configuration | ConvertTo-Json | Out-File -LiteralPath $Path -Force -ErrorAction Stop
    [Environment]::SetEnvironmentVariable("JustInTimeConfig", $Path, [EnvironmentVariableTarget]::Machine)
    $env:JustInTimeConfig = $Path

    return $true
}

function Set-JitConfigurationEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    if ($PSCmdlet.ShouldProcess("JustInTimeConfig", "Set machine environment variable to '$Path'")) {
        [Environment]::SetEnvironmentVariable("JustInTimeConfig", $Path, [EnvironmentVariableTarget]::Machine)
        $env:JustInTimeConfig = $Path
    }
}

function Set-JitDelegationFile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        return
    }

    if (-not $PSCmdlet.ShouldProcess($Path, "Create delegation configuration file")) {
        return
    }

    $parentPath = Split-Path -Path $Path -Parent
    if (-not (Test-Path -LiteralPath $parentPath -PathType Container)) {
        throw "The delegation configuration directory '$parentPath' does not exist."
    }

    $null = New-Item -Path $Path -ItemType File -ErrorAction Stop
}

function Read-JitIdentityConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration,
        [switch]$AdvancedSetup
    )

    $adminPrefix = Read-Host -Prompt "Admin Prefix for local administrators [$($Configuration.AdminPreFix)]"
    if ($adminPrefix) {
        $Configuration.AdminPreFix = $adminPrefix
    }

    do {
        $gmsaName = Read-Host -Prompt "Group managed service account name [$($Configuration.GroupManagedServiceAccountName)]"
        if (-not $gmsaName) {
            $gmsaName = $Configuration.GroupManagedServiceAccountName
        }
        if ($gmsaName.Length -lt 5 -or $gmsaName.Length -gt 14) {
            Write-Warning "The GMSA name must contain between 5 and 14 characters."
            $gmsaName = $null
        }
    } while (-not $gmsaName)
    $Configuration.GroupManagedServiceAccountName = $gmsaName

    $enableDelegation = if ($AdvancedSetup) {
        (Read-Host -Prompt "Enable the delegation mode? (Y/N)[Y]") -ne "n"
    } else {
        $true
    }
    $Configuration.EnableDelegation = $enableDelegation

    if ($enableDelegation) {
        $delegationFile = Read-Host -Prompt "File location of the delegation control file [$($Configuration.DelegationConfigPath)]"
        if ($delegationFile) {
            $Configuration.DelegationConfigPath = $delegationFile
        } else {
            $delegationFile = $Configuration.DelegationConfigPath
        }

        try {
            Set-JitDelegationFile -Path $delegationFile
        }
        catch {
            Write-Warning "Unable to create delegation file '$delegationFile': $($_.Exception.Message)"
        }
    }

    return $Configuration
}

function Add-LogonAsABatchJobPrivilege 
{
    <#
    .SYNOPSIS
        Grants the "Log on as a batch job" user right to a security principal SID.
    .DESCRIPTION
        Exports the local security policy, checks the SeBatchLogonRight assignment,
        and appends the specified SID if it is not already present. The updated
        policy is imported and applied by using secedit.
    .PARAMETER Sid
        Security identifier (SID) of the user that should receive the
        SeBatchLogonRight privilege.
    .EXAMPLE
        Add-LogonAsABatchJobPrivilege -Sid "S-1-5-21-1111111111-2222222222-3333333333-1234"
        Grants "Log on as a batch job" to the specified account SID.
    .OUTPUTS
        None
    .NOTES
        Author: Andreas Lucas
        Date: 2021-10-10
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [string]$Sid
    )

    if (-not $PSCmdlet.ShouldProcess($Sid, 'Grant the "Log on as a batch job" privilege')) {
        return
    }

    #Temporary files for secedit
    $tempPath = [System.IO.Path]::GetTempPath()
    $import = Join-Path -Path $tempPath -ChildPath "import.inf"
    if(Test-Path $import) { Remove-Item -Path $import -Force }
    $export = Join-Path -Path $tempPath -ChildPath "export.inf"
    if(Test-Path $export) { Remove-Item -Path $export -Force }
    $secedt = Join-Path -Path $tempPath -ChildPath "secedt.sdb"
    if(Test-Path $secedt) { Remove-Item -Path $secedt -Force }
    #Export the current configuration
    secedit /export /cfg $export | Out-Null
    if ($false -eq  (Test-Path $export)){
        Write-Host 'Administrator privileges required to set "Logon AS Batch job permission" please add the privilege manually'
        Return
    }
    #search for the current SID assigned to the SeBatchJob privilege
    $SIDs = (Select-String $export -Pattern "SeBatchLogonRight").Line
    if (!($SIDs.Contains($Sid)))
    {
        #create a new temporary security configuration file
        foreach ($line in @("[Unicode]", "Unicode=yes", "[System Access]", "[Event Audit]", "[Registry Values]", "[Version]", "signature=`"`$CHICAGO$`"", "Revision=1", "[Profile Description]", "Description=GrantLogOnAsABatchJob security template", "[Privilege Rights]", "$SIDs,*$sid"))
        {
            Add-Content $import $line
        }
        #configure privileges
        secedit /import /db $secedt /cfg $import | Out-Null
        secedit /configure /db $secedt | Out-Null
        gpupdate /force | Out-Null
        Remove-Item -Path $import -Force
        Remove-Item -Path $secedt -Force
    }
    #remove all temporary files   
    Remove-Item -Path $export -Force
    
}

function CreateOU {
    <#
    .SYNOPSIS
        Creates a complete OU path in the specified domain.
    .DESCRIPTION
        Creates each missing organizational unit (OU) in a relative distinguished
        name path and builds the hierarchy from top to bottom in the target domain.
        Existing OUs are detected and skipped.
    .PARAMETER OUPath
        Relative OU path without domain components (DC=...), for example
        "OU=Servers,OU=Tier 1,OU=Admin".
    .PARAMETER DomainDNS
        DNS name of the target Active Directory domain, for example "contoso.com".
    .EXAMPLE
        CreateOU -OUPath "OU=Test,OU=Demo" -DomainDNS "contoso.com"
        Creates missing OUs in the specified hierarchy in contoso.com.
    .OUTPUTS
        System.Boolean
        Returns $true when all required OUs exist or are created successfully.
        Returns $false if creation fails, including access denied scenarios.
    #>

    [CmdletBinding ( SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$OUPath,
        [Parameter (Mandatory)]
        [string]$DomainDNS
    )
    try{
        #load the OU path into array to create the entire path step by step
        $DomainDN = (Get-ADDomain -Server $DomainDNS).DistinguishedName
        $aryOU=$OUPath.Split(",").Trim()
        $OUBuildPath = ","+$DomainDN
        
        #walk through the entire domain
        [array]::Reverse($aryOU)
        $aryOU|ForEach-Object {
            #ignore 'DC=' values
            if ($_ -like "ou=*") {
                $OUName = $_ -ireplace [regex]::Escape("ou="), ""
                #check if OU already exists
                if (Get-ADOrganizationalUnit -Filter "distinguishedName -eq '$($_+$OUBuildPath)'") {
                    Write-Debug "$($_+$OUBuildPath) already exists no actions needed"
                } else {
                    $targetPath = $_ + $OUBuildPath
                    if ($PSCmdlet.ShouldProcess($targetPath, "Create Active Directory organizational unit")) {
                        Write-Host "'$targetPath' doesn't exist. Creating OU" -ForegroundColor Green
                        New-ADOrganizationalUnit -Name $OUName -Path $OUBuildPath.Substring(1) -Server $DomainDNS
                    }
                }
                #adding current OU to 'BuildOUPath' for next iteration
                $OUBuildPath = ","+$_+$OUBuildPath
            }


        }
 
    } 
    catch [System.UnauthorizedAccessException]{
        Write-Host "Access denied to create $OUPath in $domainDNS"
        Return $false
    } 
    catch{
        Write-Host "A error occured while create OU Structure"
        Write-Host $Error[0].CategoryInfo.GetType()
        Return $false
    }
    Return $true
}

function Set-JitServiceAccount {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration
    )

    $accountName = $Configuration.GroupManagedServiceAccountName
    if ($WhatIfPreference) {
        $null = $PSCmdlet.ShouldProcess($accountName, "Create or update group managed service account")
        $null = $PSCmdlet.ShouldProcess($accountName, "Install group managed service account locally")
        $null = $PSCmdlet.ShouldProcess($accountName, 'Grant the "Log on as a batch job" privilege')
        return $null
    }

    $serviceAccount = Get-ADServiceAccount -Filter "Name -eq '$accountName'" -Server $Configuration.Domain
    if ($null -eq $serviceAccount -and $PSCmdlet.ShouldProcess($accountName, "Create group managed service account")) {
        New-ADServiceAccount -Name $accountName -DisplayName $accountName -DNSHostName "$accountName.$($Configuration.Domain)" -Server $Configuration.Domain
    }

    $serviceAccount = Get-ADServiceAccount -Identity $accountName -Server $Configuration.Domain -ErrorAction SilentlyContinue
    if ($null -eq $serviceAccount) {
        if ($WhatIfPreference) {
            return $null
        }
        throw "The group managed service account '$accountName' could not be resolved."
    }

    $computerDistinguishedName = (Get-ADComputer -Identity $env:COMPUTERNAME).DistinguishedName
    $allowedPrincipals = @((Get-ADServiceAccount -Identity $accountName -Properties PrincipalsAllowedToRetrieveManagedPassword).PrincipalsAllowedToRetrieveManagedPassword)
    $allowedPrincipalDistinguishedNames = @($allowedPrincipals | ForEach-Object {
        if ($_ -is [string]) {
            $_
        }
        elseif ($_.PSObject.Properties.Name -contains "DistinguishedName") {
            [string]$_.DistinguishedName
        }
        elseif ($_.PSObject.Properties.Name -contains "Value") {
            [string]$_.Value
        }
        else {
            [string]$_
        }
    })
    if ($allowedPrincipalDistinguishedNames -notcontains $computerDistinguishedName) {
        $allowedPrincipals += $computerDistinguishedName
        if ($PSCmdlet.ShouldProcess($accountName, "Allow the local computer to retrieve the managed password")) {
            Set-ADServiceAccount -Identity $accountName -PrincipalsAllowedToRetrieveManagedPassword $allowedPrincipals -Server $Configuration.Domain
        }
    }

    if (-not (Test-ADServiceAccount -Identity $accountName)) {
        if ($PSCmdlet.ShouldProcess($accountName, "Install group managed service account locally")) {
            Install-ADServiceAccount -Identity $serviceAccount
        }
    }

    if (-not $WhatIfPreference -and -not (Test-ADServiceAccount -Identity $accountName)) {
        throw "Validation of the group managed service account '$accountName' failed."
    }

    Add-LogonAsABatchJobPrivilege -Sid $serviceAccount.SID.Value
    return $serviceAccount
}

function Set-JitOuPermission {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration,
        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$ServiceAccount
    )

    $targetPath = "AD:\$($Configuration.OU)"
    if (-not $PSCmdlet.ShouldProcess($targetPath, "Grant the JIT service account full control")) {
        return
    }

    $acl = Get-Acl -Path $targetPath
    if ($acl.Sddl.Contains($ServiceAccount.SID)) {
        return
    }

    $identity = [System.Security.Principal.IdentityReference]$ServiceAccount.SID
    $rights = [System.DirectoryServices.ActiveDirectoryRights]::GenericAll
    $accessType = [System.Security.AccessControl.AccessControlType]::Allow
    $inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::All
    $accessRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity, $rights, $accessType, $inheritanceType
    $acl.AddAccessRule($accessRule)
    Set-Acl -Path $targetPath -AclObject $acl
}

function Set-JitEventLog {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration
    )

    $eventLogExists = Get-EventLog -List | Where-Object { $_.LogDisplayName -eq $Configuration.EventLog }
    if ($null -ne $eventLogExists) {
        return
    }

    if ($PSCmdlet.ShouldProcess($Configuration.EventLog, "Create event log with source '$($Configuration.EventSource)'")) {
        New-EventLog -LogName $Configuration.EventLog -Source $Configuration.EventSource
        Write-EventLog -LogName $Configuration.EventLog -Source $Configuration.EventSource -EventId 1 -Message "JIT configuration created"
    }
}

function Set-JitScheduledTask {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration,
        [Parameter(Mandatory)]
        [string]$InstallationDirectory,
        [Parameter(Mandatory)]
        [string]$TaskPath,
        [Parameter(Mandatory)]
        [string]$GroupManagementTaskName,
        [Parameter(Mandatory)]
        [string]$ElevateUserTaskName
    )

    $taskUris = @((Get-ScheduledTask).URI)
    $groupManagementTaskUri = "$TaskPath\$GroupManagementTaskName"
    $elevateUserTaskUri = "$TaskPath\$ElevateUserTaskName"
    $registerGroupManagementTask = $groupManagementTaskUri -notin $taskUris -and $PSCmdlet.ShouldProcess($groupManagementTaskUri, "Register and start scheduled task")
    $registerElevateUserTask = $elevateUserTaskUri -notin $taskUris -and $PSCmdlet.ShouldProcess($elevateUserTaskUri, "Register event-triggered scheduled task")

    if (-not $registerGroupManagementTask -and -not $registerElevateUserTask) {
        return
    }

    $domain = Get-ADDomain
    $serviceAccount = Get-ADServiceAccount $Configuration.GroupManagedServiceAccountName
    $principal = New-ScheduledTaskPrincipal -UserId "$($domain.NetbiosName)\$($serviceAccount.SamAccountName)" -LogonType Password

    if ($registerGroupManagementTask) {
        $action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -file "' + $InstallationDirectory + '\Tier1LocalAdminGroup.ps1"')
        $trigger = New-ScheduledTaskTrigger -AtStartup
        $trigger.Repetition = (New-ScheduledTaskTrigger -Once -At 7am -RepetitionInterval (New-TimeSpan -Minutes $Configuration.GroupManagementTaskRerun)).Repetition
        $null = Register-ScheduledTask -Principal $principal -TaskName $GroupManagementTaskName -TaskPath $TaskPath -Action $action -Trigger $trigger
        $null = Start-ScheduledTask -TaskPath "$TaskPath\" -TaskName $GroupManagementTaskName
    }

    if ($registerElevateUserTask) {
        $action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -file "' + $InstallationDirectory + '\ElevateUser.ps1" -eventRecordID $(eventRecordID)') -WorkingDirectory $InstallationDirectory
        $triggerClass = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger
        $trigger = New-CimInstance -CimClass $triggerClass -ClientOnly
        $trigger.Subscription = "<QueryList><Query Id=""0"" Path=""$($Configuration.EventLog)""><Select Path=""$($Configuration.EventLog)"">*[System[Provider[@Name='$($Configuration.EventSource)'] and EventID=$($Configuration.ElevateEventID)]]</Select></Query></QueryList>"
        $trigger.Enabled = $true
        $trigger.ValueQueries = [CimInstance[]](Get-CimClass -ClassName MSFT_TaskNamedValue -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskNamedValue)
        $trigger.ValueQueries[0].Name = "eventRecordID"
        $trigger.ValueQueries[0].Value = "Event/System/EventRecordID"
        $settings = New-ScheduledTaskSettingsSet -MultipleInstances Parallel
        $null = Register-ScheduledTask -Principal $principal -TaskName $ElevateUserTaskName -TaskPath $TaskPath -Action $action -Trigger $trigger -Settings $settings
    }
}
#endregion
#############################################################################################
# Main program starts here
#############################################################################################
function Invoke-JitConfiguration {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        $InstallationDirectory,
        [switch]$AdvancedSetup,
        [switch]$Quiet,
        [string]$ConfigurationFile,
        [Parameter(Mandatory)]
        [string]$ScriptVersion
    )

$_scriptVersion = $ScriptVersion
$configurationTarget = if ([string]::IsNullOrWhiteSpace($InstallationDirectory)) {
    (Get-Location).Path
} else {
    $InstallationDirectory
}
Write-Verbose "Preparing JIT configuration for '$configurationTarget'."

if (!(New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
    #Terminate script if it is not running as local administrator
    Write-Host "Administrator privileges required" -ForegroundColor Red
    #return
}

#region global variables 
#region Default values
$configFileName = "JIT.config" #The default name of the configuration file
$STGroupManagementTaskName = "Tier 1 Local Group Management" #Name of the Schedule tasl to enumerate servers
$StGroupManagementTaskPath = "\Just-In-Time-Privilege" #Is the schedule task folder
$STElevateUser = "Elevate User" #Is the name of the Schedule task to elevate users
try {
    $ADDomainDNS = (Get-ADDomain).DNSRoot #$current domain DNSName. Testing the Powershell AD modules are working
}
catch {
    Write-Error "Cannot determine AD domain - aborting!"
    return
}
#endregion
#Checking the access to the installation directory and provide the system environment variable
#Validate the installation directory and stop execution if installation directory doesn't exists
if (!($InstallationDirectory)){
    $InstallationDirectory = (Get-Location).Path
    Write-Host "Installation directory is $installationDirectory"
} elseif (!(Test-Path $InstallationDirectory)) {
    Write-Error "Installation directory missing - aborting!"
    exit
}
#region validate configuration file for silent installation
#the quiet paramter required the configuration script or the Just-In-Time environment. 
#   The configuration scirpt will terminate if the configuraiton file is not accessible
if ($quiet){
    if (![string]::IsNullOrWhiteSpace($configurationFile)){
        if (!(Test-Path $configurationFile)){
            Write-Host "The configuration file $configurationFile doesn't exists" -ForegroundColor Red
            Write-Host "Just-In-Time configuration stopped"
            return
        }
        Set-JitConfigurationEnvironment -Path $configurationFile
    } elseif ($null -eq $env:JustInTimeConfig){
        Write-Host "The parameter silent requires the environment variable JustInTimeConfig or the -configurationFile parameter" -ForegroundColor Red
        Write-Host "Just-In-Time configuration stopped"
        return
    } else {
        if ((Test-Path $env:JustInTimeConfig)){} else {
            Write-Host "Can't access configuration file $($env:JustInTimeConfig). Aborting configuration" -ForegroundColor Red
            Write-Host "Validate the Just-In-Time variable"
            return
        }
    }

}
#endregion

#Validate the Active Directory PAW feature is activated. If not the script will terminate
if (!((Get-ADOptionalFeature -Filter "name -eq 'Privileged Access Management Feature'").EnabledScopes)){
    $enablePamCommand = "Enable-ADOptionalFeature ""Privileged Access Management Feature"" -Scope ForestOrConfigurationSet -Target $((Get-ADForest).Name)"
    Write-Host "Active Directory PAM feature is not enabled" -ForegroundColor Red
    Write-Host "Run:" -ForegroundColor Red
    Write-Host $enablePamCommand -ForegroundColor Cyan
    Write-Host "Before continuing with JIT" -ForegroundColor Red
    Write-Host "Aborting!" -ForegroundColor Red
    return
}
#region Creating the configuratin object with default values and read the existing configuration file it it exists. 
$domain = Get-ADDomain
$config = Get-JitDefaultConfiguration -ScriptVersion $_scriptVersion -DomainDns $ADDomainDNS -DomainDistinguishedName $domain.DistinguishedName

try {
    $config = Import-JitConfiguration -DefaultConfiguration $config -ScriptVersion $_scriptVersion -ConfigurationFile $configurationFile
}
catch {
    Write-Error $_.Exception.Message
    return
}

#endregion
#Definition of the AD group prefix. Use the default value if the question is not answerd
if (!$quiet){
    $config = Read-JitIdentityConfiguration -Configuration $config -AdvancedSetup:$AdvancedSetup
} 
#region GMSA
try {
    $oGmsa = Set-JitServiceAccount -Configuration $config
}
catch {
    Write-Error "Unable to configure GMSA '$($config.GroupManagedServiceAccountName)': $($_.Exception.Message)"
    return
}
#endregion

if (!$quiet){
    #Definition of the AD OU where the AD groups are stored
    do{
        $OU = Read-Host -Prompt "OU for the local administrator groups [$($config.OU)]"
        if ($OU -eq ""){
            $OU = $config.OU
        }
        try{
            if ([ADSI]::Exists("LDAP://$OU")){
                $config.OU = $OU
            } else {
                Write-Host "The Ou '$OU' doesn't exist" -ForegroundColor Yellow
                if (CreateOU -OUPath $OU -DomainDNS (Get-ADDomain).DNSRoot) {
                    Write-Host "'$OU' succesfully created" -ForegroundColor Green
                }
                # $OU = $null
            }
        } 
        catch {
            Write-Host "invalid DistinguishedName" -ForegroundColor Red
            $OU = $null
        }
    }while ($null -eq $OU)
    #Definition of the maximum time for elevated administrators
    do {
        [UINT16]$MaxMinutes = Read-Host "Maximum elevated time [$($config.MaxElevatedTime)]"
        switch ($MaxMinutes) {
            0{
                $MaxMinutes = $config.MaxElevatedTime
            }
            {($_ -gt 0) -and ($_ -lt 15)} {
                Write-Host "Minimum elevation time is 15 minutes" -ForegroundColor Yellow
                $MaxMinutes = 0
            }
            {$_ -gt 1440}{
                Write-Host "Maximum elevation time 1440 minutes" -ForegroundColor Yellow
                $MaxMinutes = 0
            }
            Default{
                $config.MaxElevatedTime = $MaxMinutes
            }
        }
    } while ($MaxMinutes -eq 0) 
    #Definition of the default elevation time
    DO {
        [INT]$DefaultElevatedTime = Read-Host -Prompt "Default elevated time [$($config.DefaultElevatedTime)]"
        switch ($DefaultElevatedTime) {
            0 {
                if ($config.DefaultElevatedTime -gt $config.MaxElevatedTime){
                    Write-Host "The default elevation time could not exceed the maximum elevation time"
                } else {
                    $DefaultElevatedTime = 1
                }
            }
            {($_ -gt 0) -and ($_ -lt 15)} {
                Write-Host "The default elevation time could not be lower then 15 minutes" -ForegroundColor Yellow
                $DefaultElevatedTime = 0
            }
            {$_ -gt $config.MaxElevatedTime} {
                Write-Host "The default elevation time cannot exceed 1440 minutes" -ForegroundColor Yellow
                $DefaultElevatedTime = 0
            }  
            Default {
                $config.DefaultElevatedTime = $DefaultElevatedTime
            }      
        }
    } while($DefaultElevatedTime -eq 0)

    do{
        $T0computergroup = Read-Host -Prompt "Tier 0 computers group [$($config.Tier0ServerGroupName)]"
        if ($T0computergroup -eq ""){
            $T0ComputerGroup = $config.Tier0ServerGroupName 
        }
        Try {
            $Group = Get-ADGroup -Identity $T0computergroup
            $config.Tier0ServerGroupName = $Group.DistinguishedName
        } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
            Write-Host "$($T0computergroup) is not a valid AD group" -ForegroundColor Yellow 
            Write-Host "Please enter either group's SamAccountName or DistinguishedName" -ForegroundColor Yellow 
            $T0computergroup = ""
        } 
        catch {
            Write-Host "unexpected occured script terminated" -ForegroundColor Red
            Write-Host $Error[0]
            return
        }
    } while ($T0computergroup -eq "")

    if ($AdvancedSetup){
        $LDAPT1Computers = Read-Host "LDAP query for Tier 1 computers [$($config.LDAPT1Computers)]"
        if ($LDAPT1Computers -ne ""){
            $config.LDAPT1Computers = $LDAPT1Computers
        }
    }
    do{
        $Tier0OUDN = Read-Host "Tier 0 OU realtive distinguished name [$($config.LDAPT0ComputerPath)]"
        if ($Tier0OUDN  -eq ""){
            $Tier0OUDN = $config.LDAPT0ComputerPath
        }
        try{
            if ([ADSI]::Exists("LDAP://$Tier0OUDN,$((Get-ADDomain).DistinguishedName)")){
                $config.LDAPT0ComputerPath = $Tier0OUDN
            } else {
                Write-Host "Invalid DistinguishedName LDAP://$Tier0OUDN,$((Get-ADDomain).Distinguishedname)."
                $Tier0OUDN = ""
            }
        } catch{
            Write-Host "Invalid DN path $($Error[0].CategoryInfo.GetType().Name)"
            $Tier0OUDN = ""
        }
    } while ($Tier0OUDN -eq "")

    do{
        try{
            [int]$GroupManagementTaskRerun = Read-Host "Minutes to evaluate Tier 1 Admin groups[$($config.GroupManagementTaskRerun)]"
            switch ($GroupManagementTaskRerun) {
                {$_ -lt 5} { 
                    $GroupManagementTaskRerun = [int]$config.GroupManagementTaskRerun
                }
                {$_ -gt 1440} {
                    Write-Host "The enumeration of Tier 1 computer must run at least once a day" -ForegroundColor Yellow
                    $GroupManagementTaskRerun = 0
                }
                Default{
                    $config.GroupManagementTaskRerun = $GroupManagementTaskRerun
                } 
            }
        }
        catch [System.Management.Automation.ArgumentTransformationMetadataException]{
            Write-Host "Invalid number please use a numer between 5 and 1439" -ForegroundColor Red
            $GroupManagementTaskRerun = $Null
        }
        catch{
            Write-Host "a unexpected error is occured $($error[0].CategoryInfo)"
            $GroupManagementTaskRerun = $Null
        }
    } while (($GroupManagementTaskRerun -lt 5) -or ($GroupManagementTaskRerun -gt 1439))
    $arySearchBase = @()
    foreach ($SearchBase in $config.T1Searchbase){
#        if ($SearchBase -ne "<DomainRoot>"){
#            $arySearchbase += $SearchBase
#        }
    }
    $config.T1SearchBase = $arySearchBase
    do{
        Write-Host "Current searchbase for JIT members"
        Write-Host $config.T1Searchbase -Separator "`n"
        if ((Read-Host "Add search base? [N]") -eq "y"){
            $arySearchBase = @()
            $arySearchBase += $config.T1Searchbase
            $SearchBase = Read-Host "Search base for JIT computers"
            if ([RegEx]::Match($Searchbase,"^(OU|CN)=.+").Success){
                if ($arySearchBase -contains $SearchBase){
                    Write-Host "$SearchBase is already available"
                } else {
                    $config.T1Searchbase += $SearchBase
                }
            } else {
                Write-Host "Invalid DN Retry" -ForegroundColor Yellow
            }
        } else {
            $SearchBase = "N"
        }
    } while ($SearchBase -ne "N") 
    if (!$config.T1Searchbase) {
        $config.T1Searchbase += "<DomainRoot>"
    }
    #endregion
    if ((-not $env:JustInTimeConfig) -or ($env:JustInTimeConfig -eq "")) {
        #Writing configuration file
        $DomainDNS = (Get-ADDomain).DNSRoot
        $DefaultJITConfigPath = "\\$DomainDNS\SYSVOL\$DomainDNS\Just-in-Time\JIT.config"
        Write-Host "It is recommended to store the configuration file on a central storage like $DefaultJITConfigPath"
    } else {
        $DefaultJITConfigPath = $env:JustInTimeConfig
    }
    $configSaved = $false
    do {
        $configFileName = Read-Host "Provide a path to store the configuration file[$DefaultJITConfigPath]"
        if ($configFileName -eq ""){
            $configFileName = $DefaultJITConfigPath
        }         
        try {
            $configSaved = Export-JitConfiguration -Configuration $config -Path $configFileName
        }
        catch [System.Security.SecurityException]{
            if ($error[0].InvocationInfo.Line -like "*SetEnvironmentVariable*"){
                Write-Host "Can change system variable. Administrator privileges required"
            } else{
                Write-Host "Can't write configuration file $configurationFile Write privileges required"
            }
        }
        catch [System.Management.Automation.MethodInvocationException]{
            Write-Host "$($error[0].Exception.InnerException)" -ForegroundColor Red
        }
        catch {
            Write-Host "can't create the configuration file. Please check the directory $configFileName exists and you have the permissions on this folder" -ForegroundColor Red
        }
    } while ($configSaved -eq $false)
}

if (-not (Get-ADOrganizationalUnit -Identity $config.OU -Server $config.Domain -ErrorAction SilentlyContinue)) {
    throw "The configured JIT administrator group OU '$($config.OU)' does not exist."
}
Set-JitOuPermission -Configuration $config -ServiceAccount $oGmsa

#region create eventlog and register EventSource id required
Set-JitEventLog -Configuration $config
#endregion
#region createing Scheduled Task Section
try {
    Set-JitScheduledTask -Configuration $config -InstallationDirectory $InstallationDirectory -TaskPath $StGroupManagementTaskPath -GroupManagementTaskName $STGroupManagementTaskName -ElevateUserTaskName $STElevateUser
}
catch {
    Write-Error "Scheduled tasks could not be configured: $($_.Exception.Message)"
    return
}
#endregion
if ($config.EnableDelegation){
    Write-Host "do not forget to configure your OU delegation"
    Write-Host "to allow the group Server-Admins on OU=Server,OU=contoso,OU=com use the command"
    Write-Host "To add a delegation use the command: Add-JitDelegation -OU ""OU=Server,DC=contoso,DC=com"" -AdObject ""contoso\Server-Admins"""
}

Write-Verbose "JIT configuration completed successfully."
return $config
}

return Invoke-JitConfiguration -InstallationDirectory $InstallationDirectory -AdvancedSetup:$AdvancedSetup -Quiet:$quiet -ConfigurationFile $configurationFile -ScriptVersion $_scriptVersion -WhatIf:$WhatIfPreference
