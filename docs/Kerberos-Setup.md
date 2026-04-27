# Kerberos Authentifizierung für KjitWeb

## Überblick

KjitWeb verwendet **Kerberos als primäre Authentifizierungsmethode**. Dies bietet:
- ✅ Gegenseitige Authentifizierung (Server und Client authentifizieren sich gegenseitig)
- ✅ Verschlüsselte Kommunikation
- ✅ Bessere Performance als NTLM
- ✅ Single Sign-On (SSO) Unterstützung
- ✅ Ticket-basiertes System

## Anforderungen

### 1. Service Principal Names (SPNs) registrieren

Für Kerberos zu funktionieren, müssen Service Principal Names auf dem KjitWeb-Server registriert sein.

**Registrierung durchführen** (als Administrator auf dem Server):

```powershell
# Für HTTP (falls ohne SSL)
setspn -A HTTP/servername.bloedgelaber.de domain_account

# Für HTTPS (empfohlen)
setspn -A HTTPS/servername.bloedgelaber.de domain_account

# Für Localhost (Testing)
setspn -A HTTP/localhost domain_account
setspn -A HTTPS/localhost domain_account
```

**Beispiel**:
```powershell
setspn -A HTTPS/jit-web.bloedgelaber.de BLOEDGELABER\kjitservice
```

### 2. Active Directory Anforderungen

- Der Server muss auf der Domain bloedgelaber.de registered sein
- Der Service Account muss ein gültiges Active Directory-Konto sein
- KDC (Kerberos Distribution Center) muss erreichbar sein (Port 88, 464)

### 3. Netzwerk-Anforderungen

- DNS muss korrekt konfiguriert sein
- Bidirektionale DNS-Auflösung (Forward + Reverse)
- Zeitsynchronisation zwischen Client und Server (max. 5 Minuten Abweichung)

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
builder.Services.AddAuthentication(NegotiateDefaults.AuthenticationScheme)
    .AddNegotiate(options =>
    {
        options.PersistKerberosCredentials = true;
        options.PersistNtlmCredentials = false;  // Nur Kerberos
    });
```

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
# Aktuelle SPNs des Accounts anzeigen
setspn -L BLOEDGELABER\kjitservice

# Sollte anzeigen:
# HTTPS/jit-web.bloedgelaber.de
# HTTP/jit-web.bloedgelaber.de
```

**In AD-Richtlinie konfigurieren** (Domänen-Admin):

```powershell
# Mit AD-Tools
Get-ADUser kjitservice -Properties ServicePrincipalNames
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
# SPNs neu registrieren
setspn -D HTTPS/servername domain_account
setspn -A HTTPS/servername domain_account

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
Kerberos-Tickets werden am Client automatisch gecacht. Persistente Credentials ermöglichen Wiederverwendung:

```csharp
options.PersistKerberosCredentials = true;  // ← Aktiviert Ticket-Wiederverwendung
```

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
