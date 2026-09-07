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

This module file contains the user functions to request the administrator privileges

Version 0.1.20240825
    initial Version

Version 0.1.20240907
    The server format can be in FQDN, HostName, NetBiosName\HostName or DNSname\HostName
Version 0.1.20241004
    New function Get-UserElevationStatus added. 
        This function validate the user is allowed to request administrator privileges on a server
    New-AdminRequest changed to use the Get-UserelevationStatus
Version 0.1.20241023
    New function to convert a distinguishedname into the corresponding DNS Name
version 0.1.20241219 by Andreas Luy
    Changed group naming from NetBios to full Dns naming scheme
    moved Get-Jitconfig to Just-in-time-configuration.psm1
version 0.1.2025016 by Kili
    Fix a error if the DNS name of a server is assigned to more the one computer object
version 0.1.20260413
    Return a error message if the requested user has no configured UPN. The UPN is required to use the delegation.config file. If the user has no UPN the function will terminate with a warning message

#>

#region global variables
$GC = Get-ADDomainController -Discover -Service "GlobalCatalog" -ForceDiscover
$GlobalCatalogServer = "$($GC.HostName):3268"

#endregion
function ConvertFrom-DN2Dns {
    <#
    .SYNOPSIS
        Resolves the DNS domain name contained in a distinguished name.
    .DESCRIPTION
        Extracts the domain components from an Active Directory distinguished name
        and looks up the matching cross-reference object in the forest partitions
        container. The DNS root of that partition is returned. This is a private
        helper used when a computer found through the Global Catalog must be queried
        again in its owning domain.
    .PARAMETER DistinguishedName
        Active Directory distinguished name containing one or more DC components.
        The value can be supplied through the pipeline.
    .EXAMPLE
        ConvertFrom-DN2Dns -DistinguishedName "CN=Server01,OU=Servers,DC=contoso,DC=com"

        Returns "contoso.com" when the partition exists in the current forest.
    .INPUTS
        System.String.
    .OUTPUTS
        System.String. The DNS root of the matching Active Directory partition.
    .NOTES
        Requires the ActiveDirectory PowerShell module and access to the current
        forest configuration partition.
    #>

    param(
        [Parameter(Mandatory= $true, ValueFromPipeline)]
        [string]$DistinguishedName
    )

    # Keep only the domain components from the supplied distinguished name.
    $DistinguishedName = [regex]::Match($DistinguishedName,"(dc=[^,]+,)*dc=.+$",[System.Text.RegularExpressions.RegexOptions]::IgnoreCase).Value

    # Resolve the partition cross-reference and return its DNS root.
    return (Get-ADObject -Filter "nCname -eq '$DistinguishedName'" -Searchbase (Get-ADForest).PartitionsContainer -Properties dnsroot).DnsRoot
}

function Write-ScriptMessage {
    <#
    .SYNOPSIS
        Writes a request-module message to the host or success pipeline.
    .DESCRIPTION
        Centralizes message output for interactive and UI callers. In UI mode, the
        message is written to the success pipeline so the caller can display it. In
        console mode, the message is written to the host with a color selected from
        its severity. This is a private helper used by the exported request commands.
    .PARAMETER Message
        Text to display or return.
    .PARAMETER Severity
        Message severity. Information uses gray, Warning uses yellow, and Error uses
        red in console mode. The default is Information.
    .PARAMETER UIused
        When $true, writes Message to the success pipeline instead of directly to the
        host. The default is $false.
    .EXAMPLE
        Write-ScriptMessage -Message "Request accepted"

        Displays an informational message in gray on the console host.
    .EXAMPLE
        Write-ScriptMessage -Message "User not found" -Severity Warning -UIused $true

        Returns the warning text through the success pipeline for a UI caller.
    .INPUTS
        None. Pipeline input is not supported.
    .OUTPUTS
        System.String when UIused is $true. No success-pipeline output is produced in
        console mode.
    #>

    param (
        [Parameter (Mandatory, Position=0)]
        [string] $Message,
        [Parameter (Mandatory=$false, Position=1)]
        [ValidateSet('Information','Warning','Error')]
        [string] $Severity = 'Information',
        [Parameter (Mandatory=$false, Position=2)]
        [bool]$UIused = $false
    )

    # UI callers receive plain text through the success pipeline.
    If ($UIused){
        Write-Output $Message
    } else {
        # Console callers receive a severity-colored host message.
        switch ($Severity) {
            'Warning' { $ForegroundColor = 'Yellow'}
            'Error'   { $ForegroundColor = 'Red'}
            Default   { $ForegroundColor = 'Gray'}
        }
        Write-Host $Message -ForegroundColor $ForegroundColor
    }
}

<#
.SYNOPSIS
    Resolves an Active Directory user and loads its authorization group SIDs.
.DESCRIPTION
    Accepts a user identifier or an existing Active Directory user object. String
    identifiers can be a user principal name, DOMAIN\UserName, or SAM account name.
    After resolving the user, the function queries the object again in its owning
    domain to load TokenGroups, which contains the recursive authorization group SIDs.

    This is a private helper used by New-AdminRequest and Get-AdminStatus.
.PARAMETER User
    User to resolve. Supported string formats are UPN, DOMAIN\UserName, and SAM account
    name. An existing AD user object can also be supplied. An empty string selects the
    currently logged-on Windows user.
.INPUTS
    None. Pipeline input is not supported.
.OUTPUTS
    Microsoft.ActiveDirectory.Management.ADUser with TokenGroups loaded, or $null when
    no matching user can be found.
.EXAMPLE
    Get-User -User "user@contoso.com"

    Resolves the UPN through the forest Global Catalog and loads TokenGroups from the
    user's domain.
.EXAMPLE
    Get-User -User "CONTOSO\user"

    Resolves the SAM account name in the forest domain whose NetBIOS name is CONTOSO.
.EXAMPLE
    Get-User -User "user"

    Resolves the SAM account name in the current domain.
.NOTES
    Requires the ActiveDirectory PowerShell module and access to the user's domain.
#>
function Get-User{
    param(
        # Username
        [Parameter(Mandatory=$true,Position=0)]
        $User
    )

    # Resolve string identifiers according to their naming format.
    if ($User -is [string]){
        switch ($user){
            ""{
                # Resolve the currently logged-on user in the default domain context.
                $oUser = get-ADuser $env:UserName -Properties ObjectSID,CanonicalName  
                break
            }
            ({$_ -like "*@*"}){
                # Search a UPN forest-wide through the previously discovered GC.
                $oUser = get-ADUser -Filter "UserPrincipalName -eq '$User'" -Server $GlobalCatalogServer -Properties ObjectSID,CanonicalName
                break
            }
            ({$_ -like "*\*"}){
                # Match DOMAIN\UserName to a forest domain by its NetBIOS name.
                foreach ($DomainDNS in (GEt-ADForest).Domains){
                    $Domain == Get-ADDomain -Server $DomainDNS
                    if ($Domain.NetBIOSName -eq $user.split("\")[0]){
                        # Query the selected domain by SAM account name.
                        $oUser = get-aduser -Filter "SamAccountName -eq $($user.split("\")[1])" -Server $DomainDNS -Properties ObjectSID,CanonicalName
                        break
                    }
                }
                breaK
            }
            Default {
                # Resolve an unqualified SAM account name in the current domain.
                $oUser = Get-aduser -Filter "SamAccountName -eq '$User'" -Properties ObjectSID,CanonicalName
            }
        }
    } else {
        # Reuse an AD user object supplied by an internal caller.
        $oUser = $User
    }

    # Stop when the initial lookup did not resolve a user.
    if ($null -eq $oUser){
        return $null
    } else {
        # TokenGroups is not reliably available through the GC, so query the user
        # again in the owning domain using a base-scope LDAP search.
        $userDomainDNSName = $oUser.CanonicalName.split("/")[0]
        $oUser = Get-ADUser -LDAPFilter "(ObjectClass=user)" -SearchBase $ouser.DistinguishedName -SearchScope Base -Server $userDomainDNSName -Properties "TokenGroups"
        return $oUser
    }
}

#region Exported functions
function Get-UserElevationStatus{
<#
.SYNOPSIS
    Tests whether a user may request elevation on a computer.
.DESCRIPTION
    Resolves the specified user and computer in Active Directory and evaluates the
    configured JIT delegation rules. When enabled, the computer's ManagedBy attribute
    is checked first. If it does not grant access, matching computer-OU entries in the
    delegation configuration are compared with the user's SID and recursive TokenGroups.
.PARAMETER ServerName
    Target computer. Supported forms are DNS hostname, computer name in the local
    domain, DOMAIN\ComputerName, and DNS-domain/OU/ComputerName canonical name.
.PARAMETER UserName
    User to authorize. Supported forms are UPN, user name in the local domain,
    DOMAIN\UserName, and DNS-domain/OU/UserName canonical name.
.PARAMETER DelegationConfig
    Fully qualified path to the delegation configuration JSON file. Its entries map a
    ComputerOU distinguished name to one or more authorized user or group SIDs.
.PARAMETER AllowManagedByAttribute
    When $true, permits the computer's ManagedBy user or group to grant access before
    the delegation configuration is evaluated. The default is $true.
.INPUTS
    None. Pipeline input is not supported.
.OUTPUTS
    System.Boolean. Returns $true when a matching authorization is found; otherwise
    returns $false, including when the user or computer cannot be resolved.
.EXAMPLE
    Get-UserElevationStatus -ServerName "Server0" -UserName "AA" -DelegationConfig "\\contoso.com\SYSVOL\contoso.com\Just-In-Time\Delegation.config"

    Tests a local-domain computer and user against ManagedBy and the delegation file.
.EXAMPLE
    Get-UserElevationStatus -ServerName "Server0.contoso.com" -UserName "AA@contoso.com" -DelegationConfig "\\contoso.com\SYSVOL\contoso.com\Just-In-Time\Delegation.config"

    Resolves both objects forest-wide using their DNS-based names.
.NOTES
    Requires the ActiveDirectory PowerShell module and read access to the delegation
    configuration when delegation checking is enabled.
#>
    param(
        [Parameter (mandatory=$true, Position=0)]
        [string]$ServerName,
        [Parameter (Mandatory=$true, Position=1)]
        [string]$UserName,
        [Parameter (Mandatory=$false, Position=2)]
        [string]$DelegationConfig,
        [Parameter (Mandatory=$false)]
        [Alias('AllowManagebyAttribute')]
        [bool]$AllowManagedByAttribute = $true
    )

    # Resolve both principals before evaluating either authorization source.
    try {
        #region user
        $user = $null
        switch -Wildcard ($UserName) {
            # Resolve a UPN through the GC, then load TokenGroups from its domain.
            "*@*" {  
                $user = Get-ADUser -Filter "UserPrincipalName -eq '$UserName'" -Server $GlobalCatalogServer -Properties CanonicalName
                $userdomain = [regex]::Match($User.CanonicalName,"[^/]+").Value
                $user = Get-ADUser -LDAPFilter '(ObjectClass=User)' -SearchBase $user.DistinguishedName -SearchScope Base -Server $userdomain -Properties "TokenGroups"
                break
            }
            # Resolve a canonical DNS-domain/path/user name.
            "*/*"{
                $uhelper = [regex]::Match($userName,"^([^/]+).*?/([^/]+)$")
                $user = Get-ADUser -Identity $uhelper.Groups[2].Value -Server $uhelper.Groups[1].Value
                $user = Get-ADUser -LDAPFilter '(ObjectClass=User)' -SearchBase $user.DistinguishedName -SearchScope Base -Server $uhelper.Groups[1].Value -Properties "TokenGroups"
                break
            }
            # Resolve DOMAIN\UserName by matching the domain NetBIOS name.
            "*\*" {
                $uhelper = [regex]::Match($UserName,"([^\\]+)\\(.+)")
                Foreach ($domainRoot in (Get-ADForest).Domains){
                    $ADDomain = Get-ADDomain -server $domainRoot
                    if ($ADDomain.NetbiosName -eq $uhelper.Groups[1].Value){                    
                        $user = Get-ADuser -Identity $uhelper.Groups[2].Value -Server $domainRoot
                        $user = Get-ADUser -LDAPFilter '(ObjectClass=User)' -SearchBase $user.DistinguishedName -SearchScope Base -Server $uhelper.Groups[1].Value -Properties "TokenGroups"
                        break
                    }
                }
                break
            }
            # Resolve an unqualified user in the current domain.
            Default {
                $user = Get-ADUser -Identity $UserName      
                $user = Get-ADUser -LDAPFilter '(ObjectClass=User)' -SearchBase $user.DistinguishedName -SearchScope Base -Properties "TokenGroups"
                break
            }   
        }
        #endregion
        #region searching computer
        # Resolve the computer according to its supplied naming format.
        switch -Wildcard ($ServerName) {
            "*.*" {
                $Computer = Get-ADComputer -Filter "DNSHostName -eq '$ServerName'" -Server $GlobalCatalogServer
            # The GC omits ManagedBy, so repeat the query in the owning domain.
                if ($Computer.GetType().Name -ne "ADcomputer"){
                    Write-Host "The computer $serverName is not available in AD. Please validate the DNS name of the computer object (Get-UserElevationState)" -ForegroundColor Red  
                    return $false
                }
                $domainDNS = ConvertFrom-DN2Dns $Computer.DistinguishedName
                $Computer = Get-ADComputer $Computer -Properties ManagedBy -Server $domainDNS
                break
            }
            "*.*/*"{
                $uhelper = [regex]::Match($userName,"^([^/]+).*?/([^/]+)$")
                $Computer = Get-ADcomputer -Filter "CN -eq '$($uhelper.Groups[2].Value)" -Properties ManagedBy -Server $uhelper.Groups[1].Value
                if ($Computer.GetType().Name -ne "ADcomputer"){
                    Write-Host "The computer $serverName is not available in AD. Please validate the canonical name ist correct (Get-UserElevationState)" -ForegroundColor Red
                    return $false
                }
                break
            }
            "*\*"{
                $uhelper = [regex]::Match($ServerName,"([^\\]+)\\(.+)")
                $DnsDomainName = (Get-ADObject -Filter "netbiosname -eq '$($uhelper.Groups[1].Value))'" -SearchBase (Get-ADForest).PartitionsContainer -Properties dnsroot).dnsroot
                if ($DnsDomainName -eq ""){
                    Write-Host "The computer $DnsDomainName is not available in AD. Please validate the computer is available (Get-UserElevationState)" -ForegroundColor Red
                    return $false
                }
                $Computer = Get-ADComputer -Filter "CN -eq '$($uhelper.Groups[2].Value)'" -Server $uhelper.Groups[1].Value -server $DnsDomainName
                if ($Computer.GetType().Name -ne "ADcomputer"){
                    Write-Host "The computer $serverName is not available in AD. Please validate the computer is available (Get-UserElevationState)" -ForegroundColor Red
                    return $false
                }    
                break
            }
            Default{
                # Resolve an unqualified computer in the current domain.
                $Computer = Get-ADcomputer -Filter "CN -eq '$ServerName'" -Properties Managedby
                if ($Computer.GetType().Name -ne "ADcomputer"){
                    Write-Host "The computer $serverName is not available in AD. Please validate the computer is available (Get-UserElevationState)" -ForegroundColor Red
                    return $false
                }
                break
            }
        }
        #endregion
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        # A missing identity is an authorization failure, not a terminating result.
        if ($null -eq $user){
            Write-Host "Cannot find user $userName " -ForegroundColor Red
        } else {
            Write-Host "Cannot find computer $serverName" -ForegroundColor Red
        }
        return $false
    }

    # Grant access when the user is the ManagedBy principal or belongs to its group.
    if ($null -ne $Computer.ManagedBy -and $AllowManagedByAttribute){
        $oManagedBy = Get-ADObject -Filter "DistinguishedName -eq '$($Computer.ManagedBy)'" -Server $GlobalCatalogServer -Properties ObjectSID, CanonicalName
        Switch ($oManagedBy.ObjectClass){
            "User"{
                if ($user.SID -eq $oManagedBy.ObjectSID.Value){
                    return $true
                }
            }
            "Group"{
                $groupDomain = [regex]::Match($Group.CanonicalName,"[^/]+").Value
                $oManagedByMembers = Get-ADGroupMember -Identity $group.DistinguishedName -Recursive -Server $groupDomain
                foreach ($member in $oManagedByMembers){
                    if ($member -eq $user.ObjectSID.Value){
                        return $true
                    }
                }

            }
        }
    }

    # Compare the user and recursive group SIDs with delegations for the computer OU.
    if ($config.EnableDelegation){
        $oDelegation = Get-Content $DelegationConfig | ConvertFrom-Json 
        $ServerDelegations = $oDelegation | Where-Object {$Computer.DistinguishedName -like "*$($_.ComputerOU)"} 
         foreach ($OU in $ServerDelegations){
            if ($OU.ADObject -contains $user.SID){
                return $true
            }
            foreach ($usergroupSID in $user.TokenGroups){
                if ($OU.ADObject -contains $usergroupSID){
                    return $true
                }
            }
        }
    }

    # No configured authorization source granted access.
    return $false
}
#endregion

function New-AdminRequest{
    <#
.SYNOPSIS
    Creates a just-in-time administrator access request for a server.
.DESCRIPTION
    Loads the JIT configuration, resolves the requesting user and target computer in
    Active Directory, enforces the configured concurrent-server and delegation rules,
    and writes the validated request as JSON to the configured Windows event log.

    For console callers, the requested duration is constrained to the configured
    minimum, default, and maximum values. UI callers are expected to provide a duration
    that has already been validated by the UI.
.PARAMETER Server
    Target computer name. Supported forms are an unqualified computer name, DNS
    hostname, DNS-domain\ComputerName, or DOMAIN\ComputerName.
.PARAMETER ServerDomain
    Optional DNS domain used to resolve an unqualified Server name. This is useful in
    multi-domain or multi-forest environments. Without it, the Global Catalog is used.
.PARAMETER Minutes
    Requested elevation duration in minutes. In console mode, 0 selects the configured
    default, values below 15 become 15, and values above MaxElevatedTime are reduced to
    that configured maximum.
.PARAMETER User
    User receiving administrator access. Supported values are accepted by Get-User. If
    omitted, the currently logged-on Windows user is used.
.PARAMETER UIused
    When $true, returns status messages through the success pipeline for a UI caller and
    skips the console-specific duration normalization. The default is $false.
.INPUTS
    None. Pipeline input is not supported.
.OUTPUTS
    System.String status messages when UIused is $true. In console mode, messages are
    written to the host and no success-pipeline object is returned.
.EXAMPLE
    New-AdminRequest -Server "myhost.contoso.com"

    Requests the configured default elevation duration for the current user.
.EXAMPLE
    New-AdminRequest -Server "myhost.contoso.com" -Minutes 30 -User "user@contoso.com"

    Requests 30 minutes of administrator access for the specified user.
.EXAMPLE
    New-AdminRequest -Server "myhost" -ServerDomain "contoso.com" -Minutes 30

    Resolves an unqualified server name in the specified DNS domain.
.NOTES
    Requires Active Directory access, the JIT configuration, and permission to write
    to the configured Windows event log.
    #>

    param(
        [Parameter(Mandatory = $true, Position=0 )]
        [string]$Server,
        [Parameter(Mandatory = $false)]
        [string]$ServerDomain,
        [Parameter(Mandatory = $false, Position=1)]
        [int]$Minutes = 0,
        [Parameter(Mandatory = $false)]
        [string]$User,
        [Parameter (Mandatory = $false)]
        [bool]$UIused = $false
    )

    # Load all request limits, naming rules, and event-log settings.
    $config = Get-JITconfig

    # Console requests normalize their duration against the configured limits.
    if (!$UIused) {
        #region validation of minutes
        switch ($Minutes) {
            0 {
                $Minutes = $config.DefaultElevatedTime
                break
              }
            ({$_ -lt 15}){
                $Minutes = 15
                break
            }
            ({$_ -gt $config.MaxElevatedTime}){
                $Minutes = $config.MaxElevatedTime
                break
            }
        }
        #endregion
    }

    #region user evaluation
    # Default to the currently logged-on user when no recipient was supplied.
    if (!$User) {
        $User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.split("\")[1]
    }

    # Resolve the user and enforce the configured concurrent-elevation limit.
    $oUser = Get-User $User
    if ((Get-AdminStatus $oUser).count -gt $config.MaxConcurrentServer){
        Write-ScriptMessage "Elevation limit reached. retry in a couple of minutes" -UIused $UIused
    }
    if ($Null -eq $oUser){
        Write-ScriptMessage "Can find the user object." -Severity Warning -UIused $UIused
        return
    }
    if ($null -eq $oUser.userPrincipalName){
        Write-ScriptMessage "Missing UPN attribute on the user object. Aborting elevation" -Severity Warning -UIused $UIused
        return
    }
    #endregion

    # Resolve the computer by NetBIOS-qualified, DNS, or unqualified name.
    switch ($Server) {
        {$_ -like "*\*"}{
            # Resolve DNS-domain\ComputerName or DOMAIN\ComputerName.
            $oNetBiosServerName = $server.Split("\")
            if ($oNetBiosServerName[0] -like "*.*"){
                $oserver = Get-ADComputer -Filter "Name -eq '$($oNetBiosServerName[1])'" -Server $oNetBiosServerName[0] -Properties CanonicalName, ManagedBy
            } else {
                Foreach ($ForestDomainDNSName in (Get-ADForest).Domains){
                    if ((Get-ADDomain -Server $ForestDomainDNSName).NetBiosName -eq $oNetBiosServerName[0]){
                        $oServer = Get-ADcomputer  -Filter "Name -eq '$($oNetBiosServerName[1])'"  -Server $ForestDomainDNSName -Properties CanonicalName, ManagedBy    
                        break
                    }
                }
            }
            break
        }
        {$_ -like "*.*"}{
            # Resolve a DNS hostname forest-wide through the GC.
            $oServer = Get-ADcomputer -Filter "DNSHostName -eq '$Server'" -Server $GlobalCatalogServer -Properties CanonicalName, ManagedBy
            break
        }
        Default {
            # Use an explicit domain when supplied; otherwise query the GC.
            if ($ServerDomain -eq ""){
                $oServer = Get-ADComputer -Filter "Name -eq '$Server'" -Server $GlobalCatalogServer -Properties CanonicalName, ManagedBy
            } else {
                $oServer = Get-ADcomputer -Filter "Name -eq '$Server'" -Server $ServerDomain -Properties CanonicalName, ManagedBy
            }
        }
    }

    # Reject missing or ambiguous computer objects before creating a request.
    if ($null -eq $oServer){
        Write-ScriptMessage -Message "Can't find a server $server in the forest" -Severity Warning -UIused $UIused
        return
    }
    if ($oServer.GetType().Name -eq "Object[]"){
        Write-ScriptMessage -Message "Multiple computer found with this name $server in the current forest, Please use the DNS hostname instead " -Severity Warning -UIused $UIused 
        return
    }
    # Build the target admin-group name according to the deployment mode.
    if ($config.EnableMultiDomainSupport){
        #$ServerDomainDN = [regex]::Match($oserver.DistinguishedName,"DC=.*").value
        #$ServerDomainDNSName = (Get-ADForest).domains | Where-Object {(Get-ADDomain -Server $_ -ErrorAction SilentlyContinue).DistinguishedName -eq $ServerDomainDN}
        $ServerDomainDNSName = $oServer.CanonicalName.split("/")[0]
        #$ServerDomainNetBiosName = (GEt-ADdomain -Server $ServerDomainDNSName).NetBIOSName
        #$ServerGroupName = "$($config.AdminPreFix)$serverDomainNetBiosName$($config.DomainSeparator)$($oServer.Name)"
        # we will work with dns domain name
        $ServerGroupName = "$($config.AdminPreFix)$ServerDomainDNSName$($config.DomainSeparator)$($oServer.Name)"
    } else {
        $ServerGroupName = "$($config.AdminPreFix)$($oServer.Name)"
    }
    #endregion

    if (!$oServer.DNSHostName){
        Write-ScriptMessage -Message "Missing DNS Hostname entry on the computer object. Aborting elevation" -Severity Warning -UIused $UIused
        return
    }

    # Enforce per-server delegation before recording the elevation request.
    if ($config.EnableDelegation) {
        if (!(Get-UserElevationStatus -ServerName $oServer.DNSHostName -UserName $oUser.UserPrincipalName -DelegationConfig $config.DelegationConfigPath)){
            Write-ScriptMessage -Message "User is not allowed to request administrator privileges" -Severity Warning -UIused $UIused
            return
        }
    }

    # Serialize the validated request for the event-driven elevation processor.
    $ElevateUser = New-Object PSObject
    $ElevateUser | Add-Member -MemberType NoteProperty -Name "UserDN" -Value $oUser.DistinguishedName
    $ElevateUser | Add-Member -MemberType NoteProperty -Name "ServerGroup" -Value $ServerGroupName
    $ElevateUser | Add-Member -MemberType NoteProperty -Name "ServerDomain" -Value $ServerDomainDNSName
    $ElevateUser | Add-Member -MemberType NoteProperty -Name "ElevationTime" -Value $Minutes
    #$ElevateUser | Add-Member -MemberType NoteProperty -Name "CallingUser" -Value "$($env:USERNAME)@$($env:USERDNSDOMAIN)"
    $ElevateUser | Add-Member -MemberType NoteProperty -Name "CallingUser" -Value (([ADSI]"LDAP://<SID=$([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)>").UserPrincipalName).ToString()
    $EventMessage = ConvertTo-Json $ElevateUser

    # Submit the request and notify the console or UI caller.
    Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId $config.ElevateEventID -Message $EventMessage
    Write-ScriptMessage -Message "The $($oUser.DistinguishedName) will be elevated soon" -Severity Information -UIused $UIused
}

function Get-AdminStatus{
    <#
.SYNOPSIS
    Returns the current just-in-time administrator assignments for a user.
.DESCRIPTION
    Resolves the supplied user and inspects the configured JIT administrator groups
    with Active Directory member TTL information enabled. Each matching membership is
    translated into a server name and its remaining lifetime in whole minutes. A
    membership without TTL is reported as permanent.
.PARAMETER User
    User name or Active Directory user object to inspect. String values are resolved by
    Get-User. If omitted, the currently logged-on user's SAM account name is used. The
    value can be supplied through the pipeline.
.PARAMETER UIused
    When $true, writes a formatted status message for each assignment instead of
    returning status objects. The default is $false.
.INPUTS
    System.String or Microsoft.ActiveDirectory.Management.ADUser.
.OUTPUTS
    PSCustomObject values with Server and TTL properties when UIused is $false. No
    success-pipeline objects are returned in UI mode.
.EXAMPLE
    Get-AdminStatus

    Returns active JIT administrator assignments for the current user.
.EXAMPLE
    Get-AdminStatus -User "user@contoso.com"

    Resolves the specified user and returns one status object per matching JIT group.
.EXAMPLE
    Get-ADUser -Identity "user" | Get-AdminStatus

    Checks assignments for an existing Active Directory user object from the pipeline.
.NOTES
    Requires the ActiveDirectory PowerShell module and permission to read the configured
    JIT groups with member time-to-live information.
    #>

    param(
        [Parameter(Mandatory=$false, Position=0, ValueFromPipeline = $true)]
        $User,
        [Parameter(Mandatory=$False)]
        [bool]$UIused = $False
    )

    # Default to the current Windows user, then load the JIT configuration.
    if ($null -eq $User){
        $user = $env:USERNAME
    }
    $config = Get-JITconfig

    # Resolve string identifiers while preserving an AD user object from the pipeline.
    if ($user -is [string]){
        $User = Get-User $User
    }
    $retVal = @()

    # Stop when the user cannot be resolved in Active Directory.
    if ($null -eq $User){
        Write-ScriptMessage -Message "cannot find user " -Severity Warning -UIused $UIused
        Return
    }

    # Enumerate configured JIT groups with expiring-membership metadata.
    foreach ($Group in (Get-ADGroup -Filter * -SearchBase $config.OU -Properties Members -ShowMemberTimeToLive)){
        $UserisMember = $Group.Members | Where-Object {$_ -like "*$($User.DistinguishedName)"}
        If ($null -ne $UserisMember){
            # Decode the server identity from the configured group-name convention.
            if ($config.EnableMultiDomainSupport){
                $Domain = (($Group.Name).Substring(($config.AdminPreFix).Length)).Split($config.DomainSeparator)[0]
                $Server = (($Group.Name).Substring(($config.AdminPreFix).Length)).Split($config.DomainSeparator)[1]
                $TTLsec = [regex]::Match($UserisMember, "\d+").Value
            } else {
                $Server = (($Group.Name).Substring(($config.AdminPreFix).Length))
                $TTLsec = [regex]::Match($UserisMember, "\d+").Value
            }

            # Convert AD's TTL seconds to whole minutes; no TTL means permanent.
            if ($TTLsec -eq ""){
                $TimeValue = "permanent"    
            } else {
                $TimeValue = [math]::Floor($TTLsec / 60)
            }

            # Return a stable object shape for every active server assignment.
            $obj = new-Object PSObject
            $obj | Add-Member -MemberType NoteProperty -Name "Server" -Value "$domain\$server"
            $obj | Add-Member -MemberType NoteProperty -Name "TTL"    -Value "$TimeValue"
            $retVal += $obj
        }
    }

    # UI callers receive formatted host messages; automation callers receive objects.
    if ($UIused){
        $retVal |ForEach-Object{Write-scriptMessage -Message "$User is elevated on $($_.Server) for $($_.TTL) minutes"}
    } else {
        return $retVal
    }
}
