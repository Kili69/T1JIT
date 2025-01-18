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

$UIModuleVersion = "0.1.20241219"

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

    function New-BreakMsgBox 
    {
        param(
            [Parameter(mandatory=$true)]$Message
        )
       [void][System.Windows.Forms.MessageBox]::Show($Message,"Critical Error!","OK",[System.Windows.Forms.MessageBoxIcon]::Stop)
        exit
    }

    function New-WarningMsgBox 
    {
        param(
            [Parameter(mandatory=$true)]$Message
        )
       [void][System.Windows.Forms.MessageBox]::Show($Message,"Error!","OK",[System.Windows.Forms.MessageBoxIcon]::Warning)
    }

    function config-JitUI
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







