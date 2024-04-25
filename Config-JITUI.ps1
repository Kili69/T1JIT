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
    This script install and configure the Tier 1 JIT solution 

.DESCRIPTION
    The installation script copies the required scripts to the script directory, create the 
    group managed service account and register the required schedule tasks

.EXAMPLE
    .\config-T1jitUI.ps1

.INPUTS
    -TargetDirectory
        Install the solution into another directory then the Windows Powershell script directory 
    -CreateGMSA [$true|$false]
        Create a new GMSA and install the GMSA on this computer
    -ServerEnumerationTime
        Rerun time for scheduled task
    -DebugOutput [$true|$false]
        For test purposes only, print out debug info.

.OUTPUTS
   none
.NOTES
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
    Version 0.1.20240228
        - by Andreas Luy
        - completely re-written for graphic UI
#>
<#
    script parameters
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    #The groupname prefix for local administrators group 
    [Parameter (mandatory=$false)]
    $AdminPreFix,
    #The name of the domain 
    [Parameter (Mandatory=$false)]
    $Domain, 
    #The distinguished name of the organizaztional Unit to store the privileged groups
    [Parameter (mandatory=$false)]
    $OU,
    #the maximum amount of minutes to elevate a user
    [Parameter (Mandatory=$false)]
    $MaxMinutes,
    #Is the name of the Tier 0 computer group. Those computers will be excluded for this PAM solution
    [Parameter (Mandatory=$false)]
    $Tier0ServerGroupName,
    #Is the default time for elevated users
    [Parameter (Mandatory=$false)]
    $DefaultElevatedTime,
    #The installation directory to find the JIT.config file
    [Parameter (Mandatory=$false)]
    $InstallationDirectory,
    [Parameter (Mandatory=$false)]
    #The in minutes to run the computer enumeration script 
    [INT] $GroupManagementTaskRerun = 10,
    #If this paramter is $True the required group management account will be created by this script
    [Parameter (Mandatory=$false)]
    [bool] $InstallGroupManagedServiceAccount = $true,
    #The name of the group managed service account
    [Parameter (Mandatory=$false)]
    $GroupManagedServiceAccountName,
    #Enable the debug option for additional information
    [Parameter (Mandatory=$false)]
    [bool] $DebugOutput = $false,
    #Install the schedule task on the local server, running in the context of the GMSA
    [Parameter (Mandatory=$false)]
    [bool] $CreateScheduledTaskADGroupManagement = $true,
    [Parameter (Mandatory=$false)]
    [INT] $ServerEnumerationTime = 10,
    [Parameter (Mandatory=$false)]
    #Enable the delegation Model
    [bool] $EnableDelegationMode = $false,
    [Parameter (Mandatory = $false)]
    #The delegation file path
    [string] $DelegationFilePath
)


## loading .net classes needed
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

# define fonts, colors and app icon
    $FontStdt = New-Object System.Drawing.Font("Arial",11,[System.Drawing.FontStyle]::Regular)
    $FontBold = New-Object System.Drawing.Font("Arial",11,[System.Drawing.FontStyle]::Bold)
    $FontItalic = New-Object System.Drawing.Font("Arial",9,[System.Drawing.FontStyle]::Italic)
    $iconBase64 = "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAAACXBIWXMAAAOwAAADsAEnxA+tAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAACpFJREFUeJztnX9QFNcBxz9358mBRKISSUFJ0EQ0iBqj1lSTTuQspbQmpVX/6DRO/NnSGSdjhglpk4yVKtKxsZkGaUbB1Omk6WjQpEkNBmbsaRpHxaABVBobRowQUykGlYAc1z+IFtgfdwe3e3u+95nZGXjv7e47vp97u3fs7gNJpPEj4BOgFXgJcIa3OxIzWQ54AV+f5R0gKpydkpiDWvhSAkHQC19KcJsTSPhSgtuUYMKXEtxmaIb/wJQs349zfu+z2x1DlsBhQMclQ2c5sB2wD6x4YEoWSxcXk/iNNMaMmcDpMxX4fL6BzSYBDwJv0iuRJlIA6+E3fIdjGAAJCalDlkAKYC0CDv8mCQmpxMUlceZsJb2jfz8mAZOBPVo7tA21x4NgGr0v8iGkgAGhFX5fTny0m71v5eHz9ahVLwL+plahMM0EdgNzkOEHRCDhA0yf9kMSE9O1qu/XqjBbgAR6hyVJAAQavtfbzV935/LZZyfVqm8AFVrrmi3AcJP3F7EEG3796ffUqnuA1UCd1vrhOARI/BCi8H1ALvCa3jbCLsD48ePx+XxCLaWlpdjt6n/6EIb/c+BVf3//sAsgGmVlZaxatYqeHuXZutnhgxTAVKwWPkgBTMOE8AEKCCJ8kAKYgknhAzQF2zcpgMGYGP6gkAIYiNXDB9DfuwVobm7G4/Fw5coV0/ftdDqZM2cOaWlpQa8bCeGDxQXweDxkZ2dz9erVsPXBZrOxadMm8vPzA17H6PDtdjvJyck0NjYG3CctLH0IKCgoCGv4AD6fj/Xr19PZ2RlQe6PDt9lsbNu2DbfbHdgL8IOlBQh3+Dfp6uoKSAAzwi8pKWHNmjWBd94PlhZg5cqV4e4CAEuWLGHkyJG6bSIxfLD4OcCKFStITEykoqKCjo4O0/dvt9uZMWMGy5cv120XqeGDxQUAyMrKIisrK9zd0CSSwweLHwKsTqSHD1KAQXM7hA9SgEFxu4QPUoCguZ3Ch+BPAh8EngQWAsnAHSHvkYUJXfi/0PyGb8eOHTz11FMh67M/AhXgDmAb8BPCcy9B2Alt+PsVdeEIHwITYCxQBUw1uC8Kenp6KC4u5sCBA3z11Vch3fbYsWPJzc1l3rx5ftvqhQ8wenRyRIYP/gVwAuWEIXyAwsJCnn/+ecO2v2fPHk6dOkVqaqpmm/Lyct3wAQ5/8Co2m53Mhc+p1ls1fPB/ErgG8P8WMYh9+/YZuv2uri7effdd3TYvvviibvg3OXS4hIr3CxXlVg4f9EcAO6D4H2hsTBQb132PJ9zpJCeOCmpnTc1tJH/71wG3T0pK4vjx40HtI1jGjRunWXfhwgXq6pT3VExKuZeGTxsV5YcOlwDcGgmsHj7ojwCzgaR+je023v7jStY++WjQ4Q+GjRs3Mn78eMO2v2jRInJycjTrKysrFWVTJ91P7f63eHbNCtV1Dh0u4cD7hRERPuiPANMGFiycl8pjc+8zsDv9SUtL49y5c9TU1IT8iqCUlBQmTpyo20ZNgOzHHsU5bBib89YBUPRqqaKN53AJdaff4/LlTxV1Vgof9AVIGFgwY0qSWjtDcTqdzJ492/T9+nw+qqqqFOXubz1862c9CSIhfNA/BCjkiI4S56GUtbW1tLS09CtzRUUx76EH+5VtzlvHr3L9f2t380oeK4UP8qtgTdSG//mzZhLtcinKf7NuLXmrtK8ZsNvtlJaWmvb1bjBIATRQE6Dv8N+X2oZ/qX4qAGsO+32x/AUh4aCrqwuPx6Mod8+bC8Dn/7mM59hxKj/4kP3/OERTc4uiLVh32O+LFECFI0eOKC5IHeZwsHPPXn76TD6nz/3b7zas/s6/SUQIcOnSpSFfITxixAgSEhQfbFRRG/67vV6K//yXgNaPhHf+TSwtwPnz58nJyaG6ujok25s+fTrl5eVMmDBBt52aAIHidDrZvn07y5YtG/Q2zMTSJ4H5+fkhCx/g5MmT5OXl6ba5fv06x44dC2q7LpeLjIwMCgsLqauri5jwweIjwNmzZ0O+zYaGBt36zs5OvF7dp6veulzc7XbjdruZP38+0dHRoeymaVhagIyMDE6cOBHSbfq7pWrUqFEsXbqUN954o195SkrKrcAXLFhAfHx8SPsVLiwtwIYNG7DZbOzfv59r164NaVsxMTFkZmZSUFDgt+2uXbt45JFHqK+vJz09Hbfb7ff/BpGKpQVwuVwUFRVRVFRk6n6dTie5ubmm7jNcWPokUGI8UgDBkQIIjhRAcKQAgiMFEBxTPwZ23ehWlLW1tQX1AKahEhcXR2ZmJjNnztRtV1NTQ1VVFZMnTyY7O1u37cWLF9m7dy9NTUE/p3HQHD16VK046Eu2TBGg7csOCooPULrniKKuvb3d9M/5L7zwAq+//jpLlixRrd+3bx+LFy+mu7tX2LVr1/Lyyy+rtm1sbGTWrFlcvnzZsP4GwR+A7wDPAWcCWcHwQ0B1bRPp3/8tL+08yJX20N7eNVi8Xi9bt27VrN+yZcut8AFeeeUV2tvbVduWlZVZJXzonYbnCeAkoH7d+gAMHQFqG5rJWLbNMsH3xdZ+GjwLVeuc1+r7/e6w+3B8+Di4VKY5On/OiO4NleHAjq9/Vl6y3AfDRoDOrm6WPr3LkuEPc9h4Zuk9mvVPL07GYf//TdA/WzSOGLXwgRXZScTHWfZq6WJgil4Dw0aAnW8epf4T5bVyI1wOsuaOIX1CLFFO8z+ERDntLJg5mmkTYzXbPD7/LmrKvklVdSupySP47pwxmm3vSXDx8WsP8/YHX/Df9htGdFmXnh745LPrvH+8laZLijdbFLAR0Lz9yTABduxWnvClJsfwzuYZ3JcUY9RuQ8bUlFimpmhL0pe7Rw9n9Q/Mv2mmL1c7vCzfXM/ug58PrFpE7y3+l9TWM+Qt2PZlBx/VX1CU7/rl1IgIPxKJjXZQlv8A4+5SzBntAB7VWs8QAZpa2ujp6T+NaVJ8FHOm6D9tUzI0YqMdLJyleri6V2sdQwS4ek35XN3kBOUdNZLQc8/dqn9nzWOZ/CpYcKQAgiMFEBwpgOBIAQRHCiA4UgDBkQIIjhRAcKQAgiMFEBwpgOBIAQRHCiA4UgDBkQIIjhRAcKQAgiMFEBwpgOBIAQRHCiA4UgDBkQIIjhRAcKQAgiMFEBwpgOBIAQRHCiA4UgDBkQIIjhRAcKQAgiMFEBwpgOBIAQRHCiA4UgDBkQIIjhRAcKQAgiMFEBwpgOBIAQRHCiA4UgDBkQIIjhRAcPQEUMzz2tEZ2KxYau2cw6RrZtDR2aNWrJyz92v0UlHM+XaiTjkRlBrVtco5dJPiFZMZSQyg+uyXasXNWu31BDg1sKDynw1Ufdig24EvWq/yu7KDivKpE0boricZOpXVrVSdaFWrOqm1jvp0mL1cpHf+2X5Tfb1ZcYpo13ASx8Zx58joW+WtV67z3qEzLF77Jy60tCk2VrJuCmOsO8NmRNPY0kHZ35tZveU0N7p9A6vPA88Odtu5gE8uEb2sVqQaBE7AY4EXIZfBLQcJweywd9F7DAn3i5FLcEsNEK+S56CIBXYCXgu8MLnoL156p44P6Kzb5r9JP6YBTwILgWTgziDXlxhDG70neweAXcDHga74P7Dv0tuSxCKLAAAAAElFTkSuQmCC"
    $iconBytes = [Convert]::FromBase64String($iconBase64)
    $stream = [System.IO.MemoryStream]::new($iconBytes, 0, $iconBytes.Length)



#region Helper functions
    function Break-MessageBox 
    {
        param(
            [Parameter(mandatory=$true)]$Message
        )
       [void][System.Windows.Forms.MessageBox]::Show($Message,"Critical Error!","OK",[System.Windows.Forms.MessageBoxIcon]::Stop)
        exit
    }

    function Warning-MessageBox 
    {
        param(
            [Parameter(mandatory=$true)]$Message
        )
       [void][System.Windows.Forms.MessageBox]::Show($Message,"Error!","OK",[System.Windows.Forms.MessageBoxIcon]::Warning)
    }

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
            Break-MessageBox -Message "Delegation config file not found!`r`n`r`nAborting ..."
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

    function Create-JiTTasks
    {
    param (
        [Parameter(Mandatory)]
        [string]$gMSA,
        [Parameter (Mandatory)]
        [string]$DomainDNS,
        [Parameter (Mandatory)]
        [int]$gMSATaskReRun
    )

        $success = $false
        Write-Host "creating schedule task to evaluate required Administrator groups"

        $STGroupManagementTaskName = "Tier 1 Local Group Management"
        $StGroupManagementTaskPath = "\Just-In-Time-Privilege"
        $STprincipal = New-ScheduledTaskPrincipal -UserId "$((Get-ADDomain -Server $DomainDNS).NetbiosName)\$((Get-ADServiceAccount $gMSA).SamAccountName)" -LogonType Password
        If (!((Get-ScheduledTask).URI -contains "$StGroupManagementTaskPath\$STGroupManagementTaskName"))
        {
            try {
                $STaction  = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -file "' + $InstallationDirectory + '\Tier1LocalAdminGroup.ps1" "' + $InstallationDirectory + '\jit.config"') 
                $STTrigger = New-ScheduledTaskTrigger -AtStartup 
                $STTrigger.Repetition = $(New-ScheduledTaskTrigger -Once -at 7am -RepetitionInterval (New-TimeSpan -Minutes $($gMSATaskReRun))).Repetition                      
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
                    $Trigger.Subscription = "<QueryList><Query Id=""0"" Path=""$($Script:config.EventLog)""><Select Path=""$($Script:config.EventLog)"">*[System[Provider[@Name='$($Script:config.EventSource)'] and EventID=$($Script:config.ElevateEventID)]]</Select></Query></QueryList>"
                    $Trigger.Enabled = $true
                    $Trigger.ValueQueries = [CimInstance[]]$(Get-CimClass -ClassName MSFT_TaskNamedValue -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskNamedValue)
                    $Trigger.ValueQueries[0].Name = "eventRecordID"
                    $Trigger.ValueQueries[0].Value = "Event/System/EventRecordID"
                    Register-ScheduledTask -Principal $STprincipal -TaskName $STElevateUser -TaskPath $StGroupManagementTaskPath -Action $STaction -Trigger $Trigger
                }
                $success = $true
            }
            catch [System.UnauthorizedAccessException] {
                Break-MessageBox -Message "Schedule task cannot registered!`r`n`r`nAborting ..."
                return $success
            }
        }
        return $success                
    }

    function Create-OU 
    {
    <# Function create the entire OU path of the relative distinuished name without the domain component. This function
    is required to provide the same OU structure in the entire forest
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

    .Version 2.0 by Andreas Luy
    #>

    [CmdletBinding (SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$OUPath,
        [Parameter (Mandatory)]
        [string]$DomainDNS
    )
        $success = $false
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
            #old code replaced by Andreas Luy
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
            $success = $true
        } 
        catch [System.UnauthorizedAccessException]{
            Break-MessageBox -Message "Delegation config file not found!`r`n`r`nAborting ..."
            Write-Host "Access denied to create $OUPath in $domainDNS"
            Return $success
        } 
        catch{
            Break-MessageBox -Message "Delegation config file not found!`r`n`r`nAborting ..."
            Write-Host "A error occured while create OU Structure"
            Write-Host $Error[0].CategoryInfo.GetType()
            Return $success
        }
        Return $success
    }

    function create-gMSA
    {
    param (
        [Parameter(Mandatory)]
        [string]$gMSA,
        [Parameter (Mandatory)]
        [string]$DomainDNS
    )

    $success = $false
    try {
        if (!(Get-ADServiceAccount -Filter "Name -eq '$($gMSA)'" -Server $($DomainDNS)))
        {
            if ($InstallGroupManagedServiceAccount)
            {
                Write-Debug "Create GMSA $($gMSA) "
                New-ADServiceAccount -Name $gMSA -DisplayName $gMSA -DNSHostName "$($gMSA).$($DomainDNS)" -Server $DomainDNS
            }
            else
            {
                Break-MessageBox -Message "Missing GMSA $($gMSA)!`r`n`r`nAborting ..."
                return $success
            }
        }
        $principalsAllowToRetrivePassword = (Get-ADServiceAccount -Identity $gMSA -Properties PrincipalsAllowedToRetrieveManagedPassword).PrincipalsAllowedToRetrieveManagedPassword
        if (($principalsAllowToRetrivePassword.Count -eq 0) -or ($principalsAllowToRetrivePassword.Value -notcontains (Get-ADComputer -Identity $env:COMPUTERNAME).DistinguishedName))
        {
            Write-Debug "Adding current computer to the list of computer who an retrive the password"
            $principalsAllowToretrivePassword.Add((Get-ADComputer -Identity $env:COMPUTERNAME))
            Set-ADServiceAccount -Identity $gMSA -PrincipalsAllowedToRetrieveManagedPassword $principalsAllowToRetrivePassword -Server $DomainDNS
        }
        else
        {
            Write-Debug "is already in the list of computer who can retrieve the password"
        }
        Set-ADServiceAccount -Identity $gMSA -KerberosEncryptionType AES128, AES256
    } catch {
        if ( $Error[0].CategoryInfo.Activity -eq "New-ADServiceAccount"){
            Break-MessageBox -Message "A GMSA coult not be created!`r`nEnsure you have the correct privileges and the KDS rootkey exists.`r`n`r`nAborting ..."
            return $success
        }
        $msg = "A error occured while configureing GMSA!`r`n`r`n"
        $msg = $msg + $Error[0]
        $msg = $msg + "`r`n`r`nAborting ..."
        Break-MessageBox -Message $msg
        $msg = ""
        return $success
    }
    $oGmsa = Get-ADServiceAccount -Identity $gMSA -Server $DomainDNS
    if (!(Test-ADServiceAccount -Identity $gMSA)){
        Install-ADServiceAccount -Identity $oGmsa
    }
    Write-Debug "Test $GMSAName $(Test-ADServiceAccount -Identity $($gMSA))"
    Add-LogonAsABatchJobPrivilege -Sid ($oGmsa.SID).Value
    $success = $true    
    return $success
    }

    function Configure-T1JiT
    {
    $success = $false

    #Writing configuration file first
    ConvertTo-Json $Script:config | Out-File "$InstallationDirectory\$Script:configFileName" -Confirm:$false

    if (!(Create-OU -OUPath $Script:config.JiTOU -DomainDNS $Script:config.Domain)) {
        return $success
    }
    if (!(create-gMSA -gMSA $Script:config.GroupManagedServiceAccountName -DomainDNS $Script:config.Domain)) {
        return $success
    }

    #region add permissions for gMSA onto JIT OU
    try {
        Write-Debug  "OU $($Script:config.JiTOU) is accessible updating ACL"
        $aclGroupOU = Get-ACL -Path "AD:\$($Script:config.JiTOU)"
        if (!($aclGroupOU.Sddl.Contains($oGmsa.SID)))
        {
            Write-Debug "Adding ACE to OU"
            #this section needs to be updated. Currently the GMSA get full control on the Tier 1 computer group OU. This should be fixed in
            # Full control to any group object in this OU and createChild, deleteChild for group object in this OU
            $identity = [System.Security.Principal.IdentityReference] $oGmsa.SID
            $adRights = [System.DirectoryServices.ActiveDirectoryRights] "GenericAll"
            $type = [System.Security.AccessControl.AccessControlType] "Allow"
            $inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "All"
            $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity,$adRights,$type,$inheritanceType
            $aclGroupOU.AddAccessRule($ace)
            Set-Acl -AclObject $aclGroupOU "AD:\$($Script:config.JiTOU)"
        }
    }
    catch {
        return $success
    }
    #endregion

    #region eventlog
    try {
        #create eventlog and register EventSource id required
        Write-Debug "Reading Windows eventlogs please wait" 
        if ($null -eq (Get-EventLog -List | Where-Object {$_.LogDisplayName -eq $Script:config.EventLog}))
        {
            Write-Debug "Creating new Event log $($Script:config.EventLog)"
            New-EventLog -LogName $Script:config.EventLog -Source $Script:config.EventSource
            Write-EventLog -LogName $Script:config.EventLog -Source $Script:config.EventSource -EventId 1 -Message "JIT configuration created"
        }
    }
    catch {
        return $success
    }
    #endregion

    if ($CreateScheduledTaskADGroupManagement -eq $true) {
        if (!(Create-JiTTasks -gMSA $Script:config.GroupManagedServiceAccountName -gMSATaskReRun $Script:config.GroupManagementTaskRerun -DomainDNS $Script:config.Domain)) {
            return $success
        }
    }
    if ($Script:config.EnableDelegation){
        Write-Host "do not forget to configure your OU delegation"
        Write-Host "to allow the group Server-Admins on OU=Server,OU=contoso,OU=com use the command"
        Write-Host ".\DelegationConfig.ps1 -action AddDelegation -OU ""OU=Server,DC=contoso,DC=com"" -AdUserOrGroup ""contoso\Server-Admins"" "
    }
    $success = $true
    return $success
    }
#endregion

#region Constant section
$_scriptVersion = "0.1.20240123"
$Script:configFileName = "JIT.config"
$MaximumElevatedTime = 1440
#$DefaultElevatedTime = 60
$DefaultAdminPrefix = "Admin_"
$DefaultLdapQuery = "(&(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))" #deprecated will be removed
$DefaultServerGroupName = "Tier0Servers"
$DefaultGroupManagementServiceAccountName = "T1GroupMgmt"
$EventSource = "T1Mgmt"
$EventLogName = "Tier 1 Management"
#$STAdminGroupManagement = "Administrator Group Management"
$STAdminGroupManagementRerunMinutes = 5
$STElevateUser = "Elevate User"
try {
    $ADDomainDNS = (Get-ADDomain).DNSRoot
}
catch {
    Break-MessageBox -Message "Cannot determine AD domain!`r`n`r`nAborting ..."
    return
}
$aInputs = @(
    "0#1#Please enter 'Admin' prefix to identify Tier 1 server 'local administrator' groups.`r`nE.g.: T1Adm-<servername> or T1Adm-WebServer01",
    "",
    "2#5#Please define the default duration for elevation. The defined time frame must be between 15 minutes and $($Script:config.MaxElevatedTime).",
    "",
    "",
    "",
    "",
    "7#8#Do you want to enable delegation mode?`r`nDelegation mode allow only access to specifc systems if defined in 'delegation.config' file.",
    "8#9#Do you want to enable multi-domain support?`r`nWithout multi-domain support enabled, only current domain ($($Script:config.domain)) will be included.",
    "",
    "",
    "11#6#Please define the name for the group managed account gMSA).`r`nThis account will be granted control over the server admin groups and run the scheduled tasks.",
    "12#7#Please define the interval the task evaluating Tier 1 server should run.`r`nThe value must be between 5 minutes and 1440 minutes (once a day).",
    "13#2#Please define the OU for the Jit computer groups.`r`nThe entry must be in full distinguished name format.",
    "14#14#Please define the relative path to your Tier 0 OU.`r`nThis must be in distinguished name format.",
    "",
    "",
    "17#4#Please define the maximum elevated time.`r`nThe value must be between 15 minutes and 1440 minutes (1 day).",
    "",
    "19#3#Please select your Tier 0 computers group.`r`nThe entry must either be in full distinguished name format or the groups SamAccountName."
)

#endregion constant section

#region Validate the installation directory and stop execution if requirements are not met
if (!($InstallationDirectory))
    {$InstallationDirectory = (Get-Location).Path
} elseif (!(Test-Path $InstallationDirectory)) {
    Break-MessageBox -Message "Installation directory missing!`r`n`r`nAborting ..."
    return
}
if (!((Get-ADOptionalFeature -Filter "name -eq 'Privileged Access Management Feature'").EnabledScopes)){
    $msg = "Active Directory PAM feature is not enabled!`r`nRun:`r`n"
    $msg = $msg + "Enable-ADOptionalFeature ""Privileged Access Management Feature"" -Scope ForestOrConfigurationSet -Target $((Get-ADForest).Name)"
    $msg = $msg + "`r`nBefore continuing with JIT!"
    Break-MessageBox -Message ($msg+"`r`n`r`nAborting ...")
    $msg = ""
    return
}
#endregion

#region generate custom PSobject
$Script:config = New-Object PSObject
$Script:config | Add-Member -MemberType NoteProperty -Name "ConfigScriptVersion"            -Value $_scriptVersion
$Script:config | Add-Member -MemberType NoteProperty -Name "AdminPreFix"                    -Value $DefaultAdminPrefix
$Script:config | Add-Member -MemberType NoteProperty -Name "JiTOU"                          -Value "OU=JIT-Administrator Groups,OU=Tier 1,OU=Admin,$((Get-ADDomain).DistinguishedName)"
$Script:config | Add-Member -MemberType NoteProperty -Name "MaxElevatedTime"                -Value $MaximumElevatedTime
$Script:config | Add-Member -MemberType NoteProperty -Name "DefaultElevatedTime"            -Value 60
$Script:config | Add-Member -MemberType NoteProperty -Name "ElevateEventID"                 -Value 100
$Script:config | Add-Member -MemberType NoteProperty -Name "Tier0ServerGroupName"           -Value $DefaultServerGroupName
$Script:config | Add-Member -MemberType NoteProperty -Name "LDAPT0Computers"                -Value $DefaultLdapQuery #Deprecated Tier 0 computer identified by Tier 0 group membership
$Script:config | Add-Member -MemberType NoteProperty -Name "LDAPT0ComputerPath"             -Value "OU=Tier 0,OU=Admin"
$Script:config | Add-Member -MemberType NoteProperty -Name "LDAPT1Computers"                -Value "(&(OperatingSystem=*Windows*)(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))" #added 20231201 LDAP query to search for Tier 1 computers
$Script:config | Add-Member -MemberType NoteProperty -Name "EventSource"                    -Value $EventSource
$Script:config | Add-Member -MemberType NoteProperty -Name "EventLog"                       -Value $EventLogName
$Script:config | Add-Member -MemberType NoteProperty -Name "GroupManagementTaskRerun"       -Value $STAdminGroupManagementRerunMinutes
$Script:config | Add-Member -MemberType NoteProperty -Name "GroupManagedServiceAccountName" -Value $DefaultGroupManagementServiceAccountName
$Script:config | Add-Member -MemberType NoteProperty -Name "Domain"                         -Value $ADDomainDNS
$Script:config | Add-Member -MemberType NoteProperty -Name "DelegationConfigPath"           -Value "$InstallationDirectory\delegation.config" #Parameter added is the path to the delegation config file
$Script:config | Add-Member -MemberType NoteProperty -Name "EnableDelegation"               -Value $EnableDelegationMode
$Script:config | Add-Member -MemberType NoteProperty -Name "EnableMultiDomainSupport"       -Value $true
$Script:config | Add-Member -MemberType NoteProperty -Name "T1Searchbase"                   -Value @("<DomainRoot>")
$Script:config | Add-Member -MemberType NoteProperty -Name "DomainSeparator"                -Value "#"
#endregion

#create field counter for $Script:config - needed in UI to point to correct input
$Script:aConfigCounter = 0
$aConfigFieldName = @()

#region check for causalities in existing configuration file
if (Test-Path "$InstallationDirectory\$Script:configFileName")
{
    # read existing file    
    $existingconfig = Get-Content "$InstallationDirectory\$Script:configFileName" | ConvertFrom-Json

    #Validate current config file settings
    foreach ($setting in ($Script:config | Get-Member -MemberType NoteProperty)){
        $aConfigFieldName += $setting.Name

        if ((([regex]::Match($existingconfig.ConfigScriptVersion,"\d+$")).Value) -gt (([regex]::Match($_scriptVersion,"\d+$")).Value)){
            Break-MessageBox -Message "The configuration file is created with a newer configuration script!`r`nPlease use the latest configuration file.`r`n`r`nAborting ..."
            return
        }
        # consitency check for DomainRoot and DomainDN fields
        if ($setting.Name -eq "Domain") {
            if ($Script:config.$($setting.Name) -ne $existingconfig.$($setting.Name)) {
                Warning-MessageBox -Message "Domain DNS inconsitency in 'jit.config' file!`r`nCurrent Domain DNS name will be used: $($Script:config.Domain)"
            }
        } elseif ($setting.Name -eq "OU") {
            if ($existingconfig.$($setting.Name) -notmatch (Get-ADDomain).DistinguishedName) {
                $Script:config.$($setting.Name) = "OU=JIT-Administrator Groups, OU=Tier 1,OU=Admin,$((Get-ADDomain).DistinguishedName)"
                Warning-MessageBox -Message "Domain DN inconsitency in 'jit.config' file!`r`nIgnoring OU entry from 'jit.config' file ..."
            }
        } elseif ($setting.Name -eq "T1Searchbase") {
            $Script:config.$($setting.Name) = @()
            $deleted = $false
            $existingconfig.$($setting.Name)|ForEach-Object {
                if ($_ -match (Get-ADDomain).DistinguishedName) {
                    $Script:config.$($setting.Name) += $_
                } else {
                    $deleted = $true
                }
            }
            if (($Script:config.$($setting.Name)).count -eq 0) {
                Warning-MessageBox -Message "Searchbase inconsitency in 'jit.config' file!`r`nApplying default searchbase ..."
                $Script:config.$($setting.Name) += "OU=Tier 1 Servers,$((Get-ADDomain).DistinguishedName)"
            } elseif ($deleted) {
                Warning-MessageBox -Message "Searchbase inconsitency in 'jit.config' file!`r`nSome entries have been removed ..."
            }
        } elseif ($setting.Name -eq "DelegationConfigPath") {
            if (!(Test-Path($existingconfig.$($setting.Name)))) {
                $Script:config.$($setting.Name) = "$InstallationDirectory\delegation.config"
                Warning-MessageBox -Message "'DelegationConfigPath' inconsitent in 'jit.config' file!`r`nUsing local 'Delegation.config' file ..."
            }
        } elseif (("MaxElevatedTime","DefaultElevatedTime","GroupManagementTaskRerun").Contains($setting.Name)) {
            [int]$Script:config.$($setting.Name) = [int]$existingconfig.$($setting.Name)
        } else {
            $Script:config.$($setting.Name) = $existingconfig.$($setting.Name)
        }
    }
} else {
    foreach ($setting in ($Script:config | Get-Member -MemberType NoteProperty)){
        $aConfigFieldName += $setting.Name
    }
}
$Script:config.ConfigScriptVersion = $_scriptVersion

#endregion


#region build form
#form and form panel dimensions
$width = 450
$height = 450
$Panelwidth = $Width-40
$Panelheight = $Height-220

$objInputForm = New-Object System.Windows.Forms.Form
$objInputForm.Text = 'Tier 1 - JiT Configurator'
$objInputForm.Size = New-Object System.Drawing.Size($width,$height)
$objInputForm.StartPosition = 'CenterScreen'
$objInputForm.FormBorderStyle = "FixedDialog"
$objInputForm.MinimizeBox = $False
$objInputForm.MaximizeBox = $False
$objInputForm.WindowState = "Normal"
$objInputForm.Icon = [System.Drawing.Icon]::FromHandle(([System.Drawing.Bitmap]::new($stream).GetHIcon()))
$objInputForm.BackColor = "White"
$objInputForm.Font = $FontStdt
$objInputForm.Topmost = $True

#region InputPanel
$objInputPanel = New-Object System.Windows.Forms.Panel
$objInputPanel.Location = new-object System.Drawing.Point(10,20)
$objInputPanel.size = new-object System.Drawing.Size($Panelwidth,$Panelheight) 
#$objInputPanel.BackColor = "255,0,255"
#$objInputPanel.BackColor = "Blue"
$objInputPanel.BorderStyle = "FixedSingle"
#endregion

#region Enter Button
$objNextButton = New-Object System.Windows.Forms.Button
$objNextButton.Location = New-Object System.Drawing.Point(30,($height-70))
$objNextButton.Size = New-Object System.Drawing.Size(100,30)
$objNextButton.Font = $FontBold
$objNextButton.Text = 'Next >'
#endregion

#region Back Button
$objBackButton = New-Object System.Windows.Forms.Button
$objBackButton.Location = New-Object System.Drawing.Point(30,($height-70))
$objBackButton.Size = New-Object System.Drawing.Size(100,30)
#$objBackButton.Font = $FontBold
$objBackButton.Text = '< Back'
$objBackButton.Visible = $false
#endregion

#region Configure Button
$objCfgButton = New-Object System.Windows.Forms.Button
$objCfgButton.Location = New-Object System.Drawing.Point(130,($height-70))
$objCfgButton.Size = New-Object System.Drawing.Size(100,30)
$objCfgButton.Text = 'Configure'
$objCfgButton.Visible = $false
#$objCfgButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
#endregion

#region Cancel Button
$objCancelButton = New-Object System.Windows.Forms.Button
$objCancelButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$objCancelButton.Location = New-Object System.Drawing.Point(((($width/4)*3)-30),($height-70))
$objCancelButton.Size = New-Object System.Drawing.Size(80,30)
$objCancelButton.Text = 'Cancel'
#$objCancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
#endregion

#region Input Label Heading
$objInputHeading = New-Object System.Windows.Forms.Label
$objInputHeading.Location = New-Object System.Drawing.Point(25,10)
$objInputHeading.Size = New-Object System.Drawing.Size(350,25)
$objInputHeading.Text = ("Step "+$aInputs[$Script:aConfigCounter].Split("#")[1]+"- "+[string]$Script:aConfigCounter)
#endregion

#region Input Label
$objInputLabel = New-Object System.Windows.Forms.Label
$objInputLabel.Location = New-Object System.Drawing.Point(25,40)
$objInputLabel.Size = New-Object System.Drawing.Size(350,70)
$objInputLabel.Text = $aInputs[$Script:aConfigCounter].Split("#")[2]
#endregion

#region Input text box
$objInputTextBox = New-Object System.Windows.Forms.TextBox
$objInputTextBox.Location = New-Object System.Drawing.Point(20,120)
$objInputTextBox.Size = New-Object System.Drawing.Size(360,60)
$objInputTextBox.Multiline = $True;
$objInputTextBox.Text = $Script:config.$($aConfigFieldName[$Script:aConfigCounter])
#$objInputTextBox.AcceptsReturn = $false 
#endregion

#region Operation result label
$objResultTextBoxLabel = new-object System.Windows.Forms.Label
$objResultTextBoxLabel.Location = new-object System.Drawing.Point(10,($height-185)) 
$objResultTextBoxLabel.size = new-object System.Drawing.Size(100,25) 
$objResultTextBoxLabel.Text = "Result:"
#endregion

#region Operation result text box
$objResultTextBox = New-Object System.Windows.Forms.TextBox
$objResultTextBox.Location = New-Object System.Drawing.Point(10,($height-160))
$objResultTextBox.Size = New-Object System.Drawing.Size(($width-30),80)
$objResultTextBox.ReadOnly = $true 
$objResultTextBox.Multiline = $true
$objResultTextBox.AcceptsReturn = $true 
$objResultTextBox.Text = ""
#endregion

#region Answer Checkbox
$objAnswerCB = new-object System.Windows.Forms.checkbox
$objAnswerCB.Location = new-object System.Drawing.Size(20,120)
$objAnswerCB.Size = new-object System.Drawing.Size(360,60)
$objAnswerCB.Text = ""
$objAnswerCB.Checked = $Script:config.EnableDelegation
$objAnswerCB.Visible = $false
#endregion

#region building form
$objInputPanel.Controls.Add($objInputHeading)
$objInputPanel.Controls.Add($objInputLabel)
$objInputPanel.Controls.Add($objInputTextBox)
$objInputPanel.Controls.Add($objAnswerCB)

$objInputForm.Controls.Add($objInputPanel)
$objInputForm.Controls.Add($objResultTextBoxLabel)
$objInputForm.Controls.Add($objResultTextBox)
$objInputForm.Controls.Add($objNextButton)
$objInputForm.Controls.Add($objBackButton)
$objInputForm.Controls.Add($objCfgButton)
$objInputForm.Controls.Add($objCancelButton)

#endregion

$objInputForm.Add_Shown({$objInputTextBox.Select()})
#endregion

#region Input handlers
$objCancelButton.Add_Click({
    $objInputForm.Close()
    $objInputForm.dispose()
    return
})

$objNextButton.Add_Click({
    
    $ForceExit = $false
    Switch ($Script:aConfigCounter) {
       0 {
        $Script:config.AdminPreFix = $objInputTextBox.Text
        $Script:aConfigCounter = 13
        $objNextButton.Location = New-Object System.Drawing.Point(130,($height-70))
        $objBackButton.Visible = $true
       }

       2 {
        if ($objInputTextBox.Text) {
            if ([int32]::TryParse($objInputTextBox.Text,[ref]5 )) {
                if (!([INT]$objInputTextBox.Text -in 15..[int]$Script:config.MaxElevatedTime)) {
                    $objResultTextBox.Text = "The default elevation time must be between 15 minutes`r`nand $($Script:config.MaxElevatedTime.ToString()) minutes!"
                    $objResultTextBox.Refresh()
                    Start-Sleep 3
                    $objResultTextBox.Text = ""
                    $objInputTextBox.Text = $Script:config.DefaultElevatedTime
                    $objResultTextBox.Refresh()
                    $objInputTextBox.Refresh()
                } else {
                    $Script:config.DefaultElevatedTime = $objInputTextBox.Text
                    $Script:aConfigCounter = 11
                }
            }else {
                $objResultTextBox.Text = "The default elevation time must be between 15 minutes`r`nand $($Script:config.MaxElevatedTime.ToString()) minutes!"
                $objResultTextBox.Refresh()
                Start-Sleep 3
                $objResultTextBox.Text = ""
                $objInputTextBox.Text = $Script:config.DefaultElevatedTime
                $objResultTextBox.Refresh()
                $objInputTextBox.Refresh()
            }
        }
       }
       
       7 {
        $Script:config.EnableDelegation = $objAnswerCB.Checked
        $objAnswerCB.Text = "Enable Multi Domain Mode"
        $objAnswerCB.Checked = $Script:config.EnableMultiDomainSupport
        $Script:aConfigCounter = 8
      }

       8 {
        $Script:config.EnableMultiDomainSupport = $objAnswerCB.Checked
        $Script:aConfigCounter = 20
        $objNextButton.Visible = $false
        $objCfgButton.Visible = $true
      }

       11 {
        $Script:config.GroupManagedServiceAccountName = $objInputTextBox.Text
        if (Get-ADServiceAccount -Filter "Name -eq '$($Script:config.GroupManagedServiceAccountName)'" -Server $($Script:config.Domain)) {
            $objResultTextBox.Text = "$($Script:config.GroupManagedServiceAccountName) already exists.`r`ngMSA will be prepared for being used with T1 JiT"
        } else {
            $objResultTextBox.Text = "$($Script:config.GroupManagedServiceAccountName) does not exists - will be created."
        }
        $objResultTextBox.Refresh()
        Start-Sleep 3
        $objResultTextBox.Text = ""
        $objResultTextBox.Refresh()
        $Script:aConfigCounter = 12
      }

       12 {
        if ($objInputTextBox.Text) {
            if ([int32]::TryParse($objInputTextBox.Text,[ref]5 )) {
                if (!([INT]$objInputTextBox.Text -in 5..1440)) {
                    $objResultTextBox.Text = "The enumeration of Tier 1 computer must be between 5 minutes`r`nand 1440 minutes!"
                    $objInputTextBox.Text = $Script:config.GroupManagementTaskRerun
                    $objResultTextBox.Refresh()
                    Start-Sleep 3
                    $objResultTextBox.Text = ""
                    $objResultTextBox.Refresh()
                } else {
                    $Script:config.GroupManagementTaskRerun = [INT]$objInputTextBox.Text
        
                    $objInputTextBox.Visible = $false
                    $objAnswerCB.Visible = $true
                    $objAnswerCB.Text = "Enable Delegation Mode"
                    $Script:aConfigCounter = 7
                }
            } else {
                $objResultTextBox.Text = "The enumeration of Tier 1 computer must be between 5 minutes`r`nand 1440 minutes!"
                $objInputTextBox.Text = $Script:config.GroupManagementTaskRerun
                $objResultTextBox.Refresh()
                Start-Sleep 3
                $objResultTextBox.Text = ""
                $objResultTextBox.Refresh()
            }
        }
      }

       13 {
        if ($objInputTextBox.Text  -eq ""){
            $objInputTextBox.Text = $Script:config.JiTOU
            $objInputTextBox.Refresh()
        } else {
            try{
                if ([ADSI]::Exists("LDAP://$($objInputTextBox.Text)")){
                    $Script:config.JiTOU = $objInputTextBox.Text
                    $objResultTextBox.Text = "OU already exists and will be used!`r`n`r`n$($objInputTextBox.Text)"
                    Start-Sleep 3
                    $objResultTextBox.Text = ""
                }
            } catch{
                $objInputTextBox.Text = $Script:config.JiTOU
                $objResultTextBox.Text = "Invalid DN path!`r`n`r`n$($Error[0].CategoryInfo.GetType().Name)"
                $objInputTextBox.Refresh()
                $objResultTextBox.Refresh()
                Start-Sleep 3
            }
        }
        $Script:config.JiTOU = $objInputTextBox.Text
        $Script:aConfigCounter = 19
      }

       17 {
        if ($objInputTextBox.Text) {
            if ([int32]::TryParse($objInputTextBox.Text,[ref]5 )) {
                if (!([INT]$objInputTextBox.Text -in 15..1440)) {
                    $objResultTextBox.Text = "The maximum elevation time must be between 15 minutes`r`nand 1440 minutes!"
                    $objResultTextBox.Refresh()
                    Start-Sleep 3
                    $objResultTextBox.Text = ""
                    $objInputTextBox.Text = $Script:config.MaxElevatedTime
                    $objResultTextBox.Refresh()
                    $objInputTextBox.Refresh()
                } else {
                    $Script:config.MaxElevatedTime = $objInputTextBox.Text
                    $Script:aConfigCounter = 2
                }
            } else {
                $objResultTextBox.Text = "The maximum elevation time must be between 15 minutes`r`nand 1440 minutes!"
                $objResultTextBox.Refresh()
                Start-Sleep 3
                $objResultTextBox.Text = ""
                $objInputTextBox.Text = $Script:config.MaxElevatedTime
                $objResultTextBox.Refresh()
                $objInputTextBox.Refresh()
            }
        }
      }

       19 {
        if ($objInputTextBox.Text -eq ""){
            $objInputTextBox.Text = $Script:config.Tier0ServerGroupName 
        }
        Try {
            $Group = Get-ADGroup -Identity $objInputTextBox.Text
            $Script:config.Tier0ServerGroupName = $Group.DistinguishedName
            $Script:aConfigCounter = 17
            $objResultTextBox.Text = "Found group:`r`n$($Group.DistinguishedName)"
        } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
            $msg = "$($objInputTextBox.Text) is not a valid AD group!`r`n"
            $msg = $msg + "Please enter either group's SamAccountName or DistinguishedName..."
            $objResultTextBox.Text = $msg
        } 
        catch {
            $msg = "Unexpected Error occured!`r`n`r`n"
            $msg = $msg + $Error[0]
            $objResultTextBox.Text = $msg
            $ForceExit = $true
        }
        $objResultTextBox.Refresh()
        Start-Sleep 3
        $msg = ""
        $objResultTextBox.Text = ""
        $objResultTextBox.Refresh()
        if ($ForceExit) {
            $objNextButton.Visible = $false
            $objCfgButton.Visible = $true
        }
       }
    }
    if ($Script:aConfigCounter -lt 20) {
        $objInputHeading.Text = ("Step "+$aInputs[$Script:aConfigCounter].Split("#")[1]+"- "+[string]$Script:aConfigCounter)
        $objInputLabel.Text = $aInputs[$Script:aConfigCounter].Split("#")[2]
        $objInputTextBox.Text = $Script:config.$($aConfigFieldName[$Script:aConfigCounter])
    }
    
    $objInputForm.Refresh()
})

$objBackButton.Add_Click({

    Switch ($Script:aConfigCounter) {
       0 {
        $Script:aConfigCounter = 0
       }

       2 {
        $Script:aConfigCounter = 17
       }
       
       7 {
        $Script:aConfigCounter = 12
        $objInputTextBox.Visible = $true
        $objAnswerCB.Visible = $false
      }

       8 {
        $Script:aConfigCounter = 7
        $objAnswerCB.Text = "Enable Delegation Mode"
        $objAnswerCB.Checked = $Script:config.EnableDelegation
      }

       11 {
        $Script:aConfigCounter = 2
      }

       12 {
        $Script:aConfigCounter = 11
      }

       13 {
        $Script:aConfigCounter = 0
      }

       17 {
        $Script:aConfigCounter = 19
      }

       19 {
        $Script:aConfigCounter = 13
       }
       20 {
        $Script:aConfigCounter = 7
        $objNextButton.Visible = $true
        $objCfgButton.Visible = $false
        $objInputTextBox.Visible = $false
#        $objAnswerCB.Visible = $true
        $objAnswerCB.Text = "Enable Delegation Mode"
        $objAnswerCB.Checked = $Script:config.EnableDelegation
      }
    }
    $objInputHeading.Text = ("Step "+$aInputs[$Script:aConfigCounter].Split("#")[1]+"- "+[string]$Script:aConfigCounter)
    $objInputLabel.Text = $aInputs[$Script:aConfigCounter].Split("#")[2]
    $objInputTextBox.Text = $Script:config.$($aConfigFieldName[$Script:aConfigCounter])
    $objInputForm.Refresh()
})

$objCfgButton.Add_Click({
    if (!(Configure-T1JiT)) {
        $objResultTextBox.Text = "Tier 1 JiT configuration failed!!!`r`n`r`nExiting..."
        $objResultTextBox.Refresh()
        Start-Sleep 5
        $script:BtnResult="Failed"
    } else {
        $objResultTextBox.Text = "Tier 1 JiT successfully configured!!!`r`n`r`nExiting..."
        $objResultTextBox.Refresh()
        Start-Sleep 5
        $script:BtnResult="OK"
    }

    $objInputForm.Close()
    $objInputForm.dispose()
    return
})

[void]$objInputForm.ShowDialog()

#endregion







