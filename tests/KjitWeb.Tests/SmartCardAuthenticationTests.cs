using System.Security.Claims;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using KjitWeb.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;
using Xunit;

namespace KjitWeb.Tests;

public sealed class SmartCardAuthenticationTests
{
    private const string ClientAuthentication = "1.3.6.1.5.5.7.3.2";
    private const string SmartCardLogon = "1.3.6.1.4.1.311.20.2.2";

    [Theory]
    [InlineData(true, true, true, true)]
    [InlineData(false, true, true, false)]
    [InlineData(true, false, true, false)]
    [InlineData(true, true, false, false)]
    [InlineData(false, false, false, false)]
    public void RequiresBothEkusAndTrustedChain(bool clientUsage, bool cardUsage, bool trusted, bool expected)
    {
        using var key = RSA.Create(2048);
        var request = CreateRequest(key, clientUsage, cardUsage);
        using var certificate = request.CreateSelfSigned(DateTimeOffset.UtcNow.AddMinutes(-1), DateTimeOffset.UtcNow.AddDays(1));
        using var chain = new X509Chain();
        chain.ChainPolicy.TrustMode = X509ChainTrustMode.CustomRootTrust;
        chain.ChainPolicy.RevocationMode = X509RevocationMode.NoCheck;
        if (trusted) { chain.ChainPolicy.CustomTrustStore.Add(certificate); }
        Assert.Equal(expected, SmartCardAuthenticationService.ValidateCertificate(certificate, chain));
    }

    [Fact]
    public void RejectsExpiredCertificateEvenWhenExplicitlyTrusted()
    {
        using var key = RSA.Create(2048);
        using var certificate = CreateRequest(key, true, true).CreateSelfSigned(
            DateTimeOffset.UtcNow.AddDays(-2), DateTimeOffset.UtcNow.AddDays(-1));
        using var chain = new X509Chain();
        chain.ChainPolicy.TrustMode = X509ChainTrustMode.CustomRootTrust;
        chain.ChainPolicy.CustomTrustStore.Add(certificate);
        chain.ChainPolicy.RevocationMode = X509RevocationMode.NoCheck;
        Assert.False(SmartCardAuthenticationService.ValidateCertificate(certificate, chain));
    }

    [Fact]
    public void PublicKeyMappingDoesNotTrustSubjectOrCertificateUpn()
    {
        using var key = RSA.Create(2048);
        using var first = CreateRequest(key, true, true).CreateSelfSigned(DateTimeOffset.UtcNow.AddMinutes(-1), DateTimeOffset.UtcNow.AddDays(1));
        var secondRequest = new CertificateRequest("CN=DifferentUser", key, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
        using var second = secondRequest.CreateSelfSigned(DateTimeOffset.UtcNow.AddMinutes(-1), DateTimeOffset.UtcNow.AddDays(1));
        using var otherKey = RSA.Create(2048);
        using var other = CreateRequest(otherKey, true, true).CreateSelfSigned(DateTimeOffset.UtcNow.AddMinutes(-1), DateTimeOffset.UtcNow.AddDays(1));
        var expected = "X509:<SHA1-PUKEY>" + Convert.ToHexString(SHA1.HashData(first.GetPublicKey()));
        Assert.Equal(expected, SmartCardAuthenticationService.GetPublicKeyMapping(first));
        Assert.Equal(expected, SmartCardAuthenticationService.GetPublicKeyMapping(second));
        Assert.NotEqual(expected, SmartCardAuthenticationService.GetPublicKeyMapping(other));
    }

    [Fact]
    public void MissingRevocationInformationIsRejectedEvenWithATrustedIssuer()
    {
        using var issuerKey = RSA.Create(2048);
        var issuerRequest = new CertificateRequest("CN=Test CA", issuerKey, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
        issuerRequest.CertificateExtensions.Add(new X509BasicConstraintsExtension(true, false, 0, true));
        issuerRequest.CertificateExtensions.Add(new X509KeyUsageExtension(X509KeyUsageFlags.KeyCertSign | X509KeyUsageFlags.CrlSign, true));
        using var issuer = issuerRequest.CreateSelfSigned(DateTimeOffset.UtcNow.AddDays(-1), DateTimeOffset.UtcNow.AddDays(2));
        using var key = RSA.Create(2048);
        using var certificate = CreateRequest(key, true, true).Create(
            issuer, DateTimeOffset.UtcNow.AddMinutes(-1), DateTimeOffset.UtcNow.AddDays(1), new byte[] { 1 });
        using var chain = new X509Chain();
        chain.ChainPolicy.TrustMode = X509ChainTrustMode.CustomRootTrust;
        chain.ChainPolicy.CustomTrustStore.Add(issuer);
        chain.ChainPolicy.RevocationMode = X509RevocationMode.Online;
        chain.ChainPolicy.RevocationFlag = X509RevocationFlag.ExcludeRoot;
        chain.ChainPolicy.UrlRetrievalTimeout = TimeSpan.FromSeconds(1);
        Assert.False(SmartCardAuthenticationService.ValidateCertificate(certificate, chain));
        Assert.Contains(chain.ChainStatus, status =>
            (status.Status & (X509ChainStatusFlags.RevocationStatusUnknown | X509ChainStatusFlags.OfflineRevocation)) != 0);
    }

    [Fact]
    public void DisabledOrUntrustedCertificatesNeverQueryTheDirectory()
    {
        using var key = RSA.Create(2048);
        using var certificate = CreateRequest(key, true, true).CreateSelfSigned(DateTimeOffset.UtcNow.AddMinutes(-1), DateTimeOffset.UtcNow.AddDays(1));
        var directory = new Mock<IActiveDirectoryService>(MockBehavior.Strict);
        foreach (var enabled in new[] { false, true })
        {
            var configuration = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["SmartCardAuthentication:Enabled"] = enabled.ToString()
            }).Build();
            var service = new SmartCardAuthenticationService(configuration, directory.Object, NullLogger<SmartCardAuthenticationService>.Instance);
            Assert.Null(service.Authenticate(certificate));
        }
        directory.VerifyNoOtherCalls();
    }

    [Theory]
    [InlineData(512, 0, 0, true)]
    [InlineData(512, 0, long.MaxValue, true)]
    [InlineData(514, 0, 0, false)]
    [InlineData(512, 16, 0, false)]
    [InlineData(528, 0, 0, false)]
    [InlineData(512, 0, 9, false)]
    [InlineData(512, 0, 11, true)]
    [InlineData(512, 0, -1, false)]
    public void RequiresEnabledUnlockedUnexpiredAccount(long flags, long computed, long expiry, bool expected)
    {
        Assert.Equal(expected, ActiveDirectoryService.IsSmartCardAccountUsable(flags, computed, expiry, 10));
    }

    [Fact]
    public void MappingRequiresExactlyOneCompleteDirectoryAccount()
    {
        var entry = CreateDirectoryUser();
        Assert.Null(ActiveDirectoryService.CreateSmartCardPrincipal(new List<SearchResultEntry>()));
        Assert.Null(ActiveDirectoryService.CreateSmartCardPrincipal(new List<SearchResultEntry> { entry, entry }));
        var principal = ActiveDirectoryService.CreateSmartCardPrincipal(new List<SearchResultEntry> { entry });
        Assert.Equal("admin@contoso.local", principal?.Identity?.Name);
        Assert.Equal("SmartCard", principal?.FindFirstValue(ClaimTypes.AuthenticationMethod));
        Assert.Equal("S-1-5-21-1-2-3-1001", principal?.FindFirstValue(ClaimTypes.PrimarySid));
    }

    [Theory]
    [InlineData("objectSid")]
    [InlineData("userPrincipalName")]
    [InlineData("userAccountControl")]
    [InlineData("msDS-User-Account-Control-Computed")]
    [InlineData("accountExpires")]
    public void IncompleteDirectoryAccountIsRejected(string missingAttribute)
    {
        var entry = CreateDirectoryUser();
        entry.Attributes.Remove(missingAttribute);
        Assert.Null(ActiveDirectoryService.CreateSmartCardPrincipal(new List<SearchResultEntry> { entry }));
    }

    private static CertificateRequest CreateRequest(RSA key, bool clientUsage, bool cardUsage)
    {
        var request = new CertificateRequest("CN=UntrustedCertificateName", key, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
        var usages = new OidCollection();
        if (clientUsage) { usages.Add(new Oid(ClientAuthentication)); }
        if (cardUsage) { usages.Add(new Oid(SmartCardLogon)); }
        request.CertificateExtensions.Add(new X509EnhancedKeyUsageExtension(usages, false));
        return request;
    }

    private static SearchResultEntry CreateDirectoryUser()
    {
        var entry = new SearchResultEntry { DistinguishedName = "CN=Admin,DC=contoso,DC=local" };
        entry.Attributes["userPrincipalName"] = new DirectoryAttribute { "admin@contoso.local" };
        entry.Attributes["userAccountControl"] = new DirectoryAttribute { "512" };
        entry.Attributes["msDS-User-Account-Control-Computed"] = new DirectoryAttribute { "0" };
        entry.Attributes["accountExpires"] = new DirectoryAttribute { "0" };
        var sid = new System.Security.Principal.SecurityIdentifier("S-1-5-21-1-2-3-1001");
        var bytes = new byte[sid.BinaryLength];
        sid.GetBinaryForm(bytes, 0);
        entry.Attributes["objectSid"] = new DirectoryAttribute { bytes };
        return entry;
    }
}
