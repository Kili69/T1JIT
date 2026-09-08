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
    Version 0.1.20260908
        - Added Verbose and WhatIf support to the configuration workflow.
        - Return the effective JIT configuration object to the caller.
        - Split configuration import, export, identity, GMSA, OU permission, event log, and scheduled task handling into dedicated functions.
        - Added complete comment-based help and intent-focused inline documentation.

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

[string]$_scriptVersion = "0.1.20260908"
Write-Host "Config-JIT script version $_scriptVersion"

#region Functions
function Get-JitDefaultConfiguration {
    <#
    .SYNOPSIS
        Creates the default JIT configuration object.
    .DESCRIPTION
        Builds a new ordered configuration object using the current script version and
        Active Directory domain information. The returned values are used for a new
        installation and as defaults when an existing JIT.config file is imported.
    .PARAMETER ScriptVersion
        Version written to the ConfigScriptVersion property.
    .PARAMETER DomainDns
        DNS name of the Active Directory domain.
    .PARAMETER DomainDistinguishedName
        Distinguished name of the Active Directory domain.
    .OUTPUTS
        System.Management.Automation.PSCustomObject
    .EXAMPLE
        Get-JitDefaultConfiguration -ScriptVersion "0.1.20260908" -DomainDns "contoso.com" -DomainDistinguishedName "DC=contoso,DC=com"
    #>
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
        # General script and environment settings
        # Configuration properties for the JIT script and environment
        # the script version who created the configuration file
        ConfigScriptVersion            = $ScriptVersion
        # prefix for admin accounts
        AdminPreFix                    = "Admin_"
        # the organizational unit for JIT administrator groups
        OU                             = "OU=JIT-Administrator Groups,OU=Tier 1,OU=Admin,$DomainDistinguishedName"
        # maximum elevated time in minutes
        MaxElevatedTime                = 1440
        # default elevated time in minutes
        DefaultElevatedTime            = 60
        # event ID for elevation events
        ElevateEventID                 = 100
        # tier 0 server group name
        Tier0ServerGroupName           = "Tier 0 Computers"
        # LDAP filter for tier 0 computers
        LDAPT0Computers                = "(&(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))"
        # LDAP path for tier 0 computers
        LDAPT0ComputerPath             = "OU=Tier 0,OU=Admin"
        # LDAP filter for tier 1 computers
        LDAPT1Computers                = "(&(OperatingSystem=*Windows*)(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))"
        # event source for logging
        EventSource                    = "T1Mgmt"
        # event log name for logging
        EventLog                       = "Tier 1 Management"
        # path for debug logs
        DebugLogPath                   = "%TEMP%"
        # number of times to rerun group management tasks
        GroupManagementTaskRerun       = 5
        # name of the group managed service account
        GroupManagedServiceAccountName = "T1GroupMgmt"
        # domain DNS name
        Domain                         = $DomainDns
        # path to delegation configuration file
        DelegationConfigPath           = "\\$DomainDns\SYSVOL\$DomainDns\Just-In-time\Tier1delegation.config"
        # flag to enable delegation
        EnableDelegation               = $true
        # flag to enable multi-domain support
        EnableMultiDomainSupport       = $true
        # search base for tier 1
        T1Searchbase                   = @("<DomainRoot>")
        # domain separator character
        DomainSeparator                = "#"
        # flag to use managed by for delegation
        UseManagedByforDelegation      = $true
        MaxConcurrentServer            = 50
    }
}


function Import-JitConfiguration {
    <#
    .SYNOPSIS
        Imports an existing JIT.config file into the current default configuration.
    .DESCRIPTION
        Resolves the configuration source in this order:
        1. The explicit ConfigurationFile parameter.
        2. The process-level JustInTimeConfig environment variable.

        If neither source is configured, the supplied default object is returned
        unchanged. The JSON file is parsed and only properties that also exist on
        DefaultConfiguration are copied. This preserves defaults for settings added
        by newer Config-JIT versions and ignores unknown legacy properties.

        The numeric build suffix in ConfigScriptVersion is compared with ScriptVersion.
        A configuration created by a newer script is rejected. After a successful
        merge, ConfigScriptVersion is set to the current ScriptVersion.
    .PARAMETER DefaultConfiguration
        Default configuration object that receives values from the existing file.
        The object is updated in place and returned.
    .PARAMETER ScriptVersion
        Current Config-JIT script version used for compatibility validation and
        written to the merged configuration.
    .PARAMETER ConfigurationFile
        Optional explicit path to an existing JIT.config file. This value takes
        precedence over the JustInTimeConfig environment variable.
    .OUTPUTS
        System.Management.Automation.PSCustomObject
        Returns the default configuration or the merged configuration object.
    .EXAMPLE
        $defaults = Get-JitDefaultConfiguration `
            -ScriptVersion "0.1.20260908" `
            -DomainDns "contoso.com" `
            -DomainDistinguishedName "DC=contoso,DC=com"
        Import-JitConfiguration -DefaultConfiguration $defaults `
            -ScriptVersion "0.1.20260908" `
            -ConfigurationFile "\\contoso.com\SYSVOL\contoso.com\Just-In-Time\JIT.config"

        Imports the explicit JIT.config file and applies its supported properties to
        the current defaults.
    .EXAMPLE
        Import-JitConfiguration -DefaultConfiguration $defaults `
            -ScriptVersion "0.1.20260908"

        Uses JustInTimeConfig when it is set; otherwise returns the defaults unchanged.
    .NOTES
        An explicit missing ConfigurationFile raises FileNotFoundException. A missing
        file selected through JustInTimeConfig produces a warning and returns defaults.
        Invalid JSON raises ArgumentException, and a newer configuration version raises
        InvalidOperationException.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]$DefaultConfiguration,
        [Parameter(Mandatory)]
        [string]$ScriptVersion,
        [string]$ConfigurationFile
    )

    # An explicit path always overrides the process-wide configuration reference.
    $existingConfigPath = if (-not [string]::IsNullOrWhiteSpace($ConfigurationFile)) {
        $ConfigurationFile
    } elseif (-not [string]::IsNullOrWhiteSpace($env:JustInTimeConfig)) {
        $env:JustInTimeConfig
    }

    # No source means a new installation can continue with the domain-derived defaults.
    if ([string]::IsNullOrWhiteSpace($existingConfigPath)) {
        return $DefaultConfiguration
    }

    # A caller-supplied missing file is an error; a stale environment value is recoverable.
    if (-not (Test-Path -LiteralPath $existingConfigPath -PathType Leaf)) {
        if (-not [string]::IsNullOrWhiteSpace($ConfigurationFile)) {
            throw [System.IO.FileNotFoundException]::new("The configuration file '$ConfigurationFile' does not exist.", $ConfigurationFile)
        }

        Write-Warning "The configuration file '$existingConfigPath' does not exist. Default values are used."
        return $DefaultConfiguration
    }

    # Normalize JSON and file-system failures into one configuration-specific exception.
    try {
        $existingConfiguration = Get-Content -LiteralPath $existingConfigPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw [System.ArgumentException]::new("The configuration file '$existingConfigPath' is invalid.", $_.Exception)
    }

    # Compare only the trailing numeric build component used by Config-JIT versions.
    $existingVersion = ([regex]::Match([string]$existingConfiguration.ConfigScriptVersion, "\d+$")).Value
    $currentVersion = ([regex]::Match($ScriptVersion, "\d+$")).Value
    if ($existingVersion -and $currentVersion -and ([long]$existingVersion -gt [long]$currentVersion)) {
        throw [System.InvalidOperationException]::new("The configuration file was created by a newer Config-JIT script.")
    }

    # Whitelist known properties so obsolete or unknown JSON fields cannot extend the model.
    foreach ($setting in $existingConfiguration.PSObject.Properties) {
        if ($DefaultConfiguration.PSObject.Properties.Name -contains $setting.Name) {
            $DefaultConfiguration.$($setting.Name) = $setting.Value
        }
    }
    $DefaultConfiguration.ConfigScriptVersion = $ScriptVersion

    return $DefaultConfiguration
}

<#
.SYNOPSIS
    Exports the JIT configuration and publishes its location.
.DESCRIPTION
    Serializes the supplied configuration object as JSON to the specified path. A
    missing parent directory is created automatically, and an existing file is
    overwritten.

    After the file has been written successfully, the function stores its path in
    the machine-level JustInTimeConfig environment variable and mirrors the value
    into the current process. This makes the exported configuration available to
    later commands immediately and to new processes on the computer.

    File-system and environment changes participate in ShouldProcess. Under WhatIf,
    no state is changed and the function returns true so the calling configuration
    workflow can complete its planning pass.
.PARAMETER Configuration
    JIT configuration object to serialize as JSON.
.PARAMETER Path
    Destination path of the JIT.config file. Local and UNC paths are supported.
.OUTPUTS
    System.Boolean
    Returns true after the configuration is exported or when the operation is
    approved as a WhatIf planning step.
.EXAMPLE
    Export-JitConfiguration -Configuration $config `
        -Path "\\contoso.com\SYSVOL\contoso.com\Just-In-Time\JIT.config"

    Writes the configuration to SYSVOL and publishes the path through the
    JustInTimeConfig environment variable.
.EXAMPLE
    Export-JitConfiguration -Configuration $config `
        -Path "C:\ProgramData\T1JIT\JIT.config" -WhatIf

    Displays the planned export without creating the directory, writing the file,
    or changing environment variables.
.NOTES
    File creation, JSON serialization, and environment-variable errors are allowed
    to propagate to the caller.
#>
function Export-JitConfiguration {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration,
        [Parameter(Mandatory)]
        [string]$Path
    )

    # Treat an approved WhatIf plan as success so interactive save loops do not repeat.
    if (-not $PSCmdlet.ShouldProcess($Path, "Save JIT configuration and update the machine environment variable")) {
        return $true
    }

    # Create the complete destination directory before replacing the configuration file.
    $parentPath = Split-Path -Path $Path -Parent
    if (-not (Test-Path -LiteralPath $parentPath -PathType Container)) {
        $null = New-Item -Path $parentPath -ItemType Directory -Force -ErrorAction Stop
    }

    # Publish the path only after the JSON file has been written successfully.
    $Configuration | ConvertTo-Json | Out-File -LiteralPath $Path -Force -ErrorAction Stop
    [Environment]::SetEnvironmentVariable("JustInTimeConfig", $Path, [EnvironmentVariableTarget]::Machine)
    # Machine-level changes are not reflected in the current process automatically.
    $env:JustInTimeConfig = $Path

    return $true
}

<#
.SYNOPSIS
    Publishes the JIT configuration path as an environment variable.
.DESCRIPTION
    Writes the supplied path to the machine-level JustInTimeConfig environment
    variable so new processes and scheduled tasks can locate the central JIT.config
    file.

    After the machine-level value has been written successfully, the function mirrors
    it into the current PowerShell process. This makes the new path available without
    restarting the current session. Both changes are skipped under WhatIf.
.PARAMETER Path
    Full local or UNC path to the JIT.config file. The function publishes the path
    but does not validate, create, or read the referenced file.
.OUTPUTS
    None.
.EXAMPLE
    Set-JitConfigurationEnvironment `
        -Path "\\contoso.com\SYSVOL\contoso.com\Just-In-Time\JIT.config"

    Publishes the central SYSVOL configuration path for the computer and the current
    PowerShell process.
.EXAMPLE
    Set-JitConfigurationEnvironment -Path "C:\ProgramData\T1JIT\JIT.config" -WhatIf

    Displays the planned machine-level environment change without modifying either
    environment scope.
.NOTES
    Writing a machine-level environment variable requires sufficient local privileges.
    Errors from the .NET environment API are allowed to propagate to the caller.
#>
function Set-JitConfigurationEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    # Guard both environment scopes with one confirmation to avoid divergent values.
    if ($PSCmdlet.ShouldProcess("JustInTimeConfig", "Set machine environment variable to '$Path'")) {
        # Persist first so the process value changes only after the machine update succeeds.
        [Environment]::SetEnvironmentVariable("JustInTimeConfig", $Path, [EnvironmentVariableTarget]::Machine)
        # Machine-level changes are not imported into the current process automatically.
        $env:JustInTimeConfig = $Path
    }
}

<#
.SYNOPSIS
    Creates the delegation configuration file when it does not exist.
.DESCRIPTION
    Ensures that the specified delegation configuration file exists. If the file is
    already present, the function returns without changing its contents.

    For a missing file, the parent directory is created first when necessary, followed
    by an empty delegation file. Directory creation and file creation use separate
    ShouldProcess confirmations. If creation of a missing parent directory is declined
    or skipped under WhatIf, the function returns before attempting to create the file.
.PARAMETER Path
    Full local or UNC path of the delegation configuration file to create.
.OUTPUTS
    None.
.EXAMPLE
    Set-JitDelegationFile `
        -Path "\\contoso.com\SYSVOL\contoso.com\Just-In-Time\Tier1delegation.config"

    Creates the SYSVOL directory when needed and then creates an empty delegation
    configuration file. An existing file is left unchanged.
.EXAMPLE
    Set-JitDelegationFile `
        -Path "C:\ProgramData\T1JIT\Tier1delegation.config" -WhatIf

    Displays the planned directory or file creation without changing the file system.
.NOTES
    File-system and access errors are allowed to propagate to the caller. The function
    creates an empty file only; delegation entries are managed separately.
#>
function Set-JitDelegationFile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    # Preserve existing delegation rules and make repeated calls idempotent.
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        return
    }

    # A delegation file may target a SYSVOL path whose parent has not been created yet.
    $parentPath = Split-Path -Path $Path -Parent
    if (-not (Test-Path -LiteralPath $parentPath -PathType Container)) {
        # Do not attempt file creation when creation of its required parent is skipped.
        if (-not $PSCmdlet.ShouldProcess($parentPath, "Create delegation configuration directory")) {
            return
        }
        $null = New-Item -Path $parentPath -ItemType Directory -Force -ErrorAction Stop
    }

    # File creation has its own confirmation when the destination directory exists.
    if (-not $PSCmdlet.ShouldProcess($Path, "Create delegation configuration file")) {
        return
    }

    # Create an empty control file without overwriting an existing file discovered above.
    $null = New-Item -Path $Path -ItemType File -ErrorAction Stop
}

<#
.SYNOPSIS
    Collects interactive identity, delegation, and logging settings.
.DESCRIPTION
    Prompts the operator for the administrator-account prefix and group managed service
    account name. Empty answers retain the values already present in Configuration.
    The GMSA prompt repeats until its name contains between 5 and 14 characters.

    With AdvancedSetup, the operator can enable or disable delegation. Without it,
    delegation is enabled automatically. When delegation is enabled, the function
    collects the control-file path and attempts to create a missing file. Creation
    failures produce a warning and do not stop the remaining configuration prompts.

    Finally, the function collects the debug-log directory. Environment-variable
    expressions such as %TEMP% are expanded for validation, but the original expression
    is retained in Configuration so it resolves in the runtime account's context. The
    prompt repeats until the expanded value is an absolute local or UNC path.
.PARAMETER Configuration
    JIT configuration object whose current values are displayed as prompt defaults.
    The object is updated in place and returned.
.PARAMETER AdvancedSetup
    Prompts the operator to enable or disable delegation. Without this switch,
    EnableDelegation is set to true without an additional prompt.
.OUTPUTS
    System.Management.Automation.PSCustomObject
    Returns the same configuration object after applying the selected values.
.EXAMPLE
    $config = Read-JitIdentityConfiguration -Configuration $config

    Collects the standard identity and logging settings and enables delegation.
.EXAMPLE
    $config = Read-JitIdentityConfiguration `
        -Configuration $config -AdvancedSetup

    Also prompts whether delegation should be enabled before requesting its file path.
.NOTES
    The function validates only the GMSA name length and whether the expanded debug path
    is rooted. Additional account and file-system validation occurs later in the setup
    workflow.
#>
function Read-JitIdentityConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration,
        [switch]$AdvancedSetup
    )

    # An empty answer preserves the prefix imported from the existing configuration.
    $adminPrefix = Read-Host -Prompt "Admin Prefix for local administrators [$($Configuration.AdminPreFix)]"
    if ($adminPrefix) {
        $Configuration.AdminPreFix = $adminPrefix
    }

    # Repeat until either the existing or newly entered GMSA name has a valid length.
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

    # Standard setup enables delegation; advanced setup exposes the opt-out prompt.
    $enableDelegation = if ($AdvancedSetup) {
        (Read-Host -Prompt "Enable the delegation mode? (Y/N)[Y]") -ne "n"
    } else {
        $true
    }
    $Configuration.EnableDelegation = $enableDelegation

    if ($enableDelegation) {
        # A blank answer keeps the current control-file location.
        $delegationFile = Read-Host -Prompt "File location of the delegation control file [$($Configuration.DelegationConfigPath)]"
        if ($delegationFile) {
            $Configuration.DelegationConfigPath = $delegationFile
        } else {
            $delegationFile = $Configuration.DelegationConfigPath
        }

        # File creation is best effort so identity and logging setup can still complete.
        try {
            Set-JitDelegationFile -Path $delegationFile
        }
        catch {
            Write-Warning "Unable to create delegation file '$delegationFile': $($_.Exception.Message)"
        }
    }

    # Validate expanded paths but retain tokens such as %TEMP% for runtime resolution.
    do {
        $debugLogPath = Read-Host -Prompt "Debug log directory [$($Configuration.DebugLogPath)]"
        if ([string]::IsNullOrWhiteSpace($debugLogPath)) {
            $debugLogPath = $Configuration.DebugLogPath
        }

        $expandedDebugLogPath = [Environment]::ExpandEnvironmentVariables($debugLogPath)
        if (-not [IO.Path]::IsPathRooted($expandedDebugLogPath)) {
            Write-Warning "The debug log directory must be an absolute local or UNC path. Environment variables such as %TEMP% are supported."
            $debugLogPath = $null
        }
    } while ([string]::IsNullOrWhiteSpace($debugLogPath))
    $Configuration.DebugLogPath = $debugLogPath

    # Return the mutated object so callers can continue the configuration pipeline.
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
        Requires local administrator privileges and the Windows secedit utility.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [string]$Sid
    )

    # Treat the SID as one protected operation because secedit updates local policy.
    if (-not $PSCmdlet.ShouldProcess($Sid, 'Grant the "Log on as a batch job" privilege')) {
        return
    }

    # Use isolated policy files in the current account's temporary directory.
    $tempPath = [System.IO.Path]::GetTempPath()
    $import = Join-Path -Path $tempPath -ChildPath "import.inf"
    if(Test-Path $import) { Remove-Item -Path $import -Force }
    $export = Join-Path -Path $tempPath -ChildPath "export.inf"
    if(Test-Path $export) { Remove-Item -Path $export -Force }
    $secedt = Join-Path -Path $tempPath -ChildPath "secedt.sdb"
    if(Test-Path $secedt) { Remove-Item -Path $secedt -Force }
    # Export the effective local security policy before changing one user right.
    secedit /export /cfg $export | Out-Null
    if ($false -eq  (Test-Path $export)){
        Write-Host 'Administrator privileges required to set "Logon AS Batch job permission" please add the privilege manually'
        Return
    }
    # Preserve existing trustees and append the SID only when it is not assigned already.
    $SIDs = (Select-String $export -Pattern "SeBatchLogonRight").Line
    if (!($SIDs.Contains($Sid)))
    {
        # Build the minimal security template required to update SeBatchLogonRight.
        foreach ($line in @("[Unicode]", "Unicode=yes", "[System Access]", "[Event Audit]", "[Registry Values]", "[Version]", "signature=`"`$CHICAGO$`"", "Revision=1", "[Profile Description]", "Description=GrantLogOnAsABatchJob security template", "[Privilege Rights]", "$SIDs,*$sid"))
        {
            Add-Content $import $line
        }
        # Import and apply the template, then refresh Group Policy before cleanup.
        secedit /import /db $secedt /cfg $import | Out-Null
        secedit /configure /db $secedt | Out-Null
        gpupdate /force | Out-Null
        Remove-Item -Path $import -Force
        Remove-Item -Path $secedt -Force
    }
    # Always remove the exported policy after the assignment check completes.
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
    .NOTES
        The function ignores DC components and creates missing OU components from the
        domain root toward the leaf. Existing OUs are not modified.
    #>

    [CmdletBinding ( SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$OUPath,
        [Parameter (Mandatory)]
        [string]$DomainDNS
    )
    try{
        # Resolve the target domain and split the requested distinguished-name path.
        $DomainDN = (Get-ADDomain -Server $DomainDNS).DistinguishedName
        $aryOU=$OUPath.Split(",").Trim()
        $OUBuildPath = ","+$DomainDN
        
        # Reverse the components so parent OUs are available before their children.
        [array]::Reverse($aryOU)
        $aryOU|ForEach-Object {
            # Domain components come from Get-ADDomain and must not be created as OUs.
            if ($_ -like "ou=*") {
                $OUName = $_ -ireplace [regex]::Escape("ou="), ""
                # Keep existing OUs unchanged; create only the missing hierarchy element.
                if (Get-ADOrganizationalUnit -Filter "distinguishedName -eq '$($_+$OUBuildPath)'") {
                    Write-Debug "$($_+$OUBuildPath) already exists no actions needed"
                } else {
                    $targetPath = $_ + $OUBuildPath
                    if ($PSCmdlet.ShouldProcess($targetPath, "Create Active Directory organizational unit")) {
                        Write-Host "'$targetPath' doesn't exist. Creating OU" -ForegroundColor Green
                        New-ADOrganizationalUnit -Name $OUName -Path $OUBuildPath.Substring(1) -Server $DomainDNS
                    }
                }
                # Use this OU as the parent path for the next, more specific component.
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

<#
.SYNOPSIS
    Creates, authorizes, and installs the JIT group managed service account.
.DESCRIPTION
    Ensures the configured GMSA exists, permits the local computer to retrieve its
    managed password, installs the account locally, validates it, and grants the
    Log on as a batch job right.
.PARAMETER Configuration
    JIT configuration containing the GMSA name and domain.
.OUTPUTS
    Microsoft.ActiveDirectory.Management.ADServiceAccount
    Returns the configured GMSA. Under WhatIf no account object is returned.
.EXAMPLE
    $serviceAccount = Set-JitServiceAccount -Configuration $config

    Creates or updates the configured GMSA, authorizes the local computer, installs
    the account locally, and grants its batch-logon right.
.EXAMPLE
    Set-JitServiceAccount -Configuration $config -WhatIf

    Displays the planned GMSA operations without changing Active Directory or the
    local computer.
.NOTES
    Active Directory module access and local administrator privileges are required.
#>
function Set-JitServiceAccount {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration
    )

    $accountName = $Configuration.GroupManagedServiceAccountName
    # AD lookups cannot reliably model a not-yet-created account, so WhatIf stops here.
    if ($WhatIfPreference) {
        $null = $PSCmdlet.ShouldProcess($accountName, "Create or update group managed service account")
        $null = $PSCmdlet.ShouldProcess($accountName, "Install group managed service account locally")
        $null = $PSCmdlet.ShouldProcess($accountName, 'Grant the "Log on as a batch job" privilege')
        return $null
    }

    # Create the account only when it is not already present in the configured domain.
    $serviceAccount = Get-ADServiceAccount -Filter "Name -eq '$accountName'" -Server $Configuration.Domain
    if ($null -eq $serviceAccount -and $PSCmdlet.ShouldProcess($accountName, "Create group managed service account")) {
        New-ADServiceAccount -Name $accountName -DisplayName $accountName -DNSHostName "$accountName.$($Configuration.Domain)" -Server $Configuration.Domain
    }

    # Resolve the canonical account object required by all subsequent local operations.
    $serviceAccount = Get-ADServiceAccount -Identity $accountName -Server $Configuration.Domain -ErrorAction SilentlyContinue
    if ($null -eq $serviceAccount) {
        if ($WhatIfPreference) {
            return $null
        }
        throw "The group managed service account '$accountName' could not be resolved."
    }

    # Preserve existing password retrievers while authorizing the local computer.
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

    # Install the GMSA locally only when its managed password cannot yet be validated.
    if (-not (Test-ADServiceAccount -Identity $accountName)) {
        if ($PSCmdlet.ShouldProcess($accountName, "Install group managed service account locally")) {
            Install-ADServiceAccount -Identity $serviceAccount
        }
    }

    if (-not $WhatIfPreference -and -not (Test-ADServiceAccount -Identity $accountName)) {
        throw "Validation of the group managed service account '$accountName' failed."
    }

    # Scheduled tasks running as the GMSA require the batch-logon user right.
    Add-LogonAsABatchJobPrivilege -Sid $serviceAccount.SID.Value
    return $serviceAccount
}

<#
.SYNOPSIS
    Grants the JIT service account control of the administrator-group OU.
.DESCRIPTION
    Reads the OU security descriptor and adds an inheritable GenericAll access rule
    for the GMSA when an equivalent rule is not already present.
.PARAMETER Configuration
    JIT configuration containing the administrator-group OU.
.PARAMETER ServiceAccount
    GMSA object whose SID receives the access rule. A null value is accepted for
    WhatIf planning.
.OUTPUTS
    None.
.EXAMPLE
    Set-JitOuPermission -Configuration $config -ServiceAccount $serviceAccount

    Grants the configured GMSA inheritable full control over the JIT group OU.
.EXAMPLE
    Set-JitOuPermission -Configuration $config -ServiceAccount $null -WhatIf

    Displays the planned permission update without requiring a resolved account.
.NOTES
    The ActiveDirectory provider must be available and the caller must be authorized
    to modify the target OU security descriptor.
#>
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
    # Return before dereferencing ServiceAccount when this is a WhatIf planning pass.
    if (-not $PSCmdlet.ShouldProcess($targetPath, "Grant the JIT service account full control")) {
        return
    }

    # Avoid adding a duplicate access rule when the account SID is already present.
    $acl = Get-Acl -Path $targetPath
    if ($acl.Sddl.Contains($ServiceAccount.SID)) {
        return
    }

    # Apply GenericAll to the OU and all descendant objects through inheritance.
    $identity = [System.Security.Principal.IdentityReference]$ServiceAccount.SID
    $rights = [System.DirectoryServices.ActiveDirectoryRights]::GenericAll
    $accessType = [System.Security.AccessControl.AccessControlType]::Allow
    $inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::All
    $accessRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity, $rights, $accessType, $inheritanceType
    $acl.AddAccessRule($accessRule)
    Set-Acl -Path $targetPath -AclObject $acl
}

<#
.SYNOPSIS
    Creates the required Windows event logs and sources.
.DESCRIPTION
    Creates the configured JIT event log and source when missing and registers the
    Tier1LocalAdminGroup source in the Windows Application log. Existing logs and
    sources are preserved.
.PARAMETER Configuration
    JIT configuration containing EventLog and EventSource.
.OUTPUTS
    None.
.EXAMPLE
    Set-JitEventLog -Configuration $config

    Creates the configured JIT event log and registers the group-management source in
    the Application log when either is missing.
.EXAMPLE
    Set-JitEventLog -Configuration $config -WhatIf

    Displays missing event-log registrations without modifying the local computer.
.NOTES
    Registering Windows event logs and sources requires local administrator privileges.
#>
function Set-JitEventLog {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]$Configuration
    )

    # Create the custom log and its configured source as a single idempotent operation.
    $eventLogExists = Get-EventLog -List | Where-Object { $_.LogDisplayName -eq $Configuration.EventLog }
    if ($null -eq $eventLogExists -and $PSCmdlet.ShouldProcess($Configuration.EventLog, "Create event log with source '$($Configuration.EventSource)'")) {
        New-EventLog -LogName $Configuration.EventLog -Source $Configuration.EventSource
        Write-EventLog -LogName $Configuration.EventLog -Source $Configuration.EventSource -EventId 1 -Message "JIT configuration created"
    }

    # Tier1LocalAdminGroup reports operational failures through the Application log.
    $groupManagementEventSource = "T1JIT Tier1LocalAdminGroup"
    $groupManagementEventSourcePath = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\$groupManagementEventSource"
    if (-not (Test-Path -LiteralPath $groupManagementEventSourcePath) -and
        $PSCmdlet.ShouldProcess("Application", "Register event source '$groupManagementEventSource'")) {
        New-EventLog -LogName Application -Source $groupManagementEventSource
    }
}

<#
.SYNOPSIS
    Registers the recurring group-management and event-driven elevation tasks.
.DESCRIPTION
    Creates missing scheduled tasks under the configured task folder. The group task
    starts at boot and repeats at GroupManagementTaskRerun intervals. The elevation
    task reacts to configured JIT request events and permits parallel instances.
.PARAMETER Configuration
    JIT configuration containing the GMSA, event, and repetition settings.
.PARAMETER InstallationDirectory
    Directory containing Tier1LocalAdminGroup.ps1 and ElevateUser.ps1.
.PARAMETER TaskPath
    Windows Task Scheduler folder for both tasks.
.PARAMETER GroupManagementTaskName
    Name of the recurring server group-management task.
.PARAMETER ElevateUserTaskName
    Name of the event-triggered user-elevation task.
.OUTPUTS
    None.
.EXAMPLE
    Set-JitScheduledTask -Configuration $config `
        -InstallationDirectory "C:\Program Files\Just-In-Time" `
        -TaskPath "\Just-In-Time-Privilege" `
        -GroupManagementTaskName "Tier 1 Local Group Management" `
        -ElevateUserTaskName "Elevate User"

    Registers any missing JIT scheduled tasks under the configured task folder.
.EXAMPLE
    Set-JitScheduledTask -Configuration $config `
        -InstallationDirectory "C:\Program Files\Just-In-Time" `
        -TaskPath "\Just-In-Time-Privilege" `
        -GroupManagementTaskName "Tier 1 Local Group Management" `
        -ElevateUserTaskName "Elevate User" -WhatIf

    Displays only the task registrations that would be required.
.NOTES
    Existing tasks are preserved and are not reconfigured by this function.
#>
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

    # Compare full task URIs so existing tasks in other folders do not suppress creation.
    $taskUris = @((Get-ScheduledTask).URI)
    $groupManagementTaskUri = "$TaskPath\$GroupManagementTaskName"
    $elevateUserTaskUri = "$TaskPath\$ElevateUserTaskName"
    $registerGroupManagementTask = $groupManagementTaskUri -notin $taskUris -and $PSCmdlet.ShouldProcess($groupManagementTaskUri, "Register and start scheduled task")
    $registerElevateUserTask = $elevateUserTaskUri -notin $taskUris -and $PSCmdlet.ShouldProcess($elevateUserTaskUri, "Register event-triggered scheduled task")

    # Resolve the GMSA principal only when at least one task must be registered.
    if (-not $registerGroupManagementTask -and -not $registerElevateUserTask) {
        return
    }

    $domain = Get-ADDomain
    $serviceAccount = Get-ADServiceAccount $Configuration.GroupManagedServiceAccountName
    $principal = New-ScheduledTaskPrincipal -UserId "$($domain.NetbiosName)\$($serviceAccount.SamAccountName)" -LogonType Password

    # The group-management task starts at boot and repeats at the configured interval.
    if ($registerGroupManagementTask) {
        $action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -file "' + $InstallationDirectory + '\Tier1LocalAdminGroup.ps1"')
        $trigger = New-ScheduledTaskTrigger -AtStartup
        $trigger.Repetition = (New-ScheduledTaskTrigger -Once -At 7am -RepetitionInterval (New-TimeSpan -Minutes $Configuration.GroupManagementTaskRerun)).Repetition
        $null = Register-ScheduledTask -Principal $principal -TaskName $GroupManagementTaskName -TaskPath $TaskPath -Action $action -Trigger $trigger
        $null = Start-ScheduledTask -TaskPath "$TaskPath\" -TaskName $GroupManagementTaskName
    }

    # The elevation task receives the triggering event record ID and allows parallel runs.
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
    <#
    .SYNOPSIS
        Runs the complete JIT configuration workflow.
    .DESCRIPTION
        Resolves or creates the JIT configuration, validates administrator and PAM
        prerequisites, configures the GMSA and OU permissions, creates event sources,
        and registers scheduled tasks. Interactive mode prompts for configurable values;
        quiet mode consumes an existing configuration.
    .PARAMETER InstallationDirectory
        Directory containing the installed JIT scripts.
    .PARAMETER AdvancedSetup
        Enables advanced interactive configuration choices.
    .PARAMETER Quiet
        Suppresses interactive prompts and requires an existing configuration source.
    .PARAMETER ConfigurationFile
        Optional explicit path to JIT.config.
    .PARAMETER ScriptVersion
        Version persisted in the configuration object.
    .OUTPUTS
        System.Management.Automation.PSCustomObject
        Returns the resulting configuration object on success.
    .EXAMPLE
        Invoke-JitConfiguration -InstallationDirectory "C:\Program Files\Just-In-Time" `
            -ScriptVersion "0.1.20260908"

        Runs the interactive setup and returns the resulting configuration object.
    .EXAMPLE
        Invoke-JitConfiguration -InstallationDirectory "C:\Program Files\Just-In-Time" `
            -ConfigurationFile "\\contoso.com\SYSVOL\contoso.com\Just-In-Time\JIT.config" `
            -ScriptVersion "0.1.20260908" -Quiet

        Applies an existing configuration without interactive prompts.
    .EXAMPLE
        Invoke-JitConfiguration -InstallationDirectory "C:\Program Files\Just-In-Time" `
            -ScriptVersion "0.1.20260908" -WhatIf -Verbose

        Displays the planned configuration actions with detailed progress information.
    .NOTES
        Requires Windows PowerShell 5.1, the ActiveDirectory module, local administrator
        privileges, and the Active Directory PAM optional feature.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        $InstallationDirectory,
        [switch]$AdvancedSetup,
        [switch]$Quiet,
        [string]$ConfigurationFile,
        [Parameter(Mandatory)]
        [string]$ScriptVersion
    )

# Keep the internal version name used by the legacy workflow synchronized with the parameter.
$_scriptVersion = $ScriptVersion
# Resolve the displayed target early; the actual default directory is assigned below.
$configurationTarget = if ([string]::IsNullOrWhiteSpace($InstallationDirectory)) {
    (Get-Location).Path
} else {
    $InstallationDirectory
}
Write-Verbose "Preparing JIT configuration for '$configurationTarget'."

# Report missing elevation before any local or Active Directory mutation is attempted.
if (!(New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
    #Terminate script if it is not running as local administrator
    Write-Host "Administrator privileges required" -ForegroundColor Red
    #return
}

#region global variables 
#region Default values
# Define stable names shared by configuration export and scheduled-task registration.
$configFileName = "JIT.config"
$STGroupManagementTaskName = "Tier 1 Local Group Management"
$StGroupManagementTaskPath = "\Just-In-Time-Privilege"
$STElevateUser = "Elevate User"
# Resolving the domain also verifies that the ActiveDirectory module is operational.
try {
    $ADDomainDNS = (Get-ADDomain).DNSRoot
}
catch {
    Write-Error "Cannot determine AD domain - aborting!"
    return
}
#endregion
# Use the current directory by default and reject an inaccessible explicit location.
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
# Quiet setup requires an accessible explicit or process-level configuration source.
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

# Time-limited group membership depends on the forest-wide PAM optional feature.
if (!((Get-ADOptionalFeature -Filter "name -eq 'Privileged Access Management Feature'").EnabledScopes)){
    $enablePamCommand = "Enable-ADOptionalFeature ""Privileged Access Management Feature"" -Scope ForestOrConfigurationSet -Target $((Get-ADForest).Name)"
    Write-Host "Active Directory PAM feature is not enabled" -ForegroundColor Red
    Write-Host "Run:" -ForegroundColor Red
    Write-Host $enablePamCommand -ForegroundColor Cyan
    Write-Host "Before continuing with JIT" -ForegroundColor Red
    Write-Host "Aborting!" -ForegroundColor Red
    return
}
#region Create or import configuration
# Merge existing values onto domain-derived defaults before prompting or provisioning.
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
# Interactive setup collects identity and logging settings before provisioning the GMSA.
if (!$quiet){
    $config = Read-JitIdentityConfiguration -Configuration $config -AdvancedSetup:$AdvancedSetup
} 
#region GMSA
# Provision and validate the service identity before assigning dependent permissions.
try {
    $oGmsa = Set-JitServiceAccount -Configuration $config
}
catch {
    Write-Error "Unable to configure GMSA '$($config.GroupManagedServiceAccountName)': $($_.Exception.Message)"
    return
}
#endregion

# Quiet mode keeps all imported interactive settings unchanged.
if (!$quiet){
    # Accept an existing administrator-group OU or create its missing hierarchy.
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
            }
        } 
        catch {
            Write-Host "invalid DistinguishedName" -ForegroundColor Red
            $OU = $null
        }
    }while ($null -eq $OU)

    # Constrain maximum elevation to the supported range of 15 through 1440 minutes.
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

    # Keep the default elevation between 15 minutes and the selected maximum.
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

    # Resolve the Tier 0 exclusion group and persist its distinguished name.
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

    # Advanced setup allows the default Tier 1 LDAP filter to be replaced.
    if ($AdvancedSetup){
        $LDAPT1Computers = Read-Host "LDAP query for Tier 1 computers [$($config.LDAPT1Computers)]"
        if ($LDAPT1Computers -ne ""){
            $config.LDAPT1Computers = $LDAPT1Computers
        }
    }

    # Validate the Tier 0 OU as a relative path beneath the current domain root.
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

    # Collect a group-management interval between 5 minutes and once per day.
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

    # Rebuild the search-base list from entries confirmed during this interaction.
    $arySearchBase = @()
    foreach ($SearchBase in $config.T1Searchbase){
#        if ($SearchBase -ne "<DomainRoot>"){
#            $arySearchbase += $SearchBase
#        }
    }
    $config.T1SearchBase = $arySearchBase
    # Allow multiple relative or fully qualified distinguished-name search bases.
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
        # An empty selection searches from the current domain root.
        $config.T1Searchbase += "<DomainRoot>"
    }
    #endregion

    # Prefer the published path; otherwise suggest the domain SYSVOL location.
    if ((-not $env:JustInTimeConfig) -or ($env:JustInTimeConfig -eq "")) {
        $DomainDNS = (Get-ADDomain).DNSRoot
        $DefaultJITConfigPath = "\\$DomainDNS\SYSVOL\$DomainDNS\Just-in-Time\JIT.config"
        Write-Host "It is recommended to store the configuration file on a central storage like $DefaultJITConfigPath"
    } else {
        $DefaultJITConfigPath = $env:JustInTimeConfig
    }

    # Retry until the configuration file and environment reference are saved together.
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

# Permission assignment requires the final configured administrator-group OU to exist.
if (-not (Get-ADOrganizationalUnit -Identity $config.OU -Server $config.Domain -ErrorAction SilentlyContinue)) {
    throw "The configured JIT administrator group OU '$($config.OU)' does not exist."
}
Set-JitOuPermission -Configuration $config -ServiceAccount $oGmsa

#region Event infrastructure
# Register event infrastructure before tasks that depend on those sources are started.
Set-JitEventLog -Configuration $config
#endregion
#region Scheduled tasks
# Register the recurring inventory task and event-triggered elevation task.
try {
    Set-JitScheduledTask -Configuration $config -InstallationDirectory $InstallationDirectory -TaskPath $StGroupManagementTaskPath -GroupManagementTaskName $STGroupManagementTaskName -ElevateUserTaskName $STElevateUser
}
catch {
    Write-Error "Scheduled tasks could not be configured: $($_.Exception.Message)"
    return
}
#endregion
# Remind interactive operators that enabling delegation also requires delegation rules.
if ($config.EnableDelegation){
    Write-Host "do not forget to configure your OU delegation"
    Write-Host "to allow the group Server-Admins on OU=Server,OU=contoso,OU=com use the command"
    Write-Host "To add a delegation use the command: Add-JitDelegation -OU ""OU=Server,DC=contoso,DC=com"" -AdObject ""contoso\Server-Admins"""
}

# Emit the final effective object for callers and installation scripts.
Write-Verbose "JIT configuration completed successfully."
return $config
}

return Invoke-JitConfiguration -InstallationDirectory $InstallationDirectory -AdvancedSetup:$AdvancedSetup -Quiet:$quiet -ConfigurationFile $configurationFile -ScriptVersion $_scriptVersion -WhatIf:$WhatIfPreference
