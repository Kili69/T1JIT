// Author: Andreas Lucas (aka Kili)
// Documentation update: 0.2.20260926.6
// History: Completed API documentation; existing option semantics are preserved.

namespace KjitWeb.Services;

/// <summary>Represents configuration settings for mutual TLS client-certificate validation.</summary>
public sealed class MutualTlsOptions
{
    /// <summary>The configuration section from which these options are bound.</summary>
    public const string SectionName = "MutualTls";

    /// <summary>Gets or sets whether mutual TLS validation is enabled.</summary>
    /// <value><see langword="true"/> to enable mutual TLS; otherwise, <see langword="false"/>.</value>
    public bool Enabled { get; set; }

    /// <summary>Gets or sets whether certificate-chain validation checks revocation status.</summary>
    /// <value>
    /// <see langword="true"/> to request revocation checking; otherwise, <see langword="false"/>.
    /// The default is <see langword="true"/>.
    /// </value>
    /// <remarks>The component consuming these options is responsible for enforcing this setting.</remarks>
    public bool CheckCertificateRevocation { get; set; } = true;

    /// <summary>Gets or sets the EKU object identifiers required on a client certificate.</summary>
    /// <value>
    /// A mutable array of OID strings. The default is an empty array, meaning that no particular
    /// EKU OID is required beyond the validator's requirement that an EKU extension exist. The
    /// property is settable and can therefore be assigned <see langword="null"/> despite its
    /// non-nullable annotation; consumers do not necessarily tolerate that value.
    /// </value>
    public string[] RequiredEkuOids { get; set; } = [];
}