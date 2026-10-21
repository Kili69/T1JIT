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

### 4. HTTP auf HTTPS am gleichen Port umstellen

KjitWeb verwendet HTTP.sys. Das Skript `enable-kjitweb-https.ps1` stellt einen
bereits installierten Dienst von HTTP auf HTTPS um (Standardport 5240). Es gibt
zwei Betriebsarten; genau eine muss angegeben werden:

| Modus | Pflichtparameter | Zertifikat |
|-------|------------------|------------|
| Selbstsigniert (Test) | `-SelfSigned -DnsName <Name>` | wird neu erstellt (drei Monate gueltig) |
| Vorhandenes Zertifikat | `-Thumbprint <Thumbprint>` | aus `Cert:\LocalMachine\My` |

Auf dem Diensthost in einer PowerShell **als Administrator** ausfuehren:

```powershell
# Variante A: selbstsigniertes Testzertifikat (DNS-Namen anpassen).
.\enable-kjitweb-https.ps1 -SelfSigned -DnsName "server01.contoso.local" -WhatIf
.\enable-kjitweb-https.ps1 -SelfSigned -DnsName "server01.contoso.local", "server01" `
    -CertificatePath "C:\Temp\KjitWeb-test.cer"

# Variante B: vorhandenes Zertifikat aus dem Computerspeicher "Eigene Zertifikate".
Get-ChildItem Cert:\LocalMachine\My | Format-List Subject, DnsNameList, Thumbprint, NotAfter
.\enable-kjitweb-https.ps1 -Thumbprint "0123456789ABCDEF0123456789ABCDEF01234567" -WhatIf
.\enable-kjitweb-https.ps1 -Thumbprint "0123456789ABCDEF0123456789ABCDEF01234567"
```

Ein vorhandenes Zertifikat muss im Speicher `LocalMachine\My` liegen, einen
privaten Schluessel besitzen, aktuell gueltig sein, (falls EKUs gesetzt sind) die
Verwendung Serverauthentifizierung (`1.3.6.1.5.5.7.3.1`) enthalten und den
DNS-Namen im SAN fuehren, ueber den Clients zugreifen. Ohne `-DnsName` wird der
erste nicht-Wildcard-Name des Zertifikats fuer die Pruefung verwendet; bei reinen
Wildcard-Zertifikaten (z. B. `*.contoso.local`) ist `-DnsName` anzugeben. Leer- und
unsichtbare Zeichen im kopierten Thumbprint werden entfernt. Clients muessen der
ausstellenden CA vertrauen. Das Zertifikat wird bei einem Fehler nicht geloescht.

Die Aufrufe sind Alternativen, nicht nacheinander auszufuehren.
Anschliessend lautet die Adresse `https://server01.contoso.local:5240/`.
HTTP ist an diesem Endpunkt nicht mehr verfuegbar; HTTP und HTTPS koennen hier
nicht gleichzeitig denselben Port verwenden.

Das Skript:

- uebernimmt die Hosts aus `ASPNETCORE_URLS`, ohne den Zugriff auszuweiten;
- reserviert die HTTPS-URLs fuer das aktuelle Dienstkonto und bindet das
  Zertifikat fuer IPv4 und IPv6 im lokalen Computerspeicher;
- behaelt alle anderen Dienst-Umgebungsvariablen und Firewallregeln bei;
- startet den Dienst neu (auch einen zuvor gestoppten Dienst);
- prueft das gebundene Zertifikat, den DNS-Namen und eine HTTPS-Antwort
  (auch 401/403 sind bei Windows-Authentifizierung erwartete Antworten);
- stellt bei einem Fehler die vorherigen Einstellungen und den Dienstzustand
  wieder her und meldet auch etwaige Fehler der Wiederherstellung;
- bricht bei vorhandenen TLS-Bindungen auf dem Port oder vorhandenen Ziel-URL-
  Reservierungen ab, statt diese zu ersetzen. Es ist kein Zertifikatswechsel-Skript.

Nur im Modus `-SelfSigned` wird eine Datei exportiert. Sie enthaelt
**nur das oeffentliche Zertifikat**, keinen privaten
Schluessel. Standardziel ist `KjitWeb-test.cer` im aktuellen Verzeichnis; vorhandene
Dateien werden nicht ueberschrieben. Zur Vertrauensstellung die Datei sicher auf
den Testclient uebertragen und den Thumbprint mit der Skriptausgabe abgleichen:

```powershell
# Nur auf Testclients und nur nach Pruefung des Zertifikats:
Import-Certificate -FilePath ".\KjitWeb-test.cer" `
    -CertStoreLocation "Cert:\CurrentUser\Root"
```

Das Skript selbst aendert keinen Vertrauensspeicher. Selbstsignierte Zertifikate
sind ausschliesslich fuer Tests vorgesehen; produktiv ein von der Unternehmens-PKI
oder einer anderen vertrauenswuerdigen CA ausgestelltes Zertifikat verwenden.
Die Pruefung auf dem Server ersetzt keinen Browser-Test vom berechtigten Client.
`MutualTls:Enabled` bleibt unveraendert; fuer normales HTTPS ist kein
Clientzertifikat erforderlich.

`update-kjitweb.ps1` behaelt die HTTPS-Adresse bei. Auch
`set-kjitweb-allowedclient.ps1` erhaelt das konfigurierte HTTPS-Schema.
Eine Neuinstallation mit `install-kjitweb.ps1` setzt dagegen wieder HTTP.

### 5. Optional: HTTPS-Weiterleitung im Dienst aktivieren

Standardmaessig ist HTTPS-Weiterleitung im Windows-Dienstmodus aus, damit der Dienst ohne Serverzertifikat startet. Wenn ein gueltiges HTTPS-Setup vorhanden ist, kann sie in `appsettings.json` aktiviert werden:

Bei ausschliesslichem HTTPS auf Port 5240 ist keine Weiterleitung erforderlich.
Die Option allein erstellt weder ein Zertifikat noch eine HTTPS-Bindung.

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
