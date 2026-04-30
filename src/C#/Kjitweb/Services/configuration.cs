using System.Net.NetworkInformation;
using System.Text.Json;

namespace KjitWeb.Services;
/// <summary>
/// The ActiveDirectoryService class provides methods for interacting with Active Directory to support Just-In-Time (JIT) access management. 
/// It retrieves information about the authenticated user's group memberships, available domains, default domain, and server names based on configured search bases. 
/// The service is designed to be resilient to common issues such as misconfiguration or LDAP query failures, logging warnings and errors as appropriate without throwing exceptions that would disrupt the user experience. This allows the application to continue functioning even if Active Directory information cannot be retrieved, albeit with reduced functionality.
/// </summary>
/// <remarks>
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
public class JitConfiguration
{
	/// <summary>
	/// 	The minimum elevation duration in minutes that can be requested. 
	/// 	This is used to enforce a lower bound on the elevation duration to prevent excessively short elevation periods that may not be practical for users. 
	/// 	The value is set to 5 minutes, which is a reasonable minimum duration for most administrative tasks while still allowing for quick elevations when needed. 
	/// 	This constant can be used throughout the application to validate user input for elevation duration and ensure that it meets the minimum requirement.
	/// </summary> 	
	public const int MinimumElevationDurationMinutes = 5;
	/// <summary>
	/// 	The JitConfiguration class represents the configuration settings for Just-In-Time (JIT) access management in the application.
	/// </summary>
	public string JitConfigPath { get; }
	/// <summary>
	/// The DomainFqdn property represents the fully qualified domain name (FQDN) of the Active Directory domain that the application is operating in.
	/// This value is used for various purposes such as constructing LDAP paths, determining the domain context for queries, and forming event log entries. 
	/// It is read from the JIT.config file, and if not specified there, it can be inferred from the system's domain information. 
	/// This allows the application to adapt to different domain environments without requiring hardcoded values, while still providing a way to explicitly configure the domain FQDN if needed.
	/// </summary>
	public string? DomainFqdn { get; }
	/// <summary>
	/// The EventLogName property specifies the name of the Windows Event Log where JIT management events will be recorded.
	/// This allows administrators to easily identify and filter JIT-related events in the event log.
	/// </summary>
	public string EventLogName { get; }
	/// <summary>
	/// 	The EventLogSourceName property specifies the source name that will be used when writing events to the Windows Event Log for JIT management activities.
	/// 	This allows administrators to easily identify the source of JIT-related events in the event log, and it is typically set to a value that clearly indicates its association with the JIT access management functionality of the application.
	/// </summary>
	public string EventLogSourceName { get; }
	/// <summary>
	/// 	The AdminPreFix property specifies a prefix that will be used when constructing server group names for event logging purposes.
	/// 	This allows for consistent naming of server groups in event log entries, which can help administrators quickly identify the context of the events and correlate them with specific servers or domains. The prefix can be configured to include relevant information such as the domain name or a specific identifier to further enhance the clarity of event log entries related to JIT management activities.
	/// </summary>
	public string AdminPreFix { get; }
	/// <summary>
	/// 	The DomainSeparator property specifies a string that will be used to separate the domain and server name when constructing server group names for event logging purposes.
	/// 	This allows for consistent formatting of server group names in event log entries, making it easier for administrators to parse and understand the context of the events. 
	/// 	The separator can be configured to use a specific character or string that is commonly used in the organization's naming conventions, such as a backslash, forward slash, or hyphen, to enhance the readability of event log entries related to JIT management activities.
	/// </summary>
	public string DomainSeparator { get; }
	/// <summary>
	/// 	The GroupOuDistinguishedName property represents the distinguished name of the organizational unit (OU) in Active Directory where the server groups are located.
	/// 	This value is used when constructing LDAP paths for querying server objects in Active Directory, allowing the application to target specific OUs for server discovery.
	/// 	If this value is not specified, the application may default to searching the entire directory or use other configured search bases, which may result in broader queries and potentially more results. 
	/// 	By specifying the GroupOuDistinguishedName, administrators can optimize server discovery by limiting the search scope to a specific OU that contains the relevant server objects, improving performance and relevance of query results.
	/// </summary>
	public string? GroupOuDistinguishedName { get; }
	/// <summary>
	/// 	The DelegationConfigPath property represents the file path to an optional delegation configuration file that defines rules for limiting server discovery based on group membership.
	/// 	This allows administrators to specify a separate JSON configuration file that contains rules for delegating access to specific servers based on the user's group memberships in Active Directory. 
	/// 	If this property is set, the application will read the delegation rules from the specified file and apply them when determining which servers to include in the results of server discovery queries. 
	/// 	The delegation configuration file can contain rules that specify which groups have access to which servers, allowing for fine-grained control over server discovery and ensuring that users only see servers they are authorized to access based on their group memberships. If this property is not set, the application will not apply any delegation rules and will return all servers that match the configured search criteria.
	/// </summary>
	public string? DelegationConfigPath { get; }
	/// <summary>
	/// 	The EnableDelegation property specifies whether delegation rules should be applied when determining which servers to include in the results of server discovery queries.
	/// 	If this property is set to true, the application will read the delegation rules from the specified DelegationConfigPath file and apply them based on the user's group memberships in Active Directory.
	/// 	If this property is set to false, the application will ignore any delegation rules and return all servers that match the configured search criteria, regardless of the user's group memberships.
	/// </summary>
	public bool EnableDelegation { get; }
	/// <summary>
	/// 	The MaxElevatedTimeMinutes property specifies the maximum duration in minutes that a user can request for elevation when using Just-In-Time access management.
	/// 	This value is used to enforce an upper bound on the elevation duration to prevent excessively long elevation periods that could pose security risks.
	/// 	The value is read from the JIT.config file, and if not specified, it defaults to 60 minutes, which is a reasonable maximum duration for most administrative tasks while still allowing for sufficient time to complete necessary actions.
	/// 	This property can be used throughout the application to validate user input for elevation duration and ensure that it does not exceed the maximum allowed duration, helping to maintain a secure and controlled elevation process for users requesting Just-In-Time access.
	/// </summary>
	public int MaxElevatedTimeMinutes { get; }
	/// <summary>
	/// 	The DefaultElevatedTimeMinutes property specifies the default duration in minutes that will be used for elevation when a user requests Just-In-Time access without specifying a duration.
	/// 	This value is used to provide a sensible default elevation duration for users who do not specify a duration when requesting elevation, ensuring that they are granted access for a reasonable amount of time to complete their tasks without needing to input a specific duration.
	/// 	The value is read from the JIT.config file, and if not specified, it defaults to the MinimumElevationDurationMinutes constant (5 minutes), which is a reasonable default duration for most administrative tasks while still allowing for quick elevations when needed.
	/// 	The value is also clamped to ensure that it is not set below the minimum elevation duration or above the maximum elevation duration, providing a safeguard against misconfiguration that could result in impractical elevation durations. This property can be used throughout the application as the default duration for elevation requests, providing a consistent and controlled experience for users requesting Just-In-Time access.	
	/// </summary>
	public int DefaultElevatedTimeMinutes { get; }
	/// <summary>
	/// 	The T1SearchBaseLdapPaths property represents a list of LDAP paths that are used as search bases for querying Tier 1 servers in Active Directory.
	/// 	These paths are read from the JIT.config file and can be configured to target specific OUs or containers in Active Directory where Tier 1 servers are located, allowing for optimized queries that focus on relevant parts of the directory.
	/// 	The application will use these LDAP paths as the base for searching computer objects that represent Tier 1 servers, and it may apply additional filters based on domain or delegation rules to further refine the search results.
	/// 	If this list is empty, the application may default to searching the entire directory or use other configured search bases, which may result in broader queries and potentially more results. By specifying the T1SearchBaseLdapPaths, administrators can optimize server discovery by limiting the search scope to specific OUs or containers that contain Tier 1 server objects, improving performance and relevance of query results.	
	/// </summary>
	public IReadOnlyList<string> T1SearchBaseLdapPaths { get; }
	/// <summary>
	/// 	The JitConfiguration class constructor initializes the configuration settings for Just-In-Time access management by reading from a specified JIT.config file.
	/// 	If the constructor is called without parameters, it attempts to build a default path to the JIT.config file based on the domain information of the system, looking for the file in the SYSVOL share of the domain.
	/// </summary>
	public JitConfiguration()
		: this(BuildDefaultJitConfigPath())
	{
	}
	/// <summary>
	/// The JitConfiguration class constructor initializes the configuration settings for Just-In-Time access management by reading from a specified JIT.config file.
	/// </summary>
	/// <param name="jitConfigPath">The path to the JIT.config file.</param>
	/// <exception cref="ArgumentException">Thrown when the jitConfigPath is null, empty, or whitespace.</exception>
	public JitConfiguration(string jitConfigPath)
	{
		if (string.IsNullOrWhiteSpace(jitConfigPath)) // If the provided jitConfigPath is null, empty, or consists only of whitespace, we cannot proceed with loading the configuration, so we throw an ArgumentException to indicate that a valid path must be provided. This ensures that the application fails fast with a clear error message if the configuration path is not properly specified, preventing further issues down the line when attempting to read the configuration file.
		{
			throw new ArgumentException("JIT config path must not be empty.", nameof(jitConfigPath));
		}

		JitConfigPath = jitConfigPath; // We assign the provided jitConfigPath to the JitConfigPath property, which will be used to read the configuration settings from the specified file. This allows us to have a clear and explicit reference to the location of the JIT.config file that is being used for configuration, and it can be accessed by other parts of the application if needed.

		using var document = OpenJsonDocument(jitConfigPath); // We open the JIT.config file as a JSON document using the OpenJsonDocument helper method, which reads the file and parses it as JSON. This allows us to access the configuration settings in a structured way using the JsonDocument API, and it also ensures that we handle any issues with file access or JSON parsing gracefully by throwing appropriate exceptions if the file cannot be read or is not valid JSON.
		T1SearchBaseLdapPaths = ReadT1SearchBaseLdapPaths(document.RootElement); // We read the T1SearchBaseLdapPaths from the root element of the JSON document using the ReadT1SearchBaseLdapPaths helper method, which extracts the list of LDAP paths from the configuration. This allows us to have a strongly typed property that represents the search bases for Tier 1 servers, and it can be used throughout the application to perform LDAP queries based on these configured paths.
		DomainFqdn = ReadDomainFqdn(document.RootElement); // We read the DomainFqdn from the root element of the JSON document using the ReadDomainFqdn helper method, which extracts the fully qualified domain name from the configuration. This allows us to have a property that represents the domain context for the application, which can be used for constructing LDAP paths, forming event log entries, and other operations that require knowledge of the domain FQDN. If the DomainFqdn is not specified in the configuration, it will be null, and the application can attempt to infer it from system information or handle it accordingly.
		EventLogName = ReadString(document.RootElement, "EventLog", "Tier 1 Management"); // We read the EventLogName from the root element of the JSON document using the ReadString helper method, which extracts a string value for the "EventLog" property, with a fallback default value of "Tier 1 Management" if it is not specified. This allows us to have a configurable property for the name of the Windows Event Log where JIT management events will be recorded, while still providing a sensible default value that can be used if the configuration does not specify one.
		EventLogSourceName = ReadEventLogSourceName(document.RootElement); // We read the event log source name with backward compatibility for both EventLogSource and legacy EventSource keys.
		AdminPreFix = ReadString(document.RootElement, "AdminPreFix", string.Empty); // We read the AdminPreFix from the root element of the JSON document using the ReadString helper method, which extracts a string value for the "AdminPreFix" property, with a fallback default value of an empty string if it is not specified. This allows us to have a configurable prefix for administrative accounts, while still providing a sensible default value that can be used if the configuration does not specify one.
		DomainSeparator = ReadString(document.RootElement, "DomainSeparator", string.Empty); // We read the DomainSeparator from the root element of the JSON document using the ReadString helper method, which extracts a string value for the "DomainSeparator" property, with a fallback default value of an empty string if it is not specified. This allows us to have a configurable separator for domain and server names when constructing server group names for event logging purposes, while still providing a sensible default value that can be used if the configuration does not specify one.
		GroupOuDistinguishedName = ReadOptionalString(document.RootElement, "OU"); // We read the GroupOuDistinguishedName from the root element of the JSON document using the ReadOptionalString helper method, which extracts a string value for the "OU" property and returns null if it is not specified or is empty. This allows us to have an optional configuration setting for the distinguished name of the organizational unit (OU) in Active Directory where the server groups are located, which can be used to optimize LDAP queries for server discovery. If this setting is not provided, the application can default to searching the entire directory or use other configured search bases.
		DelegationConfigPath = ReadDelegationConfigPath(document.RootElement); // We read the DelegationConfigPath from the root element of the JSON document using the ReadDelegationConfigPath helper method, which extracts a string value for the "DelegationConfigPath" property and returns null if it is not specified or is empty. This allows us to have an optional configuration setting for the file path to a delegation configuration file that defines rules for limiting server discovery based on group membership. If this setting is provided, the application will read the delegation rules from the specified file and apply them when determining which servers to include in the results of server discovery queries. If this setting is not provided, the application will not apply any delegation rules and will return all servers that match the configured search criteria.
		EnableDelegation = ReadEnableDelegation(document.RootElement); // We read the EnableDelegation from the root element of the JSON document using the ReadEnableDelegation helper method, which extracts a boolean value for the "EnableDelegation" property and returns false if it is not specified or is not a valid boolean. This allows us to have a configuration setting that specifies whether delegation rules should be applied when determining which servers to include in the results of server discovery queries. If this setting is true, the application will read the delegation rules from the specified DelegationConfigPath file and apply them based on the user's group memberships in Active Directory. If this setting is false, the application will ignore any delegation rules and return all servers that match the configured search criteria, regardless of the user's group memberships.
		MaxElevatedTimeMinutes = ReadPositiveInteger(document.RootElement, "MaxElevatedTime", 60); // We read the MaxElevatedTimeMinutes from the root element of the JSON document using the ReadPositiveInteger helper method, which extracts an integer value for the "MaxElevatedTime" property and returns a fallback default value of 60 if it is not specified, is not a valid integer, or is less than or equal to 0. This allows us to have a configurable maximum duration for elevation requests in minutes, while still providing a sensible default value that can be used if the configuration does not specify one. This property can be used throughout the application to validate user input for elevation duration and ensure that it does not exceed the maximum allowed duration, helping to maintain a secure and controlled elevation process for users requesting Just-In-Time access.
		// We read the DefaultElevatedTimeMinutes from the root element of the JSON document using the ReadPositiveInteger helper method, which extracts an integer value for the "DefaultElevatedTime" property and returns a fallback default value of MinimumElevationDurationMinutes (5) if it is not specified, is not a valid integer, or is less than or equal to 0. We then clamp this value to ensure that it is not set below the minimum elevation duration or above the maximum elevation duration, providing a safeguard against misconfiguration that could result in impractical elevation durations. This allows us to have a configurable default duration for elevation requests in minutes, while still ensuring that it falls within a reasonable range defined by the minimum and maximum elevation duration constants.
		DefaultElevatedTimeMinutes = Math.Clamp(
			ReadPositiveInteger(document.RootElement, "DefaultElevatedTime", MinimumElevationDurationMinutes),
			MinimumElevationDurationMinutes,
			MaxElevatedTimeMinutes);
	}
	// This helper method builds the default path to the JIT.config file based on the domain information of the system. 
	// It retrieves the fully qualified domain name (FQDN) of the current domain using IPGlobalProperties, and constructs a UNC path to the JIT.config file located in the SYSVOL share of the domain. If the domain FQDN cannot be resolved, it throws an InvalidOperationException with a clear error message indicating that the domain could not be resolved for SYSVOL lookup, and suggests using the constructor with an explicit JIT.config path as an alternative.
	private static string BuildDefaultJitConfigPath()
	{
		var domainFqdn = IPGlobalProperties.GetIPGlobalProperties().DomainName; // We attempt to retrieve the fully qualified domain name (FQDN) of the current domain using IPGlobalProperties. This provides us with the domain context that we can use to construct the default path to the JIT.config file in the SYSVOL share. If we are unable to retrieve a valid domain FQDN, we will not be able to construct the correct path to the JIT.config file, so we need to handle this case appropriately.
		// If the domain FQDN is null, empty, or consists only of whitespace, we cannot construct a valid path to the JIT.config file in the SYSVOL share, so we throw an InvalidOperationException with a clear error message indicating that the domain could not be resolved for SYSVOL lookup. We also suggest using the constructor with an explicit JIT.config path as an alternative, which allows users to specify the path directly if the automatic resolution of the domain FQDN fails. This ensures that the application fails gracefully with a clear error message if it cannot determine the domain context,
		// rather than proceeding with an invalid path that would lead to further issues when attempting to read the configuration file.
		if (string.IsNullOrWhiteSpace(domainFqdn)) 
		{
			// We throw an InvalidOperationException with a clear error message indicating that the domain could not be resolved for SYSVOL lookup, and we suggest using the constructor with an explicit JIT.config path as an alternative. This provides guidance to users on how to resolve the issue if they encounter this error, and it ensures that the application fails gracefully with a clear explanation of the problem.
			throw new InvalidOperationException(
				"Domain could not be resolved for SYSVOL lookup. Use the constructor with explicit JIT.config path.");
		}

		return $@"\\{domainFqdn}\SYSVOL\{domainFqdn}\Just-In-Time\JIT.config"; // We construct the default path to the JIT.config file in the SYSVOL share using the retrieved domain FQDN. The path follows the standard structure for files stored in the SYSVOL share for Group Policy and related configurations, which is \\<domainFqdn>\SYSVOL\<domainFqdn>\Just-In-Time\JIT.config. This allows us to have a convention-based default location for the JIT.config file that can be used in typical Active Directory environments, while still allowing for flexibility if the configuration file is located elsewhere or if the domain FQDN cannot be resolved.
	}

	// This helper method opens the specified JIT.config file and parses it as a JSON document. It checks if the file exists, and if not, it throws a FileNotFoundException with a clear error message indicating that the JIT.config file was not found. If the file exists but cannot be parsed as valid JSON, it catches the JsonException and throws an InvalidOperationException with a clear error message indicating that the JIT.config file is not a valid JSON file, along with the original exception for more details. This ensures that we handle common issues with file access and JSON parsing gracefully, providing clear feedback on what went wrong when attempting to read the configuration file.
	private static JsonDocument OpenJsonDocument(string path)
	{
		// We check if the specified file exists at the given path. If it does not exist, we throw a FileNotFoundException with a clear error message indicating that the JIT.config file was not found, along with the path that was attempted. This provides immediate feedback to users or administrators that the configuration file is missing, allowing them to take corrective action by ensuring that the file is in place at the expected location.
		if (!File.Exists(path))
		{
			throw new FileNotFoundException("JIT.config file was not found.", path); // We throw a FileNotFoundException with a clear error message indicating that the JIT.config file was not found, along with the path that was attempted. This provides immediate feedback to users or administrators that the configuration file is missing, allowing them to take corrective action by ensuring that the file is in place at the expected location.
		}

		try
		{
			return JsonDocument.Parse(File.ReadAllText(path)); // We attempt to read the contents of the specified file and parse it as a JSON document using JsonDocument.Parse. If the file is successfully read and parsed, we return the JsonDocument for further processing. If there is an issue with reading the file or if the contents cannot be parsed as valid JSON, we catch the resulting exceptions and handle them appropriately to provide clear feedback on what went wrong.
		}
		// If there is an issue with reading the file, such as insufficient permissions or an I/O error, we catch the IOException and throw a new InvalidOperationException with a clear error message indicating that there was an error reading the JIT.config file, along with the original exception for more details. This ensures that we handle file access issues gracefully and provide clear feedback on what went wrong when attempting to read the configuration file.
		catch (IOException ex)
		{
			throw new InvalidOperationException("Error reading JIT.config file.", ex);
		}
		 // If there is an issue with parsing the file as valid JSON, we catch the JsonException and throw a new InvalidOperationException with a clear error message indicating that the JIT.config file is not a valid JSON file, along with the original exception for more details. This ensures that we handle JSON parsing issues gracefully and provide clear feedback on what went wrong when attempting to read the configuration file.	
		catch (JsonException ex)
		{
			throw new InvalidOperationException("JIT.config is not a valid JSON file.", ex);
		}
	}

	// This helper method reads the T1SearchBaseLdapPaths from the root element of the JSON document. 
	// It checks if the "T1Searchbase" property exists and is an array, and if so, it enumerates the array to extract string values, normalizes them as LDAP paths, and returns a distinct list of valid LDAP paths. If the property does not exist or is not an array, it returns an empty list. This allows us to have a strongly typed property that represents the search bases for Tier 1 servers, and it can be used throughout the application to perform LDAP queries based on these configured paths.
	private static IReadOnlyList<string> ReadT1SearchBaseLdapPaths(JsonElement root)
	{
		// We check if the "T1Searchbase" property exists in the root element of the JSON document and if it is an array. 
		// If it does not exist or is not an array, we return an empty list, indicating that there are no configured search bases for Tier 1 servers. 
		// This allows the application to handle the case where this configuration is not provided without throwing an exception, and it can default to searching the entire directory or using other configured search bases as needed.
		if (!TryGetPropertyIgnoreCase(root, "T1Searchbase", out var searchBaseElement)
			|| searchBaseElement.ValueKind != JsonValueKind.Array)
		{
			return Array.Empty<string>();
		}
		// We enumerate the array of search base elements, filter for those that are strings, normalize them as LDAP paths, and return a distinct list of valid LDAP paths.
		return searchBaseElement
			.EnumerateArray()
			.Where(item => item.ValueKind == JsonValueKind.String)
			.Select(item => NormalizeLdapPath(item.GetString()))
			.Where(path => !string.IsNullOrWhiteSpace(path))
			.Cast<string>()
			.Distinct(StringComparer.OrdinalIgnoreCase)
			.ToList();
	}

	// This helper method reads the DelegationConfigPath from the root element of the JSON document. 
	// It checks if the "DelegationConfigPath" property exists and is a string, and if so, it returns the trimmed string value. 
	// If the property does not exist, is not a string, or is empty/whitespace, it returns null. 
	// This allows us to have an optional configuration setting for the file path to a delegation configuration file that defines rules for limiting server discovery based on group membership. 
	// If this setting is provided, the application will read the delegation rules from the specified file and apply them when determining which servers to include in the results of server discovery queries. 
	// If this setting is not provided, the application will not apply any delegation rules and will return all servers that match the configured search criteria.
	private static string? ReadDelegationConfigPath(JsonElement root)
	{
		// We check if the "DelegationConfigPath" property exists in the root element of the JSON document and if it is a string. 
		// If it does not exist or is not a string, we return null, indicating that there is no delegation configuration path specified.
		if (!TryGetPropertyIgnoreCase(root, "DelegationConfigPath", out var element)
			|| element.ValueKind != JsonValueKind.String)
		{
			return null;
		}

		var value = element.GetString();
		return string.IsNullOrWhiteSpace(value) ? null : value.Trim(); // We retrieve the string value of the "DelegationConfigPath" property, and if it is null, empty, or consists only of whitespace, we return null. Otherwise, we return the trimmed string value. This allows us to handle the case where the configuration is provided but is not valid (e.g., an empty string), and it ensures that we only return a valid path if it is properly specified in the configuration.
	}

	// This helper method reads the DomainFqdn from the root element of the JSON document. 
	// It checks if the "Domain" property exists and is a string, and if so, it returns the trimmed string value. 
	// If the property does not exist, is not a string, or is empty/whitespace, it returns null. 
	// This allows us to have a property that represents the domain context for the application, which can be used for constructing LDAP paths, forming event log entries, and other operations that require knowledge of the domain FQDN. 
	// If the DomainFqdn is not specified in the configuration, it will be null, and the application can attempt to infer it from system information or handle it accordingly.
	private static string? ReadDomainFqdn(JsonElement root)
	{
		// We check if the "Domain" property exists in the root element of the JSON document and if it is a string. 
		// If it does not exist or is not a string, we return null, indicating that there is no domain FQDN specified in the configuration. 
		// This allows the application to handle the case where this configuration is not provided without throwing an exception, and it can attempt to infer the domain FQDN from system information or handle it accordingly.
		if (!TryGetPropertyIgnoreCase(root, "Domain", out var element)
			|| element.ValueKind != JsonValueKind.String)
		{
			return null;
		}

		var value = element.GetString();
		return string.IsNullOrWhiteSpace(value) ? null : value.Trim(); // We retrieve the string value of the "Domain" property, and if it is null, empty, or consists only of whitespace, we return null. Otherwise, we return the trimmed string value. This allows us to handle the case where the configuration is provided but is not valid (e.g., an empty string), and it ensures that we only return a valid domain FQDN if it is properly specified in the configuration.
	}

	// This helper method reads the EnableDelegation from the root element of the JSON document. 
	// It checks if the "EnableDelegation" property exists and is a boolean value (true or false). 
	// If it does not exist or is not a valid boolean, it returns false. 
	// This allows us to have a configuration setting that specifies whether delegation rules should be applied when determining which servers to include in the results of server discovery queries. If this setting is true, the application will read the delegation rules from the specified DelegationConfigPath file and apply them based on the user's group memberships in Active Directory. If this setting is false, the application will ignore any delegation rules and return all servers that match the configured search criteria, regardless of the user's group memberships.
	private static bool ReadEnableDelegation(JsonElement root)
	{
		// We check if the "EnableDelegation" property exists in the root element of the JSON document and if it is a boolean value (true or false). 
		// If it does not exist or is not a valid boolean, we return false, indicating that delegation is not enabled.
		if (!TryGetPropertyIgnoreCase(root, "EnableDelegation", out var element)
			|| (element.ValueKind != JsonValueKind.True && element.ValueKind != JsonValueKind.False))
		{
			return false;
		}

		return element.GetBoolean(); // If the "EnableDelegation" property exists and is a valid boolean, we return its value using GetBoolean(), which will be true or false based on the configuration. This allows us to determine whether delegation rules should be applied when determining which servers to include in the results of server discovery queries, based on the user's group memberships in Active Directory.
	}

	// This helper method reads a string property from the root element of the JSON document, ignoring case sensitivity for the property name. 
	// It checks if the specified property exists and is a string, and if so, it returns the trimmed string value. 
	// If the property does not exist, is not a string, or is empty/whitespace, it returns the provided fallback value. 
	// This allows us to read optional string properties from the configuration with a specified default value, while also handling the case where the property is not provided or is not valid without throwing an exception.
	private static string ReadString(JsonElement root, string propertyName, string fallbackValue)
	{
		// We check if the specified property exists in the root element of the JSON document and if it is a string. 
		// If it does not exist or is not a string, we return the provided fallback value, indicating that we will use the default value for this configuration setting.
		if (!TryGetPropertyIgnoreCase(root, propertyName, out var element)
			|| element.ValueKind != JsonValueKind.String)
		{
			return fallbackValue; // We return the provided fallback value, indicating that we will use the default value for this configuration setting when the specified property is not present or is not a valid string in the configuration.
		}

		var value = element.GetString();
		return string.IsNullOrWhiteSpace(value) ? fallbackValue : value.Trim(); // We retrieve the string value of the specified property, and if it is null, empty, or consists only of whitespace, we return the provided fallback value. Otherwise, we return the trimmed string value. This allows us to handle the case where the configuration is provided but is not valid (e.g., an empty string), and it ensures that we only return a valid string if it is properly specified in the configuration, while still providing a sensible default value when it is not.
	}

	// This helper method reads a required string property from the root element of the JSON document, ignoring case sensitivity for the property name. 
	// It checks if the specified property exists and is a string, and if so, it returns the trimmed string value. 
	// If the property does not exist, is not a string, or is empty/whitespace, it throws an InvalidOperationException with a clear error message indicating that the required property must be provided with a non-empty string value. 
	// This ensures that we have a required configuration setting for critical properties, and it provides a clear error message if this configuration is missing or invalid, allowing users or administrators to quickly identify and resolve the issue with the configuration file.
	private static string ReadRequiredString(JsonElement root, string propertyName)
	{
		// We check if the specified property exists in the root element of the JSON document and if it is a string. 
		// If it does not exist or is not a string, we throw an InvalidOperationException with a clear error message indicating that the required property must be provided with a non-empty string value. This ensures that we have a required configuration setting for critical properties, and it provides a clear error message if this configuration is missing or invalid, allowing users or administrators to quickly identify and resolve the issue with the configuration file.
		if (!TryGetPropertyIgnoreCase(root, propertyName, out var element)
			|| element.ValueKind != JsonValueKind.String)
		{
			throw new InvalidOperationException($"JIT.config must contain a non-empty '{propertyName}' string value.");
		}

		var value = element.GetString();
		// We check if the retrieved string value is null, empty, or consists only of whitespace. 
		// If it is, we throw an InvalidOperationException with a clear error message indicating that the required property must be provided with a non-empty string value. 
		// This ensures that we have a valid configuration for this required property, and it provides clear feedback if the configuration is missing or invalid.
		if (string.IsNullOrWhiteSpace(value))
		{
			throw new InvalidOperationException($"JIT.config must contain a non-empty '{propertyName}' string value.");
		}

		return value.Trim();
	}

	private static string ReadEventLogSourceName(JsonElement root)
	{
		var eventLogSource = ReadOptionalString(root, "EventLogSource");
		if (!string.IsNullOrWhiteSpace(eventLogSource))
		{
			return eventLogSource;
		}

		var eventSource = ReadOptionalString(root, "EventSource");
		if (!string.IsNullOrWhiteSpace(eventSource))
		{
			return eventSource;
		}

		throw new InvalidOperationException("JIT.config must contain a non-empty 'EventLogSource' or 'EventSource' string value.");
	}

	// This helper method reads an optional string property from the root element of the JSON document, ignoring case sensitivity for the property name. 
	// It checks if the specified property exists and is a string, and if so, it returns the trimmed string value. 
	// If the property does not exist, is not a string, or is empty/whitespace, it returns null. 
	// This allows us to have optional configuration settings for string properties, where the absence of the property or an invalid value (e.g., an empty string) is treated as null, allowing the application to handle these cases gracefully without throwing exceptions, while still providing valid string values when they are properly specified in the configuration.
	private static string? ReadOptionalString(JsonElement root, string propertyName)
	{
		// We check if the specified property exists in the root element of the JSON document and if it is a string. 
		// If it does not exist or is not a string, we return null, indicating that there is no valid value for this optional configuration setting. 
		// This allows the application to handle the case where this configuration is not provided or is invalid without throwing an exception, and it can treat the absence of a valid value as null when processing the configuration.
		if (!TryGetPropertyIgnoreCase(root, propertyName, out var element)
			|| element.ValueKind != JsonValueKind.String)
		{
			return null;
		}

		var value = element.GetString();
		return string.IsNullOrWhiteSpace(value) ? null : value.Trim(); // We retrieve the string value of the specified property, and if it is null, empty, or consists only of whitespace, we return null. Otherwise, we return the trimmed string value. This allows us to handle the case where the configuration is provided but is not valid (e.g., an empty string), and it ensures that we only return a valid string if it is properly specified in the configuration, while treating invalid or missing values as null for optional settings.
	}

	// This helper method reads a positive integer property from the root element of the JSON document, ignoring case sensitivity for the property name. 
	// It checks if the specified property exists and is a number that can be parsed as an integer, and if so, it returns the integer value if it is greater than 0. 
	// If the property does not exist, is not a number, cannot be parsed as an integer, or is less than or equal to 0, it returns the provided fallback value. 
	// This allows us to read optional integer properties from the configuration with a specified default value, while also ensuring that the value is a valid positive integer, and providing a sensible default when it is not.
	private static int ReadPositiveInteger(JsonElement root, string propertyName, int fallbackValue)
	{
		// We check if the specified property exists in the root element of the JSON document and if it is a number that can be parsed as an integer. 
		// If it does not exist, is not a number, cannot be parsed as an integer, or is less than or equal to 0, we return the provided fallback value, indicating that we will use the default value for this configuration setting.
		if (!TryGetPropertyIgnoreCase(root, propertyName, out var element)
			|| element.ValueKind != JsonValueKind.Number
			|| !element.TryGetInt32(out var value)
			|| value <= 0)
		{
			return fallbackValue;
		}

		return value; // If the specified property exists, is a number, can be parsed as an integer, and is greater than 0, we return its integer value. This allows us to have a valid positive integer for this configuration setting, while still providing a sensible default value when the configuration is not provided or is invalid.
	}
	// This helper method attempts to retrieve a property from a JsonElement, ignoring case sensitivity for the property name. 
	// It checks if the JsonElement is an object, and if so, it enumerates the properties of the object to find a match for the specified property name, ignoring case. 
	// If a matching property is found, it returns true and outputs the value of the property. 
	// If no matching property is found, it returns false and outputs a default JsonElement value.

	private static bool TryGetPropertyIgnoreCase(JsonElement root, string propertyName, out JsonElement value)
	{
		// We check if the provided JsonElement is an object, as only objects can have properties. 
		// If it is not an object, we cannot find any properties, so we return false and output a default JsonElement value.
		if (root.ValueKind == JsonValueKind.Object)
		{
			// We enumerate the properties of the JsonElement object, and for each property, we check if its name matches the specified property name, ignoring case sensitivity. 
			// If we find a matching property, we output its value and return true, indicating that we successfully retrieved the property.
			foreach (var property in root.EnumerateObject())
			{
				if (property.Name.Equals(propertyName, StringComparison.OrdinalIgnoreCase))
				{
					value = property.Value;
					return true;
				}
			}
		}

		value = default;
		return false;
	}

	// This helper method normalizes a string value as an LDAP path. 
	// It checks if the value is null, empty, or consists only of whitespace, and if so, it returns null. 
	// It then trims the value and any surrounding quotes, and checks if it starts with "LDAP://", "OU=", "CN=", or "DC=", ignoring case. 
	// If it starts with "LDAP://", it returns the trimmed value as is.
	public static string? NormalizeLdapPath(string? value)
	{
		// We check if the provided value is null, empty, or consists only of whitespace. If it is, we return null, indicating that there is no valid LDAP path. 
		// This allows us to handle cases where the input is not valid without throwing an exception, and it ensures that we only return a valid LDAP path if the input is properly specified.
		if (string.IsNullOrWhiteSpace(value))
		{
			return null;
		}

		var trimmed = value.Trim().Trim('"', '\''); // We trim the input value to remove any leading or trailing whitespace, as well as any surrounding quotes (both double and single quotes). This helps to ensure that we are working with a clean string value when we check for the expected LDAP path formats, and it allows for some flexibility in how the input is provided in the configuration (e.g., allowing for quoted strings).
		// We check if the trimmed value starts with "LDAP://", ignoring case sensitivity. 
		// If it does, we return the trimmed value as is, since it is already in a valid LDAP path format.
		if (trimmed.StartsWith("LDAP://", StringComparison.OrdinalIgnoreCase)) 
		{
			return trimmed;
		}
		 // We check if the trimmed value starts with "OU=", "CN=", or "DC=", ignoring case sensitivity. 
		 // If it does, we assume it is a relative distinguished name (RDN) and we prepend "LDAP://" to construct a full LDAP path. 
		 // This allows for flexibility in how LDAP paths can be specified in the configuration, allowing for both full LDAP paths and relative distinguished names that will be normalized to full LDAP paths.
		if (trimmed.StartsWith("OU=", StringComparison.OrdinalIgnoreCase)
			|| trimmed.StartsWith("CN=", StringComparison.OrdinalIgnoreCase)
			|| trimmed.StartsWith("DC=", StringComparison.OrdinalIgnoreCase))
		{
			return $"LDAP://{trimmed}";
		}

		return null;
	}
}

/// <summary>
/// 	Represents a delegation rule that defines a mapping between a security identifier (SID) and an LDAP search base path. 
/// 	This is used to limit server discovery based on group membership in Active Directory, where each rule specifies that if a user is a member of the group identified by the SID, then the application should only return servers that are located within the specified LDAP search base path during server discovery queries. This allows for granular control over which servers are visible to users based on their group memberships, enhancing security and ensuring that users only have access to the servers they are authorized to manage.
/// </summary>
/// <param name="SecurityIdentifier">The security identifier (SID) of the Active Directory group that the delegation rule applies to. This should be a string representation of the SID, such as "S-1-5-21-..." for a group in Active Directory.</param>
/// <param name="SearchBaseLdapPath">The LDAP search base path that defines the scope of server discovery for users who are members of the group identified by the SecurityIdentifier. This should be a valid LDAP path, such as "LDAP://OU=Servers,DC=example,DC=com", that specifies the location in Active Directory where the application should search for servers to include in the results of server discovery queries for users who match this delegation rule.</param>	
/// <remarks>
/// 	Delegation rules are used to implement Just-In-Time (JIT) access control by limiting the visibility of servers during discovery based on group membership. 
/// 	When delegation is enabled, the application will read the delegation rules from a specified configuration file and apply them when determining which servers to include in the results of server discovery queries. If a user is a member of a group that matches a delegation rule, the application will only return servers that are located within the LDAP search base path defined by that rule. This allows for more secure and controlled access to servers, ensuring that users only see the servers they are authorized to manage based on their group memberships in Active Directory.
/// </remarks>
public record DelegationRule(string SecurityIdentifier, string SearchBaseLdapPath);

/// <summary>
/// 	Represents the configuration for delegation rules, including the path to the configuration file and the list of rules.
/// </summary> 
/// <remarks>
/// 	The DelegationConfiguration class is responsible for loading and managing delegation rules from a specified configuration file. It provides properties to access the path to the configuration file and the list of delegation rules. This class ensures that the configuration file exists and is a valid JSON file, and it parses the rules into a collection of DelegationRule objects.
/// </remarks>

public class DelegationConfiguration
{
	/// <summary>
	/// 	Gets the file path to the delegation configuration file that defines the rules for limiting server discovery based on group membership. 
	/// 	This property is set during initialization and is used to load the delegation rules from the specified file. 
	/// 	The application will read the delegation rules from this file and apply them when determining which servers to include in the results of server discovery queries, based on the user's group memberships in Active Directory. If this property is null, empty, or consists only of whitespace, it indicates that there is no delegation configuration file specified, and the application will not apply any delegation rules.
	/// </summary>
	public string DelegationConfigPath { get; }
	/// <summary>
	/// 	Gets the list of delegation rules that have been loaded from the delegation configuration file. 
	/// 	Each rule in the list defines a mapping between a security identifier (SID) and an LDAP search base path, which is used to limit server discovery based on group membership in Active Directory. 
	/// 	If delegation is enabled in the main configuration, the application will use this list of rules to determine which servers to include in the results of server discovery queries for users based on their group memberships. 
	/// 	If the list is empty, it indicates that there are no valid delegation rules defined in the configuration file, and the application will not apply any delegation-based filtering to server discovery results.
	/// </summary>	
	public IReadOnlyList<DelegationRule> Rules { get; }
	/// <summary>
	/// 	Initializes a new instance of the DelegationConfiguration class by loading delegation rules from the specified configuration file path. 
	/// 	The constructor checks if the provided path is valid, ensures that the file exists, and reads the rules from the file, parsing it as a JSON document. 
	/// 	If the file does not exist, is not a valid JSON file, or if the path is invalid, it throws appropriate exceptions with clear error messages to indicate the issue with loading the delegation configuration. 
	/// </summary>	
	/// <param name="delegationConfigPath">The file path to the delegation configuration file that defines the rules for limiting server discovery based on group membership. This should be a valid file path to a JSON file that contains the delegation rules. If the path is null, empty, or consists only of whitespace, an ArgumentException will be thrown.</param>	
	/// <exception cref="ArgumentException">Thrown when the provided delegationConfigPath is null, empty, or consists only of whitespace.</exception>
	/// <exception cref="FileNotFoundException">Thrown when the specified delegation configuration file does not exist at the provided path.</exception>
	/// <exception cref="InvalidOperationException">Thrown when there is an error reading the delegation configuration file or when the file is not a valid JSON file.</exception>
	/// <remarks>
	/// 	The constructor of the DelegationConfiguration class is responsible for initializing the configuration by loading the delegation rules from the specified file path. 
	/// 	It performs validation on the input path, checks for the existence of the file, and reads the rules from the file while handling potential exceptions that may arise during this process. This ensures that the DelegationConfiguration instance is properly initialized with valid rules or fails gracefully with clear error messages if there are issues with the configuration file.
	/// </remarks>	

	public DelegationConfiguration(string delegationConfigPath)
	{
		// We check if the provided delegationConfigPath is null, empty, or consists only of whitespace. 
		// If it is, we throw an ArgumentException with a clear error message indicating that the delegation config path must not be empty, along with the name of the parameter that caused the exception. This ensures that we have a valid file path to work with when attempting to load the delegation configuration, and it provides immediate feedback if the input is not valid.
		if (string.IsNullOrWhiteSpace(delegationConfigPath))
		{
			throw new ArgumentException("Delegation config path must not be empty.", nameof(delegationConfigPath));
		}

		DelegationConfigPath = delegationConfigPath; // We set the DelegationConfigPath property to the provided path, which will be used to load the delegation rules from the specified file. This allows us to have a reference to the configuration file path for future use, such as reloading the configuration or providing information about where the rules were loaded from.
		Rules = ReadRules(delegationConfigPath); // We call the ReadRules helper method to read the delegation rules from the specified configuration file path. This method will check if the file exists, read its contents, parse it as a JSON document, and extract the delegation rules into a list of DelegationRule objects. The resulting list of rules is then assigned to the Rules property, which can be used by the application to apply delegation-based filtering to server discovery results based on group membership in Active Directory.
	}

	// This helper method reads the delegation rules from the specified configuration file path. 
	// It checks if the file exists, and if not, it throws a FileNotFoundException with a clear error message indicating that the delegation config file was not found, along with the path that was attempted. 
	// If the file exists, it attempts to read the contents of the file and parse it as a JSON document. If the file cannot be read due to an I/O error, it catches the IOException and throws an InvalidOperationException with a clear error message indicating that there was an error reading the delegation config file, along with the original exception for more details. If the file is read successfully but cannot be parsed as valid JSON, it catches the JsonException and throws an InvalidOperationException with a clear error message indicating that the delegation config is not a valid JSON file, along with the original exception for more details. If the file is read and parsed successfully, it extracts the delegation rules from the JSON document and returns them as a distinct list of DelegationRule objects.	
	private static IReadOnlyList<DelegationRule> ReadRules(string path)
	{
		// We check if the specified file exists at the given path. If it does not exist, we throw a FileNotFoundException with a clear error message indicating that the delegation config file was not found, along with the path that was attempted. This provides immediate feedback to users or administrators that the configuration file is missing, allowing them to take corrective action by ensuring that the file is in place at the expected location.
		if (!File.Exists(path))
		{
			throw new FileNotFoundException("Delegation config file was not found.", path);
		}

		try
		{
			using var document = JsonDocument.Parse(File.ReadAllText(path)); // We attempt to read the contents of the specified file and parse it as a JSON document using JsonDocument.Parse. If the file is successfully read and parsed, we proceed to extract the delegation rules from the JSON document. If there is an issue with reading the file or if the contents cannot be parsed as valid JSON, we catch the resulting exceptions and handle them appropriately to provide clear feedback on what went wrong when attempting to read the delegation configuration file.
			// If there is an issue with reading the file, such as insufficient permissions or an I/O error, we catch the IOException and throw a new InvalidOperationException with a clear error message indicating that there was an error reading the delegation config file, along with the original exception for more details. This ensures that we handle file access issues gracefully and provide clear feedback on what went wrong when attempting to read the configuration file.
			var rules = ExtractRules(document.RootElement)
				.Distinct()
				.ToList();

			return rules;
		}
		// If there is an issue with reading the file, such as insufficient permissions or an I/O error, we catch the IOException and throw a new InvalidOperationException with a clear error message indicating that there was an error reading the delegation config file, along with the original exception for more details. This ensures that we handle file access issues gracefully and provide clear feedback on what went wrong when attempting to read the configuration file.
		catch (IOException ex)
		{
			throw new InvalidOperationException("Error reading delegation config file.", ex);
		}
		// If there is an issue with parsing the file as valid JSON, we catch the JsonException and throw a new InvalidOperationException with a clear error message indicating that the delegation config is not a valid JSON file, along with the original exception for more details. This ensures that we handle JSON parsing issues gracefully and provide clear feedback on what went wrong when attempting to read the configuration file.
		catch (JsonException ex)
		{
			throw new InvalidOperationException("Delegation config is not a valid JSON file.", ex);
		}
	}

	// This helper method recursively extracts delegation rules from a JsonElement. 
	// It checks if the element is an array and, if so, it enumerates the array and recursively calls itself for each item. 
	// If the element is an object, it looks for the "ComputerOU" property to determine the search base LDAP path and the "ADObject" property to read the security identifiers (SIDs). 
	// For each valid combination of search base and SID, it yields a new DelegationRule. 
	// This allows for flexible JSON structures where rules can be defined in arrays or nested objects, while ensuring that only valid rules with both a search base and at least one SID are returned.
	private static IEnumerable<DelegationRule> ExtractRules(JsonElement element)
	{
		// We check if the provided JsonElement is an array. If it is, we enumerate the array and recursively call ExtractRules for each item in the array, yielding any rules that are found. 
		// This allows for flexible JSON structures where rules can be defined in arrays, and it ensures that we can extract all valid rules from the configuration regardless of how they are structured within the JSON document.
		if (element.ValueKind == JsonValueKind.Array)
		{
			// We enumerate each item in the array and recursively call ExtractRules for each item, yielding any rules that are found.
			foreach (var item in element.EnumerateArray())
			{
				// For each item in the array, we call ExtractRules recursively to extract any delegation rules defined within that item. 
				// This allows for nested structures in the JSON configuration, where rules can be defined within arrays or objects at various levels of the hierarchy. 
				// We yield each rule found so that they can be collected into a list of DelegationRule objects for use in the application.
				foreach (var rule in ExtractRules(item))
				{
					yield return rule;
				}
			}

			yield break;
		}
		// If the element is not an array, we check if it is an object. 
		// If it is not an object, we cannot extract any rules from it, so we yield break to exit the method.
		if (element.ValueKind != JsonValueKind.Object)
		{
			yield break;
		}
		// We check if the object has a "ComputerOU" property that is a string, which will be used as the search base LDAP path for the delegation rule.
		if (!TryGetPropertyIgnoreCase(element, "ComputerOU", out var computerOuElement)
			|| computerOuElement.ValueKind != JsonValueKind.String)
		{
			yield break;
		}

		var searchBase = NormalizeLdapPath(computerOuElement.GetString()); // We retrieve the string value of the "ComputerOU" property and normalize it as an LDAP path using the NormalizeLdapPath helper method. This ensures that we have a valid LDAP path for the search base, which is necessary for the delegation rule to function correctly when limiting server discovery based on group membership in Active Directory. If the "ComputerOU" property is not a valid string or cannot be normalized to a valid LDAP path, we yield break to skip this rule, as it would not be valid without a proper search base.
		// We check if the normalized search base is null, empty, or consists only of whitespace. If it is, we yield break to skip this rule, as a valid search base LDAP path is required for the delegation rule to function correctly when limiting server discovery based on group membership in Active Directory. This ensures that we only return valid delegation rules that have a proper search base defined.
		if (string.IsNullOrWhiteSpace(searchBase))
		{
			yield break;
		}
		// We check if the object has an "ADObject" property, which should contain the security identifiers (SIDs) for the delegation rule. 
		// If it does not exist, we yield break to skip this rule, as a valid SID is required for the delegation rule to function correctly when limiting server discovery based on group membership in Active Directory. This ensures that we only return valid delegation rules that have both a proper search base and at least one valid SID defined.
		if (!TryGetPropertyIgnoreCase(element, "ADObject", out var adObjectElement))
		{
			yield break;
		}
		// We read the security identifiers (SIDs) from the "ADObject" property using the ReadSecurityIdentifiers helper method, which can handle both string and array formats for SIDs. 
		// For each valid SID that we read, we yield a new DelegationRule with the SID and the search base LDAP path. 
		// This allows us to create a delegation rule for each SID that is associated with the specified search base, enabling the application to apply these rules when determining which servers to include in the results of server discovery queries based on group membership in Active Directory.
		foreach (var sid in ReadSecurityIdentifiers(adObjectElement))
		{
			yield return new DelegationRule(sid, searchBase);
		}
	}

	// This helper method reads security identifiers (SIDs) from a JsonElement, which can be either a string or an array of strings. 
	// If the element is a string, it normalizes the string as a SID and yields it. If the element is an array, it enumerates the array and yields each string item as a normalized SID. 
	// If the element is neither a string nor an array, it yields nothing.
	private static IEnumerable<string> ReadSecurityIdentifiers(JsonElement element)
	{
		// We check if the provided JsonElement is a string. If it is, we retrieve the string value, normalize it as a SID using the NormalizeSecurityIdentifier helper method, and yield it if it is not null, empty, or whitespace. 
		 // This allows for a simple case where the "ADObject" property contains a single SID as a string, and we can directly return that as a delegation rule.
		if (element.ValueKind == JsonValueKind.String)
		{
			var value = element.GetString(); // We retrieve the string value of the element, which should represent a security identifier (SID) in this case.
			// We check if the retrieved string value is null, empty, or consists only of whitespace. If it is not, we normalize it as a SID using the NormalizeSecurityIdentifier helper method and yield it. 
			// This ensures that we only return valid SIDs that are properly specified in the configuration, while ignoring any invalid or empty values.
			if (!string.IsNullOrWhiteSpace(value))
			{
				yield return NormalizeSecurityIdentifier(value);
			}

			yield break;
		}

		// We check if the provided JsonElement is an array. If it is not, we yield break to exit the method, as we cannot read SIDs from a non-string, non-array element. 
		// This ensures that we only attempt to read SIDs from valid formats in the configuration.
		if (element.ValueKind != JsonValueKind.Array)
		{
			yield break;
		}
		// If the element is an array, we enumerate the array and for each item, we check if it is a string. 
		// If it is a string, we retrieve the string value, normalize it as a SID, and yield it if it is not null, empty, or whitespace. 
		// This allows for a case where the "ADObject" property contains multiple SIDs as an array of strings, and we can return a delegation rule for each valid SID in the array.
		foreach (var item in element.EnumerateArray())
		{
			// We check if the current item in the array is a string. 
			// If it is, we retrieve the string value, normalize it as a SID using the NormalizeSecurityIdentifier helper method, and yield it if it is not null, empty, or whitespace. 
			// This ensures that we only return valid SIDs that are properly specified in the configuration, while ignoring any invalid or empty values in the array.
			if (item.ValueKind == JsonValueKind.String)
			{
				var value = item.GetString();
				if (!string.IsNullOrWhiteSpace(value))
				{
					yield return NormalizeSecurityIdentifier(value);
				}
			}
		}
	}

	// This helper method attempts to retrieve a property from a JsonElement, ignoring case sensitivity for the property name. 
	// It checks if the JsonElement is an object, and if so, it enumerates the properties of the object to find a match for the specified property name, ignoring case. 
	// If a matching property is found, it returns true and outputs the value of the property. 
	// If no matching property is found, it returns false and outputs a default JsonElement value.	
	private static bool TryGetPropertyIgnoreCase(JsonElement root, string propertyName, out JsonElement value)
	{
		// We check if the provided JsonElement is an object, as only objects can have properties. 
		// If it is not an object, we cannot find any properties, so we return false and output a default JsonElement value.
		if (root.ValueKind == JsonValueKind.Object)
		{
			// We enumerate the properties of the JsonElement object, and for each property, we check if its name matches the specified property name, ignoring case sensitivity. 
			// If we find a matching property, we output its value and return true, indicating that we successfully retrieved the property. 
			// This allows us to access properties in the JSON configuration without requiring exact case matches, providing flexibility in how the configuration can be written while still allowing us to retrieve the necessary values for processing the delegation rules.
			foreach (var property in root.EnumerateObject())
			{
				// We check if the name of the current property matches the specified property name, ignoring case sensitivity.
				if (property.Name.Equals(propertyName, StringComparison.OrdinalIgnoreCase))
				{
					value = property.Value;
					return true;
				}
			}
		}
		
		// If no matching property is found, we output a default JsonElement value and return false, indicating that we did not retrieve the property. 
		// This allows the calling code to handle the case where the property is not present in the JSON configuration, and it provides a clear way to check for the existence of properties without throwing exceptions when they are missing.	
		value = default;
		return false;
	}

	// This helper method normalizes a string value as a security identifier (SID). 
	// It trims the value, removes any surrounding quotes, and converts it to uppercase invariant.
	private static string NormalizeSecurityIdentifier(string value)
	{
		return value.Trim().Trim('"', '\'').ToUpperInvariant(); // We trim the input value to remove any leading or trailing whitespace, as well as any surrounding quotes (both double and single quotes).
	}
	// This helper method normalizes a string value as an LDAP path. 
	// It checks if the value is null, empty, or consists only of whitespace, and if so, it returns null. 
	// It then trims the value and any surrounding quotes, and checks if it starts with "LDAP://", "OU=", "CN=", or "DC=", ignoring case. 
	// If it starts with "LDAP://", it returns the trimmed value as is. If it starts with "OU=", "CN=", or "DC=", it prepends "LDAP://" to construct a full LDAP path.

	private static string? NormalizeLdapPath(string? value)
	{
		return JitConfiguration.NormalizeLdapPath(value); // We call the NormalizeLdapPath method from the JitConfiguration class to perform the normalization of the LDAP path. This allows us to reuse the same logic for normalizing LDAP paths across different parts of the application, ensuring consistency in how LDAP paths are handled and allowing for any future updates to the normalization logic to be applied in one place.
	}
}