using System.Net.Security;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;

namespace KjitWeb.Services;

/// <summary>Provides explicitly enabled, directory-backed TLS certificate authentication.</summary>
public interface ISmartCardAuthenticationService
{
    /// <summary>Indicates whether certificate sign-in is explicitly enabled.</summary>
    bool Enabled { get; }

    /// <summary>Returns the strongly mapped user only after certificate validation succeeds.</summary>
    ClaimsPrincipal? Authenticate(X509Certificate2 certificate);
}

/// <summary>Validates TLS client certificates before resolving an explicitly mapped AD user.</summary>
public sealed class SmartCardAuthenticationService : ISmartCardAuthenticationService
{
    private static readonly string[] RequiredEkuOids =
    {
        "1.3.6.1.5.5.7.3.2",
        "1.3.6.1.4.1.311.20.2.2"
    };
    private readonly IActiveDirectoryService _directory;
    private readonly ILogger<SmartCardAuthenticationService> _logger;

    /// <summary>Creates a validator using the configured directory and Windows certificate trust.</summary>
    public SmartCardAuthenticationService(
        IConfiguration configuration,
        IActiveDirectoryService directory,
        ILogger<SmartCardAuthenticationService> logger)
    {
        Enabled = configuration.GetValue<bool>("SmartCardAuthentication:Enabled");
        _directory = directory;
        _logger = logger;
    }

    /// <summary>Indicates whether certificate sign-in is explicitly enabled.</summary>
    public bool Enabled { get; }

    /// <summary>Validates certificate trust, revocation and usage, then resolves its strong AD mapping.</summary>
    public ClaimsPrincipal? Authenticate(X509Certificate2 certificate)
    {
        if (!Enabled)
        {
            _logger.LogWarning("Rejected certificate sign-in because smartcard authentication is disabled.");
            return null;
        }

        using var chain = new X509Chain();
        chain.ChainPolicy.RevocationMode = X509RevocationMode.Online;
        chain.ChainPolicy.RevocationFlag = X509RevocationFlag.ExcludeRoot;
        chain.ChainPolicy.UrlRetrievalTimeout = TimeSpan.FromSeconds(10);
        chain.ChainPolicy.ApplicationPolicy.Add(new Oid(RequiredEkuOids[0]));
        if (!ValidateCertificate(certificate, chain))
        {
            _logger.LogWarning(
                "Rejected smartcard certificate {Thumbprint}: invalid trust, validity, revocation or EKU. Chain status: {Status}",
                certificate.Thumbprint,
                string.Join(", ", chain.ChainStatus.Select(status => status.Status)));
            return null;
        }

        return _directory.GetSmartCardPrincipal(GetPublicKeyMapping(certificate));
    }

    internal static bool ValidateCertificate(X509Certificate2 certificate, X509Chain chain)
    {
        return certificate.NotBefore.ToUniversalTime() <= DateTime.UtcNow
            && certificate.NotAfter.ToUniversalTime() > DateTime.UtcNow
            && MutualTlsCertificateValidator.Validate(certificate, SslPolicyErrors.None, RequiredEkuOids)
            && chain.Build(certificate);
    }

    internal static string GetPublicKeyMapping(X509Certificate2 certificate)
    {
        // This is AD's strong public-key mapping format, not a SHA-1 certificate signature.
        return $"X509:<SHA1-PUKEY>{Convert.ToHexString(SHA1.HashData(certificate.GetPublicKey()))}";
    }
}
