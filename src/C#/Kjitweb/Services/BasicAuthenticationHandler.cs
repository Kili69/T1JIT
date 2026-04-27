using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;
using System.Text.Encodings.Web;

namespace KjitWeb.Services;

public class BasicAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    private const string AuthorizationHeaderName = "Authorization";
    private const string BasicScheme = "Basic";

    // P/Invoke for Windows LogonUser
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

    public BasicAuthenticationHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder)
        : base(options, logger, encoder)
    {
    }

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
