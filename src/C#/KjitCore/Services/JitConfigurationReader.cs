using System.DirectoryServices.Protocols;
using System.Net.NetworkInformation;
using KjitCore.Models;
#if NET48
using System.Web.Script.Serialization;
#else
using System.Text.Json;
#endif

namespace KjitCore.Services;

internal static class JitConfigurationReader
{
    private static readonly string[] JitConfigurationAttributeNames =
    {
        "ConfigScriptVersion",
        "JitCnfg-ConfigScriptVersion",
        "AdminPreFix",
        "JitCnfg-AdminPreFix",
        "AdminGroupOU",
        "JitCnfg-JitAdmGroupOU",
        "OU",
        "MaxElevatedTime",
        "JitCnfg-MaxElevatedTime",
        "DefaultElevatedTime",
        "JitCnfg-DefaultElevatedTime",
        "ExcludeServerGroupName",
        "Tier0ServerGroupName",
        "LDAPexcludeComputer",
        "LDAPT0Computers",
        "ComputerSearch",
        "LDAPT1Computers",
        "JitCnfg-LDAPT1Computers",
        "GroupManagementTaskRerun",
        "GroupManagedServiceAccountName",
        "JitCnfg-GroupManagedServiceAccountName",
        "DelegationConfigPath",
        "EnableMultiDomainSupport",
        "JitCnfg-EnableMultiDomainSupport",
        "UseManagedByforDelegation",
        "MaxConcurrentServer",
        "JitCnfg-MaxConcurrentServer",
        "DomainSeparator",
        "JitCnfg-DomainSeparator",
        "Domain",
        "JitCnfg-Domain",
        "AuthorizedServer",
        "T1Searchbase",
        "JitCnfg-T1Searchbase",
        "ExcludeComputerOU",
        "LDAPT0ComputerPath",
        "JitCnfg-ElevateEventID",
        "JitCnfg-EnableDelegation",
        "JitCnfg-EventLog",
        "JitCnfg-EventSource",
        "ElevateEventID",
        "EnableDelegation",
        "EventLog",
        "EventSource",
    };

    public static JitConfigurationObject LoadFromFile(string path)
    {
        if (string.IsNullOrWhiteSpace(path))
        {
            throw new ArgumentException("A JIT configuration file path is required.", nameof(path));
        }

        if (!File.Exists(path))
        {
            throw new FileNotFoundException("JIT configuration file was not found.", path);
        }

        var json = File.ReadAllText(path);
        var configuration = new JitConfigurationObject();

#if NET48
        var serializer = new JavaScriptSerializer();
        var root = serializer.DeserializeObject(json) as IDictionary<string, object>;
        if (root is null)
        {
            throw new InvalidOperationException("JIT configuration file must contain a JSON object at the root.");
        }

        Apply(root, configuration);
#else
        using var document = JsonDocument.Parse(json);

        if (document.RootElement.ValueKind != JsonValueKind.Object)
        {
            throw new InvalidOperationException("JIT configuration file must contain a JSON object at the root.");
        }

        Apply(document.RootElement, configuration);
#endif
        return configuration;
    }

    public static JitConfigurationObject LoadFromActiveDirectory(string source, string? ldapServer = null)
    {
        if (string.IsNullOrWhiteSpace(source))
        {
            throw new ArgumentException("A configuration source value is required.", nameof(source));
        }

        var normalizedSource = source.Trim();
        var looksLikeDistinguishedName = LooksLikeDistinguishedName(normalizedSource);
        var domainFromDn = looksLikeDistinguishedName ? ExtractDomainFromDistinguishedName(normalizedSource) : string.Empty;

        using var connection = CreateLdapConnection(ldapServer, domainFromDn);

        SearchResultEntry entry;
        if (looksLikeDistinguishedName)
        {
            entry = ReadByDistinguishedName(connection, normalizedSource);
        }
        else
        {
            entry = ReadByCommonName(connection, normalizedSource);
        }

        var configuration = new JitConfigurationObject();
        Apply(entry.Attributes, configuration);
        return configuration;
    }

    private static LdapConnection CreateLdapConnection(string? ldapServer, string fallbackDomain)
    {
        var effectiveServer = string.IsNullOrWhiteSpace(ldapServer)
            ? (!string.IsNullOrWhiteSpace(fallbackDomain) ? fallbackDomain : GetCurrentDomainDnsName())
            : ldapServer!.Trim();

        var identifier = new LdapDirectoryIdentifier(effectiveServer, false, false);
        var connection = new LdapConnection(identifier)
        {
            AuthType = AuthType.Negotiate,
        };

        connection.SessionOptions.ProtocolVersion = 3;
        connection.Bind();
        return connection;
    }

    private static SearchResultEntry ReadByDistinguishedName(LdapConnection connection, string distinguishedName)
    {
        var request = new SearchRequest(distinguishedName, "(objectClass=*)", SearchScope.Base, JitConfigurationAttributeNames);
        var response = (SearchResponse)connection.SendRequest(request);
        if (response.Entries.Count == 0)
        {
            throw new InvalidOperationException($"Configuration object '{distinguishedName}' was not found in Active Directory.");
        }

        return response.Entries[0];
    }

    private static SearchResultEntry ReadByCommonName(LdapConnection connection, string commonName)
    {
        var configurationNamingContext = ReadConfigurationNamingContext(connection);
        var serviceContainer = $"CN=Just-In-Time Administration,CN=Services,{configurationNamingContext}";
        var bases = new[] { serviceContainer, configurationNamingContext };
        var filter = $"(&(objectClass=*)(cn={EscapeLdapFilterValue(commonName)}))";

        foreach (var baseDn in bases)
        {
            var request = new SearchRequest(baseDn, filter, SearchScope.Subtree, JitConfigurationAttributeNames);
            var response = (SearchResponse)connection.SendRequest(request);

            if (response.Entries.Count == 1)
            {
                return response.Entries[0];
            }

            if (response.Entries.Count > 1)
            {
                throw new InvalidOperationException(
                    $"Multiple Active Directory configuration objects with cn='{commonName}' were found below '{baseDn}'. Please provide the full distinguished name.");
            }
        }

        throw new InvalidOperationException(
            $"Active Directory configuration object with cn='{commonName}' was not found below '{serviceContainer}' or '{configurationNamingContext}'.");
    }

    private static string ReadConfigurationNamingContext(LdapConnection connection)
    {
        var request = new SearchRequest(string.Empty, "(objectClass=*)", SearchScope.Base, "configurationNamingContext");
        var response = (SearchResponse)connection.SendRequest(request);
        if (response.Entries.Count == 0)
        {
            throw new InvalidOperationException("RootDSE query returned no entries.");
        }

        var attributes = response.Entries[0].Attributes;
        if (!TryReadString(attributes, out var namingContext, "configurationNamingContext") || string.IsNullOrWhiteSpace(namingContext))
        {
            throw new InvalidOperationException("configurationNamingContext was not returned by RootDSE.");
        }

        return namingContext;
    }

    private static bool LooksLikeDistinguishedName(string value)
    {
        return value.Contains('=') && value.Contains(',');
    }

    private static string EscapeLdapFilterValue(string value)
    {
        return value
            .Replace("\\", "\\5c")
            .Replace("*", "\\2a")
            .Replace("(", "\\28")
            .Replace(")", "\\29")
            .Replace("\0", "\\00");
    }

#if NET48
    private static void Apply(IDictionary<string, object> root, JitConfigurationObject configuration)
    {
        if (TryReadString(root, out var configScriptVersion, "ConfigScriptVersion"))
        {
            configuration.ConfigScriptVersion = configScriptVersion;
        }

        if (TryReadString(root, out var adminPrefix, "AdminPreFix"))
        {
            configuration.AdminPreFix = adminPrefix;
        }

        if (TryReadString(root, out var adminGroupOu, "AdminGroupOU"))
        {
            configuration.AdminGroupOU = adminGroupOu;
        }
        else if (TryGetValue(root, out var ouObject, "OU"))
        {
            if (ouObject is string ouString)
            {
                configuration.AdminGroupOU = ouString;
            }
            else if (ouObject is object[] ouArray)
            {
                configuration.TargetOU = ReadStringList(ouArray);
            }
        }

        if (TryReadInt32(root, out var maxElevatedTime, "MaxElevatedTime"))
        {
            configuration.MaxElevatedTime = maxElevatedTime;
        }

        if (TryReadInt32(root, out var defaultElevatedTime, "DefaultElevatedTime"))
        {
            configuration.DefaultElevatedTime = defaultElevatedTime;
        }

        if (TryReadString(root, out var eventLog, "EventLog"))
        {
            configuration.EventLog = eventLog;
        }

        if (TryReadString(root, out var eventSource, "EventSource"))
        {
            configuration.EventSource = eventSource;
        }

        if (TryReadString(root, out var debugLogPath, "DebugLogPath"))
        {
            configuration.DebugLogPath = debugLogPath;
        }

        if (TryReadBoolean(root, out var enableDelegation, "EnableDelegation"))
        {
            configuration.EnableDelegation = enableDelegation;
        }

        if (TryReadInt32(root, out var elevateEventId, "ElevateEventID"))
        {
            configuration.ElevateEventID = elevateEventId;
        }

        if (TryReadString(root, out var excludeServerGroupName, "ExcludeServerGroupName", "Tier0ServerGroupName"))
        {
            configuration.ExcludeServerGroupName = excludeServerGroupName;
        }

        if (TryReadString(root, out var ldapExcludeComputer, "LDAPexcludeComputer", "LDAPT0Computers"))
        {
            configuration.LDAPexcludeComputer = ldapExcludeComputer;
        }

        if (TryReadString(root, out var computerSearch, "ComputerSearch", "LDAPT1Computers"))
        {
            configuration.ComputerSearch = computerSearch;
        }

        if (TryReadInt32(root, out var groupManagementTaskRerun, "GroupManagementTaskRerun"))
        {
            configuration.GroupManagementTaskRerun = groupManagementTaskRerun;
        }

        if (TryReadString(root, out var gmsaName, "GroupManagedServiceAccountName"))
        {
            configuration.GroupManagedServiceAccountName = NormalizeGmsaName(gmsaName);
        }

        if (TryReadString(root, out var delegationConfigPath, "DelegationConfigPath"))
        {
            configuration.DelegationConfigPath = delegationConfigPath;
        }

        if (TryReadBoolean(root, out var enableMultiDomainSupport, "EnableMultiDomainSupport"))
        {
            configuration.EnableMultiDomainSupport = enableMultiDomainSupport;
        }

        if (TryReadBoolean(root, out var useManagedByForDelegation, "UseManagedByforDelegation"))
        {
            configuration.UseManagedByforDelegation = useManagedByForDelegation;
        }

        if (TryReadInt32(root, out var maxConcurrentServer, "MaxConcurrentServer"))
        {
            configuration.MaxConcurrentServer = maxConcurrentServer;
        }

        if (TryReadString(root, out var domainSeparator, "DomainSeparator") && domainSeparator.Length == 1)
        {
            configuration.DomainSeparator = domainSeparator[0];
        }

        if (TryReadStringList(root, out var domainValues, "Domain"))
        {
            configuration.Domain = domainValues;
        }

        if (TryReadStringList(root, out var authorizedServerValues, "AuthorizedServer"))
        {
            configuration.AuthorizedServer = authorizedServerValues;
        }

        if (TryReadStringList(root, out var searchBaseOus, "T1Searchbase"))
        {
            configuration.TargetOU = searchBaseOus;
        }

        if (TryReadStringList(root, out var excludeComputerOus, "ExcludeComputerOU"))
        {
            configuration.ExcludeComputerOU = NormalizeDistinguishedNames(excludeComputerOus, configuration);
        }
        else if (TryReadString(root, out var legacyExcludeComputerOu, "LDAPT0ComputerPath"))
        {
            configuration.ExcludeComputerOU = NormalizeDistinguishedNames(new[] { legacyExcludeComputerOu }, configuration);
        }
    }
#else
    private static void Apply(JsonElement root, JitConfigurationObject configuration)
    {
        if (TryReadString(root, out var configScriptVersion, "ConfigScriptVersion"))
        {
            configuration.ConfigScriptVersion = configScriptVersion;
        }

        if (TryReadString(root, out var adminPrefix, "AdminPreFix"))
        {
            configuration.AdminPreFix = adminPrefix;
        }

        if (TryReadString(root, out var adminGroupOu, "AdminGroupOU"))
        {
            configuration.AdminGroupOU = adminGroupOu;
        }
        else if (TryGetProperty(root, out var ouElement, "OU"))
        {
            if (ouElement.ValueKind == JsonValueKind.String)
            {
                configuration.AdminGroupOU = ouElement.GetString() ?? configuration.AdminGroupOU;
            }
            else if (ouElement.ValueKind == JsonValueKind.Array)
            {
                configuration.TargetOU = ReadStringList(ouElement);
            }
        }

        if (TryReadInt32(root, out var maxElevatedTime, "MaxElevatedTime"))
        {
            configuration.MaxElevatedTime = maxElevatedTime;
        }

        if (TryReadInt32(root, out var defaultElevatedTime, "DefaultElevatedTime"))
        {
            configuration.DefaultElevatedTime = defaultElevatedTime;
        }

        if (TryReadString(root, out var eventLog, "EventLog"))
        {
            configuration.EventLog = eventLog;
        }

        if (TryReadString(root, out var eventSource, "EventSource"))
        {
            configuration.EventSource = eventSource;
        }

        if (TryReadString(root, out var debugLogPath, "DebugLogPath"))
        {
            configuration.DebugLogPath = debugLogPath;
        }

        if (TryReadBoolean(root, out var enableDelegation, "EnableDelegation"))
        {
            configuration.EnableDelegation = enableDelegation;
        }

        if (TryReadInt32(root, out var elevateEventId, "ElevateEventID"))
        {
            configuration.ElevateEventID = elevateEventId;
        }

        if (TryReadString(root, out var excludeServerGroupName, "ExcludeServerGroupName", "Tier0ServerGroupName"))
        {
            configuration.ExcludeServerGroupName = excludeServerGroupName;
        }

        if (TryReadString(root, out var ldapExcludeComputer, "LDAPexcludeComputer", "LDAPT0Computers"))
        {
            configuration.LDAPexcludeComputer = ldapExcludeComputer;
        }

        if (TryReadString(root, out var computerSearch, "ComputerSearch", "LDAPT1Computers"))
        {
            configuration.ComputerSearch = computerSearch;
        }

        if (TryReadInt32(root, out var groupManagementTaskRerun, "GroupManagementTaskRerun"))
        {
            configuration.GroupManagementTaskRerun = groupManagementTaskRerun;
        }

        if (TryReadString(root, out var gmsaName, "GroupManagedServiceAccountName"))
        {
            configuration.GroupManagedServiceAccountName = NormalizeGmsaName(gmsaName);
        }

        if (TryReadString(root, out var delegationConfigPath, "DelegationConfigPath"))
        {
            configuration.DelegationConfigPath = delegationConfigPath;
        }

        if (TryReadBoolean(root, out var enableMultiDomainSupport, "EnableMultiDomainSupport"))
        {
            configuration.EnableMultiDomainSupport = enableMultiDomainSupport;
        }

        if (TryReadBoolean(root, out var useManagedByForDelegation, "UseManagedByforDelegation"))
        {
            configuration.UseManagedByforDelegation = useManagedByForDelegation;
        }

        if (TryReadInt32(root, out var maxConcurrentServer, "MaxConcurrentServer"))
        {
            configuration.MaxConcurrentServer = maxConcurrentServer;
        }

        if (TryReadString(root, out var domainSeparator, "DomainSeparator") && domainSeparator.Length == 1)
        {
            configuration.DomainSeparator = domainSeparator[0];
        }

        if (TryReadStringList(root, out var domainValues, "Domain"))
        {
            configuration.Domain = domainValues;
        }

        if (TryReadStringList(root, out var authorizedServerValues, "AuthorizedServer"))
        {
            configuration.AuthorizedServer = authorizedServerValues;
        }

        if (TryReadStringList(root, out var searchBaseOus, "T1Searchbase"))
        {
            configuration.TargetOU = searchBaseOus;
        }

        if (TryReadStringList(root, out var excludeComputerOus, "ExcludeComputerOU"))
        {
            configuration.ExcludeComputerOU = NormalizeDistinguishedNames(excludeComputerOus, configuration);
        }
        else if (TryReadString(root, out var legacyExcludeComputerOu, "LDAPT0ComputerPath"))
        {
            configuration.ExcludeComputerOU = NormalizeDistinguishedNames(new[] { legacyExcludeComputerOu }, configuration);
        }
    }
#endif

    private static void Apply(SearchResultAttributeCollection attributes, JitConfigurationObject configuration)
    {
        if (TryReadString(attributes, out var configScriptVersion, "ConfigScriptVersion", "JitCnfg-ConfigScriptVersion"))
        {
            configuration.ConfigScriptVersion = configScriptVersion;
        }

        if (TryReadString(attributes, out var adminPrefix, "AdminPreFix", "JitCnfg-AdminPreFix"))
        {
            configuration.AdminPreFix = adminPrefix;
        }

        if (TryReadString(attributes, out var adminGroupOu, "AdminGroupOU", "JitCnfg-JitAdmGroupOU", "OU"))
        {
            configuration.AdminGroupOU = adminGroupOu;
        }

        if (TryReadInt32(attributes, out var maxElevatedTime, "MaxElevatedTime", "JitCnfg-MaxElevatedTime"))
        {
            configuration.MaxElevatedTime = maxElevatedTime;
        }

        if (TryReadInt32(attributes, out var defaultElevatedTime, "DefaultElevatedTime", "JitCnfg-DefaultElevatedTime"))
        {
            configuration.DefaultElevatedTime = defaultElevatedTime;
        }

        if (TryReadString(attributes, out var eventLog, "EventLog", "JitCnfg-EventLog"))
        {
            configuration.EventLog = eventLog;
        }

        if (TryReadString(attributes, out var eventSource, "EventSource", "JitCnfg-EventSource"))
        {
            configuration.EventSource = eventSource;
        }

        if (TryReadBoolean(attributes, out var enableDelegation, "EnableDelegation", "JitCnfg-EnableDelegation"))
        {
            configuration.EnableDelegation = enableDelegation;
        }

        if (TryReadInt32(attributes, out var elevateEventId, "ElevateEventID", "JitCnfg-ElevateEventID"))
        {
            configuration.ElevateEventID = elevateEventId;
        }

        if (TryReadString(attributes, out var excludeServerGroupName, "ExcludeServerGroupName", "Tier0ServerGroupName"))
        {
            configuration.ExcludeServerGroupName = excludeServerGroupName;
        }

        if (TryReadString(attributes, out var ldapExcludeComputer, "LDAPexcludeComputer", "LDAPT0Computers"))
        {
            configuration.LDAPexcludeComputer = ldapExcludeComputer;
        }

        if (TryReadString(attributes, out var computerSearch, "ComputerSearch", "LDAPT1Computers", "JitCnfg-LDAPT1Computers"))
        {
            configuration.ComputerSearch = computerSearch;
        }

        if (TryReadInt32(attributes, out var groupManagementTaskRerun, "GroupManagementTaskRerun"))
        {
            configuration.GroupManagementTaskRerun = groupManagementTaskRerun;
        }

        if (TryReadString(attributes, out var gmsaName, "GroupManagedServiceAccountName", "JitCnfg-GroupManagedServiceAccountName"))
        {
            configuration.GroupManagedServiceAccountName = NormalizeGmsaName(gmsaName);
        }

        if (TryReadString(attributes, out var delegationConfigPath, "DelegationConfigPath"))
        {
            configuration.DelegationConfigPath = delegationConfigPath;
        }

        if (TryReadBoolean(attributes, out var enableMultiDomainSupport, "EnableMultiDomainSupport", "JitCnfg-EnableMultiDomainSupport"))
        {
            configuration.EnableMultiDomainSupport = enableMultiDomainSupport;
        }

        if (TryReadBoolean(attributes, out var useManagedByForDelegation, "UseManagedByforDelegation"))
        {
            configuration.UseManagedByforDelegation = useManagedByForDelegation;
        }

        if (TryReadInt32(attributes, out var maxConcurrentServer, "MaxConcurrentServer", "JitCnfg-MaxConcurrentServer"))
        {
            configuration.MaxConcurrentServer = maxConcurrentServer;
        }

        if (TryReadString(attributes, out var domainSeparator, "DomainSeparator", "JitCnfg-DomainSeparator") && domainSeparator.Length == 1)
        {
            configuration.DomainSeparator = domainSeparator[0];
        }

        if (TryReadStringList(attributes, out var domainValues, "Domain", "JitCnfg-Domain"))
        {
            configuration.Domain = domainValues;
        }

        if (TryReadStringList(attributes, out var authorizedServerValues, "AuthorizedServer"))
        {
            configuration.AuthorizedServer = authorizedServerValues;
        }

        if (TryReadStringList(attributes, out var searchBaseOus, "T1Searchbase", "JitCnfg-T1Searchbase"))
        {
            configuration.TargetOU = searchBaseOus;
        }

        if (TryReadStringList(attributes, out var excludeComputerOus, "ExcludeComputerOU"))
        {
            configuration.ExcludeComputerOU = NormalizeDistinguishedNames(excludeComputerOus, configuration);
        }
        else if (TryReadString(attributes, out var legacyExcludeComputerOu, "LDAPT0ComputerPath"))
        {
            configuration.ExcludeComputerOU = NormalizeDistinguishedNames(new[] { legacyExcludeComputerOu }, configuration);
        }
    }

    private static string NormalizeGmsaName(string value)
    {
        var normalized = value.Trim();
        return normalized.EndsWith("$", StringComparison.Ordinal) ? normalized : normalized + "$";
    }

    private static IReadOnlyList<string> NormalizeDistinguishedNames(IEnumerable<string> values, JitConfigurationObject configuration)
    {
        var domainSuffix = configuration.Domain.Count > 0 ? BuildDomainDn(configuration.Domain[0]) : string.Empty;
        var result = new List<string>();

        foreach (var value in values)
        {
            var normalized = value.Trim();
            if (normalized.IndexOf("DC=", StringComparison.OrdinalIgnoreCase) < 0 && !string.IsNullOrWhiteSpace(domainSuffix))
            {
                normalized = normalized + "," + domainSuffix;
            }

            result.Add(normalized);
        }

        return result;
    }

    private static string BuildDomainDn(string dnsName)
    {
        var labels = dnsName.Split(new[] { '.' }, StringSplitOptions.RemoveEmptyEntries);
        var parts = new string[labels.Length];
        for (var index = 0; index < labels.Length; index++)
        {
            parts[index] = $"DC={labels[index].Trim()}";
        }

        return string.Join(",", parts);
    }

#if NET48
    private static bool TryReadString(IDictionary<string, object> root, out string value, params string[] propertyNames)
    {
        foreach (var propertyName in propertyNames)
        {
            if (TryGetValue(root, out var raw, propertyName) && raw is not null)
            {
                value = raw.ToString() ?? string.Empty;
                return true;
            }
        }

        value = string.Empty;
        return false;
    }
#else
    private static bool TryReadString(JsonElement root, out string value, params string[] propertyNames)
    {
        foreach (var propertyName in propertyNames)
        {
            if (TryGetProperty(root, out var element, propertyName) && element.ValueKind == JsonValueKind.String)
            {
                value = element.GetString() ?? string.Empty;
                return true;
            }
        }

        value = string.Empty;
        return false;
    }
#endif

    private static bool TryReadString(SearchResultAttributeCollection attributes, out string value, params string[] attributeNames)
    {
        foreach (var attributeName in attributeNames)
        {
            if (TryGetAttribute(attributes, attributeName, out var values) && values.Count > 0)
            {
                var first = values[0];
                var converted = ConvertAttributeValueToString(first);
                if (converted is not null)
                {
                    value = converted;
                    return true;
                }
            }
        }

        value = string.Empty;
        return false;
    }

#if NET48
    private static bool TryReadInt32(IDictionary<string, object> root, out int value, params string[] propertyNames)
    {
        foreach (var propertyName in propertyNames)
        {
            if (TryGetValue(root, out var raw, propertyName) && raw is not null && int.TryParse(raw.ToString(), out value))
            {
                return true;
            }
        }

        value = default;
        return false;
    }
#else
    private static bool TryReadInt32(JsonElement root, out int value, params string[] propertyNames)
    {
        foreach (var propertyName in propertyNames)
        {
            if (TryGetProperty(root, out var element, propertyName) && element.ValueKind == JsonValueKind.Number && element.TryGetInt32(out value))
            {
                return true;
            }
        }

        value = default;
        return false;
    }
#endif

    private static bool TryReadInt32(SearchResultAttributeCollection attributes, out int value, params string[] attributeNames)
    {
        foreach (var attributeName in attributeNames)
        {
            if (TryReadString(attributes, out var raw, attributeName) && int.TryParse(raw, out value))
            {
                return true;
            }
        }

        value = default;
        return false;
    }

#if NET48
    private static bool TryReadBoolean(IDictionary<string, object> root, out bool value, params string[] propertyNames)
    {
        foreach (var propertyName in propertyNames)
        {
            if (TryGetValue(root, out var raw, propertyName) && raw is not null)
            {
                if (raw is bool boolValue)
                {
                    value = boolValue;
                    return true;
                }

                var text = raw.ToString() ?? string.Empty;
                if (bool.TryParse(text, out value))
                {
                    return true;
                }

                if (string.Equals(text, "1", StringComparison.Ordinal))
                {
                    value = true;
                    return true;
                }

                if (string.Equals(text, "0", StringComparison.Ordinal))
                {
                    value = false;
                    return true;
                }
            }
        }

        value = default;
        return false;
    }
#else
    private static bool TryReadBoolean(JsonElement root, out bool value, params string[] propertyNames)
    {
        foreach (var propertyName in propertyNames)
        {
            if (TryGetProperty(root, out var element, propertyName))
            {
                if (element.ValueKind == JsonValueKind.True)
                {
                    value = true;
                    return true;
                }

                if (element.ValueKind == JsonValueKind.False)
                {
                    value = false;
                    return true;
                }
            }
        }

        value = default;
        return false;
    }
#endif

    private static bool TryReadBoolean(SearchResultAttributeCollection attributes, out bool value, params string[] attributeNames)
    {
        foreach (var attributeName in attributeNames)
        {
            if (TryReadString(attributes, out var raw, attributeName))
            {
                if (bool.TryParse(raw, out value))
                {
                    return true;
                }

                if (string.Equals(raw, "1", StringComparison.Ordinal))
                {
                    value = true;
                    return true;
                }

                if (string.Equals(raw, "0", StringComparison.Ordinal))
                {
                    value = false;
                    return true;
                }
            }
        }

        value = default;
        return false;
    }

#if NET48
    private static bool TryReadStringList(IDictionary<string, object> root, out IReadOnlyList<string> values, params string[] propertyNames)
    {
        foreach (var propertyName in propertyNames)
        {
            if (TryGetValue(root, out var raw, propertyName) && raw is not null)
            {
                if (raw is string text)
                {
                    values = new[] { text };
                    return true;
                }

                if (raw is object[] array)
                {
                    values = ReadStringList(array);
                    return true;
                }
            }
        }

        values = Array.Empty<string>();
        return false;
    }
#else
    private static bool TryReadStringList(JsonElement root, out IReadOnlyList<string> values, params string[] propertyNames)
    {
        foreach (var propertyName in propertyNames)
        {
            if (TryGetProperty(root, out var element, propertyName))
            {
                if (element.ValueKind == JsonValueKind.String)
                {
                    values = new[] { element.GetString() ?? string.Empty };
                    return true;
                }

                if (element.ValueKind == JsonValueKind.Array)
                {
                    values = ReadStringList(element);
                    return true;
                }
            }
        }

        values = Array.Empty<string>();
        return false;
    }
#endif

    private static bool TryReadStringList(SearchResultAttributeCollection attributes, out IReadOnlyList<string> values, params string[] attributeNames)
    {
        foreach (var attributeName in attributeNames)
        {
            if (TryGetAttribute(attributes, attributeName, out var directoryAttribute))
            {
                var list = new List<string>();
                for (var index = 0; index < directoryAttribute.Count; index++)
                {
                    var converted = ConvertAttributeValueToString(directoryAttribute[index]);
                    if (!string.IsNullOrWhiteSpace(converted))
                    {
                        list.Add(converted!);
                    }
                }

                values = list;
                return true;
            }
        }

        values = Array.Empty<string>();
        return false;
    }

#if NET48
    private static IReadOnlyList<string> ReadStringList(object[] arrayElement)
    {
        var values = new List<string>();
        foreach (var item in arrayElement)
        {
            if (item is not null)
            {
                values.Add(item.ToString() ?? string.Empty);
            }
        }

        return values;
    }
#else
    private static IReadOnlyList<string> ReadStringList(JsonElement arrayElement)
    {
        var values = new List<string>();
        foreach (var item in arrayElement.EnumerateArray())
        {
            if (item.ValueKind == JsonValueKind.String)
            {
                values.Add(item.GetString() ?? string.Empty);
            }
        }

        return values;
    }
#endif

#if NET48
    private static bool TryGetValue(IDictionary<string, object> root, out object? value, string propertyName)
    {
        foreach (var pair in root)
        {
            if (string.Equals(pair.Key, propertyName, StringComparison.OrdinalIgnoreCase))
            {
                value = pair.Value;
                return true;
            }
        }

        value = null;
        return false;
    }
#else
    private static bool TryGetProperty(JsonElement root, out JsonElement value, string propertyName)
    {
        foreach (var property in root.EnumerateObject())
        {
            if (string.Equals(property.Name, propertyName, StringComparison.OrdinalIgnoreCase))
            {
                value = property.Value;
                return true;
            }
        }

        value = default;
        return false;
    }
#endif

    private static bool TryGetAttribute(SearchResultAttributeCollection attributes, string attributeName, out DirectoryAttribute value)
    {
        foreach (var key in attributes.AttributeNames)
        {
            if (key is string currentName && string.Equals(currentName, attributeName, StringComparison.OrdinalIgnoreCase))
            {
                var attribute = attributes[currentName];
                if (attribute is not null)
                {
                    value = attribute;
                    return true;
                }
            }
        }

        value = default!;
        return false;
    }

    private static string? ConvertAttributeValueToString(object value)
    {
        return value switch
        {
            string text => text,
            byte[] bytes => System.Text.Encoding.UTF8.GetString(bytes),
            _ => value.ToString(),
        };
    }

    private static string ExtractDomainFromDistinguishedName(string distinguishedName)
    {
        var labels = distinguishedName
            .Split(',')
            .Select(part => part.Trim())
            .Where(part => part.StartsWith("DC=", StringComparison.OrdinalIgnoreCase))
            .Select(part => part.Substring(3).Trim())
            .Where(part => !string.IsNullOrWhiteSpace(part))
            .ToArray();

        return labels.Length == 0 ? string.Empty : string.Join(".", labels);
    }

    private static string GetCurrentDomainDnsName()
    {
        var domainFqdn = IPGlobalProperties.GetIPGlobalProperties().DomainName;
        if (string.IsNullOrWhiteSpace(domainFqdn))
        {
            throw new InvalidOperationException("Current Active Directory domain could not be resolved.");
        }

        return domainFqdn.Trim();
    }
}