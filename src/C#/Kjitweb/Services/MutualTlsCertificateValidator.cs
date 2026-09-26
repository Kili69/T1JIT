// Author: Andreas Lucas (aka Kili)
// Documentation update: 0.2.20260926.6
// History: Completed API documentation; existing certificate validation behavior is preserved.

using System.Net.Security;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;

namespace KjitWeb.Services;

/// <summary>Provides stateless validation of mutual-TLS client certificate policy and EKUs.</summary>
public static class MutualTlsCertificateValidator
{
    /// <summary>
    /// Determines whether a client certificate has no TLS policy errors and contains every
    /// required enhanced key usage (EKU) object identifier.
    /// </summary>
    /// <param name="certificate">The client certificate whose EKU extension is inspected.</param>
    /// <param name="policyErrors">
    /// TLS policy errors reported by the transport. Any value other than
    /// <see cref="SslPolicyErrors.None"/> causes immediate rejection.
    /// </param>
    /// <param name="requiredEkuOids">
    /// EKU OID values that must all occur in the certificate. An empty collection accepts any
    /// certificate that has an EKU extension and no policy errors. Null entries never match.
    /// </param>
    /// <returns>
    /// <see langword="true"/> only when there are no policy errors, an EKU extension is present,
    /// and every required OID matches using ordinal, case-sensitive comparison; otherwise,
    /// <see langword="false"/>.
    /// </returns>
    /// <remarks>
    /// This method does not build a certificate chain, perform revocation checks, validate names
    /// or dates independently, or mutate the certificate. Those checks must be represented by
    /// <paramref name="policyErrors"/> or performed by the caller.
    /// </remarks>
    /// <exception cref="NullReferenceException">
    /// Thrown when validation reaches a <see langword="null"/> <paramref name="certificate"/> or
    /// <paramref name="requiredEkuOids"/> argument.
    /// </exception>
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