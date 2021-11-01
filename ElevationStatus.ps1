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
    Get current elevation status
.Description
    This script shows the time restricted gorup membership of a user
.Example
    .\ElevationStatus.ps1 
        Shows the current time restricted group membership of the current user
    .\ElevationStatus.ps1 -SamAccountName <UserName>
        Shows the current time restricted group membership of a user
    .\ElevationStauts.ps1 -SamAcocuntname <UserName> -Domain <Domain DNS Name>
        Shows the current time restricted group mebership of a user from a differten domain
.Inputs
    -SamAccountNam
        The user domain SAM account name of a user
    -Domain
        The DNS domain name of the user

.Outputs
    List of time restricted group member ship
.Notes

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]
    $SamAccountName,
    [Parameter(Mandatory=$false)]
    $Domain
)
if ($SamAccountName -eq $null)
{
    $SamAccountName = $env:USERNAME
}
if ($null -eq $Domain )
{
    $Domain = $env:USERDNSDOMAIN
}

foreach ($Group in (Get-ADUser $SamAccountName $SamAccountName -Server $Domain -properties MemberOf).MemberOf) {
    if ($Group -contains "<TTL>")
    {
        Write-Host $Group.Name
    }
}
