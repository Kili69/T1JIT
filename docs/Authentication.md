# KjitWeb Authentication

KjitWeb supports two authentication methods:

## 1. Windows Authentication (Negotiate/Kerberos/NTLM)

**Used for**: Local network users, domain-joined clients

- Automatically negotiates credentials for seamless login
- Uses Kerberos for optimal performance
- Falls back to NTLM if Kerberos unavailable
- **No manual login required** - uses your Windows identity

**Requirements**:
- Client must be on the domain (bloedgelaber.de)
- Browser must support Negotiate authentication
- Server and client must have proper SPNs configured

## 2. Basic Authentication (Fallback)

**Used for**: Remote users, non-domain clients, when Negotiate fails

- Requires manual login with domain credentials
- Format: `DOMAIN\username` or `username@bloedgelaber.de`
- **HTTPS only recommended** for remote connections (avoid sending credentials over HTTP)

### How to Login with Basic Auth

#### Via Browser
If Negotiate fails, your browser will show a login prompt. Enter:
```
Username: bloedgelaber\your_username
Password: your_password
```

#### Via Command Line (curl, PowerShell)
```powershell
# PowerShell Invoke-WebRequest
$cred = New-Object System.Management.Automation.PSCredential(
    "bloedgelaber\username",
    (ConvertTo-SecureString "password" -AsPlainText -Force)
)
Invoke-WebRequest -Uri "https://servername:7240" -Credential $cred

# curl
curl -u "bloedgelaber\username:password" https://servername:7240/
```

## Priority Order

1. **Negotiate** (Windows Auth) - Tries first
2. **Basic Auth** - If Negotiate fails or no Windows credentials available
3. **Challenge** - If credentials missing, returns 401 with WWWAuthenticate header

## Security Notes

- Basic Auth sends credentials in Base64 encoding (not encryption!)
- **Always use HTTPS for Basic Auth** over untrusted networks
- Credentials are never persisted or cached on the server
- Use group policy or certificate pinning for additional security

## Troubleshooting

### "401 Unauthorized" on login
- Verify credentials are correct (`DOMAIN\username`, not just `username`)
- Check domain connectivity from client
- Try HTTPS endpoint (port 7240) instead of HTTP
- Check Windows Event Log for authentication failures

### Negotiate not working but Basic Auth works
- DNS and Kerberos might be misconfigured
- Try explicit Basic Auth for reliable remote access
- Contact IT to verify SPN registration: `HTTP/servername` and `HTTPS/servername`

### Can't login from remote client
- Use Basic Auth as fallback (requires HTTPS for security)
- Verify firewall allows outbound LDAP queries (port 389)
- Check that remote client can resolve `bloedgelaber.de` domain

## Configuration

The application uses:
- **Kestrel HTTP/1.1**: Forces HTTP/1.1 to prevent multiplexing issues with Negotiate
- **Persistent credentials**: Both Kerberos and NTLM credentials are persisted
- **Dynamic domain detection**: Automatically uses bloedgelaber.de domain from environment
