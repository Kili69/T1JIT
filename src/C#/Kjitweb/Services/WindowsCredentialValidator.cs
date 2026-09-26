// Author: Andreas Lucas (aka Kili)
// Documentation update: 0.2.20260926.6
// History: Completed API documentation; existing credential validation behavior is preserved.

using System.Runtime.InteropServices;

namespace KjitWeb.Services;

/// <summary>Validates supplied credentials against the Windows security authority.</summary>
/// <remarks>
/// Validation uses a Windows network logon, which checks credentials without requiring
/// interactive-logon rights. The plaintext password is passed directly to Windows and is not
/// stored or logged. This service is Windows-only.
/// </remarks>
public class WindowsCredentialValidator
{
    /// <summary>
    /// Requests Windows credential validation and returns a native access-token handle on success.
    /// </summary>
    /// <param name="lpszUsername">The Windows user name or UPN.</param>
    /// <param name="lpszDomain">The Windows domain, or <see langword="null"/> for a UPN.</param>
    /// <param name="lpszPassword">The plaintext password to validate.</param>
    /// <param name="dwLogonType">The requested Windows logon type.</param>
    /// <param name="dwLogonProvider">The Windows logon provider.</param>
    /// <param name="phToken">Receives the native token handle when validation succeeds.</param>
    /// <returns><see langword="true"/> when Windows accepts the credentials; otherwise, <see langword="false"/>.</returns>
    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern bool LogonUser(
        string lpszUsername,
        string? lpszDomain,
        string lpszPassword,
        int dwLogonType,
        int dwLogonProvider,
        out IntPtr phToken);

    /// <summary>Releases a native Windows handle.</summary>
    /// <param name="hHandle">The native handle to release.</param>
    /// <returns><see langword="true"/> when the handle is closed; otherwise, <see langword="false"/>.</returns>
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr hHandle);

    /// <summary>Requests validation without an interactive logon or local interactive-logon rights.</summary>
    private const int LOGON32_LOGON_NETWORK = 3;

    /// <summary>Directs Windows to select its default logon provider.</summary>
    private const int LOGON32_PROVIDER_DEFAULT = 0;

    /// <summary>The domain used for user names that do not specify one.</summary>
    private readonly string _defaultDomain;

    /// <summary>The logger used to record validation outcomes without passwords.</summary>
    private readonly ILogger<WindowsCredentialValidator> _logger;

    /// <summary>Initializes a new instance of the <see cref="WindowsCredentialValidator"/> class.</summary>
    /// <param name="configuration">
    /// Configuration containing the optional <c>ActiveDirectory:DefaultDomain</c> value.
    /// </param>
    /// <param name="logger">The logger used to record normalized identities and outcomes.</param>
    /// <exception cref="NullReferenceException">
    /// Thrown when <paramref name="configuration"/> is <see langword="null"/>.
    /// </exception>
    public WindowsCredentialValidator(IConfiguration configuration, ILogger<WindowsCredentialValidator> logger)
    {
        _logger = logger;
        _defaultDomain = configuration["ActiveDirectory:DefaultDomain"] ?? string.Empty;
    }

    /// <summary>
    /// Validates Windows credentials and produces the identity form used for logging and callers.
    /// </summary>
    /// <param name="rawUsername">
    /// A <c>DOMAIN\user</c> name, UPN, or unqualified user name. A UPN is passed intact with a null
    /// domain; an unqualified name uses the configured default domain when nonblank.
    /// </param>
    /// <param name="password">The plaintext password passed to Windows for validation.</param>
    /// <param name="normalizedIdentity">
    /// Receives <c>DOMAIN\user</c> when a domain is used, or the input user/UPN otherwise. It is set
    /// before Windows validation and therefore receives a value on both success and failure.
    /// </param>
    /// <returns><see langword="true"/> when Windows accepts the credentials; otherwise, <see langword="false"/>.</returns>
    /// <remarks>
    /// A successful native token is closed before this method returns. The normalized identity and
    /// result are logged, but the password is not. Native invocation failures can propagate, and
    /// the return value of <c>CloseHandle</c> is not inspected.
    /// </remarks>
    /// <exception cref="NullReferenceException">
    /// Thrown when <paramref name="rawUsername"/> is <see langword="null"/>.
    /// </exception>
    /// <exception cref="DllNotFoundException">Thrown when the Windows native libraries are unavailable.</exception>
    /// <exception cref="EntryPointNotFoundException">Thrown when a required Windows API entry point is unavailable.</exception>
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
