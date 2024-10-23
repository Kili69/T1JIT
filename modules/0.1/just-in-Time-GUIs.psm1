<#
Module Info

Author: Andreas Luy [MSFT]
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

$UIModuleVersion = "0.1.241014"

## loading .net classes needed
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [Windows.Forms.Application]::EnableVisualStyles()

# define fonts, colors and app icon
    $SuccessFontColor = "Green"
    $WarningFontColor = "Yellow"
    $FailureFontColor = "Red"

    $SuccessBackColor = "Black"
    $WarningBackColor = "Black"
    $FailureBackColor = "Black"

    $FontStdt = New-Object System.Drawing.Font("Arial",11,[System.Drawing.FontStyle]::Regular)
    $FontBold = New-Object System.Drawing.Font("Arial",11,[System.Drawing.FontStyle]::Bold)
    $FontItalic = New-Object System.Drawing.Font("Arial",9,[System.Drawing.FontStyle]::Italic)



#region Functions

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

    function Jitconfig-UI
    {

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

    # define fonts, colors and app icon
    $FontStdt = New-Object System.Drawing.Font("Arial",11,[System.Drawing.FontStyle]::Regular)
    $FontBold = New-Object System.Drawing.Font("Arial",11,[System.Drawing.FontStyle]::Bold)
    $FontItalic = New-Object System.Drawing.Font("Arial",9,[System.Drawing.FontStyle]::Italic)
    $iconBase64 = "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"
    $iconBytes = [Convert]::FromBase64String($iconBase64)
    $stream = [System.IO.MemoryStream]::new($iconBytes, 0, $iconBytes.Length)

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
    }

    function UIRequest-Elevation
    {
        param(
            [Parameter(mandatory=$true)][String]$ServerName,
            [Parameter(mandatory=$true)][Int]$ElevatedMinutes
        )
    $result = New-AdminRequest -Server $ServerName -Minutes $ElevatedMinutes -UIused $true
    return $result
    }


    function Request-AdminAccessUI
    {

    Param(
        [Parameter (Mandatory=$false)]
        $configurationFile = $env:JustInTimeConfig
    )


    # app icon
    $Icon = [system.drawing.icon]::ExtractAssociatedIcon("C:\Windows\System32\WindowsPowershell\v1.0\powershell.exe")
    #$iconBase64 = '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'
    #$iconBase64 = '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'
    $iconBase64 = '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'
    $iconBytes = [Convert]::FromBase64String($iconBase64)
    $stream = [System.IO.MemoryStream]::new($iconBytes, 0, $iconBytes.Length)


    #Read configuration
    if (Test-Path $configurationFile) {
        $config = Get-Content $configurationFile | ConvertFrom-Json
    } else {
        Break-MessageBox -Message "No config file found!`r`n`r`nAborting ..."
        Exit
    }

    #region build UI
    #form and form panel dimensions
        $width = 450
        $height = 350
        $Panelwidth = $Width-40
        $Panelheight = $Height-220

        $objForm = New-Object System.Windows.Forms.Form
        $objForm.Text ="Request T1 Admin Access"
        $objForm.Size = New-Object System.Drawing.Size($width,$height) 
        #$objForm.AutoSize = $true
        $objForm.FormBorderStyle = "FixedDialog"
        $objForm.StartPosition = "CenterScreen"
        $objForm.MinimizeBox = $False
        $objForm.MaximizeBox = $False
        $objForm.WindowState = "Normal"
        $ObjForm.Icon = [System.Drawing.Icon]::FromHandle(([System.Drawing.Bitmap]::new($stream).GetHIcon()))
        $objForm.BackColor = "White"
        $objForm.Font = $FontStdt
        $objForm.Topmost = $False
    #endregion

    #region InputPanel
        $objInputPanel = New-Object System.Windows.Forms.Panel
        $objInputPanel.Location = new-object System.Drawing.Point(10,20)
        $objInputPanel.size = new-object System.Drawing.Size($Panelwidth,$Panelheight) 
        #$objInputPanel.BackColor = "255,0,255"
        #$objInputPanel.BackColor = "Blue"
        $objInputPanel.BorderStyle = "FixedSingle"
        $objForm.Controls.Add($objInputPanel)
    #endregion

    #region InputLabel1
        $objInputLabel1 = new-object System.Windows.Forms.Label
        $objInputLabel1.Location = new-object System.Drawing.Point(10,10) 
        $objInputLabel1.size = new-object System.Drawing.Size(170,30) 
        $objInputLabel1.Text = "Currently known T1 servers:"
        $objInputLabel1.AutoSize = $true
        $objInputPanel.Controls.Add($objInputLabel1)
    #endregion

    #region SelectionList
        $objComboBox = New-Object System.Windows.Forms.ComboBox

        $T1Groups = Get-ADGroup -Filter "Name -like '*$($config.AdminPreFix)*'" -SearchBase $config.OU
        Foreach ($T1Group in $T1Groups) {
            $ServerDomainNetBiosName = $T1Group.Name.Substring(($config.AdminPreFix).Length) 
            $ServerDomainNetBiosName = $ServerDomainNetBiosName.replace($config.DomainSeparator , "\")
            $objComboBox.Items.Add($ServerDomainNetBiosName) | Out-Null
        }
        $objComboBox.Location  = New-Object System.Drawing.Point(10,40)
        $objComboBox.size = new-object System.Drawing.Size(($Panelwidth-30),25) 
        $objComboBox.AutoCompleteSource = 'ListItems'
        $objComboBox.AutoCompleteMode = 'SuggestAppend'
        $objComboBox.DropDownStyle = 'DropDownList'
        $objInputPanel.Controls.Add($objComboBox)
    #endregion

    #region InputLabel2
        $objInputLabel2 = new-object System.Windows.Forms.Label
        $objInputLabel2.Location = new-object System.Drawing.Point(10,90) 
        $objInputLabel2.size = new-object System.Drawing.Size(150,30) 
        $objInputLabel2.Text = "Elevation time (min):"
        $objInputLabel2.AutoSize = $true
        $objInputPanel.Controls.Add($objInputLabel2)
    #endregion

    #region InputLabel2
        $objElevationTimeInputBox = New-Object System.Windows.Forms.TextBox
        $objElevationTimeInputBox.Location = New-Object System.Drawing.Point(170,85)
        $objElevationTimeInputBox.Size = New-Object System.Drawing.Size(50,30)
        $objElevationTimeInputBox.Multiline = $false
        $objElevationTimeInputBox.AcceptsReturn = $true 
        $objElevationTimeInputBox.Text = [String]$config.DefaultElevatedTime
        $objInputPanel.Controls.Add($objElevationTimeInputBox)

        $objElevationTimeInputBox.Add_TextChanged({
            if ($this.Text -match '[^0-9]') {
                $cursorPos = $this.SelectionStart
                $this.Text = $this.Text -replace '[^0-9]',''
                # move the cursor to the end of the text:
                # $this.SelectionStart = $this.Text.Length

                # or leave the cursor where it was before the replace
                $this.SelectionStart = $cursorPos - 1
                $this.SelectionLength = 0
            }
        })
    #endregion

    #region Operation result text box
        $objResultTextBoxLabel = new-object System.Windows.Forms.Label
        $objResultTextBoxLabel.Location = new-object System.Drawing.Point(10,($height-185)) 
        $objResultTextBoxLabel.size = new-object System.Drawing.Size(100,25) 
        $objResultTextBoxLabel.Text = "Output log:"
        $objForm.Controls.Add($objResultTextBoxLabel)

        $objResultTextBox = New-Object System.Windows.Forms.TextBox
        $objResultTextBox.Location = New-Object System.Drawing.Point(10,($height-160))
        $objResultTextBox.Size = New-Object System.Drawing.Size(($width-30),80)
        $objResultTextBox.ReadOnly = $true 
        $objResultTextBox.Multiline = $true
        $objResultTextBox.AcceptsReturn = $true 
        $objResultTextBox.Text = ""
        $objForm.Controls.Add($objResultTextBox)
    #endregion

    #region RequestButton
        $objRequestAccessButton = New-Object System.Windows.Forms.Button
        $objRequestAccessButton.Location = New-Object System.Drawing.Point(10,($height-70))
        $objRequestAccessButton.Size = New-Object System.Drawing.Size(150,30)
        $objRequestAccessButton.Text = "Request Access"
        $objForm.Controls.Add($objRequestAccessButton)

        $objRequestAccessButton.Add_Click({
            if ($ObjComboBox.selectedItem) {
                $objResultTextBox.Text = $ObjComboBox.selectedItem
                $ElevationTime = [Int]$objElevationTimeInputBox.Text
                if (($ElevationTime -lt 10) -or ($ElevationTime -gt $config.MaxElevatedTime)) {
                    Warning-MessageBox -Message ("Elevation time must be between 10 and "+[String]$config.MaxElevatedTime+" minutes")
                } else {
                    $objResultTextBox.Text = ("Requesting elevation for:`r`n  Server   : "+$ObjComboBox.selectedItem+`
                        "`r`n  Domain: "+[String](Get-ADDomain).DNSroot+"`r`n  Time     : "+$objElevationTimeInputBox.Text)
                    Start-Sleep -Seconds 3
                    $result = UIRequest-Elevation -ServerName $ObjComboBox.SelectedItem -ElevatedMinutes ([int]$objElevationTimeInputBox.Text) 
                    $objResultTextBox.Text = $result
                    Start-Sleep -Seconds 5
                    $objElevationTimeInputBox.Text = [String]$config.DefaultElevatedTime
                    $objResultTextBox.Text = ""
                    $ObjComboBox.selectedItem = $null
                }
            } else {
                $objResultTextBox.ForeColor = $FailureFontColor
                Warning-MessageBox -Message "No server selected..."
            }
        })
    #endregion

    #region ExitButton
        $objBtnExit = New-Object System.Windows.Forms.Button
        $objBtnExit.Cursor = [System.Windows.Forms.Cursors]::Hand
        $objBtnExit.Location = New-Object System.Drawing.Point(((($width/4)*3)-40),($height-70))
        $objBtnExit.Size = New-Object System.Drawing.Size(80,30)
        $objBtnExit.Text = "Exit"
        $objBtnExit.TabIndex=0
        $objForm.Controls.Add($objBtnExit)

        $objBtnExit.Add_Click({
            $script:BtnResult="Exit"
            $objForm.Close()
            $objForm.dispose()
        })
    #endregion


    $objForm.Add_Shown({$objForm.Activate()})
    [void]$objForm.ShowDialog()


    }






