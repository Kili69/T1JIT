# KjitWeb

Webanwendung mit Windows-Authentifizierung zur Auswahl von Servern aus dem Active Directory und Schreiben eines Events in das Eventlog.

## Anforderungen

- Windows Server/Client mit Domain Join
- .NET 10 SDK
- Berechtigung fuer Zugriff auf AD
- Berechtigung zum Schreiben ins Eventlog (inkl. ggf. Erstellen einer Event Source)

## Konfiguration

Die wichtigsten Einstellungen in `appsettings.json`:

Die Domain wird automatisch aus der Machine-Domain des Servers ermittelt. Alternativ kann sie in der JIT.config unter `Domain` oder in appsettings unter `ActiveDirectory:DomainFqdn` ueberschrieben werden.

EventLog-Einstellungen (Name und Source) werden vollstaendig aus der JIT.config gelesen:

- `EventLog`: Name des Eventlogs (z. B. `Tier 1 Management`)
- `EventLogSource`: Source-Name fuer das Eventlog (Pflichtwert)

Wichtig: Die Server-Suchbasis kommt ausschliesslich aus `T1Searchbase` in `JIT.config`. Wenn `T1Searchbase` fehlt oder keine gueltigen LDAP-Pfade enthaelt, beendet sich der Dienst beim Start mit einem Fehler und schreibt einen Fehler ins Windows Application Log.

Wichtig: Wenn `EventLogSource` in `JIT.config` fehlt oder leer ist, beendet sich der Dienst ebenfalls beim Start mit einem Fehler und schreibt einen Fehler ins Windows Application Log.

## Start

```powershell
cd c:\repos\kjitweb\KjitWeb
dotnet restore
dotnet run
```

Dann im Browser `https://localhost:7240` aufrufen.

## Betrieb als Windows-Dienst

### 1. Build/Publish

```powershell
cd c:\repos\kjitweb\KjitWeb
dotnet restore
dotnet publish .\KjitWeb.csproj -c Release -o .\publish
```

### 2. Dienst installieren

```powershell
sc.exe create KjitWeb binPath= "\"c:\repos\kjitweb\KjitWeb\publish\KjitWeb.exe\"" start= auto
sc.exe description KjitWeb "KjitWeb ASP.NET Core Windows Service"
```

Optional (empfohlen): URL fuer den Dienst als Umgebungsvariable setzen:

```powershell
sc.exe config KjitWeb obj= "NT AUTHORITY\NetworkService"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\KjitWeb" /v Environment /t REG_MULTI_SZ /d "ASPNETCORE_URLS=http://0.0.0.0:5240" /f
```

### 3. Dienst starten/stoppen

```powershell
sc.exe start KjitWeb
sc.exe stop KjitWeb
```

### 4. Optional: HTTPS-Weiterleitung im Dienst aktivieren

Standardmaessig ist HTTPS-Weiterleitung im Windows-Dienstmodus aus, damit der Dienst ohne Serverzertifikat startet. Wenn ein gueltiges HTTPS-Setup vorhanden ist, kann sie in `appsettings.json` aktiviert werden:

```json
{
	"Hosting": {
		"UseHttpsRedirection": true
	}
}
```

## Verhalten

1. Benutzer authentifiziert sich mit seinem Windows-Account.
2. Dropdown wird mit Computernamen aus den in JIT.config konfigurierten `T1Searchbase`-LDAP-Pfaden gefuellt.
3. Beim Auswaehlen eines Servers und Absenden wird Event ID `100` in `Tier 1 Management` geschrieben.
4. Eventtext enthaelt den Distinguished Name des Benutzers und den ausgewaehlten Server.
