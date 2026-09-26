# Kerberos Authentifizierung für KjitWeb

## Überblick

KjitWeb verwendet **Kerberos als primäre Authentifizierungsmethode**. Dies bietet:
- ✅ Gegenseitige Authentifizierung (Server und Client authentifizieren sich gegenseitig)
- ✅ Verschlüsselte Kommunikation
- ✅ Bessere Performance als NTLM
- ✅ Single Sign-On (SSO) Unterstützung
- ✅ Ticket-basiertes System

KjitWeb wird über **HTTP.sys** gehostet (nicht Kestrel), genau wie IIS. Windows-Authentifizierung
(Negotiate/Kerberos/NTLM) läuft dadurch im Kernel-Modus des Betriebssystems und nicht im
KjitWeb-Prozess selbst. Deshalb kann der Windows-Dienst als **NetworkService** laufen (statt als
LocalSystem oder als dedizierter Domänen-Dienstkonto): NetworkService präsentiert im Netzwerk die
**Computerkonto-Identität** des Servers, genau wie ein IIS-Anwendungspool. Das bedeutet auch, dass
die benötigten SPNs auf dem **Computerkonto** liegen, nicht auf einem separaten Dienstkonto.

> Wurde KjitWeb vor der HTTP.sys-Migration installiert und läuft aktuell mit einem eigenen
> Domänen-Dienstkonto samt eigener SPNs, sind diese SPNs nach einem Update auf NetworkService
> nicht mehr nötig und können vom Konto entfernt werden (`setspn -D ... domain_account`).

## Anforderungen

### 1. Service Principal Names (SPNs) registrieren

Für Kerberos zu funktionieren, müssen Service Principal Names auf dem **Computerkonto** des
KjitWeb-Servers registriert sein (nicht auf einem Benutzer- oder Dienstkonto). Standardmäßig
besitzt jedes domänenbeigetretene Computerkonto bereits `HOST/servername` sowie
`HOST/servername.domain.tld`; für den HTTP-Dienst müssen zusätzlich `HTTP`-SPNs ergänzt werden.

> **Automatische Registrierung**: `install-kjitweb.ps1`, `update-kjitweb.ps1` und
> `set-kjitweb-allowedclient.ps1` prüfen bei jeder Installation/Aktualisierung automatisch, ob
> `HTTP/<hostname>` und `HTTP/<fqdn>` auf dem Computerkonto vorhanden sind, und registrieren sie
> bei Bedarf selbst — sofern `AllowedClient` nicht auf `localhost` steht (rein lokaler Zugriff
> läuft über NTLM und benötigt keine SPNs). Fehlt dem ausführenden Konto die Berechtigung, das
> Computerkonto zu ändern (i. d. R. Domänen-Administrator-Rechte oder delegiertes "Validated
> write to service principal name"), wird eine deutliche Warnung mit dem passenden manuellen
> `setspn -A`-Befehl ausgegeben; die Installation/Aktualisierung wird dadurch **nicht**
> abgebrochen. Die manuellen Schritte unten bleiben als Fallback gültig, falls die automatische
> Registrierung fehlschlägt.

**Manuelle Registrierung durchführen** (als Domänen-Administrator, `$$` markiert das Computerkonto):

```powershell
# Für HTTP (falls ohne SSL)
setspn -A HTTP/servername.bloedgelaber.de servername$

# Für HTTPS (empfohlen)
setspn -A HTTPS/servername.bloedgelaber.de servername$
```

**Beispiel**:
```powershell
setspn -A HTTPS/jit-web.bloedgelaber.de JIT-WEB$
```

Für reinen `http://localhost:<port>`-Zugriff (z. B. lokale Tests auf dem Server selbst) sind
**keine** zusätzlichen SPNs nötig; Windows verwendet dafür NTLM über die Loopback-Adresse.

### 2. Active Directory Anforderungen

- Der Server muss auf der Domain bloedgelaber.de registered sein
- KDC (Kerberos Distribution Center) muss erreichbar sein (Port 88, 464)

### 3. Netzwerk-Anforderungen

- DNS muss korrekt konfiguriert sein
- Bidirektionale DNS-Auflösung (Forward + Reverse)
- Zeitsynchronisation zwischen Client und Server (max. 5 Minuten Abweichung)

### 4. HTTP.sys URL-Reservierung

Da HTTP.sys (anders als Kestrel) entweder Administratorrechte oder eine explizite
URL-Namensraum-Reservierung benötigt, damit ein nicht-administrativer Dienstaccount wie
NetworkService einen HTTP-Port binden darf, legen `install-kjitweb.ps1` und `update-kjitweb.ps1`
diese Reservierung automatisch an:

```powershell
netsh http add urlacl url=http://*:5240/ user="NT AUTHORITY\NETWORK SERVICE"
```

Diese Reservierung ist mit `netsh http show urlacl` überprüfbar und wird bei jeder Installation
bzw. jedem Update erneuert.

## Konfiguration

### In appsettings.Development.json

```json
{
  "Kerberos": {
    "Enabled": true,
    "RequiresMutualAuthentication": true,
    "PreferredAuthMethod": "Kerberos"
  }
}
```

### In Program.cs

```csharp
builder.Services.AddAuthentication(HttpSysDefaults.AuthenticationScheme);
builder.WebHost.UseHttpSys(options =>
{
    options.Authentication.Schemes = AuthenticationSchemes.Negotiate | AuthenticationSchemes.NTLM;
    options.Authentication.AllowAnonymous = true;
});
```

Die eigentliche Kerberos/NTLM-Aushandlung übernimmt HTTP.sys im Kernel; die App erhält nur noch
die bereits authentifizierte Windows-Identität.

## Authentifizierungsfluss

```
Client Request
    ↓
[1] Browser sendet Kerberos Ticket
    ↓
[2] Server validiert Ticket mit KDC
    ↓
[3] Server authentifiziert Benutzer
    ↓
✅ Zugriff gewährt / 401 Unauthorized
```

## SPN-Verification

**SPNs überprüfen**:

```powershell
# Aktuelle SPNs des Computerkontos anzeigen
setspn -L JIT-WEB$

# Sollte anzeigen:
# HTTPS/jit-web.bloedgelaber.de
# HTTP/jit-web.bloedgelaber.de
```

**In AD-Richtlinie konfigurieren** (Domänen-Admin):

```powershell
# Mit AD-Tools
Get-ADComputer JIT-WEB -Properties ServicePrincipalNames
```

## Troubleshooting

### "401 Unauthorized" trotz korrektem Passwort

**Ursachen**:
- SPNs nicht registriert → `setspn -L account` überprüfen
- Zeitsynchronisation falsch → `w32tm /query /status` auf beiden Systemen
- DNS-Reverse-Lookup fehlgeschlagen → `nslookup IP` testen
- Firewall blockiert Port 88 (KDC)

**Lösungen**:
```powershell
# SPNs neu registrieren (auf dem Computerkonto)
setspn -D HTTPS/servername servername$
setspn -A HTTPS/servername servername$

# Zeitsync überprüfen
w32tm /resync /force

# DNS testen
nslookup jit-web.bloedgelaber.de
nslookup IP-ADDRESS
```

### "Negotiate not working" bei Remote-Zugriff

**Fallback auf Basic Auth**:
- Wenn Kerberos fehlschlägt, nutzt KjitWeb automatisch HTTP Basic Auth
- Credentials im Format: `BLOEDGELABER\username:password`
- **HTTPS wird empfohlen** für Basic Auth über Remote

### Kerberos-Logging aktivieren

```powershell
# Event Log für Kerberos öffnen
eventvwr.msc
# Navigiere zu: Windows Logs → Security

# CLI-Logging für Negotiate
[HKLM:\System\CurrentControlSet\Control\SecurityProviders\SCHANNEL]
# EnableLogging = 1
```

## Performance-Optimierungen

### Ticket-Caching
Kerberos-Tickets werden am Client automatisch gecacht. Auf Serverseite übernimmt HTTP.sys das
Zwischenspeichern und die Wiederverwendung von Sicherheitskontexten selbst; es ist keine
zusätzliche Konfiguration in `Program.cs` nötig (anders als früher mit
`PersistKerberosCredentials` beim verwalteten Negotiate-Handler unter Kestrel).

### Mutual Authentication
Server und Client authentifizieren sich gegenseitig - verhindert Man-in-the-Middle:

```csharp
// In appsettings.json
"Kerberos": {
  "RequiresMutualAuthentication": true
}
```

## Vergleich: Kerberos vs. NTLM

| Feature | Kerberos | NTLM |
|---------|----------|------|
| Gegenseitige Auth | ✅ Ja | ❌ Nein |
| Verschlüsselung | ✅ Stark | ⚠️ Schwächer |
| Single Sign-On | ✅ Ja | ❌ Nein |
| Performance | ✅ Besser | ⚠️ Langsamer |
| Sicherheit | ✅ Besser | ❌ Veraltet |
| Tickets | ✅ Token-basiert | ⚠️ Challenge-Response |

## Fallback-Verhalten

Falls Kerberos fehlschlägt:
1. **Negotiate versucht NTLM** (wenn Client nicht unterstützt)
2. **Basic Auth Fallback** (wenn NTLM auch fehlschlägt)
3. **401 Unauthorized** (wenn keine Auth möglich)

```
Kerberos (Primary)
    ↓ Falls fehlgeschlagen
NTLM (Secondary)
    ↓ Falls fehlgeschlagen
Basic Auth (Fallback)
    ↓ Falls fehlgeschlagen
401 Unauthorized
```

## Security Best Practices

- ✅ Verwende HTTPS/TLS für alle Verbindungen
- ✅ Halte Service Account Passwort sicher
- ✅ Registriere nur notwendige SPNs
- ✅ Verwende Kerberos wenn möglich (statt NTLM)
- ✅ Überwache Security Event Log auf Auth-Fehler
- ✅ Synchronisiere Systemzeiten regelmäßig

## Weitere Ressourcen

- [Microsoft Kerberos Documentation](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-kile/2a32282e-dd48-4ad9-a542-609fb432882f)
- [Service Principal Names (SPNs)](https://learn.microsoft.com/en-us/windows/win32/ad/service-principal-names)
- [HTTP Negotiate Auth in .NET](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/windowsauth)
