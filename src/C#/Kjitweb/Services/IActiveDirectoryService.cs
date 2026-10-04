// Author: Andreas Lucas (aka Kili)
// Documentation update: 0.2.20260926.6
// History: Completed API contract documentation; existing behavior is preserved.

using System.Security.Claims;
using KjitWeb.Models;

namespace KjitWeb.Services;

/// <summary>
/// Defines Active Directory lookups used to discover domains, delegated servers, elevation
/// state, and canonical user identifiers.
/// </summary>
/// <remarks>
/// Implementations may query a directory and write diagnostic logs. Callers should treat returned
/// distinguished names, UPNs, computer names, and domain names as directory-derived security data.
/// </remarks>
public interface IActiveDirectoryService
{
    /// <summary>
    /// Retrieves the configured Active Directory domains available to the application.
    /// </summary>
    /// <returns>A non-null, potentially empty list of domain DNS names.</returns>
    List<string> GetAvailableDomains();

    /// <summary>
    /// Determines the default domain for a user.
    /// </summary>
    /// <param name="user">
    /// The claims principal to inspect, or <see langword="null"/> to use implementation-specific
    /// configuration fallback behavior.
    /// </param>
    /// <returns>The inferred domain DNS name, or an empty string when it cannot be determined.</returns>
    string GetDefaultDomainForUser(ClaimsPrincipal? user);

    /// <summary>
    /// Retrieves computers on which a user currently has time-limited elevation.
    /// </summary>
    /// <param name="user">
    /// The principal whose directory membership is queried, or <see langword="null"/> when no user
    /// context is available.
    /// </param>
    /// <returns>A non-null, potentially empty list describing elevated computers.</returns>
    /// <remarks>
    /// Implementations may perform LDAP searches and typically return an empty list when the
    /// principal, configuration, membership, or directory is unavailable.
    /// </remarks>
    List<ElevatedComputerViewModel> GetCurrentElevatedComputers(ClaimsPrincipal? user);

    /// <summary>
    /// Retrieves server names accessible to a user across all permitted domains.
    /// </summary>
    /// <param name="user">
    /// The principal used to enforce delegation, or <see langword="null"/> when no user context is
    /// available.
    /// </param>
    /// <returns>A non-null, potentially empty list of distinct server FQDNs backed by existing JIT groups.</returns>
    /// <remarks>
    /// When delegation is enabled, implementations should fail closed if the user's group
    /// memberships or applicable search bases cannot be resolved.
    /// </remarks>
    List<string> GetServerNames(ClaimsPrincipal? user);

    /// <summary>
    /// Retrieves server names accessible to a user, optionally restricted to a domain.
    /// </summary>
    /// <param name="user">
    /// The principal used to enforce delegation, or <see langword="null"/> when no user context is
    /// available.
    /// </param>
    /// <param name="selectedDomain">
    /// The domain filter, or <see langword="null"/>, empty, or whitespace to include every
    /// permitted domain.
    /// </param>
    /// <returns>A non-null, potentially empty list of distinct server FQDNs backed by existing JIT groups.</returns>
    /// <remarks>
    /// Implementations may perform LDAP searches and log lookup failures. Delegation must be
    /// applied before the optional domain filter.
    /// </remarks>
    List<string> GetServerNames(ClaimsPrincipal? user, string? selectedDomain);

    /// <summary>
    /// Resolves a user identity to its Active Directory distinguished name.
    /// </summary>
    /// <param name="identityName">
    /// A Windows account name or UPN, or <see langword="null"/> when the identity is unavailable.
    /// </param>
    /// <returns>
    /// The directory distinguished name, <c>unknown-user</c> when the input is blank, or the
    /// original identity when the directory value cannot be resolved.
    /// </returns>
    /// <remarks>Implementations may query LDAP and log failures.</remarks>
    string GetUserDistinguishedName(string? identityName);

    /// <summary>
    /// Resolves a user identity to its user principal name (UPN).
    /// </summary>
    /// <param name="identityName">
    /// A Windows account name or UPN, or <see langword="null"/> when the identity is unavailable.
    /// </param>
    /// <returns>
    /// The resolved UPN, an empty string when <paramref name="identityName"/> is blank, or the
    /// original identity when directory lookup is not possible.
    /// </returns>
    /// <remarks>Implementations may query LDAP and log failures.</remarks>
    string GetUserPrincipalName(string? identityName);
}
