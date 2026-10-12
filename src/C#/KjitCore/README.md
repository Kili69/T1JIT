# KjitCore

`KjitCore` ist eine wiederverwendbare C#-Bibliothek (DLL), um Logik aus den PowerShell-Modulen in gemeinsame .NET-Services auszulagern.

## Ziel

- Gemeinsame Business-Logik fuer PowerShell und native .NET Anwendungen.
- Schrittweise Migration bestehender Funktionen aus `src/Powershell/modules/0.1`.
- Klare API ueber Interfaces in `Abstractions`.

## Build

```powershell
dotnet build .\KjitCore.csproj -c Release
```

Die DLL wird unter `bin\Release\<targetframework>\KjitCore.dll` erzeugt.

## Verwendung in PowerShell

```powershell
$assemblyPath = "C:\Repos\T1JIT\src\C#\KjitCore\bin\Release\net8.0\KjitCore.dll"
Add-Type -Path $assemblyPath

# Statische Facade nutzen
[KjitCore.KjitCore]::DistinguishedName.ConvertDomainDnToDnsName("OU=Users,DC=contoso,DC=com")

# JIT.config laden
$config = [KjitCore.KjitCore]::LoadJitConfiguration("C:\Repos\T1JIT\docs\config.jit.example")

# Delegationen laden, aendern und kanonisch serialisieren
$delegations = [KjitCore.KjitCore]::LoadDelegationConfiguration("\\contoso.com\SYSVOL\contoso.com\Just-In-Time\delegation.config")
$delegations.AddDelegation(
	"OU=Servers,DC=contoso,DC=com",
	"S-1-5-21-1000000000-2000000000-3000000000-1234"
)
$json = [KjitCore.KjitCore]::SerializeDelegationConfiguration($delegations)
```

## Delegationslogik

KjitCore ist die einzige Implementierung fuer das Delegationsschema
`ComputerOU`/`ADObject`, SID-Normalisierung, JSON-Parsing und -Serialisierung sowie
Add/Remove-Mutationen. PowerShell und KjitWeb verwenden diese API gemeinsam.

Host-spezifisch bleiben nur Active-Directory-Aufloesung, Berechtigungspruefung,
Konflikterkennung und atomarer Dateiaustausch.

## Naechste Migrationskandidaten

- `ConvertFrom-DN2Dns`
- `Get-UserElevationStatus`
