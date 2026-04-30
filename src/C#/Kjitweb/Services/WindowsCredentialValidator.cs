using System.Runtime.InteropServices;

namespace KjitWeb.Services;

public class WindowsCredentialValidator
{
    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern bool LogonUser(
        string lpszUsername,
        string? lpszDomain,
        string lpszPassword,
        int dwLogonType,
        int dwLogonProvider,
        out IntPtr phToken);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr hHandle);

    private const int LOGON32_LOGON_NETWORK = 3;
    private const int LOGON32_PROVIDER_DEFAULT = 0;

    private readonly string _defaultDomain;
    private readonly ILogger<WindowsCredentialValidator> _logger;

    public WindowsCredentialValidator(IConfiguration configuration, ILogger<WindowsCredentialValidator> logger)
    {
        _logger = logger;
        _defaultDomain = configuration["ActiveDirectory:DefaultDomain"] ?? string.Empty;
    }

    /// <summary>
    /// Validates Windows credentials using LogonUser. Returns true on success and sets
    /// normalizedIdentity to the canonical "DOMAIN\user" or "user@domain" form.
    /// </summary>
    public bool Validate(string rawUsername, string password, out string normalizedIdentity)
    {
        string? domain;
        string user;

        if (rawUsername.Contains('\\'))
        {
            var idx = rawUsername.IndexOf('\\');
            domain = rawUsername[..idx];
            user = rawUsername[(idx + 1)..];
        }
        else if (rawUsername.Contains('@'))
        {
            // UPN logon: pass username as-is, domain = null
            domain = null;
            user = rawUsername;
        }
        else
        {
            // Plain username – use configured default domain
            domain = string.IsNullOrWhiteSpace(_defaultDomain) ? null : _defaultDomain;
            user = rawUsername;
        }

        normalizedIdentity = string.IsNullOrWhiteSpace(domain) ? user : $"{domain}\\{user}";

        if (LogonUser(user, domain, password, LOGON32_LOGON_NETWORK, LOGON32_PROVIDER_DEFAULT, out IntPtr token))
        {
            CloseHandle(token);
            _logger.LogInformation("Windows credential validation succeeded for {Identity}", normalizedIdentity);
            return true;
        }

        _logger.LogWarning("Windows credential validation failed for {Identity}", normalizedIdentity);
        return false;
    }
}
