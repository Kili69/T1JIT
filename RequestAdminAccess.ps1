param (
[Parameter(Mandatory=$false)]
$User,
[Parameter(Mandatory=$false)]
$Domain,
[Parameter(Mandatory=$false)]
$Servername,
[Parameter(Mandatory=$false)]
$ServerDomain,
[Parameter(Mandatory=$false)]
$ElevatedMinutes,
[Parameter(Mandatory=$false)]
$configurationFile
)
if ($configurationFile -eq $null)
{
    $configurationFile = "c:\Program Files\WindowsPowershell\scripts\JIT.config"
}
if (!(Test-Path $configurationFile))
{
    Write-Host "Missing configuration file"
}
$config = Get-Content $configurationFile | ConvertFrom-Json

if ($User -eq $null){$User = $env:USERNAME}
if ($Domain -eq $null){$Domain = $env:USERDNSDOMAIN}
if (!(Get-ADUser -Identity $User -Server $Domain))
{
    Write-Host "User not found $User"
    Return
}
if ($Servername -eq $null)
    {$Servername = Read-Host -Prompt "ServerName"}
if ($Servername -eq "")
{
    Write-Host "ServerName missing"
    Return
}
if ($ServerDomain -eq $null)
    {
        $DefaultServerDomain = (Get-ADDomain).DNSRoot
        $ServerDomain = Read-Host "Server DNS domain [$($DefaultServerDomain)]"
        if ($ServerDomain -eq "")
        { $ServerDomain = (Get-ADDomain).DNSroot}
    }
$ServerGroupName = $config.AdminPreFix + $ServerName
if (!(Get-ADGroup -Filter {SamAccountName -eq $ServerGroupName} -Server $ServerDomain))
{
    Write-Host "Can not file Group $ServerGroupName"
    return
}
if ($ElevatedMinutes -eq $null) 
{
    $DefaultElevateMinutes = $config.DefaultElevatedTime
    $ElevatedMinutes = Read-Host "Elevated time [$($DefaultElevateMinutes) minutes]"
    if ($ElevatedMinutes -eq "")
    {
        $ElevatedMinutes = $config.DefaultElevatedTime
    }
}
if (($ElevatedMinutes -lt 10) -and ($ElevatedMinutes -gt $config.MaxElevatedTime))
{
    Write-Host "invalid elevation time"
    Return
}

$ElevateUser = New-Object PSObject
$ElevateUser | Add-Member -MemberType NoteProperty -Name "UserDN" -Value (Get-ADUser -Identity $User -Server $Domain).DistinguishedName
$ElevateUser | Add-Member -MemberType NoteProperty -Name "ServerGroup" -Value $ServerGroupName
$ElevateUser | Add-Member -MemberType NoteProperty -Name "ServerDomain" -Value $ServerDomain
$ElevateUser | Add-Member -MemberType NoteProperty -Name "ElevationTime" -Value $ElevatedMinutes
$EventMessage = ConvertTo-Json $ElevateUser
Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId 100 -Message $EventMessage
