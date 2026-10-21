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
- liest Reservierungen und TLS-Bindungen mit `netsh http show urlacl` und
  `netsh http show sslcert` (nicht mit dem wirkungslosen `netsh http dump`);
- stoppt den Dienst vor dem Ersetzen seiner passenden HTTP-Reservierungen
  und sichert deren urspruengliche SDDL-Berechtigungen fuer die Wiederherstellung;
- reserviert die HTTPS-URLs fuer das aktuelle Dienstkonto und bindet das
  Zertifikat fuer IPv4 und IPv6 im lokalen Computerspeicher;
- behaelt alle anderen Dienst-Umgebungsvariablen und Firewallregeln bei;
- startet den Dienst neu (auch einen zuvor gestoppten Dienst);
- prueft das gebundene Zertifikat, den DNS-Namen und eine HTTPS-Antwort
  (auch 401/403 sind bei Windows-Authentifizierung erwartete Antworten);
- stellt bei einem Fehler die vorherigen Einstellungen und den Dienstzustand
  einschliesslich entfernter HTTP-Reservierungen mit ihren urspruenglichen
  Berechtigungen wieder her und meldet auch etwaige Fehler der Wiederherstellung;
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

### Benutzerwechsel und Smartcard-Anmeldung

Unter **Benutzer wechseln** gibt es drei getrennte Wege:

- **Zur Windows-Identitaet zurueckkehren** entfernt nur das KjitWeb-Sitzungscookie.
  Danach verwendet die Anwendung wieder die vom Browser ausgehandelte
  Windows-Authentifizierung. Es wird kein Windows-Benutzer abgemeldet; ein
  anderer Windows-Kontext wird dadurch nicht erzwungen.
- **Mit Kennwort anmelden** behaelt die bisherige Kennwortpruefung bei.
  Eine Smartcard-PIN ist kein AD-Kennwort und darf hier nicht eingegeben werden.
- **Mit Smartcard anmelden** verwendet das im TLS-Handshake vorgelegte
  Clientzertifikat. Diese Option ist standardmaessig deaktiviert.
  Die PIN verarbeitet ausschliesslich das Betriebssystem bzw. die Kartenmiddleware.

#### Voraussetzungen fuer direkte Smartcard-Anmeldung

1. Direkte HTTPS-Verbindung zum KjitWeb-Dienst; Zertifikatweiterleitungsheader von
   Reverse-Proxys werden nicht als Identitaetsnachweis akzeptiert.
2. Smartcard-Leser und Kartenmiddleware auf dem Client sowie ein Browser, der
   das Karten-Zertifikat fuer TLS-Clientauthentifizierung verwenden kann.
3. Das Clientzertifikat muss gueltig sein, zu einer auf dem Server vertrauenswuerdigen
   CA verketten und beide EKUs enthalten: Client Authentication
   (`1.3.6.1.5.5.7.3.2`) und Smart Card Logon (`1.3.6.1.4.1.311.20.2.2`).
   Der Server muss die Sperrinformationen der CA erreichen koennen.
   Sperrpruefung ist fuer diese Anmeldung immer aktiv; die Einstellung
   `MutualTls:CheckCertificateRevocation` schaltet sie nicht ab.
4. In der bestehenden HTTP.sys-TLS-Bindung muss `clientcertnegotiation=enable`
   eingerichtet sein, fuer IPv4 und IPv6 bzw. die verwendete SNI-Bindung.
   Zuerst `netsh http show sslcert` verwenden und die vorhandenen Bindungswerte
   sichern. Ein Administrator muss die passende Bindung mit `netsh http update sslcert`
   aktualisieren und dabei Zertifikathash, App-ID und weitere bestehende Optionen
   erhalten. Die Anwendung veraendert keine TLS-Bindung automatisch.
   Clientzertifikate werden beim Verbindungsaufbau angefragt, nicht erst beim
   Anklicken des Buttons; TLS-Renegotiation wird nicht verwendet.
5. Genau ein aktives, nicht gesperrtes und nicht abgelaufenes Benutzerkonto in der
   konfigurierten AD-Domain muss unter `altSecurityIdentities` die starke
   Public-Key-Zuordnung `X509:<SHA1-PUKEY>...` besitzen.
   Eine UPN, ein Anzeigename oder der Subject des Zertifikats allein wird
   ausdruecklich **nicht** zur Anmeldung verwendet.
   Ein SID-Zertifikat allein ersetzt diese explizite Zuordnung in KjitWeb nicht.

Der folgende Befehl berechnet die Zuordnung aus einem **oeffentlichen**
Karten-Zertifikat; er aendert keine AD-Eigenschaften:

```powershell
$certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
    (Resolve-Path ".\smartcard-user.cer").Path)
$sha1 = [System.Security.Cryptography.SHA1]::Create()
try {
    $keyHash = $sha1.ComputeHash($certificate.GetPublicKey())
    $mapping = "X509:<SHA1-PUKEY>" + [BitConverter]::ToString($keyHash).Replace("-", "")
    $mapping
}
finally {
    $sha1.Dispose()
    $certificate.Dispose()
}
```

`SHA1-PUKEY` bezeichnet hier das standardisierte AD-Mapping eines oeffentlichen
Schluessels, keine Freigabe SHA-1-signierter Zertifikate.
Ein AD-Administrator muss Zertifikat, Kontoinhaber und Zielkonto unabhaengig
pruefen und diese Zuordnung zum richtigen Konto **hinzufuegen**, ohne bestehende
Zuordnungen zu ueberschreiben. Fehlende oder mehrdeutige Zuordnungen fuehren
zur Ablehnung. Das Dienstkonto benoetigt nur Lesezugriff; die Anwendung schreibt
keine Zertifikatszuordnungen ins AD.

Erst nach Erfuellen dieser Voraussetzungen in der Konfiguration des
installierten Dienstes aktivieren und den Dienst neu starten:

```json
{
  "SmartCardAuthentication": {
    "Enabled": true
  }
}
```

Die separate Option `MutualTls:Enabled` muss dafuer nicht eingeschaltet werden.
Sie erzwingt weiterhin ein Clientzertifikat fuer **alle** Anfragen und ist kein
Schalter fuer die AD-Kontozuordnung.

Nach erfolgreicher Anmeldung zeigt die Anwendung den aus dem AD gelesenen
Benutzernamen an. Die Smartcard-Sitzung ist ein nicht persistentes Cookie,
maximal 30 Minuten gueltig, nicht gleitend verlaengerbar und nie laenger gueltig
als das Zertifikat. Kartenentnahme oder eine spaetere Zertifikatssperrung beendet
ein bereits ausgestelltes Sitzungscookie nicht sofort. Vor Verlassen des Clients
zur Windows-Identitaet zurueckkehren bzw. die Sitzung beenden.

Die Anwendung kann weder die Karten-PIN lesen noch eine neue Zertifikatsauswahl
erzwingen. Browser koennen Zertifikate und TLS-Verbindungen zwischenspeichern.
Fuer ein anderes Kartenkonto gegebenenfalls alle Browserprozesse schliessen oder
eine separate Browserinstanz mit eigenem Profil verwenden; ein Inkognito-Fenster
allein garantiert keinen Wechsel. Danach die angezeigte Identitaet kontrollieren.
Die App prueft Zertifikate, nicht die physische Speicherung des Schluessels:
Hardwarebindung muss die PKI mit passender Kartenvorlage und nicht exportierbaren
Schluesseln sicherstellen.

#### Automatisierte Tests

Im Repository-Stamm unter Windows:

```powershell
dotnet test .\tests\KjitWeb.Tests\KjitWeb.Tests.csproj
```

Die Tests pruefen Zertifikatsverwendung, Vertrauensketten, Ablauf,
Kontostatus, eindeutige Zuordnung und die Sitzungswechsel einschliesslich
Fehlerfaellen. Ein echter Karten-/PIN-/Browser-Test gegen die eigene PKI bleibt
fuer die Inbetriebnahme erforderlich.

### Elevation

1. Benutzer authentifiziert sich mit seinem Windows-Account.
2. Dropdown wird mit Computernamen aus den in JIT.config konfigurierten `T1Searchbase`-LDAP-Pfaden gefuellt.
3. Beim Auswaehlen eines Servers und Absenden wird Event ID `100` in `Tier 1 Management` geschrieben.
4. Eventtext enthaelt den Distinguished Name des Benutzers und den ausgewaehlten Server.
