// -----------------------------------------------------------------------------
// ActiveDirectoryService.cs
// Author: Andreas Lucas (aka Kili)
// Documentation update: 0.2.20260926.6
//
// History: Existing implementation attribution and behavior are preserved.
// This revision consolidates and completes the API and helper documentation.
// -----------------------------------------------------------------------------

using KjitWeb.Models;
using Sds = System.DirectoryServices.Protocols;
using System.Net;
using System.Net.NetworkInformation;
using System.Security.Claims;
using System.Security.Principal;
using System.Text.RegularExpressions;

namespace KjitWeb.Services;

/// <summary>
/// Provides integer values corresponding to LDAP search scopes.
/// </summary>
/// <remarks>Values are cast to System.DirectoryServices.Protocols.SearchScope when requests are created.</remarks>
internal static class SearchScope
{
    /// <summary>
    /// Searches only the named base directory object.
    /// </summary>
    public const int Base = 0;
    /// <summary>
    /// Searches the immediate children of the base directory object.
    /// </summary>
    public const int OneLevel = 1;
    /// <summary>
    /// Searches the base directory object and all descendants.
    /// </summary>
    public const int Subtree = 2;
}

/// <summary>
/// Represents the subset of an LDAP search result consumed by this service.
/// </summary>
/// <remarks>Missing attributes are absent; attribute names are case-insensitive.</remarks>
internal class SearchResultEntry
{
    /// <summary>
    /// Gets or sets the entry distinguished name.
    /// </summary>
    /// <remarks>Never null; an empty string represents an unavailable name.</remarks>
    public string DistinguishedName { get; set; } = string.Empty;
    /// <summary>
    /// Gets or sets the attributes returned for the entry.
    /// </summary>
    /// <remarks>Initialized to a non-null, case-insensitive collection.</remarks>
    public DirectoryAttributeCollection Attributes { get; set; } = new();
}

/// <summary>
/// Stores LDAP attributes using case-insensitive names.
/// </summary>
internal class DirectoryAttributeCollection : Dictionary<string, DirectoryAttribute>
{
    /// <summary>
    /// Initializes an empty collection that compares LDAP attribute names without regard to case.
    /// </summary>
    public DirectoryAttributeCollection() : base(StringComparer.OrdinalIgnoreCase) { }
}

/// <summary>
/// Represents one named, potentially multi-valued LDAP attribute.
/// </summary>
internal class DirectoryAttribute : List<object>
{
    /// <summary>
    /// Gets or sets the LDAP attribute name.
    /// </summary>
    /// <remarks>Never null; an empty string denotes an unspecified name.</remarks>
    public string Name { get; set; } = string.Empty;
}
/// <summary>
/// Queries Active Directory for users, elevations, domains, and visible servers.
/// </summary>
/// <remarks>LDAP uses default Windows credentials with Negotiate, signing, sealing, LDAP v3, and no referral chasing. Delegated server visibility fails closed when authorization data is unavailable.</remarks>
public class ActiveDirectoryService : IActiveDirectoryService
{
    private const int LdapReferralErrorCode = 10; // LDAP error code 10 = LDAP_REFERRAL
    private readonly IConfiguration _configuration; // The configuration instance is used to access application settings, particularly those related to JIT configuration and Active Directory parameters. It is injected into the service through the constructor and stored in a private readonly field for use in the service methods when performing LDAP queries and resolving configuration values.
    private readonly ILogger<ActiveDirectoryService> _logger; // The logger instance is used for logging information, warnings, and errors within the ActiveDirectoryService. It is injected through the constructor and stored in a private readonly field, allowing the service methods to log relevant information about their operations, such as LDAP query results, configuration issues, and any exceptions that may occur during processing. This logging is crucial for troubleshooting and understanding the behavior of the service in different environments and scenarios.
    private readonly string _domainLdapPath; // The domain LDAP path is a critical configuration value that specifies the base LDAP path for the domain against which the service will perform queries. It is resolved during the construction of the service, typically from the JIT configuration, and stored in a private readonly field for use in LDAP queries when determining elevation groups, available domains, and server information. The domain LDAP path is essential for correctly targeting the Active Directory environment and ensuring that queries are performed against the correct directory context.
    private readonly string _domainFqdn; // The domain FQDN (Fully Qualified Domain Name) is a critical piece of information that represents the domain in a format like "example.com". It is resolved during the construction of the service, either by parsing it from the domain LDAP path or by using other configuration values. The domain FQDN is used in various parts of the service, such as when extracting domain information from UPNs or when filtering server results based on domain. Having the domain FQDN allows the service to perform accurate comparisons and formatting related to domains in Active Directory.
    private readonly string? _groupOuDistinguishedName; // The group OU distinguished name is an optional configuration value that specifies the LDAP distinguished name of the organizational unit (OU) where elevation groups are located. If configured, it is used by the GetCurrentElevationGroups method to perform LDAP queries to find the groups that the authenticated user is a member of. This allows the service to determine the user's current elevation groups based on their group memberships in Active Directory. If this value is not configured, the service will not be able to retrieve elevation groups and will return an empty list instead.
    private readonly string _adminPreFix; // The admin prefix is a configuration value that can be used to format the display names of elevation groups for better readability. It is typically a string that is prefixed to the group name when formatting the current elevation group names for display. This allows the application to present elevation groups in a more user-friendly way, especially if the actual group names in Active Directory are not easily readable or need additional context to be understood by end users. The admin prefix can be an empty string if no prefixing is desired.
    private readonly string _domainSeparator; // The domain separator is a configuration value that defines the character used to separate the domain from the username in formats like "DOMAIN\username". It is used by the service when parsing or formatting user and group names that include domain information. This allows the service to correctly handle different naming conventions and ensure that comparisons and formatting of names are consistent with the expected format in the environment where it is deployed.
    private readonly bool _enableMultiDomainSupport;
    private readonly IReadOnlyList<string> _serverSearchBaseLdapPaths; // The server search base LDAP paths are critical configuration values that specify the base LDAP paths where the service will search for computer objects (servers) in Active Directory. These paths are resolved from the JIT configuration and stored in a private readonly list for use in the GetServerNames method when performing LDAP queries to retrieve server information. Having multiple search base paths allows the service to search across different parts of the directory, which can be useful in complex Active Directory environments where computer objects may be located in various OUs or containers.
    private readonly bool _delegationEnabled; // The delegation enabled flag is a configuration value that indicates whether delegation rules should be applied when retrieving server names. If delegation is enabled, the service will resolve the effective search bases for the user based on their group memberships and the defined delegation rules, which can restrict the servers that are visible to the user based on their group memberships. This allows for more granular control over server visibility and can enhance security by ensuring that users only see servers they are allowed to access based on their roles in Active Directory.
    private readonly IReadOnlyList<DelegationRule> _delegationRules; // The delegation rules are a collection of rules defined in the JIT configuration that specify how to determine the effective search bases for a user based on their group memberships. Each rule typically includes a group name and a corresponding search base LDAP path. If delegation is enabled, the service will evaluate these rules against the user's group memberships to determine which search bases should be used when retrieving server names. This allows for dynamic adjustment of server visibility based on the user's roles in Active Directory, enhancing security and ensuring that users only see servers they are authorized to access.

    
    // The constructor initializes the ActiveDirectoryService by loading configuration settings, 
    // resolving critical parameters such as the domain LDAP path and server search bases, 
    // and preparing any necessary state for LDAP queries. 
    // It also loads delegation rules if delegation is enabled in the configuration. 
    // Any issues during initialization (e.g. missing or invalid configuration) will be logged and may cause exceptions to be thrown, 
    // which should be handled by the caller to ensure the application can respond appropriately to startup failures.
    // The constructor takes an IConfiguration instance to access application settings and an ILogger for logging. 
    // It attempts to load the JIT configuration, resolve the domain LDAP path, and extract necessary parameters for later use in LDAP queries. If critical configuration is missing or invalid (e.g. no valid server search bases), 
    // it will log errors and throw exceptions to prevent the service from operating in a misconfigured state.
    // By performing this initialization logic in the constructor, we ensure that any issues with configuration are detected early, 
    // ideally during application startup, allowing for faster troubleshooting and preventing runtime errors when the service methods are called.
    /// <summary>
    /// Initializes the service and resolves JIT, domain, search-base, and delegation configuration.
    /// </summary>
    /// <param name="configuration">Application configuration used to locate JIT and Active Directory settings; expected to be non-null.</param>
    /// <param name="logger">Logger that receives configuration, authorization, LDAP, and fallback diagnostics; expected to be non-null.</param>
    /// <remarks>
    /// Construction reads configuration files and may inspect the host DNS domain. It does not bind to LDAP.
    /// </remarks>
    /// <exception cref="InvalidOperationException">The domain or required server search bases cannot be resolved.</exception>
    /// <exception cref="Exception">The configured JIT file cannot be loaded or parsed; the original exception is logged and propagated.</exception>
    public ActiveDirectoryService(IConfiguration configuration, ILogger<ActiveDirectoryService> logger)
    {
        _configuration = configuration; // Store the configuration instance for later use in service methods.
        _logger = logger; // Store the logger instance for logging within the service.  
        var jitConfiguration = ResolveJitConfiguration(); // Load the JIT configuration from the application's configuration settings. This typically involves reading a specific section of the configuration that contains settings related to JIT access and Active Directory parameters. The resolved JIT configuration will be used to extract critical values such as the domain LDAP path, group OU distinguished name, server search bases, and delegation rules.
        _domainLdapPath = ResolveDomainLdapPath(jitConfiguration); // Resolve the domain LDAP path from the JIT configuration. This is a critical parameter that specifies the base LDAP path for the domain against which the service will perform queries. The method may involve validating the provided LDAP path and ensuring it is in a correct format. If the domain LDAP path cannot be resolved or is invalid, it may log an error and throw an exception, as this would prevent the service from functioning correctly.
        _domainFqdn = ParseDomainFqdnFromLdapPath(_domainLdapPath) ?? ResolveDomainFqdn(); // Parse the domain FQDN from the resolved domain LDAP path. If parsing fails, attempt to resolve the domain FQDN through other means (e.g. using the current user's domain). The domain FQDN is used in various parts of the service for formatting and comparisons related to domains. If it cannot be resolved, it may log a warning and continue with an empty string, but this could lead to issues in other methods that rely on the domain FQDN.
        _groupOuDistinguishedName = jitConfiguration.GroupOuDistinguishedName; // Load the group OU distinguished name from the JIT configuration, which specifies where elevation groups are located in Active Directory. This is used by the GetCurrentElevationGroups method to perform LDAP queries to find the groups that the authenticated user is a member of. If this value is not configured, the service will not be able to retrieve elevation groups and will return an empty list instead.
        _adminPreFix = jitConfiguration.AdminPreFix; // Load the admin prefix from the JIT configuration, which may be used to format elevation group names for display. This is optional and can be an empty string if not used.   
        _domainSeparator = jitConfiguration.DomainSeparator; // Load the domain separator from the JIT configuration, which may be used to parse or format domain-related information.
        _enableMultiDomainSupport = jitConfiguration.EnableMultiDomainSupport;
        _serverSearchBaseLdapPaths = ResolveServerSearchBasesFromJitConfiguration(jitConfiguration); // Resolve the LDAP paths for server search bases from the JIT configuration. These paths will be used to search for servers in the directory.
        _delegationEnabled = jitConfiguration.EnableDelegation; // Load the delegation enabled flag from the JIT configuration, which indicates whether delegation rules should be applied.
        _delegationRules = ResolveDelegationRules(jitConfiguration); // Resolve the delegation rules from the JIT configuration, if delegation is enabled.
    }

    /// <summary>
    /// Gets computers for which the user currently has direct membership in configured elevation groups.
    /// </summary>
    /// <param name="user">Principal used for identity or delegation checks; may be null.</param>
    /// <returns>A new ordered list; empty when configuration, identity resolution, or LDAP access is unavailable.</returns>
    /// <remarks>Queries group membership with link TTL metadata. Failures are logged and suppressed; this reports directory state and does not grant authorization.</remarks>
    public List<ElevatedComputerViewModel> GetCurrentElevatedComputers(ClaimsPrincipal? user)
    {
        // If the group OU is not configured, we cannot perform the query, so return an empty list. 
        // This is a graceful handling of misconfiguration that allows the application to continue functioning without elevation information rather than throwing exceptions.
        if (string.IsNullOrWhiteSpace(_groupOuDistinguishedName))
        {
            return new List<ElevatedComputerViewModel>();
        }
        // Attempt to resolve the user's distinguished name from their identity. If this fails, we cannot perform the query, 
        // so return an empty list.
        var identityName = user?.Identity?.Name;
        if (string.IsNullOrWhiteSpace(identityName))
        {
            return new List<ElevatedComputerViewModel>();
        }
        // Get the user's distinguished name, which is required for the LDAP query. If this cannot be resolved, return an empty list.
        var userDn = GetUserDistinguishedName(identityName);
        if (string.IsNullOrWhiteSpace(userDn) || userDn.Equals("unknown-user", StringComparison.OrdinalIgnoreCase))
        {
            return new List<ElevatedComputerViewModel>();
        }
        // Normalize the group OU LDAP path and perform the LDAP query to find all groups that the user is a member of, 
        // including nested memberships.
        var groupOuLdapPath = NormalizeLdapPath(_groupOuDistinguishedName);
        // If the normalized group OU LDAP path is invalid, return an empty list.
        if (string.IsNullOrWhiteSpace(groupOuLdapPath))
        {
            return new List<ElevatedComputerViewModel>();
        }

        try
        {
            var entries = LdapSearchPagedWithLinkTtl(
                groupOuLdapPath,
                $"(&(objectCategory=group)(member:1.2.840.113556.1.4.1941:={EscapeLdapFilter(userDn)}))",
                SearchScope.Subtree,
                "cn", "distinguishedName", "member");

            return entries
                .Select(entry => new
                {
                    Name = ExtractGroupDisplayName(entry),
                    Membership = GetDirectMembershipTimeToLive(entry, userDn)
                })
                .Where(result => !string.IsNullOrWhiteSpace(result.Name) && result.Membership.Found)
                .Select(result => ParseElevatedComputer(result.Name!, result.Membership.RemainingSeconds))
                .Where(computer => computer != null)
                .Select(computer => computer!)
                .GroupBy(
                    computer => $"{computer.Domain}\0{computer.ComputerName}",
                    StringComparer.OrdinalIgnoreCase)
                .Select(group => group.First())
                .OrderBy(computer => computer.ComputerName, StringComparer.OrdinalIgnoreCase)
                .ThenBy(computer => computer.Domain, StringComparer.OrdinalIgnoreCase)
                .ToList();
        }
        // If there is an issue with the LDAP query (e.g. connectivity problems, invalid search parameters), 
        // log a warning and return an empty list.
        catch (Exception ex) when (ex is Sds.LdapException)
        {
            _logger.LogWarning(ex, "LDAP matching rule query failed for current elevations of user {IdentityName}", identityName);
            return new List<ElevatedComputerViewModel>();
        }
        // Catch any other unexpected exceptions, 
        // log a warning, and return an empty list to allow the application to continue functioning.
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not resolve current elevations for user {IdentityName}", identityName);
            return new List<ElevatedComputerViewModel>();
        }
    }

    /// <summary>
    /// Gets the domain encoded in the configured domain LDAP path.
    /// </summary>
    /// <returns>A new list containing one FQDN, or an empty list when it cannot be parsed.</returns>
    /// <remarks>Performs no forest discovery or network request.</remarks>
    public List<string> GetAvailableDomains()
    {
        // System.DirectoryServices.ActiveDirectory.Forest is not available when running as a
        // Windows Service under SYSTEM. Return the domain derived from the configured LDAP path.
        var fallbackDomain = ParseDomainFqdnFromLdapPath(_domainLdapPath);
        return string.IsNullOrWhiteSpace(fallbackDomain)
            ? new List<string>()
            : new List<string> { fallbackDomain };
    }

    /// <summary>
    /// Determines the preferred domain for a principal.
    /// </summary>
    /// <param name="user">Principal used for identity or delegation checks; may be null.</param>
    /// <returns>The UPN suffix, configured LDAP domain, or an empty string.</returns>
    /// <remarks>A missing UPN claim can trigger an LDAP lookup; failures are logged and converted to fallback text.</remarks>
    public string GetDefaultDomainForUser(ClaimsPrincipal? user)
    {
        // First, attempt to get the UPN from the user's claims. 
        // If a UPN claim is present, extract the domain portion and return it as the default domain.
        var upnFromClaim = user?.FindFirst(ClaimTypes.Upn)?.Value;
        // If there is no UPN claim, we will attempt to parse the domain from the configured domain LDAP path as a fallback.
        var upn = string.IsNullOrWhiteSpace(upnFromClaim)
            ? GetUserPrincipalName(user?.Identity?.Name)
            : upnFromClaim;
        // If we have a UPN (either from the claim or from looking up the user's principal name), 
        // attempt to extract the domain from it.
        var domainFromUpn = ExtractDomainFromUpn(upn);
        if (!string.IsNullOrWhiteSpace(domainFromUpn))
        {
            // If we successfully extracted a domain from the UPN, return it as the default domain.
            return domainFromUpn;
        }

        // If we could not determine the domain from the UPN, fall back to parsing the domain from the configured LDAP path.
        return ParseDomainFqdnFromLdapPath(_domainLdapPath) ?? string.Empty;
    }

    /// <summary>
    /// Gets visible server names without a domain filter.
    /// </summary>
    /// <param name="user">Principal used for identity or delegation checks; may be null.</param>
    /// <returns>A new distinct, case-insensitively ordered list.</returns>
    /// <remarks>Equivalent to the two-parameter overload with a null domain. Delegation uses the principal and fails closed.</remarks>
    public List<string> GetServerNames(ClaimsPrincipal? user)
    {
        return GetServerNames(user, null);
    }

    /// <summary>
    /// Gets visible server names, optionally restricted to one DNS domain.
    /// </summary>
    /// <param name="user">Principal used for identity or delegation checks; may be null.</param>
    /// <param name="selectedDomain">Optional DNS domain; null or blank disables filtering.</param>
    /// <returns>A new distinct, case-insensitively ordered list of DNS host names; never null.</returns>
    /// <remarks>Only authorized computers with a DNS host name and an existing matching JIT group are returned.</remarks>
    public List<string> GetServerNames(ClaimsPrincipal? user, string? selectedDomain)
    {
        var serverNames = new List<string>();
        var effectiveSearchBases = ResolveSearchBasesForUser(user);
        var normalizedSelectedDomain = NormalizeDomain(selectedDomain);
        var jitGroupNames = GetJitGroupNames();
        if (jitGroupNames.Count == 0)
        {
            _logger.LogWarning("No JIT groups were found in {GroupOu}. Returning no servers.", _groupOuDistinguishedName);
            return serverNames;
        }

        foreach (var searchBase in effectiveSearchBases)
        {
            try
            {
                _logger.LogInformation("Searching for servers in base: {SearchBase}", searchBase);
                var entries = LdapSearchPaged(
                    searchBase,
                    "(&(objectCategory=computer)(name=*))",
                    SearchScope.Subtree,
                    "name", "dNSHostName", "distinguishedName");

                _logger.LogInformation("LDAP search for servers returned {EntryCount} results from base {SearchBase}", entries.Count, searchBase);

                foreach (var entry in entries)
                {
                    if (!MatchesSelectedDomain(entry, normalizedSelectedDomain))
                        continue;

                    var computerName = ReadEntryAttribute(entry, "name");
                    var dnsHostName = ReadEntryAttribute(entry, "dNSHostName");
                    var computerDomain = ResolveComputerDomain(entry);
                    if (string.IsNullOrWhiteSpace(computerName)
                        || string.IsNullOrWhiteSpace(dnsHostName)
                        || string.IsNullOrWhiteSpace(computerDomain))
                    {
                        continue;
                    }

                    var expectedGroupName = BuildJitGroupName(computerName, computerDomain);
                    if (jitGroupNames.Contains(expectedGroupName))
                    {
                        serverNames.Add(dnsHostName.TrimEnd('.'));
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Ignoring LDAP search base due to unexpected error: {SearchBase}", searchBase);
            }
        }

        var serverResults = serverNames
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(n => n, StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (serverResults.Count == 0)
        {
            _logger.LogWarning(
                "GetServerNames returned 0 servers for user {IdentityName}. EffectiveSearchBaseCount={SearchBaseCount} EffectiveBases=[{EffectiveBases}]",
                user?.Identity?.Name,
                effectiveSearchBases.Count,
                string.Join("; ", effectiveSearchBases));
        }
        else
        {
            _logger.LogWarning(
                "GetServerNames returned {Count} servers for user {IdentityName}.",
                serverResults.Count,
                user?.Identity?.Name);
        }

        return serverResults;
    }

    /// <summary>
    /// Loads the names of all groups below the configured JIT group OU.
    /// </summary>
    /// <returns>A case-insensitive set; empty when the group OU is missing or cannot be queried.</returns>
    private HashSet<string> GetJitGroupNames()
    {
        if (string.IsNullOrWhiteSpace(_groupOuDistinguishedName))
        {
            _logger.LogWarning("No JIT group OU is configured. Returning no servers.");
            return new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        }

        var groupOuLdapPath = NormalizeLdapPath(_groupOuDistinguishedName);
        if (string.IsNullOrWhiteSpace(groupOuLdapPath))
        {
            _logger.LogWarning("The configured JIT group OU is invalid: {GroupOu}. Returning no servers.", _groupOuDistinguishedName);
            return new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        }

        try
        {
            return LdapSearchPaged(
                    groupOuLdapPath,
                    "(objectCategory=group)",
                    SearchScope.Subtree,
                    "name")
                .Select(entry => ReadEntryAttribute(entry, "name"))
                .Where(name => !string.IsNullOrWhiteSpace(name))
                .Select(name => name!)
                .ToHashSet(StringComparer.OrdinalIgnoreCase);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Unable to query JIT groups in {GroupOu}. Returning no servers.", _groupOuDistinguishedName);
            return new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        }
    }

    /// <summary>
    /// Builds the configured JIT administrator-group name for a computer.
    /// </summary>
    private string BuildJitGroupName(string computerName, string computerDomain)
    {
        return _enableMultiDomainSupport
            ? $"{_adminPreFix}{computerDomain}{_domainSeparator}{computerName}"
            : $"{_adminPreFix}{computerName}";
    }

    // This helper method checks if a given LDAP search result for a computer object matches the selected domain filter.
    // If no selected domain is specified, it returns true for all results. 
    // If a selected domain is specified, it attempts to resolve the domain of the computer object from its properties (dNSHostName or distinguishedName) and compares it to the selected domain. 
    // This allows the GetServerNames method to filter results based on the specified domain.
    /// <summary>
    /// Tests whether a computer entry belongs to the selected normalized domain.
    /// </summary>
    /// <param name="entry">LDAP search result to inspect.</param>
    /// <param name="selectedDomain">Optional DNS domain; null or blank disables filtering.</param>
    /// <returns>True when no filter is active or the entry domain matches; otherwise false.</returns>
    private static bool MatchesSelectedDomain(SearchResultEntry entry, string? selectedDomain)
    {
        if (string.IsNullOrWhiteSpace(selectedDomain))
            return true;

        var objectDomain = ResolveComputerDomain(entry);
        return !string.IsNullOrWhiteSpace(objectDomain)
            && objectDomain.Equals(selectedDomain, StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Resolves a computer domain from its DNS host name, then its distinguished name.
    /// </summary>
    /// <param name="entry">LDAP search result to inspect.</param>
    /// <returns>The normalized domain, or null when neither attribute contains one.</returns>
    private static string? ResolveComputerDomain(SearchResultEntry entry)
    {
        var dnsHostName = ReadEntryAttribute(entry, "dNSHostName");
        var domainFromDns = ExtractDomainFromDnsHostName(dnsHostName);
        if (!string.IsNullOrWhiteSpace(domainFromDns))
            return domainFromDns;

        var distinguishedName = ReadEntryAttribute(entry, "distinguishedName");
        return ParseDomainFqdnFromLdapPath(distinguishedName);
    }

    /// <summary>
    /// Reads the first LDAP attribute value as text.
    /// </summary>
    /// <param name="entry">LDAP search result to inspect.</param>
    /// <param name="attributeName">Case-insensitive LDAP attribute name.</param>
    /// <returns>The first value converted to text, or null when missing, empty, or null.</returns>
    private static string? ReadEntryAttribute(SearchResultEntry entry, string attributeName)
    {
        var attr = entry.Attributes[attributeName];
        if (attr == null || attr.Count == 0)
            return null;
        return attr[0]?.ToString();
    }

    // This helper method attempts to extract the domain portion from a dNSHostName value.
    // It checks if the dNSHostName is valid and contains a dot, and if so, it takes the portion after the first dot as the domain. It then normalizes the extracted domain before returning it. If the dNSHostName is not valid or does not contain a dot, it returns null.    
    /// <summary>
    /// Extracts and normalizes the suffix following the first dot in a DNS host name.
    /// </summary>
    /// <param name="dnsHostName">DNS host name to parse; may be null or blank.</param>
    /// <returns>A normalized domain, or null for an unqualified or invalid host name.</returns>
    private static string? ExtractDomainFromDnsHostName(string? dnsHostName)
    {
        if (string.IsNullOrWhiteSpace(dnsHostName)) // If the dNSHostName is null, empty, or whitespace, we cannot extract a domain from it, so we return null.
        {
            return null;
        }

        var host = dnsHostName.Trim(); // Trim any leading or trailing whitespace from the dNSHostName.
        var firstDotIndex = host.IndexOf('.'); // Find the index of the first dot in the dNSHostName. The domain portion is expected to be after this first dot. If there is no dot, or if the dot is at the end of the string, we cannot extract a valid domain, so we return null.
        if (firstDotIndex < 0 || firstDotIndex >= host.Length - 1)
        {
            return null;
        }

        return NormalizeDomain(host[(firstDotIndex + 1)..]); // Extract the portion of the dNSHostName after the first dot, which is expected to be the domain, and normalize it before returning. This allows us to get a consistent domain format for comparison and filtering.
    }

    // This helper method attempts to parse a domain FQDN from an LDAP path, such as a distinguished name.
    // It looks for DC components in the LDAP path and concatenates them to form the domain FQDN. If it cannot find any DC components, it returns null. The resulting domain is normalized before being returned.
    /// <summary>
    /// Normalizes a DNS domain for comparison.
    /// </summary>
    /// <param name="domain">Domain to normalize; may be null or blank.</param>
    /// <returns>A trimmed lower-case value without trailing dots, or null for missing input.</returns>
    private static string? NormalizeDomain(string? domain)
    {
        if (string.IsNullOrWhiteSpace(domain)) // If the input domain string is null, empty, or whitespace, we cannot normalize it, so we return null.
        {
            return null;
        }

        return domain.Trim().TrimEnd('.').ToLowerInvariant(); // Normalize the domain by trimming whitespace, removing any trailing dots, and converting it to lowercase for consistent comparison. This helps ensure that domain comparisons are case-insensitive and not affected by formatting variations.
    }

    // This helper method resolves the effective LDAP search bases for the specified user, taking into account delegation rules if delegation is enabled.
    /// <summary>
    /// Resolves LDAP server search bases allowed for a principal.
    /// </summary>
    /// <param name="user">Principal used for identity or delegation checks; may be null.</param>
    /// <returns>Configured bases when delegation is off, authorized bases when on, or an empty list.</returns>
    /// <remarks>Delegation fails closed when rules or SID tokens are unavailable. LDAP enrichment and failures are logged.</remarks>
    private IReadOnlyList<string> ResolveSearchBasesForUser(ClaimsPrincipal? user)
    {
        if (!_delegationEnabled) // If delegation is not enabled, we simply return the configured server search base LDAP paths without applying any user-specific filtering. This means that all users will have access to the same search bases as defined in the configuration.  
        {
            return _serverSearchBaseLdapPaths;
        }

        if (_delegationRules.Count == 0) // If delegation is enabled but no delegation rules are loaded, we log a warning and return no servers.
        {   
            _logger.LogWarning("Delegation is enabled but no delegation rules could be loaded. Returning no servers."); // This is a safeguard against misconfiguration where delegation is turned on but there are no rules defined, which would otherwise result in all users having access to all search bases. By returning an empty list, we prevent unintended access while alerting administrators to the configuration issue through logging.
            return Array.Empty<string>();
        }

        var userGroupTokens = ResolveUserGroupTokens(user); // Resolve the user's group tokens, which are used to determine which delegation rules apply to the user. This typically involves extracting the SIDs of the groups that the user is a member of from their claims or by querying Active Directory. If we cannot resolve any group tokens for the user, we will not be able to apply any delegation rules, so we log a warning and return no servers.   
        if (userGroupTokens.Count == 0) // If we could not resolve any group tokens for the user, we log a warning and return no servers. This means that if the user's group memberships cannot be determined, they will not have access to any search bases, which is a secure default behavior.  
        {
            _logger.LogWarning("No group SID claims could be resolved for user {IdentityName}. Returning no servers.", user?.Identity?.Name); // This log entry helps administrators understand that the reason no servers are being returned for this user is because their group memberships could not be determined, which may indicate an issue with claims configuration or Active Directory connectivity.
            return Array.Empty<string>();
        }

        var allowedSearchBases = _delegationRules
            .Where(rule => userGroupTokens.Contains(NormalizeSecurityIdentifier(rule.SecurityIdentifier)))
            .Select(rule => rule.SearchBaseLdapPath)
            .Where(IsSearchBaseAllowed)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (allowedSearchBases.Count == 0)
        {
            _logger.LogInformation("User {IdentityName} has no delegated search bases.", user?.Identity?.Name); // This log entry helps administrators understand that the reason no search bases are being returned for this user is because they do not have any delegated search bases, which may indicate an issue with delegation rules or group memberships.      
        }

        return allowedSearchBases; // Return the list of allowed search bases for the user based on the delegation rules. This list will be used by the GetServerNames method to determine where to search for computer objects for this user.
    }

    /// <summary>
    /// Resolves an identity to an Active Directory distinguished name.
    /// </summary>
    /// <param name="identityName">SAM name, DOMAIN\account, or UPN; nullable where declared.</param>
    /// <returns>The directory DN, original identity fallback, or "unknown-user" for missing input.</returns>
    /// <remarks>Input is escaped against LDAP injection. Failures are logged and suppressed.</remarks>
    public string GetUserDistinguishedName(string? identityName)
    {
        if (string.IsNullOrWhiteSpace(identityName)) // If the identity name is null, empty, or whitespace, we cannot resolve a distinguished name for the user, so we return "unknown-user" to indicate that the user is not recognized. This allows the application to handle cases where the user context is not properly established without throwing exceptions.
        {
            return "unknown-user";
        }

        try
        {
            var entries = LdapSearchPaged(
                _domainLdapPath,
                BuildUserLookupFilter(identityName),
                SearchScope.Subtree,
                "distinguishedName", "userPrincipalName");
            var entry = entries.FirstOrDefault();
            return entry != null
                ? ReadEntryAttribute(entry, "distinguishedName") ?? identityName
                : identityName;
        }
        catch (Exception ex) when (ex is Sds.LdapException)
        {
            _logger.LogWarning(ex, "LDAP error while resolving DN for user {IdentityName}. Falling back to identity name.", identityName);
            return identityName;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Unexpected error while resolving DN for user {IdentityName}. Falling back to identity name.", identityName);
            return identityName;
        }
    }

    /// <summary>
    /// Resolves an identity to an Active Directory user principal name.
    /// </summary>
    /// <param name="identityName">SAM name, DOMAIN\account, or UPN; nullable where declared.</param>
    /// <returns>The directory UPN, original identity fallback, or an empty string for missing input.</returns>
    /// <remarks>Input is escaped against LDAP injection. Failures are logged and suppressed.</remarks>
    public string GetUserPrincipalName(string? identityName)
    {
        // If the identity name is null, empty, or whitespace, we cannot resolve a UPN for the user, so we return an empty string to indicate that the UPN is not available. 
        // This allows the application to handle cases where the user context is not properly established without throwing exceptions.
        if (string.IsNullOrWhiteSpace(identityName))
        {
            return string.Empty;
        }

        try
        {
            var entries = LdapSearchPaged(
                _domainLdapPath,
                BuildUserLookupFilter(identityName),
                SearchScope.Subtree,
                "userPrincipalName");
            var entry = entries.FirstOrDefault();
            return entry != null
                ? ReadEntryAttribute(entry, "userPrincipalName") ?? identityName
                : identityName;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Unexpected error while resolving UPN for user {IdentityName}. Falling back to identity name.", identityName);
            return identityName;
        }
    }
    // This helper method escapes special characters in a string for use in an LDAP filter. This is important to prevent LDAP injection vulnerabilities and to ensure that the filter syntax is correct when the input value contains characters that have special meaning in LDAP filters.
    /// <summary>
    /// Escapes LDAP filter metacharacters according to RFC 4515.
    /// </summary>
    /// <param name="value">Value to process; expected non-null unless declared nullable.</param>
    /// <returns>A filter-safe representation of the value.</returns>
    /// <remarks>Prevents identity text from changing LDAP filter structure.</remarks>
    private static string EscapeLdapFilter(string value)
    {
        // According to RFC 4515, the following characters need to be escaped in LDAP filters:
        // * ( ) \ and the null character. We replace each of these characters with a backslash followed by their two-digit hexadecimal ASCII code. 
        // This ensures that the input value can be safely included in an LDAP filter without breaking the syntax or allowing for injection attacks. 
        // The resulting escaped string is returned for use in LDAP filter construction.
        return value
            .Replace("\\", "\\5c")
            .Replace("*", "\\2a")
            .Replace("(", "\\28")
            .Replace(")", "\\29")
            .Replace("\0", "\\00");
    }

    // This helper method attempts to extract the domain portion from a user principal name (UPN) string.
    // It checks if the UPN is valid and contains an '@' character, and if so, it takes the portion after the last '@' as the domain. 
    // It then trims any whitespace from the extracted domain and returns it. If the UPN is not valid or does not contain an '@' character, it returns null.
    // This allows the application to infer a default domain for the user based on their UPN, which is a common format for user identities in Active Directory.
    // If the UPN is not available or does not contain domain information, the application can fall back to other methods of determining the domain.
    /// <summary>
    /// Extracts the suffix after the last at-sign in a UPN.
    /// </summary>
    /// <param name="upn">UPN to parse; may be null or blank.</param>
    /// <returns>The trimmed suffix, or null when none exists.</returns>
    private static string? ExtractDomainFromUpn(string? upn)
    {
        if (string.IsNullOrWhiteSpace(upn)) // If the UPN is null, empty, or whitespace, we cannot extract a domain from it, so we return null. This allows the application to handle cases where the UPN is not properly established without throwing exceptions.
        {
            return null;
        }

        var atIndex = upn.LastIndexOf('@'); // Find the index of the last '@' character in the UPN. The domain portion is expected to be after this character. If there is no '@' character, or if it is at the end of the string, we cannot extract a valid domain, so we return null.
        if (atIndex < 0 || atIndex >= upn.Length - 1)
        {
            return null; // If there is no '@' character or if it is the last character in the string, we cannot extract a domain, so we return null. This means that the UPN does not contain valid domain information in this case.
        }

        var domain = upn[(atIndex + 1)..].Trim(); // Extract the portion of the UPN after the last '@' character, which is expected to be the domain, and trim any whitespace from it. This allows us to get a clean domain string for comparison and filtering. We return this extracted domain as the result.
        return string.IsNullOrWhiteSpace(domain) ? null : domain; // If the extracted domain is null, empty, or whitespace after trimming, we return null to indicate that we could not extract a valid domain. Otherwise, we return the extracted domain string.
    }

    // This helper method attempts to extract the common name (CN) from a distinguished name (DN) string.
    // It checks if the distinguished name starts with "CN=" and if so, it extracts the portion after "CN=" up to the first comma (if present) as the common name. 
    // If the distinguished name does not start with "CN=", it returns the original distinguished name as a fallback. 
    // This allows us to get a more user-friendly name for groups or objects when the CN is available in the DN, while still providing a fallback if the format is unexpected.
    /// <summary>
    /// Extracts the leading common-name component from a distinguished name.
    /// </summary>
    /// <param name="distinguishedName">Distinguished name to inspect; expected non-null.</param>
    /// <returns>The leading CN value, or the original value for an unexpected format.</returns>
    private static string ExtractCommonNameFromDn(string distinguishedName)
    {
        const string cnPrefix = "CN="; // The common name (CN) in a distinguished name typically starts with "CN=". We check for this prefix to determine if we can extract the CN from the DN. If the DN does not start with this prefix, we will return the original DN as a fallback.
        if (!distinguishedName.StartsWith(cnPrefix, StringComparison.OrdinalIgnoreCase)) // If the distinguished name does not start with "CN=", we cannot reliably extract a common name from it, so we return the original distinguished name as a fallback. This allows the application to continue functioning even if the DN format is not as expected, although it may not provide a user-friendly name in this case.
        {
            return distinguishedName; // Return the original distinguished name as a fallback if it does not start with "CN=". This means that if the DN format is unexpected, we will still have some identifier to work with, even if it is not the common name.
        }

        var commaIndex = distinguishedName.IndexOf(','); // Find the index of the first comma in the distinguished name. The common name is typically the portion after "CN=" and before the first comma. If there is no comma, we will take the entire portion after "CN=" as the common name.
        if (commaIndex <= cnPrefix.Length) // If there is no comma, or if the comma is immediately after "CN=", we will take the entire portion after "CN=" as the common name. This allows us to handle cases where the DN consists of only a CN without additional components.
        {
            return distinguishedName[cnPrefix.Length..]; // Extract the portion of the distinguished name after "CN=" as the common name and return it. This is the user-friendly name we want to use for display purposes when the DN format is as expected.
        }

        return distinguishedName[cnPrefix.Length..commaIndex]; // Extract the portion of the distinguished name after "CN=" and before the first comma as the common name and return it. This allows us to get a clean common name for display purposes when the DN format is as expected.
    }
    // This helper method attempts to extract a display name for a group from an LDAP search result. 
    // It first tries to read the "cn" property, which is commonly used for the common name of groups. If the "cn" property is not available or is empty, it falls back to reading the "distinguishedName" property and extracting the common name from it using the ExtractCommonNameFromDn method. If neither property provides a valid name, it returns null. This allows us to get a user-friendly display name for groups when possible, while still providing a fallback mechanism if the expected properties are not present.
    /// <summary>
    /// Gets a displayable group name from cn or the distinguished name.
    /// </summary>
    /// <param name="entry">LDAP search result to inspect.</param>
    /// <returns>A group name, or null when none is usable.</returns>
    private static string? ExtractGroupDisplayName(SearchResultEntry entry)
    {
        var cn = ReadEntryAttribute(entry, "cn");
        if (!string.IsNullOrWhiteSpace(cn))
            return cn;

        // Prefer the attribute value; fall back to the always-populated DistinguishedName property.
        var distinguishedName = ReadEntryAttribute(entry, "distinguishedName")
            ?? (string.IsNullOrWhiteSpace(entry.DistinguishedName) ? null : entry.DistinguishedName);
        return string.IsNullOrWhiteSpace(distinguishedName)
            ? null
            : ExtractCommonNameFromDn(distinguishedName);
    }

    /// <summary>
    /// Finds direct membership and optional LDAP link time-to-live metadata.
    /// </summary>
    /// <param name="entry">Group entry whose <c>member</c> values are inspected.</param>
    /// <param name="userDistinguishedName">User distinguished name compared without regard to case.</param>
    /// <returns>A tuple indicating membership and its parseable remaining seconds.</returns>
    /// <remarks>Nested membership does not count unless the user DN is present directly in member values.</remarks>
    private static (bool Found, int? RemainingSeconds) GetDirectMembershipTimeToLive(
        SearchResultEntry entry,
        string userDistinguishedName)
    {
        if (!entry.Attributes.TryGetValue("member", out var members))
        {
            return (false, null);
        }

        foreach (var memberValue in members.Select(value => value?.ToString()).Where(value => value != null))
        {
            var value = memberValue!;
            var ttlMatch = Regex.Match(value, @"^<TTL=(?<seconds>\d+)>,(?<dn>.+)$", RegexOptions.IgnoreCase);
            if (ttlMatch.Success
                && ttlMatch.Groups["dn"].Value.Equals(userDistinguishedName, StringComparison.OrdinalIgnoreCase))
            {
                return int.TryParse(ttlMatch.Groups["seconds"].Value, out var seconds)
                    ? (true, seconds)
                    : (true, null);
            }

            if (value.Equals(userDistinguishedName, StringComparison.OrdinalIgnoreCase))
            {
                return (true, null);
            }
        }

        return (false, null);
    }

    /// <summary>
    /// Parses an elevation-group name into computer, domain, and TTL data.
    /// </summary>
    /// <param name="groupName">Elevation-group display name to parse.</param>
    /// <param name="remainingSeconds">Optional remaining link TTL.</param>
    /// <returns>A populated model, or null when prefix validation fails or no computer remains.</returns>
    /// <remarks>Removes the configured prefix and splits on the first configured domain separator.</remarks>
    private ElevatedComputerViewModel? ParseElevatedComputer(string groupName, int? remainingSeconds)
    {
        var value = groupName.Trim();
        if (!string.IsNullOrWhiteSpace(_adminPreFix))
        {
            if (!value.StartsWith(_adminPreFix, StringComparison.OrdinalIgnoreCase))
            {
                return null;
            }

            value = value[_adminPreFix.Length..];
        }

        string? domain = null;
        var computerName = value;
        if (!string.IsNullOrWhiteSpace(_domainSeparator))
        {
            var separatorIndex = value.IndexOf(_domainSeparator, StringComparison.Ordinal);
            if (separatorIndex >= 0)
            {
                domain = value[..separatorIndex].Trim();
                computerName = value[(separatorIndex + _domainSeparator.Length)..].Trim();
            }
        }

        return string.IsNullOrWhiteSpace(computerName)
            ? null
            : new ElevatedComputerViewModel
            {
                ComputerName = computerName,
                Domain = string.IsNullOrWhiteSpace(domain) ? null : domain,
                RemainingSeconds = remainingSeconds
            };
    }
    // This helper method checks if a given LDAP search base is allowed based on the configured server search base LDAP paths.
    // It compares the search base to each of the configured base paths, allowing for case-insensitive matches and also allowing for the search base to end with the configured base path (ignoring the "LDAP://" prefix).  
    /// <summary>
    /// Checks whether a delegated search base is within configured server bases.
    /// </summary>
    /// <param name="searchBase">Search-base token, LDAP path, or relative DN.</param>
    /// <returns>True for an exact configured path or a path ending in a configured base DN.</returns>
    /// <remarks>This allow-list prevents delegation rules from expanding directory visibility.</remarks>
    private bool IsSearchBaseAllowed(string searchBase)
    {
        // We check if the search base matches any of the configured server search base LDAP paths. We allow for case-insensitive matches, and we also allow for the search base to end with the configured base path (ignoring the "LDAP://" prefix) to provide flexibility in how the search bases are specified in the configuration. This allows administrators to specify search bases in a way that is convenient for them while still ensuring that only allowed search bases are used by the service.
        return _serverSearchBaseLdapPaths.Any(basePath =>
            searchBase.Equals(basePath, StringComparison.OrdinalIgnoreCase)
            || searchBase.EndsWith(basePath["LDAP://".Length..], StringComparison.OrdinalIgnoreCase));
    }

    // This helper method resolves the domain LDAP path to be used for Active Directory queries. 
    // It first checks if the JIT configuration specifies a DomainFqdn and builds the LDAP path from it. 
    // If not, it checks if there is a DomainLdapPath configured directly in the application configuration. 
    // If neither is specified, it attempts to resolve the domain FQDN using other methods and builds the LDAP path from that. 
    // This allows for flexible configuration of the domain LDAP path based on either direct specification or inference from the environment.
    /// <summary>
    /// Resolves the LDAP domain root from JIT, application, or host DNS configuration.
    /// </summary>
    /// <param name="jitConfiguration">Loaded JIT configuration.</param>
    /// <returns>The domain LDAP path.</returns>
    /// <exception cref="InvalidOperationException">No domain can be resolved.</exception>
    private string ResolveDomainLdapPath(JitConfiguration jitConfiguration)
    {
        // First, we check if the JIT configuration specifies a DomainFqdn. If it does, we build the LDAP path from this FQDN and return it. 
        // This allows the JIT configuration to take precedence in defining the domain context for Active Directory queries, 
        // which can be useful in scenarios where the service needs to operate in different domain contexts based on JIT settings.
        if (!string.IsNullOrWhiteSpace(jitConfiguration.DomainFqdn))
        {
            return BuildDomainLdapPath(jitConfiguration.DomainFqdn);
        }

        var configured = _configuration["ActiveDirectory:DomainLdapPath"]; // If the JIT configuration does not specify a DomainFqdn, we check if there is a DomainLdapPath configured directly in the application configuration. If it is specified, we return this configured LDAP path. This allows for direct configuration of the domain LDAP path without relying on JIT settings, providing flexibility for different deployment scenarios.  
        if (!string.IsNullOrWhiteSpace(configured))
        {
            return configured;
        }

        var domainFqdn = ResolveDomainFqdn(); // If neither the JIT configuration nor the application configuration provides a domain LDAP path, we attempt to resolve the domain FQDN using other methods (e.g. from the environment or DNS) and then build the LDAP path from that. This allows the service to infer the domain context in cases where it is not explicitly configured, which can simplify deployment in certain environments where the domain can be automatically determined.       
        return BuildDomainLdapPath(domainFqdn);
    }

    // This helper method builds an LDAP path from a given domain FQDN. 
    // It splits the FQDN into its components and constructs an LDAP path in the format of "LDAP://DC=part1,DC=part2,...". 
    // This allows us to convert a standard domain FQDN into the corresponding LDAP path format that can be used for Active Directory queries.

    /// <summary>
    /// Builds an LDAP domain-root path from an FQDN.
    /// </summary>
    /// <param name="domainFqdn">Dot-separated domain FQDN.</param>
    /// <returns>An LDAP path composed of DC components.</returns>
    /// <remarks>Empty labels are removed; no DNS validation occurs.</remarks>
    private static string BuildDomainLdapPath(string domainFqdn)
    {
        // We split the domain FQDN into its components (e.g. "example.com" becomes ["example", "com"]) and then construct the LDAP path by prefixing each component with "DC=" and joining them with commas. This results in an LDAP path like "LDAP://DC=example,DC=com" which can be used as the search base for Active Directory queries. This transformation allows us to work with standard domain FQDNs while still being able to generate the necessary LDAP paths for querying Active Directory.   
        var dcParts = domainFqdn
            .Split('.', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(part => $"DC={part}");

        return $"LDAP://{string.Join(',', dcParts)}";
    }

    // This helper method resolves the JIT configuration for the Active Directory service. 
    // It reads the JIT configuration path from the application configuration and attempts to load the JIT configuration from the specified path. 
    // If the path is not specified or the configuration cannot be loaded, it returns a default JIT configuration. 
    // This allows the service to dynamically load JIT settings based on the environment or deployment scenario.
    /// <summary>
    /// Loads JIT configuration from the resolved configuration path.
    /// </summary>
    /// <returns>A loaded configuration, or a default instance when no path is set.</returns>
    /// <remarks>Load failures are logged and rethrown.</remarks>
    /// <exception cref="Exception">The configured file cannot be loaded or parsed.</exception>
    private JitConfiguration ResolveJitConfiguration()
    {
        var jitConfigPath = JitConfigPathResolver.Resolve(_configuration); // Read the JIT configuration path from app configuration first, then fallback to JustInTimeConfig environment variable. If no path is provided, use the default JIT configuration resolution.
        try
        {
            // If the JIT configuration path is not specified, we return a default JIT configuration. 
            // Otherwise, we attempt to load the JIT configuration from the specified path. 
            // This allows for flexible configuration of JIT settings based on whether a custom configuration file is provided or not. 
            // If there are issues with loading the JIT configuration (e.g. file not found, invalid format), we catch the exception, log an error, and rethrow it to ensure that the service does not start with an invalid configuration.
            return string.IsNullOrWhiteSpace(jitConfigPath)
                ? new JitConfiguration()
                : new JitConfiguration(jitConfigPath);
        }
        // If there is an error while loading the JIT configuration, we log the error and rethrow the exception. 
        // This ensures that any issues with the JIT configuration are properly recorded in the logs and that the service does not start with an invalid or incomplete configuration, which could lead to unexpected behavior.
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error while loading JIT configuration.");
            throw;
        }
    }

    // This helper method resolves the server search base LDAP paths from the JIT configuration. 
    // It checks if the JIT configuration contains any T1SearchBaseLdapPaths and if so, it returns them as the server search base LDAP paths. 
    // If there are no valid T1SearchBaseLdapPaths in the JIT configuration, it logs an error and throws an exception to prevent the service from starting without valid search bases.
    /// <summary>
    /// Resolves and domain-qualifies configured server search bases.
    /// </summary>
    /// <param name="jitConfig">JIT configuration containing search bases.</param>
    /// <returns>A distinct case-insensitive list.</returns>
    /// <exception cref="InvalidOperationException">No search base is configured.</exception>
    private IReadOnlyList<string> ResolveServerSearchBasesFromJitConfiguration(JitConfiguration jitConfig)
    {
        // We check if the JIT configuration contains any T1SearchBaseLdapPaths. 
        // If it does, we log the count of search bases loaded and return them as the server search base LDAP paths. 
        // This allows the JIT configuration to define the search bases that the service will use for Active Directory queries, which can be useful for dynamically controlling the scope of searches based on JIT settings. If there are no valid T1SearchBaseLdapPaths in the JIT configuration, we log an error and throw an exception to prevent the service from starting without valid search bases, which are essential for its operation.
        if (jitConfig.T1SearchBaseLdapPaths.Count > 0)
        {
            var resolvedSearchBases = jitConfig.T1SearchBaseLdapPaths
                .Select(searchBase => QualifySearchBaseForDomain(searchBase, _domainLdapPath))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            _logger.LogInformation(
                "Server search bases loaded from JIT config file {FilePath}. Count: {Count}. ResolvedBases=[{ResolvedBases}]",
                jitConfig.JitConfigPath,
                resolvedSearchBases.Count,
                string.Join("; ", resolvedSearchBases));
            return resolvedSearchBases;
        }
        // If there are no valid T1SearchBaseLdapPaths in the JIT configuration, we log an error and throw an exception to prevent the service from starting without valid search bases. 
        // This is a critical configuration issue, as the service relies on having valid search bases to function properly. By throwing an exception, we ensure that this issue is addressed during deployment or configuration rather than allowing the service to run in a broken state.
        _logger.LogError(
            "No valid T1Searchbase LDAP paths found in JIT config file {FilePath}. Service startup must be aborted.",
            jitConfig.JitConfigPath);
        // We throw an exception to prevent the service from starting without valid search bases, which are essential for its operation. 
        // This forces administrators to address the configuration issue before the service can run, ensuring that it does not operate in a broken state.
        throw new InvalidOperationException(
            $"No valid T1Searchbase LDAP paths were found in JIT config file '{jitConfig.JitConfigPath}'.");
    }

    /// <summary>
    /// Qualifies a search-base token or relative DN against the domain path.
    /// </summary>
    /// <param name="searchBase">Search-base token, LDAP path, or relative DN.</param>
    /// <param name="domainLdapPath">Domain LDAP path used for qualification.</param>
    /// <returns>A fully prefixed LDAP path.</returns>
    private static string QualifySearchBaseForDomain(string searchBase, string domainLdapPath)
    {
        if (searchBase.Equals("<DomainRoot>", StringComparison.OrdinalIgnoreCase))
        {
            return domainLdapPath;
        }

        var searchBaseDn = searchBase.StartsWith("LDAP://", StringComparison.OrdinalIgnoreCase)
            ? searchBase["LDAP://".Length..]
            : searchBase;
        if (Regex.IsMatch(searchBaseDn, @"(^|,)\s*DC=", RegexOptions.IgnoreCase))
        {
            return $"LDAP://{searchBaseDn}";
        }

        var domainDn = domainLdapPath.StartsWith("LDAP://", StringComparison.OrdinalIgnoreCase)
            ? domainLdapPath["LDAP://".Length..]
            : domainLdapPath;
        return $"LDAP://{searchBaseDn},{domainDn}";
    }

    // This helper method resolves the delegation rules from the JIT configuration. 
    // It checks if delegation is enabled in the JIT configuration, and if so, it attempts to load the delegation configuration from the specified path. 
    // If delegation is not enabled, it returns an empty list of delegation rules.  
    /// <summary>
    /// Loads delegation rules when delegation is enabled.
    /// </summary>
    /// <param name="jitConfiguration">Loaded JIT configuration.</param>
    /// <returns>Loaded rules, or an empty list when disabled or loading fails.</returns>
    /// <remarks>Failures are logged and suppressed; an empty result later fails authorization closed.</remarks>
    private IReadOnlyList<DelegationRule> ResolveDelegationRules(JitConfiguration jitConfiguration)
    {
        // We check if delegation is enabled in the JIT configuration. 
        // If it is not enabled, we return an empty list of delegation rules, which means that no delegation will be applied when determining search bases for users. 
        // This allows the service to operate without delegation if it is not needed or desired, while still providing the option to enable it through configuration.
        if (!jitConfiguration.EnableDelegation)
        {
            return Array.Empty<DelegationRule>();
        }
        // If delegation is enabled, we check if the DelegationConfigPath is specified in the JIT configuration. 
        // If it is not specified, we log a warning and return an empty list of delegation rules, which means that no delegation will be applied. 
        // This allows the service to continue operating without delegation, even if it is enabled in the configuration, while still providing a warning to administrators.
        if (string.IsNullOrWhiteSpace(jitConfiguration.DelegationConfigPath))
        {
            _logger.LogWarning("EnableDelegation is true but DelegationConfigPath is not configured in JIT.config.");
            return Array.Empty<DelegationRule>();
        }

        try
        {
            // If delegation is enabled and a DelegationConfigPath is specified, we attempt to load the delegation configuration from the specified path.
            var delegationConfiguration = new DelegationConfiguration(jitConfiguration.DelegationConfigPath);
            _logger.LogInformation(
                "Delegation config loaded from {FilePath}. Rules: {Count}",
                delegationConfiguration.DelegationConfigPath,
                delegationConfiguration.Rules.Count);

            return delegationConfiguration.Rules;
        }
        // If there is an error while loading the delegation configuration, we log the error and return an empty list of delegation rules. 
        // This allows the service to continue operating without delegation in case of issues with the delegation configuration, while ensuring that the error is recorded in the logs for troubleshooting. 
        // By returning an empty list of delegation rules, we effectively disable delegation without causing the service to fail, which can be a safer fallback in case of configuration issues.
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error while loading delegation configuration from {FilePath}", jitConfiguration.DelegationConfigPath);
            return Array.Empty<DelegationRule>();
        }
    }
    // This helper method resolves the user group tokens from the claims of the given user.
    // It iterates through the claims of the user and looks for claims that represent group SIDs (e.g. ClaimTypes.GroupSid or claims that end with "/groupsid" or "/primarygroupsid").
    // For each group SID claim found, it normalizes the value of the claim (trimming whitespace and quotes, and converting to uppercase) and adds it to a hash set of tokens. 
    // This allows us to efficiently check for group memberships based on SIDs when determining elevation groups for the user. If the user is null, it returns an empty set of tokens.  
    /// <summary>
    /// Collects normalized user and group SIDs for delegation matching.
    /// </summary>
    /// <param name="user">Principal used for identity or delegation checks; may be null.</param>
    /// <returns>A case-insensitive SID set from claims, Windows identity, and directory token groups.</returns>
    /// <remarks>Directory enrichment can query LDAP; failures are logged and suppressed.</remarks>
    private HashSet<string> ResolveUserGroupTokens(ClaimsPrincipal? user)
    {
        var tokens = new HashSet<string>(StringComparer.OrdinalIgnoreCase); // We use a HashSet to store the group tokens for efficient lookup, and we specify a case-insensitive comparer to ensure that token comparisons are not affected by case differences. This allows us to easily check if a user belongs to a group based on its SID without worrying about case sensitivity. If the user is null, we simply return an empty set of tokens, which means that no group memberships will be recognized for a null user.

        if (user == null) // If the user is null, we cannot resolve any group tokens, so we return an empty set. This allows the application to handle cases where the user context is not established without throwing exceptions, while still providing a consistent return type.
        {
            return tokens;
        }
        // We iterate through the claims of the user and look for claims that represent group SIDs. 
        // We check if the claim type is ClaimTypes.GroupSid or if it ends with "/groupsid" or "/primarygroupsid" (ignoring case) to identify group SID claims. 
        // For each group SID claim found, we normalize the value of the claim by trimming whitespace and quotes and converting it to uppercase, and then we add it to the hash set of tokens. 
        // This allows us to build a set of group SIDs that the user belongs to, which can be used for efficiently determining elevation groups based on group memberships.   
        foreach (var claim in user.Claims)
        {
            if (!IsGroupSidClaim(claim)) // If the claim is not a group SID claim, we skip it and continue to the next claim. We are only interested in claims that represent group SIDs for the purpose of determining elevation groups, so we ignore any other types of claims. This allows us to focus on the relevant claims for our use case while efficiently building the set of group tokens.   
            {
                continue;
            }

            tokens.Add(NormalizeSecurityIdentifier(claim.Value)); // If the claim is a group SID claim, we normalize the value of the claim (trimming whitespace and quotes, and converting to uppercase) and add it to the hash set of tokens. This ensures that the group SIDs are stored in a consistent format for efficient lookup when determining elevation groups based on group memberships. By normalizing the SIDs, we can avoid issues with formatting differences that may arise from different sources of claims or variations in how SIDs are represented.
        }

        // Some authentication flows emit only a partial set of SID claims.
        // Enrich them with the user SID and all effective group memberships so both
        // direct-user and group delegation rules can match.
        var windowsIdentity = user.Identities.OfType<WindowsIdentity>().FirstOrDefault();
        AddWindowsIdentityTokens(windowsIdentity, tokens);
        AddDirectoryIdentityTokens(user.Identity?.Name, tokens);

        return tokens;
    }

    /// <summary>
    /// Adds the Windows user SID and effective group SIDs to a token set.
    /// </summary>
    /// <param name="identity">Windows identity; may be null.</param>
    /// <param name="tokens">Mutable destination SID set.</param>
    /// <remarks>Mutates the destination set and performs no network access.</remarks>
    private static void AddWindowsIdentityTokens(WindowsIdentity? identity, ISet<string> tokens)
    {
        var userSid = identity?.User?.Value;
        if (!string.IsNullOrWhiteSpace(userSid))
        {
            tokens.Add(NormalizeSecurityIdentifier(userSid));
        }

        if (identity?.Groups == null)
        {
            return;
        }

        foreach (var groupSid in identity.Groups)
        {
            var sidValue = groupSid?.Value;
            if (!string.IsNullOrWhiteSpace(sidValue))
            {
                tokens.Add(NormalizeSecurityIdentifier(sidValue));
            }
        }
    }

    /// <summary>
    /// Adds the directory user SID and computed tokenGroups SIDs to a token set.
    /// </summary>
    /// <param name="identityName">SAM name, DOMAIN\account, or UPN; nullable where declared.</param>
    /// <param name="tokens">Mutable destination SID set.</param>
    /// <remarks>Performs LDAP searches, mutates the set, and logs/suppresses lookup failures.</remarks>
    private void AddDirectoryIdentityTokens(string? identityName, ISet<string> tokens)
    {
        if (string.IsNullOrWhiteSpace(identityName))
        {
            return;
        }

        try
        {
            // Step 1: resolve the user's distinguished name via LDAP.
            var userEntries = LdapSearchPaged(
                _domainLdapPath,
                BuildUserLookupFilter(identityName),
                SearchScope.Subtree,
                "distinguishedName",
                "objectSid");

            var userEntry = userEntries.FirstOrDefault();
            var userDn = userEntry is null
                ? null
                : ReadEntryAttribute(userEntry, "distinguishedName");

            if (string.IsNullOrWhiteSpace(userDn))
                return;

            var objectSidAttribute = userEntry?.Attributes["objectSid"];
            if (objectSidAttribute?[0] is byte[] objectSidBytes && objectSidBytes.Length > 0)
            {
                tokens.Add(NormalizeSecurityIdentifier(new SecurityIdentifier(objectSidBytes, 0).Value));
            }

            // Step 2: base-scope search on the user DN for the tokenGroups constructed attribute.
            var tgEntries = LdapSearchPaged(
                userDn,
                "(objectClass=*)",
                SearchScope.Base,
                "tokenGroups");

            if (tgEntries.Count == 0)
                return;

            var tgAttr = tgEntries[0].Attributes["tokenGroups"];
            if (tgAttr == null)
                return;

            for (var i = 0; i < tgAttr.Count; i++)
            {
                if (tgAttr[i] is byte[] sidBytes && sidBytes.Length > 0)
                {
                    var sid = new SecurityIdentifier(sidBytes, 0).Value;
                    if (!string.IsNullOrWhiteSpace(sid))
                        tokens.Add(NormalizeSecurityIdentifier(sid));
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Unexpected error while resolving tokenGroups for user {IdentityName}.", identityName);
        }
    }

    /// <summary>
    /// Builds an injection-safe LDAP user filter for an identity.
    /// </summary>
    /// <param name="identityName">SAM name, DOMAIN\account, or UPN; nullable where declared.</param>
    /// <returns>A filter restricted to user objects.</returns>
    /// <remarks>Every identity fragment is escaped before interpolation.</remarks>
    private static string BuildUserLookupFilter(string identityName)
    {
        var trimmedIdentity = identityName.Trim();

        if (trimmedIdentity.Contains('\\'))
        {
            var accountName = trimmedIdentity[(trimmedIdentity.LastIndexOf('\\') + 1)..];
            return $"(&(objectCategory=user)(sAMAccountName={EscapeLdapFilter(accountName)}))";
        }

        if (trimmedIdentity.Contains('@'))
        {
            var upn = EscapeLdapFilter(trimmedIdentity);
            var samAccountName = EscapeLdapFilter(trimmedIdentity[..trimmedIdentity.IndexOf('@')]);
            return $"(&(objectCategory=user)(|(userPrincipalName={upn})(sAMAccountName={samAccountName})))";
        }

        return $"(&(objectCategory=user)(sAMAccountName={EscapeLdapFilter(trimmedIdentity)}))";
    }

    // This helper method checks if a given claim is a group SID claim by examining the claim type.
    // It returns true if the claim type is ClaimTypes.GroupSid or if it ends with "/groupsid" or "/primarygroupsid" (ignoring case), which are common patterns for claims that represent group SIDs in various identity systems.   
    /// <summary>
    /// Tests whether a claim type represents a group or primary-group SID.
    /// </summary>
    /// <param name="claim">Claim to inspect.</param>
    /// <returns>True for recognized SID claim types; otherwise false.</returns>
    private static bool IsGroupSidClaim(Claim claim)
    {
        return claim.Type == ClaimTypes.GroupSid
            || claim.Type.EndsWith("/groupsid", StringComparison.OrdinalIgnoreCase)
            || claim.Type.EndsWith("/primarygroupsid", StringComparison.OrdinalIgnoreCase);
    }

    // This helper method normalizes a security identifier (SID) string by trimming whitespace and quotes, and converting it to uppercase.
    // This ensures that SIDs are stored in a consistent format for efficient lookup and comparison when determining group memberships based on SIDs. By normalizing the SIDs, we can avoid issues with formatting differences that may arise from different sources of claims or variations in how SIDs are represented, allowing for reliable comparisons when checking if a user belongs to a group based on its SID.
    /// <summary>
    /// Normalizes SID text for authorization comparisons.
    /// </summary>
    /// <param name="value">Value to process; expected non-null unless declared nullable.</param>
    /// <returns>The trimmed, unquoted, upper-case SID text.</returns>
    private static string NormalizeSecurityIdentifier(string value)
    {
        // We trim any leading or trailing whitespace from the value, remove any surrounding quotes (both single and double), and convert the string to uppercase to ensure a consistent format for security identifiers (SIDs). This normalization process allows us to reliably compare SIDs regardless of variations in formatting that may occur in different sources of claims or representations of SIDs. By storing SIDs in a normalized format, we can efficiently check for group memberships based on SIDs when determining elevation groups for users.
        return value.Trim().Trim('"', '\'').ToUpperInvariant();
    }

    // This helper method resolves the domain FQDN to be used for Active Directory queries.
    // It first checks if the domain FQDN is specified in the application configuration and returns it if available. 
    // If not, it checks if there is a domain LDAP path configured and attempts to parse the domain FQDN from it. 
    // If that also fails, it tries to get the domain name from the DNS configuration of the machine. 
    // If all methods fail to resolve a valid domain FQDN, it throws an exception to indicate that the domain FQDN could not be resolved and that the configuration needs to be updated. 
    // This allows for flexible resolution of the domain FQDN based on various configuration options and environment settings, while ensuring that the service does not operate without a valid domain context.   
    /// <summary>
    /// Resolves the directory DNS domain from configuration or host networking.
    /// </summary>
    /// <returns>The resolved domain FQDN.</returns>
    /// <exception cref="InvalidOperationException">No domain can be determined.</exception>
    private string ResolveDomainFqdn()
    {
        var configuredFqdn = _configuration["ActiveDirectory:DomainFqdn"]; // First, we check if the domain FQDN is specified in the application configuration. If it is, we return this configured FQDN for use in building the domain LDAP path. This allows administrators to directly specify the domain FQDN in the configuration, which can be useful for clarity and explicit configuration of the domain context for Active Directory queries.
        if (!string.IsNullOrWhiteSpace(configuredFqdn)) // If the domain FQDN is specified in the configuration and is not empty or whitespace, we return it as the resolved domain FQDN. This allows us to use the explicitly configured domain FQDN for building the LDAP path, providing a clear and direct way to specify the domain context for Active Directory queries.
        {
            return configuredFqdn; // Return the configured domain FQDN from the application configuration if it is specified and valid. This allows for straightforward configuration of the domain context for Active Directory queries without relying on inference or other methods of resolution.
        }

        var configuredLdapPath = _configuration["ActiveDirectory:DomainLdapPath"]; // If the domain FQDN is not directly configured, we check if there is a domain LDAP path configured in the application configuration. If it is specified, we attempt to parse the domain FQDN from this LDAP path using the ParseDomainFqdnFromLdapPath helper method. If we successfully parse a valid domain FQDN from the LDAP path, we return it. This allows us to infer the domain FQDN from a provided LDAP path, which can be useful in cases where administrators prefer to specify the LDAP path directly and have the service extract the necessary domain information from it.
        if (!string.IsNullOrWhiteSpace(configuredLdapPath)) // If there is a domain LDAP path configured, we attempt to parse the domain FQDN from it. If we successfully parse a valid domain FQDN from the LDAP path, we return it. This allows us to infer the domain FQDN from a provided LDAP path, which can be useful in cases where administrators prefer to specify the LDAP path directly and have the service extract the necessary domain information from it. If the parsing fails or does not yield a valid domain FQDN, we will continue to the next method of resolution.
        {
            var fromLdap = ParseDomainFqdnFromLdapPath(configuredLdapPath); // Attempt to parse the domain FQDN from the configured domain LDAP path. If this parsing is successful and yields a valid domain FQDN, we return it as the resolved domain FQDN. This allows us to derive the necessary domain information from the LDAP path configuration, providing flexibility in how the domain context can be specified in the application configuration. If the parsing does not yield a valid domain FQDN, we will continue to the next method of resolution, which is to check the DNS configuration of the machine.
            if (!string.IsNullOrWhiteSpace(fromLdap)) // If the parsing of the domain FQDN from the configured domain LDAP path is successful and yields a valid domain FQDN, we return it as the resolved domain FQDN. This allows us to use the inferred domain FQDN from the LDAP path configuration for building the domain LDAP path, providing a way to specify the domain context indirectly through the LDAP path. If the parsing fails or does not yield a valid domain FQDN, we will continue to the next method of resolution, which is to check the DNS configuration of the machine.
            {
                return fromLdap;
            }
        }

        var dnsDomain = IPGlobalProperties.GetIPGlobalProperties().DomainName; // If the domain FQDN is not directly configured and cannot be parsed from a configured LDAP path, we attempt to get the domain name from the DNS configuration of the machine. This is done by accessing the IPGlobalProperties of the machine and retrieving the DomainName property, which typically contains the DNS domain name that the machine is joined to. If this value is available and not empty, we return it as the resolved domain FQDN. This allows us to infer the domain context based on the machine's network configuration, which can be useful in environments where machines are joined to a domain and we want to automatically determine the domain context for Active Directory queries. If this method also fails to yield a valid domain FQDN, we will throw an exception to indicate that the domain FQDN could not be resolved.
        if (!string.IsNullOrWhiteSpace(dnsDomain)) // If the domain name obtained from the DNS configuration of the machine is available and not empty, we return it as the resolved domain FQDN. This allows us to infer the domain context based on the machine's network configuration, which can be useful in environments where machines are joined to a domain and we want to automatically determine the domain context for Active Directory queries. If this method also fails to yield a valid domain FQDN (i.e. if the dnsDomain is null, empty, or whitespace), we will throw an exception to indicate that the domain FQDN could not be resolved and that the configuration needs to be updated.
        {
            return dnsDomain; // Return the domain name obtained from the DNS configuration of the machine if it is available and valid. This allows us to use the inferred domain FQDN from the machine's network configuration for building the domain LDAP path, providing a way to automatically determine the domain context in environments where machines are joined to a domain. If this method also fails to yield a valid domain FQDN, we will throw an exception to indicate that the domain FQDN could not be resolved and that the configuration needs to be updated.
        }
        // If all methods of resolving the domain FQDN fail, we log an error and throw an exception to indicate that the domain FQDN could not be resolved. This is a critical issue, as the service relies on having a valid domain context to function properly. By throwing an exception, we ensure that this issue is addressed during deployment or configuration rather than allowing the service to run in a broken state without a valid domain context for Active Directory queries.
        _logger.LogError("Domain FQDN could not be resolved. Configure ActiveDirectory:DomainFqdn or ActiveDirectory:DomainLdapPath.");
        throw new InvalidOperationException(
            "Domain FQDN could not be resolved. Configure ActiveDirectory:DomainFqdn or ActiveDirectory:DomainLdapPath.");
    }

    // This helper method attempts to parse a domain FQDN from a given LDAP path. 
    // It uses a regular expression to extract the components of the domain from the LDAP path, which are typically represented as "DC=part" in the path. 
    // It then joins these components with dots to form the FQDN. 
    // If the input LDAP path is null, empty, or does not contain valid domain components, it returns null. 
    // This allows us to infer the domain FQDN from a provided LDAP path when possible, while still providing a fallback of null if the parsing fails or the input is not valid.
    /// <summary>
    /// Extracts DC components from an LDAP path or distinguished name.
    /// </summary>
    /// <param name="ldapPath">LDAP path or DN; may be null only where declared.</param>
    /// <returns>Dot-joined DC labels, or null when none exist.</returns>
    private static string? ParseDomainFqdnFromLdapPath(string? ldapPath)
    {
        if (string.IsNullOrWhiteSpace(ldapPath)) // If the input LDAP path is null, empty, or consists only of whitespace, we cannot parse a valid domain FQDN from it, so we return null. This allows us to handle cases where the LDAP path is not properly configured or provided without throwing exceptions, while still indicating that a valid domain FQDN could not be parsed from the input.
        {
            return null;
        }
        // We use a regular expression to extract the components of the domain from the LDAP path, which are typically represented as "DC=part" in the path. 
        // The regular expression looks for occurrences of "DC=([^,]+)" which captures the value of the domain component after "DC=" and before a comma. 
        // We ignore case when matching to allow for variations in how the LDAP path may be formatted. 
        // If there are no matches found, it means that we could not extract any valid domain components from the LDAP path, and we return null. 
        // This allows us to handle cases where the LDAP path does not contain valid domain information without throwing exceptions, while still indicating that a valid domain FQDN could not be parsed from the input.
        var matches = Regex.Matches(ldapPath, @"DC=([^,]+)", RegexOptions.IgnoreCase);
        if (matches.Count == 0)
        {
            return null;
        }
        // We take the captured domain components from the regular expression matches, trim any whitespace from them, and filter out any empty or whitespace-only values. 
        // We then join the valid domain components with dots to form the FQDN. 
        var labels = matches
            .Select(match => match.Groups[1].Value.Trim())
            .Where(value => !string.IsNullOrWhiteSpace(value));
        // Finally, we join the valid domain components with dots to form the FQDN. 
        // If the resulting FQDN is empty or consists only of whitespace, we return null to indicate that a valid domain FQDN could not be parsed from the input. 
        // This allows us to handle cases where the LDAP path does not contain valid domain information without throwing exceptions, while still indicating that a valid domain FQDN could not be parsed from the input.
        var fqdn = string.Join('.', labels);
        return string.IsNullOrWhiteSpace(fqdn) ? null : fqdn;
    }

    // This helper method normalizes an LDAP path by trimming whitespace and quotes, and ensuring that it starts with "LDAP://".
    // If the input value is null, empty, or consists only of whitespace, it returns null. 
    // If the trimmed value already starts with "LDAP://", it returns the trimmed value as is. 
    // If the trimmed value starts with "OU=", "CN=", or "DC=", it prefixes it with "LDAP://" and returns it. 
    // If the trimmed value does not match any of these patterns, it returns null to indicate that the input could not be normalized into a valid LDAP path.
    /// <summary>
    /// Normalizes a recognizable LDAP path or distinguished name.
    /// </summary>
    /// <param name="value">Value to process; expected non-null unless declared nullable.</param>
    /// <returns>A trimmed LDAP path with LDAP:// prefix, or null when unrecognized.</returns>
    private static string? NormalizeLdapPath(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) // If the input value is null, empty, or consists only of whitespace, we cannot normalize it into a valid LDAP path, so we return null. This allows us to handle cases where the input is not properly provided without throwing exceptions, while still indicating that a valid LDAP path could not be derived from the input.
        {
            return null;
        }

        var trimmed = value.Trim().Trim('"', '\''); // We trim any leading or trailing whitespace from the input value, and we also remove any surrounding quotes (both single and double) to clean up the input before attempting to normalize it into a valid LDAP path. This allows us to handle cases where the input may have unintended whitespace or quotes that could interfere with the normalization process, ensuring that we are working with a clean and consistent string when checking for LDAP path patterns.
        // If the trimmed value already starts with "LDAP://", we assume it is already a valid LDAP path and return it as is. 
        // This allows us to accept fully specified LDAP paths without modification, while still providing normalization for inputs that may be missing the "LDAP://" prefix.
        if (trimmed.StartsWith("LDAP://", StringComparison.OrdinalIgnoreCase))
        {
            return trimmed;
        }
        // If the trimmed value starts with "OU=", "CN=", or "DC=", we assume it is an LDAP path that is missing the "LDAP://" prefix, so we prefix it with "LDAP://" and return it. 
        // This allows us to accept LDAP paths that are specified in a more concise format (e.g. "DC=example,DC=com") and normalize them into a valid LDAP path format by adding the necessary prefix. If the trimmed value does not match any of these patterns, we return null to indicate that the input could not be normalized into a valid LDAP path, which allows us to handle invalid inputs gracefully without throwing exceptions.
        if (trimmed.StartsWith("OU=", StringComparison.OrdinalIgnoreCase)
            || trimmed.StartsWith("CN=", StringComparison.OrdinalIgnoreCase)
            || trimmed.StartsWith("DC=", StringComparison.OrdinalIgnoreCase))
        {
            return $"LDAP://{trimmed}";
        }
        // If the trimmed value does not match any of the expected patterns for an LDAP path, we return null to indicate that the input could not be normalized into a valid LDAP path. 
        // This allows us to handle cases where the input is not in a recognizable format for an LDAP path without throwing exceptions, while still indicating that a valid LDAP path could not be derived from the input.
        return null;
    }
    // ─── LDAP connection & search helpers ─────────────────────────────────────

    /// <summary>
    /// Creates and binds an LDAP connection using the process security context.
    /// </summary>
    /// <returns>A bound connection owned by the caller.</returns>
    /// <remarks>Uses Negotiate/default credentials, signing, sealing, port 389, LDAP v3, and no referral chasing. Binding authenticates but does not modify directory data.</remarks>
    /// <exception cref="Sds.LdapException">The endpoint is unavailable or authentication fails.</exception>
    private Sds.LdapConnection CreateLdapConnection()
    {
        _logger.LogInformation("Creating LDAP connection to {DomainFqdn}", _domainFqdn);
        var identifier = new Sds.LdapDirectoryIdentifier(_domainFqdn, 389, false, false);
        var conn = new Sds.LdapConnection(identifier)
        {
            AuthType = Sds.AuthType.Negotiate,
            Credential = CredentialCache.DefaultNetworkCredentials,
        };
        conn.SessionOptions.ProtocolVersion = 3;
        conn.SessionOptions.ReferralChasing = Sds.ReferralChasingOptions.None;
        conn.SessionOptions.Sealing = true;
        conn.SessionOptions.Signing = true;

        try
        {
            conn.Bind();
            _logger.LogInformation("LDAP bind successful using service security context (Negotiate)");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "LDAP bind failed in service security context");
            throw;
        }
        
        return conn;
    }

    /// <summary>
    /// Executes a paged LDAP search without link TTL metadata.
    /// </summary>
    /// <param name="baseLdapPath">LDAP path or raw base DN.</param>
    /// <param name="filter">LDAP filter; untrusted values must already be escaped.</param>
    /// <param name="scope">Numeric SearchScope value.</param>
    /// <param name="attributes">LDAP attributes to request.</param>
    /// <returns>All successfully parsed entries across pages.</returns>
    /// <remarks>Binds with the service context, pages by 500, logs metadata, and skips malformed entries.</remarks>
    private IList<SearchResultEntry> LdapSearchPaged(string baseLdapPath, string filter, int scope, params string[] attributes)
    {
        return LdapSearchPaged(baseLdapPath, filter, scope, false, attributes);
    }

    /// <summary>
    /// Executes a paged LDAP search requesting Active Directory link TTL metadata.
    /// </summary>
    /// <param name="baseLdapPath">LDAP path or raw base DN.</param>
    /// <param name="filter">LDAP filter; untrusted values must already be escaped.</param>
    /// <param name="scope">Numeric SearchScope value.</param>
    /// <param name="attributes">LDAP attributes to request.</param>
    /// <returns>All successfully parsed entries across pages.</returns>
    /// <remarks>Adds the show-link-TTL control; other security and paging behavior matches the normal search.</remarks>
    private IList<SearchResultEntry> LdapSearchPagedWithLinkTtl(string baseLdapPath, string filter, int scope, params string[] attributes)
    {
        return LdapSearchPaged(baseLdapPath, filter, scope, true, attributes);
    }

    /// <summary>
    /// Implements LDAP paging and optional Active Directory link TTL retrieval.
    /// </summary>
    /// <param name="baseLdapPath">LDAP path or raw base DN.</param>
    /// <param name="filter">LDAP filter; untrusted values must already be escaped.</param>
    /// <param name="scope">Numeric SearchScope value.</param>
    /// <param name="showLinkTimeToLive">Whether to request Active Directory link TTL metadata.</param>
    /// <param name="attributes">LDAP attributes to request.</param>
    /// <returns>A mutable list of successfully converted entries.</returns>
    /// <remarks>Creates and disposes a bound connection and issues read-only searches; transport failures propagate.</remarks>
    private IList<SearchResultEntry> LdapSearchPaged(
        string baseLdapPath,
        string filter,
        int scope,
        bool showLinkTimeToLive,
        params string[] attributes)
    {
        var baseDn = LdapPathToDn(baseLdapPath);
        
        _logger.LogInformation("LDAP Search: BaseDN={BaseDn}, Filter={Filter}, Scope={Scope}, Attributes={Attributes}", 
            baseDn, filter, scope, string.Join(",", attributes));
        
        using var conn = CreateLdapConnection();
        var entries = new List<SearchResultEntry>();

        // AD commonly enforces a max result size per request; use RFC2696 paging.
        var pageRequest = new Sds.PageResultRequestControl(500);
        byte[]? nextCookie = null;

        do
        {
            pageRequest.Cookie = nextCookie ?? Array.Empty<byte>();
            var request = new Sds.SearchRequest(baseDn, filter, (Sds.SearchScope)scope, attributes);
            request.Controls.Add(pageRequest);
            if (showLinkTimeToLive)
            {
                request.Controls.Add(new Sds.DirectoryControl("1.2.840.113556.1.4.2309", null, true, true));
            }

            var response = (Sds.SearchResponse)conn.SendRequest(request);

            foreach (Sds.SearchResultEntry sdsEntry in response.Entries)
            {
                try
                {
                    var entry = new SearchResultEntry
                    {
                        DistinguishedName = sdsEntry.DistinguishedName
                    };

                    foreach (string attrName in sdsEntry.Attributes.AttributeNames)
                    {
                        var sdsAttr = sdsEntry.Attributes[attrName];
                        if (sdsAttr == null)
                        {
                            continue;
                        }

                        var dirAttr = new DirectoryAttribute { Name = attrName };
                        for (var i = 0; i < sdsAttr.Count; i++)
                        {
                            var value = sdsAttr[i];
                            if (value != null)
                            {
                                dirAttr.Add(value);
                            }
                        }

                        if (dirAttr.Count > 0)
                        {
                            entry.Attributes[attrName] = dirAttr;
                        }
                    }

                    entries.Add(entry);
                }
                catch
                {
                    // Skip entries that fail to parse.
                    continue;
                }
            }

            nextCookie = response.Controls
                .OfType<Sds.PageResultResponseControl>()
                .FirstOrDefault()
                ?.Cookie;
        }
        while (nextCookie is { Length: > 0 });
        
        _logger.LogInformation("LDAP Search returned {ResultCount} entries", entries.Count);
        return entries;
    }

    /// <summary>
    /// Removes an optional LDAP:// prefix from a directory path.
    /// </summary>
    /// <param name="ldapPath">LDAP path or DN; may be null only where declared.</param>
    /// <returns>The raw distinguished name, preserving all other text.</returns>
    private static string LdapPathToDn(string ldapPath)
    {
        const string prefix = "LDAP://";
        return ldapPath.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)
            ? ldapPath[prefix.Length..]
            : ldapPath;
    }
}
