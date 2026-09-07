#requires -PSEdition Desktop

<#
Script Info

Author: Andreas Lucas [MSFT]

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

function ValidateOU {
    <#
    .SYNOPSIS
        Validates an Active Directory organizational unit distinguished name.
    .DESCRIPTION
        Verifies that the supplied value has the expected OU distinguished-name
        format, belongs to a domain in the current Active Directory forest, and can
        be resolved as an Active Directory object in that domain.

        If the value is empty or invalid, the function displays an error when
        applicable and interactively prompts for another OU path until validation
        succeeds. This is a private helper used when adding a JIT delegation.
    .PARAMETER OU
        Distinguished name of the organizational unit to validate, for example
        "OU=Servers,DC=contoso,DC=com". When omitted or invalid, the function prompts
        interactively for a replacement value.
    .EXAMPLE
        ValidateOU -OU "OU=Servers,DC=contoso,DC=com"

        Validates the OU against the current forest and returns its distinguished
        name when it exists.
    .INPUTS
        None. Pipeline input is not supported.
    .OUTPUTS
        System.String. The validated organizational unit distinguished name.
    .NOTES
        Requires the ActiveDirectory PowerShell module, access to the current forest,
        and an interactive host when the initial value is empty or invalid.
    #>

    param(
        [Parameter (Position = 1)]
        [String]$OU
    )  

    # Repeat validation until an OU from a known forest domain can be resolved.
    $DomainDNS = ""    
    Do {
        if ($OU -eq ""){
            $OU=Read-Host "OU path"
        }

        # Require one or more OU components followed by the domain components.
        if (!($OU -match "^(OU=[^,]+,)+(DC=[^,]+,)+DC=.+")){
            Write-Host "Invalid OU path" -ForegroundColor Red
            $OU= ""
        } else {
            # Determine which forest domain owns the supplied distinguished name.
            $DomainDN = $OU -replace "^(OU=[^,]+,)+"
            Foreach ($ForestDomain in (Get-ADForest).Domains){
                if ((Get-ADDomain -Server $ForestDomain).DistinguishedName -eq $domainDN){
                    $DomainDNS = $ForestDomain
                    break
                }
            }
            #$ComputerDomainDNS = (Get-ADForest).domains | Where-Object {(Get-ADDomain -Server $_).DistinguishedName -like "$domainDN"}    
            if ($DomainDNS -eq ""){
                Write-Host "Invalid domain" -ForegroundColor Red
                $OU=""
            } else {
                # Accept the value only when the directory object exists in that domain.
                If ($Null -eq (Get-ADObject -Filter 'DistinguishedName -eq $OU' -Server $DomainDNS)){
                    Write-Host "Invalid OU path" -ForegroundColor Red
                    $OU=""
                }
            }
        }
    } while ($OU -eq "")
    return $OU
}
function Get-Sid{
    <#
    .SYNOPSIS
        Resolves an Active Directory user or group name to its SID.
    .DESCRIPTION
        Resolves an Active Directory object by using one of three input formats:
        a user principal name, a DOMAIN\Name value, or a common name. User principal
        names are searched through a discovered Global Catalog. DOMAIN\Name values
        are resolved in the matching domain of the current forest, and common names
        are resolved through the default Active Directory connection.

        If Name is empty, or if no SID is found, the function interactively prompts
        for another user or group name until resolution succeeds. This is a private
        helper used by the JIT delegation commands.
    .PARAMETER Name
        Active Directory user or group identifier. Supported formats are a user
        principal name such as "user@contoso.com", a domain-qualified name such as
        "CONTOSO\Server-Admins", or a common name such as "Server-Admins".
    .EXAMPLE
        Get-Sid -Name "user@contoso.com"

        Resolves the user through the Global Catalog and returns its SID value.
    .EXAMPLE
        Get-Sid -Name "CONTOSO\Server-Admins"

        Finds the forest domain with the CONTOSO NetBIOS name and resolves the group
        in that domain.
    .INPUTS
        None. Pipeline input is not supported.
    .OUTPUTS
        System.String. The SID value of the resolved Active Directory object.
    .NOTES
        Requires the ActiveDirectory PowerShell module, access to a Global Catalog,
        and an interactive host when the supplied name cannot be resolved.
    #>

    param (
        [Parameter ()]
        [string] $Name
    )

    # Discover a Global Catalog once for forest-wide UPN lookups.
    $OSID = ""
    $GC = (Get-ADDomainController -Discover -Service GlobalCatalog)
    do{
        # Request an identifier interactively when none was supplied or resolved.
        if ($Name -eq ""){
            $Name = Read-Host "Domain user or Group"
        }

        # Select the lookup strategy from the identifier format.
        switch -Wildcard ($Name){
            "*@*" {
                # Resolve a user principal name across the forest through the GC.
                $OSID= (Get-ADObject -Filter{UserprincipalName -eq $Name} -Server $GC -Properties ObjectSID).ObjectSid.Value
            }
            "*\*" {
                # Split DOMAIN\Name and map the NetBIOS domain name to its DNS name.
                $UserNetBiosName = $Name.Split("\")
                $UserName = $UserNetBiosName[1]
                $DomainDNS = (Get-ADForest).Domains | Where-Object {(Get-ADDomain -Server $_).NetBiosName -eq $userNetBiosName[0]}

                # Resolve the SAM account name in the selected forest domain.
                $OSID= (Get-ADObject -Filter{SamAccountName -like $UserName} -Server $DomainDNS -Properties ObjectSId).ObjectSID.Value
            }
            Default {
                # Treat all other input as a common name in the default AD context.
                $OSID = (Get-ADObject -Filter {cn -eq $Name} -Properties ObjectSID).ObjectSid.Value
            }
        }

        # Reset Name after an unsuccessful lookup so the next iteration prompts.
        if ($Null -eq $OSID ){
            $Name = ""
        }
    } while ($Name -eq "")
    return $OSID
}

function Update-JitDelegation {
    <#
    .SYNOPSIS
        Reads or updates the persisted JIT delegation configuration.
    .DESCRIPTION
        Provides the internal implementation for the exported JIT delegation
        commands. The Action parameter selects one of four operations:

        ShowCurrentDelegation reads all delegation entries, translates their stored
        SIDs to NT account names, and returns objects containing OU and SID properties.
        AddDelegation validates an OU, resolves a user or group to its SID, and adds
        the SID to a new or existing OU entry. RemoveDelegation removes the complete
        entry for an OU. RemoveUserOrGroup removes one resolved SID from an OU entry.

        Mutating actions rewrite the delegation JSON file identified by
        DelegationConfigPath in the loaded JIT configuration. This is a private helper
        used by Add-JitDelegation, Remove-JitDelegation, and Get-JitDelegation.
    .PARAMETER action
        Operation to perform. Accepted values are ShowCurrentDelegation,
        AddDelegation, RemoveDelegation, and RemoveUserOrGroup. If omitted, the
        current delegation configuration is returned.
    .PARAMETER OU
        Distinguished name of the computer OU affected by an add or remove operation.
    .PARAMETER ADUserOrGroup
        Active Directory user or group identifier to add to, or remove from, the OU
        delegation. Get-Sid resolves this value to the SID stored in the JSON file.
    .PARAMETER configFileName
        Optional JIT configuration source passed to Get-JitConfig. When omitted,
        Get-JitConfig applies its normal source-resolution rules.
    .EXAMPLE
        Update-JitDelegation -action ShowCurrentDelegation

        Returns the configured OUs and their translated NT account names.
    .EXAMPLE
        Update-JitDelegation -action AddDelegation -OU "OU=Servers,DC=contoso,DC=com" -ADUserOrGroup "CONTOSO\Server-Admins"

        Adds the resolved group SID to the delegation entry for the Servers OU.
    .EXAMPLE
        Update-JitDelegation -action RemoveDelegation -OU "OU=Servers,DC=contoso,DC=com"

        Removes the complete delegation entry for the Servers OU.
    .INPUTS
        None. Pipeline input is not supported.
    .OUTPUTS
        System.Boolean for mutating actions. ShowCurrentDelegation returns
        System.Management.Automation.PSCustomObject instances with OU and SID
        properties.
    .NOTES
        Requires a readable JIT configuration, access to its DelegationConfigPath,
        and Active Directory connectivity for validation and SID translation.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ShowCurrentDelegation')]
    param (
    [Parameter(Position = 1)]
    [ValidateSet('ShowCurrentDelegation', 'AddDelegation', 'RemoveDelegation', 'RemoveUserOrGroup')]
    [string]$action,
    [Parameter(Position = 2)]
    [string]$OU = "",
    [Parameter(Position = 2)]
    [string]$ADUserOrGroup,
    [Parameter (Position = 3)]
    [string]$configFileName    
)
    # Resolve the main JIT configuration, optionally from an explicit source.
    $CurrentDelegation = @()
    if ($null -eq $configFileName){
        $config = Get-JitConfig
    } else {
        $config = Get-JitConfig -configurationFile $configFileName
    }

    # Load existing delegation entries; a missing file represents an empty database.
    if ((Test-Path $config.DelegationConfigPath)){
        $CurrentDelegation += Get-Content "$($config.DelegationConfigPath)" | ConvertFrom-Json 
    } 

    # Dispatch the requested read or mutation operation.
    switch ($action) {
        'AddDelegation' {
            # Validate both sides of the delegation before changing persisted data.
            $OU= ValidateOU -OU $OU
            $ObjectSId = Get-Sid $ADUserOrGroup
            $NewEntry = $true

            # Reuse an existing OU entry and append the SID only when it is new.
            if ($CurrentDelegation.Count -gt 0){
                for ($i = 0; $i -lt $CurrentDelegation.Count; $i++){
                    if ($CurrentDelegation[$i].ComputerOU -eq $OU){
                        $NewEntry = $false 
                        if (!($CurrentDelegation[$i].ADObject -contains $objectSId)){
                            $CurrentDelegation[$i].ADObject += $objectSId
                        }
                        break
                    }
                }
            }

            # Create the first delegation entry for an OU not yet in the file.
            if ($NewEntry){
                $Delegation = New-Object psobject
                $Delegation | Add-Member NoteProperty "ComputerOU" -Value $OU 
                $Delegation | Add-Member NoteProperty "ADObject" -Value @($ObjectSID)
                $CurrentDelegation += $Delegation
            }

            # Persist the complete delegation collection after the add operation.
            ConvertTo-Json $CurrentDelegation  | Out-File $config.DelegationConfigPath -Confirm:$false
            return $true
        }
        'RemoveDelegation'{
            # Rebuild the collection without entries for the requested OU.
            $tempDelegation = @()
            for ($i = 0; $i -lt $CurrentDelegation.count; $i++){
                if ($CurrentDelegation[$i].ComputerOU -ne $OU){
                    $tempDelegation += $CurrentDelegation[$i]
                }
            }

            # Persist the filtered delegation collection.
            ConvertTo-Json $tempDelegation | Out-File $config.DelegationConfigPath -Confirm:$false
            return $true
        }
        'RemoveUserOrGroup'{
            # Resolve the account and locate its OU delegation entry.
            $ObjectSID = Get-Sid $ADUserOrGroup
            for ($i = 0; $i -lt $CurrentDelegation.count;$i++){
                if ($CurrentDelegation[$i].ComputerOU -eq $OU){
                    # Rebuild the OU's SID list without the resolved account SID.
                    $tempSIDList = @()
                    Foreach ($SID in $CurrentDelegation[$i].ADObject){
                        if ($SID -ne $ObjectSId){
                            $tempSIDList +=  $SID
                        }
                    }
                    $CurrentDelegation[$i].ADObject = $tempSIDList

                    # Persist the modified OU entry and stop after the first match.
                    ConvertTo-Json $CurrentDelegation | Out-File $config.DelegationConfigPath -Confirm:$false
                    return $true    
                }
            }
        }
        Default {
            # Translate stored SIDs into readable NT account names for callers.
            $retVal = @()
            For($iOU= 0; $iOU -lt $CurrentDelegation.Count; $iOU++){
                $arySID = @()
                For($iSID = 0; $iSID -lt $CurrentDelegation[$iOU].ADObject.count;$iSID++){
                    $SID = New-Object System.Security.Principal.SecurityIdentifier($CurrentDelegation[$iOU].ADObject[$iSID])
                    $arySID +=$SID.Translate([System.Security.Principal.NTAccount]).Value
                }

                # Return one presentation object per configured computer OU.
                $OUdelegation = New-Object PSObject
                $OUdelegation | Add-Member -MemberType NoteProperty -Name OU -Value $CurrentDelegation[$iOU].ComputerOU
                $OUdelegation | Add-Member -MemberType NoteProperty -Name SID -Value $arySID
                $retVal +=$OUdelegation
            }
            return $retVal
        }
    }
}

function Add-JitDelegation {
    param (
        [Parameter (Mandatory = $true,Position = 0)]
        [string]$OU,
        [Parameter (Mandatory = $true, Position = 1)]
        [string]$ADobject
    )
    #validate the OU format is correct
    $pattern = '^((CN|OU|DC)=[^,]+,)*(CN|OU|DC)=[^,]+$'
    if ($ou -notmatch $pattern){
        throw [System.FormatException]::new("$OU is not a valid distinguishedname for a organizational unit")
    }
    if ($null -eq (Get-Sid $ADobject)){
        throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]::new("$ADObject doesn't exist")
    }
    return Update-JitDelegation -action AddDelegation -OU $OU -ADUserOrGroup $ADobject
}

function Remove-JitDelegation {
    <#
    .SYNOPSIS
        Removes an OU delegation or one delegated Active Directory object.
    .DESCRIPTION
        Removes delegation data for the specified organizational unit. When
        ADObject is omitted, the complete delegation entry for the OU is removed.
        When ADObject is supplied, only the resolved user or group SID is removed
        from that OU entry.

        By default, the function asks for interactive confirmation before changing
        the delegation configuration. Force suppresses that prompt. The actual JSON
        update is performed by the private Update-JitDelegation helper.
    .PARAMETER OU
        Distinguished name of the organizational unit whose delegation should be
        changed, for example "OU=Servers,DC=contoso,DC=com".
    .PARAMETER ADObject
        Optional Active Directory user or group to remove from the OU delegation.
        Supported identifiers are the formats accepted by Get-Sid, including UPN,
        DOMAIN\Name, and common name. If omitted, the complete OU entry is removed.
    .PARAMETER Force
        Removes the delegation without displaying an interactive confirmation prompt.
    .EXAMPLE
        Remove-JitDelegation -OU "OU=Servers,DC=contoso,DC=com"

        Prompts for confirmation and then removes the complete delegation entry for
        the Servers OU.
    .EXAMPLE
        Remove-JitDelegation -OU "OU=Servers,DC=contoso,DC=com" -ADObject "CONTOSO\Server-Admins"

        Prompts for confirmation and then removes the Server-Admins group SID from
        the Servers OU delegation.
    .EXAMPLE
        Remove-JitDelegation -OU "OU=Servers,DC=contoso,DC=com" -Force

        Removes the complete OU delegation without prompting for confirmation.
    .INPUTS
        None. Pipeline input is not supported.
    .OUTPUTS
        System.Boolean. Returns $true when Update-JitDelegation performs the selected
        removal and $false when the caller declines confirmation. No value is returned
        when an individual AD object is not found in the specified OU entry.
    .NOTES
        This function is exported by the Just-In-time module. It requires a valid JIT
        and delegation configuration. Removing an individual AD object additionally
        requires Active Directory connectivity to resolve its SID.
    #>

    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$OU,
        [Parameter(Mandatory = $false, Position = 1)]
        [string]$ADObject,
        [switch]$Force
    )

    # Reject values that are not syntactically valid distinguished names.
    $pattern = '^((CN|OU|DC)=[^,]+,)*(CN|OU|DC)=[^,]+$'
    if ($ou -notmatch $pattern){
        throw [System.FormatException]::new("$OU is not a valid distinguishedname for a organizational unit")
    }

    # Without ADObject, remove the complete delegation entry for the OU.
    if (-not $ADObject){
        if ($Force){
            # Force bypasses the interactive safety prompt.
            return Update-JitDelegation -action RemoveDelegation -OU $OU
        } else {
            $confirmation = Read-Host "Do you want to remove the OU $OU from the JIT access database (Y/N)"
            if ($confirmation -eq 'Y' -or $confirmation -eq 'y') {
                return Update-JitDelegation -action RemoveDelegation -OU $OU
            } else {
                # Report cancellation without modifying the delegation file.
                return $false
            }
        }
    } else {
        # Resolve and validate the user or group before attempting SID removal.
        if ($null -eq (Get-Sid $ADobject)){
            throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]::new("$ADObject doesn't exist")
        }
        if ($Force){
            # Remove only the resolved account SID without prompting.
            return Update-JitDelegation -action RemoveUserOrGroup -OU $OU -ADUserOrGroup $ADObject 
        } else {
            $confirmation = Read-Host "Do you want to remove the $ADobject from $OU (Y/N)"
            if ($confirmation -eq 'Y' -or $confirmation -eq 'y'){
                return Update-JitDelegation -action RemoveUserOrGroup -OU $OU -ADUserOrGroup $ADObject
            } else {
                # Report cancellation without modifying the delegation file.
                return $false
            }
        }
    }   
}

function Get-JitDelegation{
    <#
    .SYNOPSIS
        Returns the configured JIT delegations in a readable form.
    .DESCRIPTION
        Reads the persisted delegation configuration through Update-JitDelegation.
        Stored security identifiers are translated to NT account names, and one
        pipeline object is returned for each configured organizational unit.
    .EXAMPLE
        Get-JitDelegation

        Returns all configured organizational units and their delegated users or
        groups.
    .EXAMPLE
        Get-JitDelegation | Where-Object OU -eq "OU=Servers,DC=contoso,DC=com"

        Returns the delegation entry for the specified organizational unit.
    .EXAMPLE
        Get-JitDelegation | Select-Object -ExpandProperty SID

        Returns the translated NT account names from all delegation entries.
    .INPUTS
        None. Pipeline input is not supported.
    .OUTPUTS
        System.Management.Automation.PSCustomObject. Each object contains an OU
        property with the organizational unit distinguished name and a SID property
        containing the translated NT account names.
    .NOTES
        This function is exported by the Just-In-time module. It requires a readable
        JIT and delegation configuration as well as Active Directory connectivity for
        translating stored SIDs to NT account names.
    #>

    # Use the shared dispatcher to load entries and translate their stored SIDs.
    return Update-JitDelegation -action ShowCurrentDelegation
}
