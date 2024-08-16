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

}
function Add-JIT.ServerOU{

}
function Remove-JIT.ServerOU{

}

#endregion

