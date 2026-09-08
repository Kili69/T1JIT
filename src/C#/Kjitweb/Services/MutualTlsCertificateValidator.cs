using System.Net.Security;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;

namespace KjitWeb.Services;

public static class MutualTlsCertificateValidator
{
    public static bool Validate(
        X509Certificate2 certificate,
        SslPolicyErrors policyErrors,
        IReadOnlyCollection<string> requiredEkuOids)
    {
        if (policyErrors != SslPolicyErrors.None)
        {
            return false;
        }

        var ekuExtension = certificate.Extensions
            .OfType<X509EnhancedKeyUsageExtension>()
            .FirstOrDefault();
        if (ekuExtension is null)
        {
            return false;
        }

        var certificateEkuOids = ekuExtension.EnhancedKeyUsages
            .Cast<Oid>()
            .Select(oid => oid.Value)
            .Where(value => value is not null)
            .ToHashSet(StringComparer.Ordinal);

        return requiredEkuOids.All(certificateEkuOids.Contains);
    }
}