// Author: Andreas Lucas (aka Kili)
// Documentation update: 0.2.20260926.6
// History: Completed API documentation; existing authentication behavior is preserved.

using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;
using System.Text.Encodings.Web;

namespace KjitWeb.Services;

/// <summary>
/// Authenticates HTTP Basic credentials against the Windows security authority.
/// </summary>
/// <remarks>
/// Credentials are decoded from UTF-8 Base64 and validated with a network logon. The handler
/// accepts <c>DOMAIN\user</c>, UPN, and unqualified user names; unqualified names use the
/// hard-coded <c>BLOEDGELABER</c> domain. Passwords are neither retained nor logged. Successful
/// validation creates a <see cref="GenericPrincipal"/> without role claims and closes the native
/// token handle. This handler is Windows-only and Basic authentication does not itself protect
/// credentials in transit, so callers must use TLS.
/// </remarks>
public class BasicAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    /// <summary>The HTTP request header containing authentication credentials.</summary>
    private const string AuthorizationHeaderName = "Authorization";

    /// <summary>The authentication scheme token recognized and emitted by this handler.</summary>
    private const string BasicScheme = "Basic";

    /// <summary>
    /// Requests Windows credential validation and returns a native access-token handle on success.
    /// </summary>
    /// <param name="lpszUsername">The Windows user name or UPN.</param>
    /// <param name="lpszDomain">The Windows domain, or <see langword="null"/> for a UPN.</param>
    /// <param name="lpszPassword">The plaintext password supplied by the client.</param>
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

    /// <summary>Initializes a new instance of the <see cref="BasicAuthenticationHandler"/> class.</summary>
    /// <param name="options">The monitor that supplies authentication scheme options.</param>
    /// <param name="logger">The factory used by the base handler to create its logger.</param>
    /// <param name="encoder">The URL encoder used by the base authentication handler.</param>
    /// <exception cref="ArgumentNullException">
    /// Thrown by the base authentication handler when a required dependency is <see langword="null"/>.
    /// </exception>
    public BasicAuthenticationHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder)
        : base(options, logger, encoder)
    {
    }

    /// <summary>Authenticates the current request's HTTP Basic credentials against Windows.</summary>
    /// <returns>
    /// A completed task containing no result when the Basic header is absent or uses another
    /// scheme, a failed result for malformed or rejected credentials, or a successful ticket for
    /// accepted credentials.
    /// </returns>
    /// <remarks>
    /// This method reads the request header, invokes the Windows <c>LogonUser</c> API, closes a
    /// successful token, and logs the normalized identity and outcome without logging the
    /// password. Parsing and platform errors are converted to failed authentication results.
    /// </remarks>
    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        // Check for Authorization header with Basic scheme.
        if (!Request.Headers.ContainsKey(AuthorizationHeaderName))
        {
            return Task.FromResult(AuthenticateResult.NoResult());
        }

        var authHeader = Request.Headers[AuthorizationHeaderName].ToString();
        if (!authHeader.StartsWith(BasicScheme, StringComparison.OrdinalIgnoreCase))
        {
            return Task.FromResult(AuthenticateResult.NoResult());
        }

        try
        {
            var encodedCredentials = authHeader[(BasicScheme.Length + 1)..].Trim();
            var decodedCredentials = Encoding.UTF8.GetString(Convert.FromBase64String(encodedCredentials));
            var colonIndex = decodedCredentials.IndexOf(':');

            if (colonIndex == -1)
            {
                return Task.FromResult(AuthenticateResult.Fail("Invalid credentials format."));
            }

            var username = decodedCredentials[..colonIndex];
            var password = decodedCredentials[(colonIndex + 1)..];

            // Accept DOMAIN\\user, user@domain, or plain user.
            string? domain = "BLOEDGELABER";
            string user = username;

            if (username.Contains('\\'))
            {
                var separatorIndex = username.IndexOf('\\');
                domain = username[..separatorIndex];
                user = username[(separatorIndex + 1)..];
            }
            else if (username.Contains('@'))
            {
                // UPN logon requires domain = null for LogonUser.
                domain = null;
                user = username;
            }

            // NETWORK logon validates credentials without requiring local interactive logon rights.
            if (LogonUser(user, domain, password, LOGON32_LOGON_NETWORK, LOGON32_PROVIDER_DEFAULT, out IntPtr token))
            {
                CloseHandle(token);
                var normalizedIdentity = string.IsNullOrWhiteSpace(domain) ? user : $"{domain}\\{user}";
                Logger.LogInformation("Basic authentication successful for user {Identity}", normalizedIdentity);

                var identity = new GenericIdentity(normalizedIdentity, Scheme.Name);
                var principal = new GenericPrincipal(identity, null);
                var ticket = new AuthenticationTicket(principal, Scheme.Name);
                return Task.FromResult(AuthenticateResult.Success(ticket));
            }

            var failedIdentity = string.IsNullOrWhiteSpace(domain) ? user : $"{domain}\\{user}";
            Logger.LogWarning("Basic authentication failed for user {Identity}", failedIdentity);
            return Task.FromResult(AuthenticateResult.Fail("Invalid Windows credentials."));
        }
        catch (FormatException)
        {
            return Task.FromResult(AuthenticateResult.Fail("Invalid Base64 encoding in Authorization header."));
        }
        catch (Exception ex)
        {
            Logger.LogWarning(ex, "Basic authentication error");
            return Task.FromResult(AuthenticateResult.Fail($"Authentication failed: {ex.Message}"));
        }
    }

    /// <summary>Issues an HTTP Basic challenge for the current request.</summary>
    /// <param name="properties">Properties associated with the authentication challenge.</param>
    /// <returns>A task that completes after the base handler has written the challenge response.</returns>
    /// <remarks>
    /// Sets <c>WWW-Authenticate</c> to a realm containing the current Unix timestamp in seconds
    /// before invoking the base implementation. Changing the realm discourages browsers from
    /// reusing cached Basic credentials, but challenges within the same second share a realm.
    /// The response headers and status can be modified by the base handler.
    /// </remarks>
    /// <exception cref="ArgumentNullException">
    /// May be thrown by the base implementation if <paramref name="properties"/> is
    /// <see langword="null"/>.
    /// </exception>
    protected override async Task HandleChallengeAsync(AuthenticationProperties properties)
    {
        // Use a per-second timestamp in the realm so each challenge is unique.
        // Browsers cache Basic Auth credentials per realm; a changing realm forces
        // a fresh login dialog every time Switch User is clicked.
        var nonce = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        Response.Headers.WWWAuthenticate = $"{BasicScheme} realm=\"KjitWeb-{nonce}\"";
        await base.HandleChallengeAsync(properties);
    }
}
