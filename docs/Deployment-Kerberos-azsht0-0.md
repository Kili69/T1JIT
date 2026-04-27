# KjitWeb Deployment mit Kerberos (azsht0-0)

## Status: ✅ SPNs korrekt registriert

Deine Kerberos-SPNs sind bereits registriert:

```
HTTP/azsht0-0:5240
HTTP/azsht0-0.bloedgelaber.de:5240
HTTPS/azsht0-0.bloedgelaber.de:7240
HTTPS/azsht0-0
HTTPS/azsht0-0.bloedgelaber.de
HTTP/azsht0-0.bloedgelaber.de
HTTP/azsht0-0
```

Das ist eine **sehr gute** Konfiguration mit:
- ✅ FQDN mit Port (HTTP/azsht0-0.bloedgelaber.de:5240)
- ✅ Kurzer Name mit Port (HTTP/azsht0-0:5240)
- ✅ HTTPS Endpoint (HTTPS/azsht0-0.bloedgelaber.de:7240)
- ✅ Fallbacks für verschiedene Zugriffsmöglichkeiten

## Deployment-Schritte

### 1. App-Binaries vorbereiten

```powershell
# Release-Build erstellen
dotnet publish -c Release -o C:\KjitWeb\publish

# Oder direkt mit dotnet run
cd C:\Repos\T1JIT\src\C#\Kjitweb
dotnet run -c Release
```

### 2. Zugriffs-URLs

Mit den registrierten SPNs kannst du auf die App zugreifen über:

| URL | Typ | Einsatz |
|-----|------|---------|
| `https://azsht0-0.bloedgelaber.de:7240` | FQDN + HTTPS | Production (Kerberos) |
| `https://azsht0-0:7240` | Short Name + HTTPS | Lokales Netzwerk |
| `http://azsht0-0.bloedgelaber.de:5240` | FQDN + HTTP | Development |
| `http://azsht0-0:5240` | Short Name + HTTP | Lokales Testing |
| `https://localhost:7240` | Localhost | Lokales Debugging |

**Empfohlene URLs nach Umgebung**:
- **Production**: `https://azsht0-0.bloedgelaber.de:7240`
- **Development**: `http://azsht0-0:5240` oder `https://localhost:7240`

### 3. Service-Account-Anforderung

Die App sollte mit einem Domain-Service-Account laufen. Die SPNs sind auf Computerkonto `azsht0-0` registriert.

Falls Service-Account nötig:
```powershell
# Service-Account für KjitWeb erstellen (Optional)
New-ADUser -Name "kjitservice" `
  -UserPrincipalName "kjitservice@bloedgelaber.de" `
  -Path "OU=ServiceAccounts,DC=bloedgelaber,DC=de" `
  -Enabled $true `
  -ChangePasswordAtLogon $false `
  -PasswordNotRequired $false
```

### 4. Kerberos-Debugging

Falls Kerberos nicht funktioniert, überprüfe mit diesen Befehlen:

**SPN-Registrierung überprüfen**:
```powershell
# Sollte alle deine SPNs anzeigen
setspn -l azsht0-0

# Oder mit PowerShell
Get-ADComputer azsht0-0 -Properties ServicePrincipalNames | Select-Object -ExpandProperty ServicePrincipalNames
```

**Kerberos-Tickets überprüfen**:
```powershell
# Aktuell gecachte Tickets anzeigen
klist

# Alle Tickets löschen (für neuen Test)
klist purge

# Neues Ticket für HTTP Service anfordern
Invoke-WebRequest -Uri "https://azsht0-0.bloedgelaber.de:7240" -UseDefaultCredentials
```

**Event Log für Kerberos-Fehler**:
```powershell
# Windows Event Viewer öffnen
eventvwr.msc

# Im Event Viewer navigieren zu:
# Windows Logs → Security → Event ID 4768 (Ticket Request) und 4769 (Service Ticket)
```

**Network Trace für Debug**:
```powershell
# Starten Sie einen Netzwerk-Trace bei Kerberos-Fehlern
netsh trace start scenario=InternetClient level=verbose
# ...test durchführen...
netsh trace stop
```

### 5. Loggung für Production

**appsettings.Production.json** nutzt:
- `LogLevel.Default: Warning` (nur wichtige Logs)
- `LogLevel.KjitWeb: Information` (App-spezifische Logs)
- `AllowedHosts: azsht0-0,azsht0-0.bloedgelaber.de,*.bloedgelaber.de`

Das schützt die App vor Host Header Injection Angriffen.

## Authentifizierungs-Fallback

Falls Kerberos aus irgendeinem Grund fehlschlägt:

```
Request an https://azsht0-0.bloedgelaber.de:7240
    ↓
[Versuche 1] Kerberos (Negotiate) - Primary
    ↓ Falls fehlgeschlagen
[Versuche 2] NTLM - Fallback
    ↓ Falls fehlgeschlagen
[Versuche 3] Basic Auth - Fallback (mit Domain-Credentials)
    ↓ Falls fehlgeschlagen
401 Unauthorized
```

### Basic Auth manuell testen

```powershell
# Mit Base64-Encoding
$credential = "bloedgelaber\username:password"
$base64Credential = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($credential))

# Mit curl
curl -H "Authorization: Basic $base64Credential" https://azsht0-0.bloedgelaber.de:7240
```

## Windows Service Installation (Optional)

Falls du die App als Windows Service starten möchtest:

```powershell
# Service-Dateien vorbereiten
$publishPath = "C:\KjitWeb\publish"
$serviceName = "KjitWeb"
$servicePath = "$publishPath\KjitWeb.exe"

# Service installieren
New-Service -Name $serviceName `
  -BinaryPathName $servicePath `
  -DisplayName "KjitWeb - Just-In-Time Admin Access" `
  -StartupType Automatic `
  -Credential "bloedgelaber\kjitservice"

# Service starten
Start-Service -Name $serviceName

# Service-Status überprüfen
Get-Service -Name $serviceName
```

## HTTPS-Zertifikat

Für Production wird ein gültiges Zertifikat benötigt:

```powershell
# Zertifikat-Anforderung für azsht0-0.bloedgelaber.de
# Dies sollte vom IT durchgeführt werden:
# - Subject: azsht0-0.bloedgelaber.de
# - SubjectAltName (SAN): 
#   - azsht0-0
#   - azsht0-0.bloedgelaber.de

# In launchSettings.json oder appsettings wird der Pfad zu HTTPS-Zertifikat konfiguriert
# Falls nötig, über Umgebungsvariable:
$env:ASPNETCORE_URLS = "https://azsht0-0.bloedgelaber.de:7240;http://azsht0-0.bloedgelaber.de:5240"
```

## Reverse Proxy Setup (Optional)

Falls die App hinter einem Reverse Proxy (IIS, nginx, etc.) läuft:

**IIS Application Request Routing (ARR)**:
```xml
<!-- web.config -->
<rewrite>
  <rules>
    <rule name="ProxyToKjitWeb" stopProcessing="true">
      <match url="^(.*)" />
      <action type="Rewrite" url="http://localhost:5240/{R:1}" />
      <conditions>
        <add input="{HTTP_HOST}" pattern="^azsht0-0" />
      </conditions>
    </rule>
  </rules>
</rewrite>
```

## Sicherheits-Checkliste

- ✅ SPNs korrekt registriert (du hast das schon gemacht!)
- ⏳ HTTPS-Zertifikat gültig
- ⏳ DNS-Auflösung `azsht0-0` → IP verifizieren
- ⏳ Umgekehrte DNS-Auflösung (IP → `azsht0-0.bloedgelaber.de`) prüfen
- ⏳ Zeitsynchronisation: `w32tm /query /status`
- ⏳ Event Log auf Kerberos-Fehler prüfen
- ⏳ Firewall: Ports 5240 (HTTP) und 7240 (HTTPS) freigeben
- ⏳ Kerberos Port 88 (KDC) muss erreichbar sein

## Performance-Optimierungen

**HTTP/2 vs HTTP/1.1**:
- Aktuell: **HTTP/1.1** (wegen Kerberos Handshake)
- Pro: Stabilere Negotiate-Authentifizierung
- Contra: Weniger Parallelismus

Sobald Kerberos stabil läuft, kann HTTP/2 wieder aktiviert werden:

```csharp
// In Program.cs
listenOptions.Protocols = HttpProtocols.Http2;  // oder Http2
```

## Support & Troubleshooting

Falls Probleme auftreten:

1. **Logs anschauen**:
   ```powershell
   # Live Logs folgen
   Get-Content -Path "C:\Logs\kjit.log" -Wait
   ```

2. **Kerberos Debug aktivieren**:
   ```powershell
   # Registry (Admin PowerShell)
   Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\LSA\Kerberos" `
     -Name LogLevel -Value 1
   ```

3. **Netzwerk-Connectivity prüfen**:
   ```powershell
   # DNS auflösen
   [System.Net.Dns]::GetHostAddresses("azsht0-0.bloedgelaber.de")
   
   # Umgekehrter DNS
   [System.Net.Dns]::GetHostByAddress("IP-ADRESSE")
   
   # Kerberos-Server (KDC) erreichbar?
   nslookup -type=SRV _kerberos._tcp.bloedgelaber.de
   ```

## Referenzen

- [SPN-Registrierung: setspn -a](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-service-accounts)
- [Negotiate Auth in ASP.NET Core](https://docs.microsoft.com/en-us/aspnet/core/security/authentication/windowsauth)
- [Kerberos Authentifizierung Debugging](https://docs.microsoft.com/en-us/troubleshoot/windows-server/identity/kerberos-authentication-issues)
