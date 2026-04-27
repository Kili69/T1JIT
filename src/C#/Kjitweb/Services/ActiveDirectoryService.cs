using Sds = System.DirectoryServices.Protocols;
using System.Net;
using System.Net.NetworkInformation;
using System.Security.Claims;
using System.Security.Principal;
using System.Text.RegularExpressions;

namespace KjitWeb.Services;

// SearchScope constants for LDAP searches
internal static class SearchScope
{
    public const int Base = 0;
    public const int OneLevel = 1;
    public const int Subtree = 2;
}

// Compatibility wrappers for LDAP results to keep existing parsing code unchanged
internal class SearchResultEntry
{
    public string DistinguishedName { get; set; } = string.Empty;
    public DirectoryAttributeCollection Attributes { get; set; } = new();
}

internal class DirectoryAttributeCollection : Dictionary<string, DirectoryAttribute>
{
    public DirectoryAttributeCollection() : base(StringComparer.OrdinalIgnoreCase) { }
}

internal class DirectoryAttribute : List<object>
{
    public string Name { get; set; } = string.Empty;
}
/// <summary>
/// Service responsible for interacting with Active Directory to resolve user and server information based on the application's configuration and the authenticated user's context. This includes determining the user's current elevation groups, available domains, default domain, and server names based on LDAP queries. The service also supports delegation rules to restrict server visibility based on group membership.
/// </summary> 
/// <remarks>
/// This service relies on the configuration provided in JIT.config for critical settings such as the domain LDAP path, server search bases, and delegation rules. It uses the System.DirectoryServices APIs to perform LDAP queries against Active Directory. The service is designed to handle various edge cases gracefully, such as missing configuration, LDAP connectivity issues, and unexpected user contexts, while logging relevant information for troubleshooting.
/// The GetCurrentElevationGroups method retrieves the groups that the authenticated user is currently a member of, which can be used to determine their current elevation level. The GetAvailableDomains method lists the domains in the current forest, while GetDefaultDomainForUser attempts to infer the user's default domain from their UPN or the service's domain configuration. The GetServerNames method queries Active Directory for computer objects based on configured search bases and optional domain filtering, supporting delegation rules to limit results based on group membership.
/// The service also includes helper methods for parsing and normalizing LDAP paths, extracting information from search results, and handling security identifiers. It is designed to be resilient to common issues such as misconfiguration or LDAP query failures, logging warnings and errors as appropriate without throwing exceptions that would disrupt the user experience. This allows the application to continue functioning even if Active Directory information cannot be retrieved, albeit with reduced functionality.
/// </remarks> 
/// <example>
/// <code>
/// var adService = new ActiveDirectoryService(configuration, logger);
/// var elevationGroups = adService.GetCurrentElevationGroups();
/// var domains = adService.GetAvailableDomains();
/// var defaultDomain = adService.GetDefaultDomainForUser();
/// var serverNames = adService.GetServerNames();
/// </code>
/// </example>
public class ActiveDirectoryService : IActiveDirectoryService
{
    // LDAP error code 10 = LDAP_REFERRAL
    private const int LdapReferralErrorCode = 10;
    private readonly IConfiguration _configuration;
    private readonly ILogger<ActiveDirectoryService> _logger;
    private readonly string _domainLdapPath;
    private readonly string _domainFqdn;
    private readonly string? _groupOuDistinguishedName;
    private readonly string _adminPreFix;
    private readonly string _domainSeparator;
    private readonly IReadOnlyList<string> _serverSearchBaseLdapPaths;
    private readonly bool _delegationEnabled;
    private readonly IReadOnlyList<DelegationRule> _delegationRules;

    
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
    public ActiveDirectoryService(IConfiguration configuration, ILogger<ActiveDirectoryService> logger)
    {
        _configuration = configuration; // Store the configuration instance for later use in service methods.
        _logger = logger; // Store the logger instance for logging within the service.  
        var jitConfiguration = ResolveJitConfiguration(); //
        _domainLdapPath = ResolveDomainLdapPath(jitConfiguration);
        _domainFqdn = ParseDomainFqdnFromLdapPath(_domainLdapPath) ?? ResolveDomainFqdn();
        _groupOuDistinguishedName = jitConfiguration.GroupOuDistinguishedName;
        _adminPreFix = jitConfiguration.AdminPreFix; // Load the admin prefix from the JIT configuration, which may be used to format elevation group names for display. This is optional and can be an empty string if not used.   
        _domainSeparator = jitConfiguration.DomainSeparator; // Load the domain separator from the JIT configuration, which may be used to parse or format domain-related information.
        _serverSearchBaseLdapPaths = ResolveServerSearchBasesFromJitConfiguration(jitConfiguration); // Resolve the LDAP paths for server search bases from the JIT configuration. These paths will be used to search for servers in the directory.
        _delegationEnabled = jitConfiguration.EnableDelegation; // Load the delegation enabled flag from the JIT configuration, which indicates whether delegation rules should be applied.
        _delegationRules = ResolveDelegationRules(jitConfiguration); // Resolve the delegation rules from the JIT configuration, if delegation is enabled.
    }

    /// <summary>
    /// Retrieves the list of elevation groups that the specified user is currently a member of. 
    /// This is determined by performing an LDAP query against the configured group OU, 
    /// using a matching rule to find all groups that the user is a member of, including nested group memberships. 
    /// The method returns a list of formatted group names that represent the user's current elevations, 
    /// which can be used by the application to determine what elevated permissions or roles the user currently has. 
    /// If any issues occur during this process (e.g. LDAP connectivity problems, misconfiguration, or unexpected user context), 
    /// the method will log warnings and return an empty list, allowing the application to continue functioning without elevation information rather than throwing exceptions.
    /// </summary>
    /// <param name="user">The user for whom to retrieve elevation groups.</param>
    /// <returns>A list of elevation group names that the user is currently a member of.</returns>
    /// <remarks>
    /// This method performs an LDAP query against the configured group OU to determine the user's current elevation groups.
    /// It uses a matching rule to find all groups that the user is a member of, including nested group memberships.
    /// The method returns a list of formatted group names that represent the user's current elevations.
    /// If any issues occur during this process (e.g. LDAP connectivity problems, misconfiguration, or unexpected user context),
    /// the method will log warnings and return an empty list, allowing the application to continue functioning without elevation information rather than throwing exceptions.
    /// </remarks>
    /// <exception cref="InvalidOperationException">Thrown if the group OU distinguished name is not configured or if the user's distinguished name cannot be resolved.</exception>
    /// <exception cref="DirectoryServicesCOMException">Thrown if there is an error during the LDAP query, such as connectivity issues or invalid search parameters.</exception>
    /// <exception cref="Exception">Thrown for any other unexpected errors that may occur during the process.</exception>
    /// <example>
    /// var elevationGroups = activeDirectoryService.GetCurrentElevationGroups(User);
    /// foreach (var group in elevationGroups)
    /// {
    ///     Console.WriteLine($"User is currently a member of elevation group: {group}");
    /// }
    /// </example>  

    public List<string> GetCurrentElevationGroups(ClaimsPrincipal? user)
    {
        // If the group OU is not configured, we cannot perform the query, so return an empty list. 
        // This is a graceful handling of misconfiguration that allows the application to continue functioning without elevation information rather than throwing exceptions.
        if (string.IsNullOrWhiteSpace(_groupOuDistinguishedName))
        {
            return new List<string>();
        }
        // Attempt to resolve the user's distinguished name from their identity. If this fails, we cannot perform the query, 
        // so return an empty list.
        var identityName = user?.Identity?.Name;
        if (string.IsNullOrWhiteSpace(identityName))
        {
            return new List<string>();
        }
        // Get the user's distinguished name, which is required for the LDAP query. If this cannot be resolved, return an empty list.
        var userDn = GetUserDistinguishedName(identityName);
        if (string.IsNullOrWhiteSpace(userDn) || userDn.Equals("unknown-user", StringComparison.OrdinalIgnoreCase))
        {
            return new List<string>();
        }
        // Normalize the group OU LDAP path and perform the LDAP query to find all groups that the user is a member of, 
        // including nested memberships.
        var groupOuLdapPath = NormalizeLdapPath(_groupOuDistinguishedName);
        // If the normalized group OU LDAP path is invalid, return an empty list.
        if (string.IsNullOrWhiteSpace(groupOuLdapPath))
        {
            return new List<string>();
        }

        try
        {
            var entries = LdapSearchPaged(
                groupOuLdapPath,
                $"(&(objectCategory=group)(member:1.2.840.113556.1.4.1941:={EscapeLdapFilter(userDn)}))",
                SearchScope.Subtree,
                "cn", "distinguishedName");

            return entries
                .Select(ExtractGroupDisplayName)
                .Where(name => !string.IsNullOrWhiteSpace(name))
                .Select(name => FormatCurrentElevationGroupName(name!))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .OrderBy(name => name, StringComparer.OrdinalIgnoreCase)
                .ToList();
        }
        // If there is an issue with the LDAP query (e.g. connectivity problems, invalid search parameters), 
        // log a warning and return an empty list.
        catch (Exception ex) when (ex is Sds.LdapException)
        {
            _logger.LogWarning(ex, "LDAP matching rule query failed for current elevations of user {IdentityName}", identityName);
            return new List<string>();
        }
        // Catch any other unexpected exceptions, 
        // log a warning, and return an empty list to allow the application to continue functioning.
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not resolve current elevations for user {IdentityName}", identityName);
            return new List<string>();
        }
    }

    /// <summary>
    /// Retrieves the list of available domains in the current forest.
    /// </summary>
    /// <returns>A list of domain names.</returns>
    /// <remarks>
    /// This method attempts to retrieve the list of available domains in the current Active Directory forest using the System.DirectoryServices.ActiveDirectory APIs. 
    /// If it encounters any issues during this process (e.g. connectivity problems, permissions issues, or unexpected environment), 
    /// it will log a warning and fall back to parsing the domain from the configured domain LDAP path. 
    /// This allows the application to continue functioning with at least one domain available rather than throwing exceptions that would disrupt the user experience.
    /// The method first tries to get the domains from the current forest, and if successful, returns a distinct and ordered list of domain names. If it fails to retrieve the domains, it logs the exception and attempts to parse a single domain from the configured domain LDAP path. If that also fails, it returns an empty list.
    /// This approach ensures that the application can still operate even if there are issues with Active Directory connectivity or configuration, while providing as much information as possible about the available domains for use in other parts of the application.
    /// </remarks>
    /// <exception cref="Exception">Thrown for any unexpected errors that may occur during the process of retrieving domains from the forest or parsing the domain from the LDAP path.</exception>
    /// <example>
    /// var domains = activeDirectoryService.GetAvailableDomains();
    /// foreach (var domain in domains)
    /// {
    ///     Console.WriteLine($"Available domain: {domain}");   
    /// }
    /// </example>
    /// <seealso cref="GetDefaultDomainForUser(ClaimsPrincipal?)"/>
    /// <seealso cref="GetServerNames(ClaimsPrincipal?, string?)"/>
    /// <seealso cref="GetUserDistinguishedName(string?)"/>
    /// <seealso cref="GetUserPrincipalName(string?)"/>
    /// <seealso cref="IActiveDirectoryService"/>
    /// <seealso cref="ActiveDirectoryService"/>
    /// <seealso cref="JitConfiguration"/>
    /// <seealso cref="DelegationRule"/>
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
    /// Determines the default domain for the specified user.
    /// </summary>
    /// <param name="user">The user for whom to determine the default domain.</param>
    /// <returns>The default domain for the user, or an empty string if it cannot be determined.</returns>
    /// <remarks>
    /// This method attempts to determine the default domain for the specified user by first looking for a UPN claim in the user's claims. 
    /// If a UPN is found, it extracts the domain portion of the UPN and returns it. 
    /// If no UPN claim is present, it falls back to parsing the domain from the service's configured domain LDAP path. 
    /// This allows the application to infer a default domain for the user even if their claims do not include explicit domain information, while also providing a fallback based on the service's configuration. If neither method yields a valid domain, it returns an empty string.
    /// </remarks>
    /// <exception cref="Exception">Thrown for any unexpected errors that may occur during the process of determining the default domain, 
    /// such as issues with claims parsing or LDAP path parsing.</exception>
    /// <example>   
    /// var defaultDomain = activeDirectoryService.GetDefaultDomainForUser(User);
    /// Console.WriteLine($"Default domain for user: {defaultDomain}");
    /// </example>
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
    /// Retrieves the list of server names based on the configured LDAP search bases and optional domain filtering.
    /// </summary>
    /// <param name="user">The user for whom to retrieve server names, used for applying delegation rules if enabled.</param>
    /// <param name="selectedDomain">An optional domain filter to limit servers to a specific domain.</param>
    /// <returns>A list of server names that match the search criteria.</returns>
    /// <remarks>
    /// This method retrieves server names by performing LDAP queries against the configured search bases.
    /// If delegation is enabled, it first resolves the effective search bases for the user based on their group memberships and the defined delegation rules.
    /// It then queries each search base for computer objects, applying an optional domain filter if specified.
    /// The method handles various edge cases gracefully, such as invalid search bases, LDAP connectivity issues, and unexpected user contexts, by logging warnings and continuing to process other search bases rather than throwing exceptions.
    /// The resulting list of server names is distinct and ordered for better usability. If no servers can be retrieved due to configuration issues or LDAP problems, it will return an empty list, allowing the application to continue functioning without server information rather than throwing exceptions.
    /// </remarks>
    /// <exception cref="Exception">Thrown for any unexpected errors that may occur during the process of retrieving server names, such as issues with LDAP queries or configuration.</exception>
    /// <example>
    ///   var serverNames = activeDirectoryService.GetServerNames(User, selectedDomain);
    ///   foreach (var server in serverNames)
    ///   {
    ///      Console.WriteLine($"Available server: {server}");
    ///     }
    /// </example>
    public List<string> GetServerNames(ClaimsPrincipal? user)
    {
        return GetServerNames(user, null);
    }

    /// <summary>
    ///     Retrieves the list of server names based on the configured LDAP search bases and optional domain filtering.
    /// </summary>
    /// <param name="user">The user for whom to retrieve server names, used for applying delegation rules if enabled.</param>
    /// <param name="selectedDomain">An optional domain filter to limit servers to a specific domain.</param>
    /// <returns>A list of server names that match the search criteria.</returns>
    /// <remarks>
    /// This method retrieves server names by performing LDAP queries against the configured search bases.
    /// If delegation is enabled, it first resolves the effective search bases for the user based on their group memberships and the defined delegation rules.
    /// It then queries each search base for computer objects, applying an optional domain filter if specified.
    /// The method handles various edge cases gracefully, such as invalid search bases, LDAP connectivity issues, 
    /// and unexpected user contexts, by logging warnings and continuing to process other search bases rather than throwing exceptions.
    /// The resulting list of server names is distinct and ordered for better usability. If no servers can be retrieved due to configuration issues or LDAP problems, it will return an empty list, allowing the application to continue functioning without server information rather than throwing exceptions.
    /// </remarks>  
    /// <exception cref="Exception">Thrown for any unexpected errors that may occur during the process of retrieving server names, such as issues with LDAP queries or configuration.</exception>
    /// <example>
    ///   var serverNames = activeDirectoryService.GetServerNames(User, selectedDomain);
    ///   foreach (var server in serverNames)
    ///   {
    ///      Console.WriteLine($"Available server: {server}");
    ///   }
    /// </example>  
    public List<string> GetServerNames(ClaimsPrincipal? user, string? selectedDomain)
    {
        var serverNames = new List<string>(); // This list will hold the server names that we retrieve from the LDAP queries.
        var effectiveSearchBases = ResolveSearchBasesForUser(user); // Resolve the effective search bases for the user, taking into account delegation rules if enabled. This determines where in the directory we will search for computer objects.
        var normalizedSelectedDomain = NormalizeDomain(selectedDomain); // Normalize the selected domain for consistent comparison during filtering. This allows the method to correctly filter servers based on the specified domain, even if there are variations in formatting (e.g. case differences, trailing dots).
        // Iterate through each effective search base and perform an LDAP query to find computer objects.
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

                    var name = ReadEntryAttribute(entry, "name");
                    if (!string.IsNullOrWhiteSpace(name))
                        serverNames.Add(name);
                }
            }
            // If there is an issue with the LDAP query for this search base (e.g. invalid search base, connectivity problems), 
            // log a warning and continue to the next search base rather than throwing an exception. 
            // This allows us to still retrieve servers from other valid search bases even if one of them has issues.
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Ignoring LDAP search base due to unexpected error: {SearchBase}", searchBase);
            }
        }
        // After processing all search bases, we return a distinct and ordered list of server names for better usability.
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

    // This helper method checks if a given LDAP search result for a computer object matches the selected domain filter.
    // If no selected domain is specified, it returns true for all results. 
    // If a selected domain is specified, it attempts to resolve the domain of the computer object from its properties (dNSHostName or distinguishedName) and compares it to the selected domain. 
    // This allows the GetServerNames method to filter results based on the specified domain.
    private static bool MatchesSelectedDomain(SearchResultEntry entry, string? selectedDomain)
    {
        if (string.IsNullOrWhiteSpace(selectedDomain))
            return true;

        var objectDomain = ResolveComputerDomain(entry);
        return !string.IsNullOrWhiteSpace(objectDomain)
            && objectDomain.Equals(selectedDomain, StringComparison.OrdinalIgnoreCase);
    }

    private static string? ResolveComputerDomain(SearchResultEntry entry)
    {
        var dnsHostName = ReadEntryAttribute(entry, "dNSHostName");
        var domainFromDns = ExtractDomainFromDnsHostName(dnsHostName);
        if (!string.IsNullOrWhiteSpace(domainFromDns))
            return domainFromDns;

        var distinguishedName = ReadEntryAttribute(entry, "distinguishedName");
        return ParseDomainFqdnFromLdapPath(distinguishedName);
    }

    private static string? ReadEntryAttribute(SearchResultEntry entry, string attributeName)
    {
        var attr = entry.Attributes[attributeName];
        if (attr == null || attr.Count == 0)
            return null;
        return attr[0]?.ToString();
    }

    // This helper method attempts to extract the domain portion from a dNSHostName value.
    // It checks if the dNSHostName is valid and contains a dot, and if so, it takes the portion after the first dot as the domain. It then normalizes the extracted domain before returning it. If the dNSHostName is not valid or does not contain a dot, it returns null.    
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
    private static string? NormalizeDomain(string? domain)
    {
        if (string.IsNullOrWhiteSpace(domain)) // If the input domain string is null, empty, or whitespace, we cannot normalize it, so we return null.
        {
            return null;
        }

        return domain.Trim().TrimEnd('.').ToLowerInvariant(); // Normalize the domain by trimming whitespace, removing any trailing dots, and converting it to lowercase for consistent comparison. This helps ensure that domain comparisons are case-insensitive and not affected by formatting variations.
    }

    // This helper method resolves the effective LDAP search bases for the specified user, taking into account delegation rules if delegation is enabled.
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
    /// Retrieves the distinguished name of a user based on their identity name (e.g. sAMAccountName or UPN).   
    /// </summary>
    /// <param name="identityName">The identity name of the user (e.g. sAMAccountName or UPN).</param>
    /// <returns>The distinguished name of the user, or "unknown-user" if the identity name is null or empty.</returns>
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
    ///     Retrieves the user principal name (UPN) of a user based on their identity name (e.g. sAMAccountName or UPN).
    /// </summary>
    /// <param name="identityName">The identity name of the user (e.g. sAMAccountName or UPN).</param>
    /// <returns>The user principal name (UPN) of the user, or the original identity name if not found.</returns>
    /// <remarks>
    /// This method attempts to retrieve the user principal name (UPN) of a user based on their identity name, which can be in the format of sAMAccountName (e.g. DOMAIN\username) or UPN (e.g. username@domain).
    /// It performs an LDAP search in Active Directory to find the user object based on the sAMAccountName extracted from the identity name, and if found, it retrieves the userPrincipalName property from the search result.
    /// If the user cannot be found or if the userPrincipalName property is not available, it returns the original identity name as a fallback. This allows the application to continue functioning even if it cannot resolve the user's UPN, although certain features that rely on the UPN may not work properly.
    /// </remarks>  
    /// <exception cref="Exception">Thrown for any unexpected errors that may occur during the process of retrieving the user's UPN, such as issues with LDAP queries or connectivity.</exception>
    /// <example>
    ///   var upn = activeDirectoryService.GetUserPrincipalName(User.Identity.Name);
    ///   Console.WriteLine($"User principal name: {upn}");
    /// </example>
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
    private static string? ExtractGroupDisplayName(SearchResultEntry entry)
    {
        var cn = ReadEntryAttribute(entry, "cn");
        if (!string.IsNullOrWhiteSpace(cn))
            return cn;

        var distinguishedName = ReadEntryAttribute(entry, "distinguishedName");
        return string.IsNullOrWhiteSpace(distinguishedName)
            ? null
            : ExtractCommonNameFromDn(distinguishedName);
    }

    // This helper method formats the name of an elevation group by applying certain transformations based on configured prefixes and separators.
    // It trims whitespace from the group name, removes a configured admin prefix if it exists, and replaces a configured domain separator with a space. 
    // This allows us to present elevation group names in a cleaner and more user-friendly format based on the application's configuration.
    private string FormatCurrentElevationGroupName(string groupName)
    {
        var formatted = groupName.Trim(); // Trim any leading or trailing whitespace from the group name to ensure a clean format.

        if (!string.IsNullOrWhiteSpace(_adminPreFix) // If an admin prefix is configured and the group name starts with this prefix, we remove the prefix from the group name. This allows us to simplify the display of elevation group names by removing a common prefix that may be used in Active Directory to identify admin groups.
            && formatted.StartsWith(_adminPreFix, StringComparison.OrdinalIgnoreCase)) // Check if the formatted group name starts with the configured admin prefix, ignoring case. If it does, we will remove this prefix from the display name to make it cleaner and more user-friendly.
        {
            formatted = formatted[_adminPreFix.Length..]; // Remove the admin prefix from the beginning of the group name by taking the substring starting from the length of the prefix to the end of the string. This allows us to present a cleaner group name without the common prefix that may be used in Active Directory.
        }

        if (!string.IsNullOrWhiteSpace(_domainSeparator)) // If a domain separator is configured, we replace all occurrences of this separator in the group name with a space. This allows us to further clean up the display of elevation group names by replacing configured separators (e.g. underscores, dashes) with spaces for better readability.
        {
            formatted = formatted.Replace(_domainSeparator, " ", StringComparison.Ordinal); // Replace all occurrences of the configured domain separator in the group name with a space. This transformation is applied to improve the readability of the group name when displayed to users, based on the application's configuration for what constitutes a domain separator.
        }

        return formatted.Trim(); // Finally, we trim any leading or trailing whitespace from the formatted group name again to ensure that the final output is clean and does not have unintended spaces after the transformations. We return this formatted group name for display purposes.
    }
    // This helper method checks if a given LDAP search base is allowed based on the configured server search base LDAP paths.
    // It compares the search base to each of the configured base paths, allowing for case-insensitive matches and also allowing for the search base to end with the configured base path (ignoring the "LDAP://" prefix).  
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
    private IReadOnlyList<string> ResolveServerSearchBasesFromJitConfiguration(JitConfiguration jitConfig)
    {
        // We check if the JIT configuration contains any T1SearchBaseLdapPaths. 
        // If it does, we log the count of search bases loaded and return them as the server search base LDAP paths. 
        // This allows the JIT configuration to define the search bases that the service will use for Active Directory queries, which can be useful for dynamically controlling the scope of searches based on JIT settings. If there are no valid T1SearchBaseLdapPaths in the JIT configuration, we log an error and throw an exception to prevent the service from starting without valid search bases, which are essential for its operation.
        if (jitConfig.T1SearchBaseLdapPaths.Count > 0)
        {
            _logger.LogInformation(
                "Server search bases loaded from JIT config file {FilePath}. Count: {Count}",
                jitConfig.JitConfigPath,
                jitConfig.T1SearchBaseLdapPaths.Count);
            return jitConfig.T1SearchBaseLdapPaths;
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

    // This helper method resolves the delegation rules from the JIT configuration. 
    // It checks if delegation is enabled in the JIT configuration, and if so, it attempts to load the delegation configuration from the specified path. 
    // If delegation is not enabled, it returns an empty list of delegation rules.  
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

        // Some authentication flows emit only a partial set of group SID claims.
        // Always enrich with Windows identity groups and LDAP tokenGroups so delegation
        // rules can match all effective memberships.
        var windowsIdentity = user.Identities.OfType<WindowsIdentity>().FirstOrDefault();
        AddWindowsIdentityGroupTokens(windowsIdentity, tokens);
        AddDirectoryTokenGroups(user.Identity?.Name, tokens);

        return tokens;
    }

    private static void AddWindowsIdentityGroupTokens(WindowsIdentity? identity, ISet<string> tokens)
    {
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

    private void AddDirectoryTokenGroups(string? identityName, ISet<string> tokens)
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
                "distinguishedName");

            var userDn = userEntries.FirstOrDefault() is { } ue
                ? ReadEntryAttribute(ue, "distinguishedName")
                : null;

            if (string.IsNullOrWhiteSpace(userDn))
                return;

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
    private static bool IsGroupSidClaim(Claim claim)
    {
        return claim.Type == ClaimTypes.GroupSid
            || claim.Type.EndsWith("/groupsid", StringComparison.OrdinalIgnoreCase)
            || claim.Type.EndsWith("/primarygroupsid", StringComparison.OrdinalIgnoreCase);
    }

    // This helper method normalizes a security identifier (SID) string by trimming whitespace and quotes, and converting it to uppercase.
    // This ensures that SIDs are stored in a consistent format for efficient lookup and comparison when determining group memberships based on SIDs. By normalizing the SIDs, we can avoid issues with formatting differences that may arise from different sources of claims or variations in how SIDs are represented, allowing for reliable comparisons when checking if a user belongs to a group based on its SID.
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
    /// Creates an LDAP connection using the current service security context.
    /// Uses System.DirectoryServices.Protocols with Negotiate (Kerberos/NTLM) and no password.
    /// </summary>
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
    /// Performs an LDAP search using System.DirectoryServices.Protocols.
    /// baseLdapPath may include the "LDAP://" prefix.
    /// </summary>
    private IList<SearchResultEntry> LdapSearchPaged(string baseLdapPath, string filter, int scope, params string[] attributes)
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

    /// <summary>Strips the "LDAP://" prefix, returning the raw distinguished name.</summary>
    private static string LdapPathToDn(string ldapPath)
    {
        const string prefix = "LDAP://";
        return ldapPath.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)
            ? ldapPath[prefix.Length..]
            : ldapPath;
    }
}
