/*
 * File: IDistinguishedNameService.cs
 * Author: Andreas Lucas (aka Kili)
 *
 * Version history:
 * - 0.1.20260507: Initial distinguished-name service contract.
 * - 0.2.20260926.6: Added complete API and return-value documentation.
 */

namespace KjitCore.Abstractions;

/// <summary>
/// Defines operations for converting Active Directory distinguished-name values.
/// </summary>
/// <remarks>
/// Implementations provide distinguished-name parsing without requiring callers to
/// depend on a concrete directory-service implementation.
/// </remarks>
public interface IDistinguishedNameService
{
    /// <summary>
    /// Converts the domain components of an Active Directory distinguished name
    /// to a DNS domain name.
    /// </summary>
    /// <param name="distinguishedName">
    /// An Active Directory distinguished name containing one or more
    /// <c>DC=</c> components, for example
    /// <c>CN=Server01,OU=Servers,DC=contoso,DC=com</c>.
    /// </param>
    /// <returns>
    /// The DNS domain assembled from the domain components in their original order,
    /// for example <c>contoso.com</c>; otherwise, <see langword="null"/> when
    /// <paramref name="distinguishedName"/> is null, empty, whitespace, or contains
    /// no domain components.
    /// </returns>
    string? ConvertDomainDnToDnsName(string distinguishedName);
}
