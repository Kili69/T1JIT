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

$configurationModuleVersion = "0.1.240816"
$DefaultconfigFileName = "JIT.config" #The default name of the configuration file
$DefaultSTGroupManagementTaskName = "Tier 1 Local Group Management" #Name of the Schedule tasl to enumerate servers
$DefaultStGroupManagementTaskPath = "\Just-In-Time-Privilege" #Is the schedule task folder
$DefaultSTElevateUser = "Elevate User" #Is the name of the Schedule task to elevate users
$RegExDistinguishedName = "((OU|CN)=[^,]+,)*DC="

#region Functions
function New-ADDGuidMap
{
    <#
    .SYNOPSIS
        Creates a guid map for the delegation part
    .DESCRIPTION
        Creates a guid map for the delegation part
    .EXAMPLE
        PS C:\> New-ADDGuidMap
    .OUTPUTS
        Hashtable
    .NOTES
        Author: Constantin Hager
        Date: 06.08.2019
    #>
    $rootdse = Get-ADRootDSE
    $guidmap = @{ }
    $GuidMapParams = @{
        SearchBase = ($rootdse.SchemaNamingContext)
        LDAPFilter = "(schemaidguid=*)"
        Properties = ("lDAPDisplayName", "schemaIDGUID")
    }
    Get-ADObject @GuidMapParams | ForEach-Object { $guidmap[$_.lDAPDisplayName] = [System.GUID]$_.schemaIDGUID }
    return $guidmap
}
<#
    This function add a SID to the "Logon as a Batch Job" privilege
#>
function Add-LogonAsABatchJobPrivilege 
{
    <#
    .SYNOPSIS
        Assign the Logon As A Batch Job privilege to a SID
    .DESCRIPTION
        Assign the Logon As A Batch Job privilege to a SID
    .EXAMPLE
        Add-LogonAsABatchJob -SID "S-1-5-0"
    .OUTPUTS
        none
    .NOTES
        Author: Andreas Lucas
        Date: 2021-10-10
    #>
    param ($Sid)
    #Temporary files for secedit
    $tempPath = [System.IO.Path]::GetTempPath()
    $import = Join-Path -Path $tempPath -ChildPath "import.inf"
    if(Test-Path $import) { Remove-Item -Path $import -Force }
    $export = Join-Path -Path $tempPath -ChildPath "export.inf"
    if(Test-Path $export) { Remove-Item -Path $export -Force }
    $secedt = Join-Path -Path $tempPath -ChildPath "secedt.sdb"
    if(Test-Path $secedt) { Remove-Item -Path $secedt -Force }
    #Export the current configuration
    secedit /export /cfg $export
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
        secedit /import /db $secedt /cfg $import
        secedit /configure /db $secedt
        gpupdate /force
        Remove-Item -Path $import -Force
        Remove-Item -Path $secedt -Force
    }
    #remove all temporary files   
    Remove-Item -Path $export -Force
    
}

function CreateOU {
    <# Function create the entire OU path of the relative distinuished name without the domain component. This function
    is required to provide the same OU structure in the entrie forest
    .SYNOPSIS 
        Create OU path in the current $DomainDNS
    .DESCRIPTION
        create OU and sub OU to build the entire OU path. As an example on a DN like OU=Computers,OU=Tier 0,OU=Admin in
        contoso. The funtion create in the 1st round the OU=Admin if requried, in the 2nd round the OU=Tier 0,OU=Admin
        and so on till the entrie path is created
    .PARAMETER OUPath 
        the relative OU path withou domain component
    .PARAMETER DomainDNS
        Domain DNS Name
    .EXAMPLE
        CreateOU -OUPath "OU=Test,OU=Demo" -DomainDNS "contoso.com"
    .OUTPUTS
        $True
            if the OUs are sucessfully create
        $False
            If at least one OU cannot created. It the user has not the required rights, the function will also return $false 
    #>

    [CmdletBinding ( SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$OUPath,
        [Parameter (Mandatory)]
        [string]$DomainDNS
    )
    try{
        #check if OU already exist
        if ([ADSI]::Exists("LDAP://$OUPath")){
            $success = $true
            return $success
        }
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
                    Write-Host "'$($_+$OUBuildPath)' doesn't exist. Creating OU" -ForegroundColor Green
                    New-ADOrganizationalUnit -Name $OUName -Path $OUBuildPath.Substring(1) -Server $DomainDNS                        
                    
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


function Read-JIT.Configuration{
    param(
        [Parameter (Mandatory=$false, Position=0)]
        [string]$configurationFile
    )
    #region configuration object
    try {
        $ADDomainDNS = (Get-ADDomain).DNSRoot #$current domain DNSName. Testing the Powershell AD modules are working
    }
    catch {
        Write-Output "Cannot determine AD domain - aborting!"
        return
    }
    #build the default configuration object
    $config = New-Object PSObject
    $config | Add-Member -MemberType NoteProperty -Name "ConfigScriptVersion"            -Value $_scriptVersion
    $config | Add-Member -MemberType NoteProperty -Name "ConfigurationModulVersion"      -Value $configurationModuleVersion
    $config | Add-Member -MemberType NoteProperty -Name "ConfigVersion"                  -Value "20240816"
    $config | Add-Member -MemberType NoteProperty -Name "AdminPreFix"                    -Value "Admin_"
    $config | Add-Member -MemberType NoteProperty -Name "OU"                             -Value "OU=JIT-Administrator Groups,OU=Tier 1,OU=Admin,$((Get-ADDomain).DistinguishedName)"
    $config | Add-Member -MemberType NoteProperty -Name "MaxElevatedTime"                -Value 1440
    $config | Add-Member -MemberType NoteProperty -Name "DefaultElevatedTime"            -Value 60
    $config | Add-Member -MemberType NoteProperty -Name "ElevateEventID"                 -Value 100
    $config | Add-Member -MemberType NoteProperty -Name "Tier0ServerGroupName"           -Value "Tier 0 Computers"
    $config | Add-Member -MemberType NoteProperty -Name "LDAPT0Computers"                -Value "(&(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))" #Deprecated Tier 0 computer identified by Tier 0 group membership
    $config | Add-Member -MemberType NoteProperty -Name "LDAPT0ComputerPath"             -Value "OU=Tier 0,OU=Admin"
    $config | Add-Member -MemberType NoteProperty -Name "LDAPT1Computers"                -Value "(&(OperatingSystem=*Windows*)(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))" #added 20231201 LDAP query to search for Tier 1 computers
    $config | Add-Member -MemberType NoteProperty -Name "EventSource"                    -Value "T1Mgmt"
    $config | Add-Member -MemberType NoteProperty -Name "EventLog"                       -Value "Tier 1 Management"
    $config | Add-Member -MemberType NoteProperty -Name "GroupManagementTaskRerun"       -Value 5
    $config | Add-Member -MemberType NoteProperty -Name "GroupManagedServiceAccountName" -Value "T1GroupMgmt"
    $config | Add-Member -MemberType NoteProperty -Name "Domain"                         -Value $ADDomainDNS
    $config | Add-Member -MemberType NoteProperty -Name "DelegationConfigPath"           -Value "$InstallationDirectory\Tier1delegation.config" #Parameter added is the path to the delegation config file
    $config | Add-Member -MemberType NoteProperty -Name "EnableDelegation"               -Value $true
    $config | Add-Member -MemberType NoteProperty -Name "EnableMultiDomainSupport"       -Value $true
    $config | Add-Member -MemberType NoteProperty -Name "T1Searchbase"                   -Value @("<DomainRoot>")
    $config | Add-Member -MemberType NoteProperty -Name "DomainSeparator"                -Value "#"
    #endregion
    try{
        if ($configurationFile -eq ""){
            if ($Null -eq $env:JustInTimeConfig){
                if (Test-Path -Path $env:JustInTimeConfig){
                    $existingconfig = get-content $env:JustInTimeConfig | ConvertFrom-Json
                } else {
                    $existingconfig = $Null
                }
            } 
        } else {
            if (Test-Path -Path $configurationFile){
                    $existingconfig = Get-Content -Path $configurationFile | ConvertFrom-Json
            } else {
                $existingconfig = $null
            }
        }
        if ($null -eq $existingconfig ){
            return $config
        }
        if ($existingconfig.ConfigVersion -gt $config.ConfigVersion){
            Write-Host "Invalid configuration model $($existingconfig.ConfigVersion)"
            return $null
        }
        #Replace the default values with the existing values
        foreach ($setting in ($existingconfig | Get-Member -MemberType NoteProperty)){
            $config.$($setting.Name) = $existingconfig.$($setting.Name)
        }
        $config.ConfigurationModulVersion = $configurationModuleVersion
        return $config
    }
    catch{
        Throw $Error[0]
    }
}

function Write-JIT.Configuration{

}
function Update-JIT.GMSA{

}
function Create-JIT.ScheduleTask{
    $config = Read-JIT.Configuration
    $STprincipal = New-ScheduledTaskPrincipal -UserId "$((Get-ADDomain).NetbiosName)\$((Get-ADServiceAccount $config.GroupManagedServiceAccountName).SamAccountName)" -LogonType Password
If (!((Get-ScheduledTask).URI -contains "$StGroupManagementTaskPath\$STGroupManagementTaskName"))
{
    try {
        $STaction  = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -file "' + $InstallationDirectory + '\Tier1LocalAdminGroup.ps1"') 
        $STTrigger = New-ScheduledTaskTrigger -AtStartup 
        $STTrigger.Repetition = $(New-ScheduledTaskTrigger -Once -at 7am -RepetitionInterval (New-TimeSpan -Minutes $($config.GroupManagementTaskRerun))).Repetition                      
        Register-ScheduledTask -Principal $STprincipal -TaskName $STGroupManagementTaskName -TaskPath $StGroupManagementTaskPath -Action $STaction -Trigger $STTrigger
        Start-ScheduledTask -TaskPath "$StGroupManagementTaskPath\" -TaskName $STGroupManagementTaskName
        If (!((Get-ScheduledTask).URI -contains "$StGroupManagementTaskPath\$STElevateUser"))
        {
            <#
            create s schedule task who is triggered by eventlog entry in the event Log Tier 1 Management
            #>
            $STaction = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -file "' + $InstallationDirectory + '\ElevateUser.ps1" -eventRecordID $(eventRecordID)') -WorkingDirectory $InstallationDirectory
            $CIMTriggerClass = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger
            $Trigger = New-CimInstance -CimClass $CIMTriggerClass -ClientOnly
            $Trigger.Subscription = "<QueryList><Query Id=""0"" Path=""$($config.EventLog)""><Select Path=""$($config.EventLog)"">*[System[Provider[@Name='$($config.EventSource)'] and EventID=$($config.ElevateEventID)]]</Select></Query></QueryList>"
            $Trigger.Enabled = $true
            $Trigger.ValueQueries = [CimInstance[]]$(Get-CimClass -ClassName MSFT_TaskNamedValue -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskNamedValue)
            $Trigger.ValueQueries[0].Name = "eventRecordID"
            $Trigger.ValueQueries[0].Value = "Event/System/EventRecordID"
            $ElevateUserSettings = New-ScheduledTaskSettingsSet -MultipleInstances Parallel 
            Register-ScheduledTask -Principal $STprincipal -TaskName $STElevateUser -TaskPath $StGroupManagementTaskPath -Action $STaction -Trigger $Trigger -Settings $ElevateUserSettings
        }                        
    }
    catch [System.UnauthorizedAccessException] {
        Write-Host "Schedule task cannot registered." -ForegroundColor Red
    }
}
}
function Add-JitServerOU{
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$OU
    )
    $config = Get-Content $env:JustInTimeConfig | ConvertFrom-Json
    #Search for dnsdomain
    $DomainDN = [regex]::Match($OU,"dc=.+").Value
    foreach ($ADDomainDNS in (Get-ADForest).Domains){
        IF ($DomainDN -eq $(Get-ADDomain -Server $ADDomainDNS).DistinguishedName){
            break;
        }
    }
    if ((Get-ADObject -Filter "DistinguishedName -eq '$OU'" -server $ADDomainDNS)){
        if ($config.T1Searchbase -contains $OU){
            Write-Host "$OU is already defined" -ForegroundColor Yellow
        } else {
            $config.T1Searchbase += $OU
            ConvertTo-Json $config | Out-File $env:JustInTimeConfig -Confirm:$false
        }
    } else {
        throw [System.ArgumentException]::new("Invalid DistinguishedName", $OU)
    }
}
function Get-JitServerOU{
    $config = Get-Content $env:JustInTimeConfig | ConvertFrom-Json
    return $config.T1Searchbase
}
function Remove-JITServerOU{
    param(
        [Parameter (Mandatory = $true, ValueFromPipeline = $true)]
        [string]$OU
    )
    $config = Get-Content $env:JustInTimeConfig | ConvertFrom-Json
    if ($config.T1Searchbase -contains $OU){
        $tempSerachBase = @()
        foreach ($sb in $config.T1Searchbase){
            if ($sb -ne $OU){
                $tempSerachBase += $sb
            }
        }
        $config.T1Searchbase = $tempSerachBase
        ConvertTo-Json $config | Out-File $env:JustInTimeConfig -Confirm:$false
    } else {
        Write-Host "$OU is not defined" -ForegroundColor Yellow
    }
}
#endregion


<#
.SYNOPSIS
    Import the configuration from JIT.config file
.DESCRIPTION
    Reading the JIT.config from the System variable or a expicite JIT configuration file. 
    The function return the configuration as JIT config object
    This is a module private function
.PARAMETER configurationFile
    this is a optional parameter to use a dedicated configuration file.
    If this parameter is not available the function read the configuration files
    from the in the $env:JustInTimeConfig varaible or from the current directory
.INPUTS
    The path to the configuration file as string
.OUTPUTS
    JIT config object as PSObject 
.EXAMPLE
    Get-JITConfig
    Tries to read the JIT configuration from the path in the SYSTEM variable JustInTimeConfig. 
    If the environement is not available or the file doesn't exist, the function tries to read 
    the configuration file from the current directory
    Get-JITConfig .\jit.config
        Read the configuration from the path
    Get-JITConfig -ConfigurationFile .\jit.config
        Read the configuration from the path
#>
function Get-JITconfig{
    param(
        [Parameter (Mandatory=$false, Position=0)]
        [string]$configurationFile
    )
    function Resolve-KjitCoreAssemblyPath {
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
        param(
            [string]$InputValue
        )

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

    function Register-KjitAssemblyResolver {
        param(
            [Parameter(Mandatory = $true)]
            [string]$KjitCoreAssemblyPath
        )

        if ($script:KjitAssemblyResolveHandler) {
            return
        }

        $assemblyDirectory = Split-Path -Path $KjitCoreAssemblyPath -Parent
        $script:KjitAssemblyResolveHandler = [System.ResolveEventHandler]{
            param($sender, $args)

            try {
                $requestedAssemblyName = New-Object System.Reflection.AssemblyName($args.Name)
                $candidatePath = Join-Path -Path $assemblyDirectory -ChildPath ($requestedAssemblyName.Name + ".dll")
                if (Test-Path -LiteralPath $candidatePath -PathType Leaf) {
                    return [System.Reflection.Assembly]::LoadFrom($candidatePath)
                }
            }
            catch {
                return $null
            }

            return $null
        }

        [System.AppDomain]::CurrentDomain.add_AssemblyResolve($script:KjitAssemblyResolveHandler)
    }

    $assemblyPath = Resolve-KjitCoreAssemblyPath
    $alreadyLoadedAssembly = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -eq "KjitCore" } | Select-Object -First 1
    if ($null -ne $alreadyLoadedAssembly -and -not [string]::IsNullOrWhiteSpace($alreadyLoadedAssembly.Location)) {
        $loadedPath = (Resolve-Path -LiteralPath $alreadyLoadedAssembly.Location -ErrorAction SilentlyContinue).ProviderPath
        $targetPath = (Resolve-Path -LiteralPath $assemblyPath -ErrorAction SilentlyContinue).ProviderPath
        if ($loadedPath -and $targetPath -and ($loadedPath -ne $targetPath)) {
            throw "KjitCore is already loaded from '$loadedPath'. The module needs '$targetPath'. Start a new PowerShell session and import the module again."
        }
    }

    if (-not ("KjitCore.KjitCore" -as [type])) {
        try {
            Register-KjitAssemblyResolver -KjitCoreAssemblyPath $assemblyPath
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

    $source = Resolve-JitConfigurationSource -InputValue $configurationFile
    return [KjitCore.KjitCore]::LoadJitConfiguration($source)
}


