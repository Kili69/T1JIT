<#
# ==============================================================================================
# THIS SAMPLE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED 
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR 
# FITNESS FOR A PARTICULAR PURPOSE.
#
# This sample is not supported under any Microsoft standard support program or service. 
# The script is provided AS IS without warranty of any kind. Microsoft further disclaims all
# implied warranties including, without limitation, any implied warranties of merchantability
# or of fitness for a particular purpose. The entire risk arising out of the use or performance
# of the sample and documentation remains with you. In no event shall Microsoft, its authors,
# or anyone else involved in the creation, production, or delivery of the script be liable for 
# any damages whatsoever (including, without limitation, damages for loss of business profits, 
# business interruption, loss of business information, or other pecuniary loss) arising out of 
# the use of or inability to use the sample or documentation, even if Microsoft has been advised 
# of the possibility of such damages.
# ==============================================================================================
.Notes 20240731
    Configuration file parameter default value is $env:JustIntime
#>

 <#

    .SYNOPSIS
    Submits an T1 elevation request for a specific T1 server.
    Graphical UI for T1JiT by Kili69

    .PARAMETER
    -configurationfile
        Specify a configuration file. By default the script reads the configuration file from the working directory
    
   .Notes
   Version 0.1.20240213
   Autor: Andreas Luy

#>


Param(
    [Parameter (Mandatory=$false)]
    $configurationFile = $env:JustInTimeConfig
)


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
    $Icon = [system.drawing.icon]::ExtractAssociatedIcon("C:\Windows\System32\WindowsPowershell\v1.0\powershell.exe")
    #$iconBase64 = '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'
    #$iconBase64 = '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'
    $iconBase64 = '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'
    $iconBytes = [Convert]::FromBase64String($iconBase64)
    $stream = [System.IO.MemoryStream]::new($iconBytes, 0, $iconBytes.Length)

#Helper functions
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


    function RequestElevation
    {
        param(
            [Parameter(mandatory=$true)][String]$ServerName,
            [Parameter(mandatory=$true)][Int]$ElevatedMinutes
        )

    $ServerDomain = (Get-ADDomain).DNSroot

    $result = .\RequestAdminAccess.ps1 -ServerDomain $ServerDomain -Servername $ServerName -ElevatedMinutes $ElevatedMinutes -UIused
    return $result
    }



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
        $objComboBox.Items.Add(($T1Group.Name).Substring(($config.AdminPreFix).Length))|Out-Null
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
    $objInputLabel2AutoSize = $true
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
                $result = RequestElevation -ServerName $ObjComboBox.selectedItem -ElevatedMinutes ([Int]$objElevationTimeInputBox.Text)
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














