<#
#>

param (
    [Parameter (mandatory=$false)]
    $AdminPreFix,
    [Parameter (mandatory=$false)]
    $OU,
    [Parameter (Mandatory=$false)]
    $MaxMinutes,
    [Parameter (Mandatory=$false)]
    $Tier0ServerGroupName,
    [Parameter (Mandatory=$false)]
    $DefaultElevatedTime,
    [Parameter (Mandatory=$false)]
    $configFile
)
if ($configFile -eq $null)
    {$configFile = "c:\Program Files\WindowsPowershell\scripts\JIT.config"}
if (Test-Path $configFile)
{
    $config = Get-Content $configFile | ConvertFrom-Json
}
else
{
    $config = New-Object PSObject
    $config | Add-Member -MemberType NoteProperty -Name "AdminPreFix" -Value "Admin_"
    $config | Add-Member -MemberType NoteProperty -Name "OU" -Value "OU=Tier 1 - Management Groups,OU=Admin, $(Get-ADDomain)"
    $config | Add-Member -MemberType NoteProperty -Name "MaxElevatedTime" -Value 120
    $config | Add-Member -MemberType NoteProperty -Name "DefaultElevatedTime" -Value 60
    $config | Add-Member -MemberType NoteProperty -Name "ElevateEventID" -Value 100
    $config | Add-Member -MemberType NoteProperty -Name "Tier0ServerGroupName" -Value "Tier 0 Computers"
    $config | Add-Member -MemberType NoteProperty -Name "LDAPT0Computers" -Value "(&(Operatingsystem=*Windows Server*)(!(PrimaryGroupID=516))(!(memberof=[DNTier0serverGroup])))"
    $config | Add-Member -MemberType NoteProperty -Name "EventSource" -Value "T1Mgmt"
    $config | Add-Member -MemberType NoteProperty -Name "EventLog" -Value "Tier 1 Management"
}
if ($AdminPreFix -eq $null)
{
    $DefaultAdminPrefix = $config.AdminPreFix
    $AdminPreFix = Read-Host -Prompt "Admin Prefix for local administrators default[$($DefaultAdminPreFix)]"
    if ($AdminPreFix -ne "")
        {$config.AdminPreFix = $AdminPreFix}
    else
        {$config.AdminPreFix = $DefaultAdminPreFix}
}
if ($ou -eq $null)
{
    $DefaultOu = $config.OU
    $OU = Read-Host -Prompt "OU for the local administrator groups Default[$($DefaultOU)]"
    if ($OU -ne "")
        {$config.OU = $OU}
    else
        {$config.OU = $DefaultOU}
}
if ($MaxMinutes -eq $null)
{
    $DefaultMaxMin = $config.MaxElevatedTime
    [UINT16]$MaxMinutes = Read-Host "Maximum elevated time [$($DefaultMaxMin)]"
    if ($MaxMinutes -gt 0)
        {$config.MaxElevatedTime = $MaxMinutes}
}
if ($DefaultElevatedTime -eq $null)
{
    $DefDefaultElevatedTime = $config.DefaultElevatedTime 
    [INT]$DefaultElevatedTime = Read-Host -Prompt "Default elevated time [$($DefDefaultElevatedTime)]"
    if (($DefaultElevatedTime -gt 0  ) -and ($DefaultElevatedTime -lt ($config.MaxElevatedTime +1)))
    {
        $config.DefaultElevatedTime = $DefaultElevatedTime
    }
}
if ($Tier0ServerGroupName -eq $null)
{
    $DefaultT0ComputerGroup = $config.Tier0ServerGroupName
    $T0computergroup = Read-Host -Prompt "Tier 0 computers group default[$($DefaultT0computerGroup)]"
    if ($T0computergroup -ne "")
        {$config.Tier0ServerGroupName = $DefaultT0ComputerGroup}
    else
        {$config.Tier0ServerGroupName = $DefaultT0ComputerGroup}
}
$T0ServerGroup = Get-ADGroup $config.Tier0ServerGroupName
$config.LDAPT0Computers = $config.LDAPT0Computers -replace "\[DNTier0serverGroup\]", $T0ServerGroup.DistinguishedName

ConvertTo-Json $config | Out-File $configName -Confirm:$false

#create eventlog and register EventSource id required

if ((Get-EventLog -List | where {$_.LogDisplayName -eq $config.EventLog}) -eq $null)
{
    New-EventLog -LogName $config.EventLog -Source $config.EventSource
    Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId 1 -Message "JIT configuration created"
}