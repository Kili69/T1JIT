using System.Net.NetworkInformation;
using System.Text.RegularExpressions;

namespace KjitCore.Models;

/// <summary>
/// Represents the Just-In-Time configuration used by PowerShell and native .NET components.
/// </summary>
/// <remarks>
/// The model centralizes default values, validation rules, and helper operations for distinguished names,
/// DNS names, UNC paths, LDAP filters, SAM-compatible names, and SID-based allow lists.
/// </remarks>
public sealed class JitConfigurationObject
{
    /// <summary>
    /// Defines the highest allowed value for <see cref="MaxElevatedTime"/> in minutes.
    /// </summary>
    public const int MaximumElevatedTime = 2880;

    /// <summary>
    /// Defines the maximum allowed length for SAM-compatible names, including <see cref="AdminPreFix"/>.
    /// </summary>
    public const int MaximumSamAccountNameLength = 20;

    private const int DefaultSamAccountNameLength = 256;

    /// <summary>
    /// Defines the highest allowed value for <see cref="MaxConcurrentServer"/>.
    /// </summary>
    public const int MaximumConcurrentServer = 1000;

    /// <summary>
    /// Defines the highest allowed value for <see cref="GroupManagementTaskRerun"/> in minutes.
    /// </summary>
    public const int MaximumGroupManagementTaskRerun = 60;

    /// <summary>
    /// Gets the regular expression used to validate distinguished names.
    /// </summary>
    private static readonly Regex DistinguishedNameRegex =
        new("^[A-Za-z]+=[^,]+(,[A-Za-z]+=[^,]+)*$", RegexOptions.Compiled);

    /// <summary>
    /// Gets the regular expression used to validate LDAP search strings.   
    /// </summary>
    private static readonly Regex LdapFilterRegex =
        new("^\\(.+\\)$", RegexOptions.Compiled);

    /// <summary>
    /// Gets the regular expression used to validate DNS names.
    /// </summary>
    private static readonly Regex DnsNameRegex =
        new("^(?=.{1,253}$)(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-)\\.)+(?!-)[A-Za-z0-9-]{1,63}(?<!-)$", RegexOptions.Compiled);

    /// <summary>
    /// Gets the regular expression used to validate Security Identifiers (SIDs).
    /// </summary>
    private static readonly Regex SidRegex =
        new("^S-1-(?:0|[1-9][0-9]*)(?:-(?:0|[1-9][0-9]*))+$", RegexOptions.Compiled | RegexOptions.IgnoreCase);

    /// <summary>
    /// Gets the array of characters that are invalid in SAM account names.
    /// </summary>
    private static readonly char[] InvalidSamAccountNameChars =
    {
        '"',
        '/',
        '\\',
        '[',
        ']',
        ':',
        ';',
        '|',
        '=',
        ',',
        '+',
        '*',
        '?',
        '<',
        '>'
    };

    /// <summary>
    /// Gets or sets the maximum elevation duration in minutes. The default value is 1440 (24 hours).
    /// </summary>
    private int _maxElevatedTime = 1440;
    /// <summary>
    /// Gets or sets the default elevation duration in minutes. The default value is 60 (1 hour).
    /// </summary>
    private int _defaultElevatedTime = 60;
    /// <summary>
    /// Gets or sets the interval in minutes to elevate a new server. The default value is 5 minutes.
    /// </summary>
    private int _groupManagementTaskRerun = 5;
    /// <summary>
    /// Gets or sets the maximum number of servers processed concurrently. The default value is 50.
    /// </summary>
    private int _maxConcurrentServer = 50;
    /// <summary>
    /// Gets or sets the SAM-compatible name of the group managed service account used by the solution.
    /// </summary>
    private string _groupManagedServiceAccountName = "KjitGmsa";
    /// <summary>
    /// Gets or sets the event log name used for JIT-related entries.
    /// </summary>
    private string _eventLog = "Tier 1 Management";
    /// <summary>
    /// Gets or sets the event source used for JIT-related event log entries.
    /// </summary>
    private string _eventSource = "T1Mgmt";
    /// <summary>
    /// Gets or sets a value indicating whether delegation support is enabled.
    /// </summary>
    private bool _enableDelegation = true;
    /// <summary>
    /// Gets or sets the event identifier used for elevation operations.
    /// </summary>
    private int _elevateEventId = 100;
    /// <summary>
    /// Gets or sets the character used to separate domain and object name segments inside generated SAM-compatible names.
    /// </summary>
    private char _domainSeparator = '#';
    /// <summary>
    /// Gets or sets the prefix of the JIT server group.
    /// </summary>
    private string _adminPreFix = "Admin_";
    /// <summary>
    /// Is a list of distinguished name of  organizational unit that stores JIT administrator groups.
    /// </summary>
    private string _adminGroupOu = string.Empty;
    /// <summary>
    /// Is the UNC path to the delegation configuration file.
    /// </summary>
    private string _delegationConfigPath = string.Empty;
    /// <summary>
    /// Is the distinguished name of a server group that is excluded from delegation.
    /// </summary>
    private string _excludeServerGroupName = string.Empty;
    /// <summary>
    /// Is the LDAP filter used to exclude computer objects from processing.
    /// </summary>
    /// <remarks>
    /// This filter is used to avoid including critical computers like domain controllers.
    /// </remarks>
    private string _ldapExcludeComputer = "(&(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))";
    /// <summary>
    /// Is a list of SIDs from authorized servers.
    /// </summary>
    private IReadOnlyList<string> _authorizedServer = Array.Empty<string>();
    /// <summary> 
    ///     Is a list of organizational units that are part of the JIT scope.
    /// </summary>  
    private IReadOnlyList<string> _targetOU = Array.Empty<string>();
    /// <summary>
    /// Is a list of organizational units that are excluded from computer processing.
    /// </summary>
    private IReadOnlyList<string> _excludeComputerOu = Array.Empty<string>();
    /// <summary>
    /// Is a list of DNS domains that belong to the JIT configuration.
    /// </summary>
    private IReadOnlyList<string> _domain = Array.Empty<string>();
    /// <summary> Is the LDAP filter used to search for eligible computer objects.
    /// </summary>
    private string _computerSearch = "(&(OperatingSystem=*Windows*)(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))";

    /// <summary>
    /// Initializes a new instance of the <see cref="JitConfigurationObject"/> class with defaults derived from the current Active Directory domain.
    /// </summary>
    public JitConfigurationObject()
    {
        AdminGroupOU = BuildDefaultAdminGroupOu();
        Domain = new[] { GetCurrentDomainDnsName() };
        DelegationConfigPath = BuildDefaultDelegationConfigPath();
    }

    /// <summary>
    /// Gets or sets the version string of the configuration schema or provisioning script.
    /// </summary>
    public string ConfigScriptVersion { get; set; } = "0.1.0";

    /// <summary>
    /// Gets or sets the prefix used when constructing administrative account or group names.
    /// </summary>
    /// <exception cref="ArgumentException">Thrown when the value is null, empty, or contains invalid characters or exceeds the maximum length.</exception>
    public string AdminPreFix
    {
        get => _adminPreFix;
        set => _adminPreFix = ValidateSamAccountName(value, MaximumSamAccountNameLength);
    }

    /// <summary>
    /// Gets or sets the character used to separate domain and object name segments inside generated SAM-compatible names.
    /// </summary>
    /// <exception cref="ArgumentException">Thrown when the value is not a valid SAM account name character.</exception>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when the value exceeds the maximum length for SAM account names.</exception>
    /// <remarks>
    /// The <see cref="DomainSeparator"/> is used to construct JIT compatibel group names in the format of <c>{AdminPreFix}{Domain}{DomainSeparator}{ServerName}</c>.
    /// </remarks>
    public char DomainSeparator
    {
        get => _domainSeparator;
        set => _domainSeparator = ValidateSamAccountNameCharacter(value);
    }

    /// <summary>
    /// Gets or sets the distinguished name of the organizational unit that stores JIT administrator groups.
    /// </summary>
    /// <exception cref="ArgumentException">Thrown when the value is null, empty, or not a valid distinguished name.</exception>
    public string AdminGroupOU
    {
        get => _adminGroupOu;
        set => _adminGroupOu = ValidateDistinguishedName(value);
    }

    /// <summary>
    /// Gets or sets the distinguished name of the organizational unit that stores JIT administrator groups.
    /// </summary>
    /// <remarks>
    /// This property is deprecated and will be removed in future versions. Use <see cref="AdminGroupOU"/> instead.
    /// </remarks>
    public string OU{
        get => AdminGroupOU;
        set => AdminGroupOU = value;
    }

    /// <summary>
    /// Gets or sets the UNC path to the delegation configuration file.
    /// </summary>
    /// <exception cref="ArgumentException">Thrown when the value is null, empty, or not a valid UNC path.</exception>
    /// <remarks>
    /// This attribute is only used if the json configuration is used
    /// </remarks>
    public string DelegationConfigPath
    {
        get => _delegationConfigPath;
        set => _delegationConfigPath = ValidateUncPath(value, nameof(DelegationConfigPath));
    }

    /// <summary>
    /// Gets or sets the maximum elevation duration in minutes.
    /// </summary>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when the value is not a positive integer, exceeds <see cref="MaximumElevatedTime"/>, or is less than or equal to <see cref="DefaultElevatedTime"/>.</exception>
    /// <remarks>
    /// The <see cref="MaxElevatedTime"/> default value is 1440 minutes (24 hours).
    /// </remarks>
    public int MaxElevatedTime
    {
        get => _maxElevatedTime;
        set
        {
            if (value <= 0)
            {
                throw new ArgumentOutOfRangeException(nameof(MaxElevatedTime), "MaxElevatedTime must be a positive integer.");
            }

            if (value > MaximumElevatedTime)
            {
                throw new ArgumentOutOfRangeException(nameof(MaxElevatedTime), $"MaxElevatedTime must not be greater than {MaximumElevatedTime}.");
            }
            _maxElevatedTime = value;
        }
    }

    /// <summary>
    /// Gets or sets the default elevation duration in minutes.
    /// </summary>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when the value is not a positive integer or is greater than or equal to <see cref="MaxElevatedTime"/>.</exception>
    /// <remarks>
    /// The <see cref="DefaultElevatedTime"/> default value is 60 minutes (1 hour).
    /// </remarks>
    public int DefaultElevatedTime
    {
        get => _defaultElevatedTime;
        set
        {
            if (value <= 0)
            {
                throw new ArgumentOutOfRangeException(nameof(DefaultElevatedTime), "DefaultElevatedTime must be a positive integer.");
            }

            if (value >= _maxElevatedTime)
            {
                throw new ArgumentOutOfRangeException(nameof(DefaultElevatedTime), "DefaultElevatedTime must be smaller than MaxElevatedTime.");
            }

            _defaultElevatedTime = value;
        }
    }

    /// <summary>
    /// Gets or sets the event log name used for JIT-related entries.
    /// </summary>
    public string EventLog
    {
        get => _eventLog;
        set => _eventLog = ValidateRequiredText(value, nameof(EventLog));
    }

    /// <summary>
    /// Gets or sets the event source used for JIT-related event log entries.
    /// </summary>
    public string EventSource
    {
        get => _eventSource;
        set => _eventSource = ValidateRequiredText(value, nameof(EventSource));
    }

    /// <summary>
    /// Gets or sets a value indicating whether delegation support is enabled.
    /// </summary>
    public bool EnableDelegation
    {
        get => _enableDelegation;
        set => _enableDelegation = value;
    }

    /// <summary>
    /// Gets or sets the event identifier used for elevation operations.
    /// </summary>
    public int ElevateEventID
    {
        get => _elevateEventId;
        set
        {
            if (value <= 0)
            {
                throw new ArgumentOutOfRangeException(nameof(ElevateEventID), "ElevateEventID must be a positive integer.");
            }

            _elevateEventId = value;
        }
    }

    /// <summary>
    /// Gets or sets a value indicating whether multi-domain operation is enabled.
    /// </summary>
    /// <remarks>
    /// When enabled, the solution can operate across multiple Active Directory domains. 
    /// When disabled, it operates only within the current domain.
    /// The default value is <c>true</c>.
    /// </remarks>
    public bool EnableMultiDomainSupport { get; set; } = true;

    /// <summary>
    /// Gets or sets a value indicating whether the <c>managedBy</c> attribute may be used for delegation decisions.
    /// </summary>
    /// <remarks>
    /// If the value is <c>true</c>, the solution may use the <c>managedBy</c> attribute of computer objects to determine delegation eligibility.
    /// If the value is <c>false</c>, the solution will ignore the <c>managedBy</c> attribute and rely solely on group membership for delegation decisions.
    /// The default value is <c>true</c>.
    /// </remarks>
    public bool UseManagedByforDelegation { get; set; } = true;

    /// <summary>
    /// Gets or sets the maximum number of servers processed concurrently.
    /// </summary>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when the value is less than 1 or greater than <see cref="MaximumConcurrentServer"/>.</exception>
    /// <remarks>
    /// The <see cref="MaxConcurrentServer"/> default value is 10.
    /// </remarks>
    public int MaxConcurrentServer
    {
        get => _maxConcurrentServer;
        set
        {
            if (value < 1 || value > MaximumConcurrentServer)
            {
                throw new ArgumentOutOfRangeException(nameof(MaxConcurrentServer), $"MaxConcurrentServer must be between 1 and {MaximumConcurrentServer}.");
            }

            _maxConcurrentServer = value;
        }
    }

    /// <summary>
    /// Gets or sets the interval in minutes after which the group management task should run again.
    /// </summary>
    public int GroupManagementTaskRerun
    {
        get => _groupManagementTaskRerun;
        set
        {
            if (value < 5 || value > MaximumGroupManagementTaskRerun)
            {
                throw new ArgumentOutOfRangeException(nameof(GroupManagementTaskRerun), $"GroupManagementTaskRerun must be between 5 and {MaximumGroupManagementTaskRerun}.");
            }

            _groupManagementTaskRerun = value;
        }
    }

    /// <summary>
    /// Gets or sets the SAM-compatible name of the group managed service account used by the solution.
    /// </summary>
    public string GroupManagedServiceAccountName
    {
        get => _groupManagedServiceAccountName;
        set => _groupManagedServiceAccountName = ValidateSamAccountName(value);
    }

    /// <summary>
    /// Gets or sets the distinguished name of a server group that is excluded from delegation.
    /// </summary>
    public string ExcludeServerGroupName
    {
        get => _excludeServerGroupName;
        set => _excludeServerGroupName = ValidateOptionalDistinguishedName(value);
    }

    /// <summary>
    /// Gets or sets the distinguished name of a server group that is excluded from delegation.
    /// </summary>
    /// <remarks>
    /// This property is deprecated and will be removed in future versions. Use <see cref="ExcludeServerGroupName"/> instead.   
    /// </remarks>
    public string Tier0ServerGroupName
    {
        get => ExcludeServerGroupName;
        set => ExcludeServerGroupName = value;
    }
    /// <summary>
    /// Gets or sets the LDAP filter used to exclude computer objects from processing.
    /// </summary>
    public string LDAPexcludeComputer
    {
        get => _ldapExcludeComputer;
        set => _ldapExcludeComputer = ValidateLdapFilter(value, nameof(LDAPexcludeComputer));
    }
    /// <summary>
    /// Gets or sets the LDAP filter used to search for eligible computer objects.
    /// </summary>
    /// <remarks>
    /// This attribute is deprecated and will be removed in future versions. Use <see cref="LDAPexcludeComputer"/> instead.
    /// </remarks>
    public string LDAPT0Computers
    {
        get => LDAPexcludeComputer;
        set => LDAPexcludeComputer = value;
    }
    /// <summary>
    /// Gets or sets the list of authorized server SIDs.
    /// </summary>
    public IReadOnlyList<string> AuthorizedServer
    {
        get => _authorizedServer;
        set => _authorizedServer = ValidateDistinctSidValues(value, nameof(AuthorizedServer));
    }

    /// <summary>
    /// Gets or sets the list of organizational units that are part of the JIT scope.
    /// </summary>
    public IReadOnlyList<string> TargetOU
    {
        get => _targetOU;
        set => _targetOU = ValidateDistinctDistinguishedNames(value);
    }

    public IReadOnlyList<string> T1Searchbase
    {
        get => TargetOU;
        set => TargetOU = value;
    }

    /// <summary>
    /// Gets or sets the list of organizational units that are excluded from computer processing.
    /// </summary>
    public IReadOnlyList<string> ExcludeComputerOU
    {
        get => _excludeComputerOu;
        set => _excludeComputerOu = ValidateDistinctDistinguishedNames(value);
    }

    /// <summary>
    /// Gets or sets the list of DNS domains that belong to the JIT configuration.
    /// </summary>
    public IReadOnlyList<string> Domain
    {
        get => _domain;
        set => _domain = ValidateDistinctDnsNames(value, nameof(Domain));
    }

    /// <summary>
    /// Adds a distinguished name to the excluded computer OU list.
    /// </summary>
    /// <param name="distinguishedName">The distinguished name to add.</param>
    /// <exception cref="ArgumentException">Thrown when the value is invalid or already exists.</exception>
    public void AddExcludeComputerOU(string distinguishedName)
    {
        var normalized = ValidateDistinguishedName(distinguishedName);
        if (_excludeComputerOu.Any(existing => string.Equals(existing, normalized, StringComparison.OrdinalIgnoreCase)))
        {
            throw new ArgumentException("Duplicate distinguished names are not allowed.");
        }

        var updated = _excludeComputerOu.ToList();
        updated.Add(normalized);
        _excludeComputerOu = updated;
    }

    /// <summary>
    /// Adds a distinguished name to the OU list.
    /// </summary>
    /// <param name="distinguishedName">The distinguished name to add.</param>
    /// <exception cref="ArgumentException">Thrown when the value is invalid or already exists.</exception>
    public void AddOU(string distinguishedName)
    {
        var normalized = ValidateDistinguishedName(distinguishedName);
        if (_targetOU.Any(existing => string.Equals(existing, normalized, StringComparison.OrdinalIgnoreCase)))
        {
            throw new ArgumentException("Duplicate distinguished names are not allowed.");
        }

        var updated = _targetOU.ToList();
        updated.Add(normalized);
        _targetOU = updated;
    }

    /// <summary>
    /// Removes a distinguished name from the excluded computer OU list.
    /// </summary>
    /// <param name="distinguishedName">The distinguished name to remove.</param>
    /// <returns><see langword="true"/> when the value was removed; otherwise, <see langword="false"/>.</returns>
    public bool RemoveExcludeComputerOU(string distinguishedName)
    {
        var normalized = ValidateDistinguishedName(distinguishedName);
        var updated = _excludeComputerOu.ToList();
        var removed = updated.RemoveAll(existing => string.Equals(existing, normalized, StringComparison.OrdinalIgnoreCase)) > 0;
        _excludeComputerOu = updated;
        return removed;
    }

    /// <summary>
    /// Removes a distinguished name from the OU list.
    /// </summary>
    /// <param name="distinguishedName">The distinguished name to remove.</param>
    /// <returns><see langword="true"/> when the value was removed; otherwise, <see langword="false"/>.</returns>
    public bool RemoveOU(string distinguishedName)
    {
        var normalized = ValidateDistinguishedName(distinguishedName);
        var updated = _targetOU.ToList();
        var removed = updated.RemoveAll(existing => string.Equals(existing, normalized, StringComparison.OrdinalIgnoreCase)) > 0;
        _targetOU = updated;
        return removed;
    }

    /// <summary>
    /// Gets or sets the LDAP filter used to search for eligible computer objects.
    /// </summary>
    public string ComputerSearch
    {
        get => _computerSearch;
        set => _computerSearch = ValidateLdapFilter(value, nameof(ComputerSearch));
    }

    /// <summary>
    /// Gets or sets the LDAP filter used to search for eligible computer objects.
    /// </summary>
    /// <remarks>
    /// This attribute is deprecated and will be removed in future versions. Use <see cref="ComputerSearch"/> instead.
    /// </remarks>
    public string LDAPT1Computers{
        get => ComputerSearch;
        set => ComputerSearch = value;
    }
    private static string ValidateDistinguishedName(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("A distinguished name value is required.");
        }

        var normalized = value.Trim();
        if (!DistinguishedNameRegex.IsMatch(normalized))
        {
            throw new ArgumentException("The value is not a valid distinguished name.");
        }

        return normalized;
    }

    private static string ValidateOptionalDistinguishedName(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        return ValidateDistinguishedName(value);
    }

    private static IReadOnlyList<string> ValidateDistinctDistinguishedNames(IReadOnlyList<string>? values)
    {
        if (values is null || values.Count == 0)
        {
            return Array.Empty<string>();
        }

        var uniqueValues = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var normalizedValues = new List<string>(values.Count);

        foreach (var value in values)
        {
            var normalized = ValidateDistinguishedName(value);
            if (!uniqueValues.Add(normalized))
            {
                throw new ArgumentException("Duplicate distinguished names are not allowed.");
            }

            normalizedValues.Add(normalized);
        }

        return normalizedValues;
    }

    private static IReadOnlyList<string> ValidateDistinctDnsNames(IReadOnlyList<string>? values, string propertyName)
    {
        if (values is null || values.Count == 0)
        {
            return Array.Empty<string>();
        }

        var uniqueValues = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var normalizedValues = new List<string>(values.Count);

        foreach (var value in values)
        {
            var normalized = ValidateDnsName(value, propertyName);
            if (!uniqueValues.Add(normalized))
            {
                throw new ArgumentException("Duplicate DNS names are not allowed.", propertyName);
            }

            normalizedValues.Add(normalized);
        }

        return normalizedValues;
    }

    private static IReadOnlyList<string> ValidateDistinctSidValues(IReadOnlyList<string>? values, string propertyName)
    {
        if (values is null || values.Count == 0)
        {
            return Array.Empty<string>();
        }

        var uniqueValues = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var normalizedValues = new List<string>(values.Count);

        foreach (var value in values)
        {
            var normalized = ValidateSid(value, propertyName);
            if (!uniqueValues.Add(normalized))
            {
                throw new ArgumentException("Duplicate SID values are not allowed.", propertyName);
            }

            normalizedValues.Add(normalized);
        }

        return normalizedValues;
    }

    private static string ValidateDnsName(string value, string propertyName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("A DNS name value is required.", propertyName);
        }

        var normalized = value.Trim();
        if (!DnsNameRegex.IsMatch(normalized))
        {
            throw new ArgumentException("The value is not a valid DNS name.", propertyName);
        }

        return normalized;
    }

    private static string ValidateSid(string value, string propertyName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("A SID value is required.", propertyName);
        }

        var normalized = value.Trim();
        if (!SidRegex.IsMatch(normalized))
        {
            throw new ArgumentException("The value is not a valid SID.", propertyName);
        }

        return normalized.ToUpperInvariant();
    }

    private static string ValidateLdapFilter(string value, string propertyName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("An LDAP filter string is required.", propertyName);
        }

        var normalized = value.Trim();
        if (!LdapFilterRegex.IsMatch(normalized))
        {
            throw new ArgumentException("The value is not a valid LDAP search string.", propertyName);
        }

        return normalized;
    }

    private static string ValidateUncPath(string value, string propertyName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("A UNC path value is required.", propertyName);
        }

        var normalized = value.Trim();
        if (!Uri.TryCreate(normalized, UriKind.Absolute, out var uri) || !uri.IsUnc)
        {
            throw new ArgumentException("The value is not a valid UNC path.", propertyName);
        }

        return normalized;
    }

    private static string ValidateRequiredText(string value, string propertyName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("A text value is required.", propertyName);
        }

        return value.Trim();
    }

    private static string ValidateSamAccountName(string value, int maximumLength = DefaultSamAccountNameLength)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("A SAMAccountName value is required.");
        }

        if (maximumLength <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(maximumLength), "Maximum length must be greater than 0.");
        }

        var normalized = value.Trim();
        if (normalized.Length > maximumLength)
        {
            throw new ArgumentOutOfRangeException($"Value must not be longer than {maximumLength} characters.");
        }

        if (normalized.IndexOfAny(InvalidSamAccountNameChars) >= 0)
        {
            throw new ArgumentException("Value contains characters that are not valid for SAMAccountName.");
        }

        if (normalized.EndsWith(".", StringComparison.Ordinal))
        {
            throw new ArgumentException("Value must not end with a period.");
        }

        foreach (var c in normalized)
        {
            if (char.IsControl(c))
            {
                throw new ArgumentException("Value contains control characters that are not valid for SAMAccountName.");
            }
        }

        return normalized;
    }

    /// <summary>
    /// Validates a single character for use in SAM account names.
    /// </summary>
    /// <param name="value">The character to validate.</param>
    /// <returns>The validated character.</returns>
    private static char ValidateSamAccountNameCharacter(char value)
    {
        var normalized = ValidateSamAccountName(value.ToString());
        return normalized[0];
    }

    /// <summary>
    /// Builds the default distinguished name for the JIT administrator groups organizational unit based on the current Active Directory domain.
    /// </summary>
    /// <returns>The default distinguished name for the JIT administrator groups organizational unit.</returns>
    private static string BuildDefaultAdminGroupOu()
    {
        var domainDn = GetCurrentDomainDistinguishedName();
        return $"OU=JIT-Administrator Groups,OU=Tier 1,OU=Admin,{domainDn}";
    }

    /// <summary>
    /// Builds the default UNC path for the delegation configuration file based on the current Active Directory domain.
    /// </summary>
    /// <returns>The default UNC path for the delegation configuration file.</returns>
    private static string BuildDefaultDelegationConfigPath()
    {
        var domainDnsName = GetCurrentDomainDnsName();
        return $@"\\{domainDnsName}\SYSVOL\{domainDnsName}\Just-In-Time\JITdelegation.config";
    }

    /// <summary>
    /// Gets the distinguished name of the current Active Directory domain based on the DNS name.   
    /// </summary>
    /// <returns>The distinguished name of the current Active Directory domain.</returns>
    private static string GetCurrentDomainDistinguishedName()
    {
        var domainFqdn = GetCurrentDomainDnsName(); // Get the current domain's DNS name
        var labels = domainFqdn.Split(new[] { '.' }, StringSplitOptions.RemoveEmptyEntries); // Split the DNS name into its labels

        var dcParts = new string[labels.Length];    // Initialize an array to hold the DC components
        for (var i = 0; i < labels.Length; i++)
        {
            dcParts[i] = $"DC={labels[i].Trim()}"; // Construct each DC component by prefixing with "DC=" and trimming whitespace
        }

        return string.Join(",", dcParts);
    }

    /// <summary>
    /// Gets the DNS name of the current Active Directory domain.
    /// </summary>
    /// <returns>The DNS name of the current Active Directory domain.</returns>
    private static string GetCurrentDomainDnsName()
    {
        var domainFqdn = IPGlobalProperties.GetIPGlobalProperties().DomainName;
        if (string.IsNullOrWhiteSpace(domainFqdn))
        {
            throw new InvalidOperationException("Current Active Directory domain could not be resolved.");
        }

        return ValidateDnsName(domainFqdn, nameof(Domain));
    }
}
