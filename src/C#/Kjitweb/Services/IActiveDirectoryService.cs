using System.Security.Claims;

namespace KjitWeb.Services;

/// <summary>
///     Interface for Active Directory related operations. 
///     This service provides methods to interact with Active Directory, such as retrieving available domains, getting user information, and fetching server names based on user context.
/// </summary>
public interface IActiveDirectoryService
{
    /// <summary>
    ///     Retrieves a list of available domains in the Active Directory.
    /// </summary>
    List<string> GetAvailableDomains();

    /// <summary>
    ///     Gets the default domain for the specified user.
    /// </summary>
    string GetDefaultDomainForUser(ClaimsPrincipal? user);

    /// <summary>
    ///     Retrieves the current elevation groups for the specified user.
    /// </summary>
    List<string> GetCurrentElevationGroups(ClaimsPrincipal? user);

    /// <summary>
    ///     Retrieves a list of server names accessible to the specified user.
    /// </summary>
    List<string> GetServerNames(ClaimsPrincipal? user);

    /// <summary>
    ///     Retrieves a list of server names accessible to the specified user within the selected domain.
    /// </summary>
    List<string> GetServerNames(ClaimsPrincipal? user, string? selectedDomain);

    /// <summary>
    ///     Gets the distinguished name of the specified user.
    /// </summary>
    string GetUserDistinguishedName(string? identityName);

    /// <summary>
    ///     Gets the user principal name (UPN) of the specified user.
    /// </summary>
    string GetUserPrincipalName(string? identityName);
}
