/*
 * File: JitConfigurationObject.cs
 * Author: Andreas Lucas (aka Kili)
 *
 * Version history:
 * - 0.1.20260507: Initial JIT configuration model.
 * - 0.2.20260907: Hardened configuration validation and compatibility aliases.
 * - 0.2.20260926: Fixed cross-target configuration compatibility.
 * - 0.2.20260926.6: Completed API, validation, null-behavior, and helper documentation.
 */

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
    /// <exception cref="InvalidOperationException">Thrown when the current DNS domain cannot be resolved.</exception>
    /// <exception cref="ArgumentException">Thrown when the resolved DNS domain is invalid.</exception>
    /// <remarks>Reads the current machine's network domain and derives default distinguished-name and UNC values.</remarks>
    public JitConfigurationObject()
    {
        AdminGroupOU = BuildDefaultAdminGroupOu();
        Domain = new[] { GetCurrentDomainDnsName() };
        DelegationConfigPath = BuildDefaultDelegationConfigPath();
    }

    /// <summary>
    /// Gets or sets the version string of the configuration schema or provisioning script.
    /// </summary>
    /// <value>The version string; the default is <c>0.1.0</c>. No validation is performed.</value>
    public string ConfigScriptVersion { get; set; } = "0.1.0";

    /// <summary>
    /// Gets or sets the prefix used when constructing administrative account or group names.
    /// </summary>
    /// <value>A trimmed SAM-compatible string of at most <see cref="MaximumSamAccountNameLength"/> characters.</value>
    /// <exception cref="ArgumentException">Thrown when the value is null, empty, or contains invalid characters or exceeds the maximum length.</exception>
    public string AdminPreFix
    {
        get => _adminPreFix;
        set => _adminPreFix = ValidateSamAccountName(value, MaximumSamAccountNameLength);
    }

    /// <summary>
    /// Gets or sets the character used to separate domain and object name segments inside generated SAM-compatible names.
    /// </summary>
    /// <value>A character accepted by the SAM-compatible name validator; the default is <c>#</c>.</value>
    /// <exception cref="ArgumentException">Thrown when the value is not a valid SAM account name character.</exception>
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
    /// <value>A trimmed distinguished name.</value>
    /// <exception cref="ArgumentException">Thrown when the value is null, empty, or not a valid distinguished name.</exception>
    public string AdminGroupOU
    {
        get => _adminGroupOu;
        set => _adminGroupOu = ValidateDistinguishedName(value);
    }

    /// <summary>
    /// Gets or sets the distinguished name of the organizational unit that stores JIT administrator groups.
    /// </summary>
    /// <value>The same value as <see cref="AdminGroupOU"/>.</value>
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
    /// <value>A trimmed absolute UNC path or URI.</value>
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
    /// <value>A value from 1 through <see cref="MaximumElevatedTime"/>; the default is 1440.</value>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when the value is not positive or exceeds <see cref="MaximumElevatedTime"/>.</exception>
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
    /// <value>A positive value less than the current <see cref="MaxElevatedTime"/>; the default is 60.</value>
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
    /// <value>Trimmed, nonblank text; the default is <c>Tier 1 Management</c>.</value>
    /// <exception cref="ArgumentException">Thrown when the value is null, empty, or whitespace.</exception>
    public string EventLog
    {
        get => _eventLog;
        set => _eventLog = ValidateRequiredText(value, nameof(EventLog));
    }

    /// <summary>
    /// Gets or sets the event source used for JIT-related event log entries.
    /// </summary>
    /// <value>Trimmed, nonblank text; the default is <c>T1Mgmt</c>.</value>
    /// <exception cref="ArgumentException">Thrown when the value is null, empty, or whitespace.</exception>
    public string EventSource
    {
        get => _eventSource;
        set => _eventSource = ValidateRequiredText(value, nameof(EventSource));
    }

    /// <summary>
    /// Gets or sets the directory used for PowerShell debug log files.
    /// Environment variables are expanded by the consuming process at runtime.
    /// </summary>
    /// <value>The unvalidated path text; the default is <c>%TEMP%</c>.</value>
    public string DebugLogPath { get; set; } = "%TEMP%";

    /// <summary>
    /// Gets or sets a value indicating whether delegation support is enabled.
    /// </summary>
    /// <value><see langword="true"/> by default.</value>
    public bool EnableDelegation
    {
        get => _enableDelegation;
        set => _enableDelegation = value;
    }

    /// <summary>
    /// Gets or sets the event identifier used for elevation operations.
    /// </summary>
    /// <value>A positive event identifier; the default is 100.</value>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when the value is zero or negative.</exception>
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
    /// <value><see langword="true"/> by default.</value>
    /// <remarks>
    /// When enabled, the solution can operate across multiple Active Directory domains. 
    /// When disabled, it operates only within the current domain.
    /// The default value is <c>true</c>.
    /// </remarks>
    public bool EnableMultiDomainSupport { get; set; } = true;

    /// <summary>
    /// Gets or sets a value indicating whether the <c>managedBy</c> attribute may be used for delegation decisions.
    /// </summary>
    /// <value><see langword="true"/> by default.</value>
    /// <remarks>
    /// If the value is <c>true</c>, the solution may use the <c>managedBy</c> attribute of computer objects to determine delegation eligibility.
    /// If the value is <c>false</c>, the solution will ignore the <c>managedBy</c> attribute and rely solely on group membership for delegation decisions.
    /// The default value is <c>true</c>.
    /// </remarks>
    public bool UseManagedByforDelegation { get; set; } = true;

    /// <summary>
    /// Gets or sets the maximum number of servers processed concurrently.
    /// </summary>
    /// <value>A value from 1 through <see cref="MaximumConcurrentServer"/>; the default is 50.</value>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when the value is less than 1 or greater than <see cref="MaximumConcurrentServer"/>.</exception>
    /// <remarks>
    /// The <see cref="MaxConcurrentServer"/> default value is 50.
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
    /// <value>A value from 5 through <see cref="MaximumGroupManagementTaskRerun"/>; the default is 5.</value>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when the value is outside the supported range.</exception>
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
    /// <value>A trimmed SAM-compatible name; the default is <c>KjitGmsa</c>.</value>
    /// <exception cref="ArgumentException">Thrown when the value is blank or contains unsupported characters.</exception>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when the value exceeds the supported length.</exception>
    public string GroupManagedServiceAccountName
    {
        get => _groupManagedServiceAccountName;
        set => _groupManagedServiceAccountName = ValidateSamAccountName(value);
    }

    /// <summary>
    /// Gets or sets the Active Directory identity of a server group that is excluded from delegation.
    /// The value may be a simple group name or a distinguished name.
    /// </summary>
    /// <value>Trimmed text, or an empty string when assigned null, empty, or whitespace.</value>
    public string ExcludeServerGroupName
    {
        get => _excludeServerGroupName;
        set => _excludeServerGroupName = string.IsNullOrWhiteSpace(value) ? string.Empty : value.Trim();
    }

    /// <summary>
    /// Gets or sets the Active Directory identity of a server group that is excluded from delegation.
    /// </summary>
    /// <value>The same value as <see cref="ExcludeServerGroupName"/>.</value>
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
    /// <value>A trimmed, parenthesized LDAP filter.</value>
    /// <exception cref="ArgumentException">Thrown when the value is null, blank, or not parenthesized.</exception>
    public string LDAPexcludeComputer
    {
        get => _ldapExcludeComputer;
        set => _ldapExcludeComputer = ValidateLdapFilter(value, nameof(LDAPexcludeComputer));
    }
    /// <summary>
    /// Gets or sets the LDAP filter used to search for eligible computer objects.
    /// </summary>
    /// <value>The same value as <see cref="LDAPexcludeComputer"/>.</value>
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
    /// <value>A normalized, duplicate-free list; null is normalized to an empty list.</value>
    /// <exception cref="ArgumentException">Thrown when a SID is invalid or duplicated.</exception>
    public IReadOnlyList<string> AuthorizedServer
    {
        get => _authorizedServer;
        set => _authorizedServer = ValidateDistinctSidValues(value, nameof(AuthorizedServer));
    }

    /// <summary>
    /// Gets or sets the list of organizational units that are part of the JIT scope.
    /// </summary>
    /// <value>A normalized, duplicate-free distinguished-name list; null is normalized to an empty list.</value>
    /// <exception cref="ArgumentException">Thrown when a distinguished name is invalid or duplicated.</exception>
    public IReadOnlyList<string> TargetOU
    {
        get => _targetOU;
        set => _targetOU = ValidateDistinctDistinguishedNames(value);
    }

    /// <summary>
    /// Gets or sets the organizational-unit search bases through the legacy property name.
    /// </summary>
    /// <value>The same validated list exposed by <see cref="TargetOU"/>.</value>
    /// <remarks>This compatibility alias delegates directly to <see cref="TargetOU"/>.</remarks>
    public IReadOnlyList<string> T1Searchbase
    {
        get => TargetOU;
        set => TargetOU = value;
    }

    /// <summary>
    /// Gets or sets the list of organizational units that are excluded from computer processing.
    /// </summary>
    /// <value>A normalized, duplicate-free distinguished-name list; null is normalized to an empty list.</value>
    /// <exception cref="ArgumentException">Thrown when a distinguished name is invalid or duplicated.</exception>
    public IReadOnlyList<string> ExcludeComputerOU
    {
        get => _excludeComputerOu;
        set => _excludeComputerOu = ValidateDistinctDistinguishedNames(value);
    }

    /// <summary>
    /// Gets or sets the list of DNS domains that belong to the JIT configuration.
    /// </summary>
    /// <value>A normalized, duplicate-free DNS-name list; null is normalized to an empty list.</value>
    /// <exception cref="ArgumentException">Thrown when a DNS name is invalid or duplicated.</exception>
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
    /// <remarks>Replaces the stored list with a new list containing the appended normalized value.</remarks>
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
    /// <remarks>Replaces the stored list with a new list containing the appended normalized value.</remarks>
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
    /// <exception cref="ArgumentException">Thrown when <paramref name="distinguishedName"/> is blank or invalid.</exception>
    /// <remarks>Replaces the stored list with a new list even when no match is found.</remarks>
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
    /// <exception cref="ArgumentException">Thrown when <paramref name="distinguishedName"/> is blank or invalid.</exception>
    /// <remarks>Replaces the stored list with a new list even when no match is found.</remarks>
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
    /// <value>A trimmed, parenthesized LDAP filter.</value>
    /// <exception cref="ArgumentException">Thrown when the value is null, blank, or not parenthesized.</exception>
    public string ComputerSearch
    {
        get => _computerSearch;
        set => _computerSearch = ValidateLdapFilter(value, nameof(ComputerSearch));
    }

    /// <summary>
    /// Gets or sets the LDAP filter used to search for eligible computer objects.
    /// </summary>
    /// <value>The same value as <see cref="ComputerSearch"/>.</value>
    /// <remarks>
    /// This attribute is deprecated and will be removed in future versions. Use <see cref="ComputerSearch"/> instead.
    /// </remarks>
    public string LDAPT1Computers{
        get => ComputerSearch;
        set => ComputerSearch = value;
    }
    /// <summary>
    /// Trims and validates a distinguished name.
    /// </summary>
    /// <param name="value">The distinguished name to validate.</param>
    /// <returns>The trimmed distinguished name.</returns>
    /// <exception cref="ArgumentException">Thrown when the value is null, empty, whitespace, or does not match the supported distinguished-name form.</exception>
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

    /// <summary>
    /// Validates and case-insensitively deduplicates distinguished names.
    /// </summary>
    /// <param name="values">The values to validate, or null.</param>
    /// <returns>A new normalized list, or an empty list for null or empty input.</returns>
    /// <exception cref="ArgumentException">Thrown when an item is invalid or duplicated.</exception>
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

    /// <summary>
    /// Validates and case-insensitively deduplicates DNS names.
    /// </summary>
    /// <param name="values">The values to validate, or null.</param>
    /// <param name="propertyName">The property name associated with validation failures.</param>
    /// <returns>A new normalized list, or an empty list for null or empty input.</returns>
    /// <exception cref="ArgumentException">Thrown when an item is invalid or duplicated.</exception>
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

    /// <summary>
    /// Validates, uppercases, and case-insensitively deduplicates SID strings.
    /// </summary>
    /// <param name="values">The values to validate, or null.</param>
    /// <param name="propertyName">The property name associated with validation failures.</param>
    /// <returns>A new normalized list, or an empty list for null or empty input.</returns>
    /// <exception cref="ArgumentException">Thrown when an item is invalid or duplicated.</exception>
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

    /// <summary>
    /// Trims and validates a dotted DNS name.
    /// </summary>
    /// <param name="value">The DNS name to validate.</param>
    /// <param name="propertyName">The property name associated with validation failures.</param>
    /// <returns>The trimmed DNS name.</returns>
    /// <exception cref="ArgumentException">Thrown when the value is null, blank, or invalid.</exception>
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

    /// <summary>
    /// Trims, validates, and uppercases a security identifier.
    /// </summary>
    /// <param name="value">The SID string to validate.</param>
    /// <param name="propertyName">The property name associated with validation failures.</param>
    /// <returns>The normalized uppercase SID.</returns>
    /// <exception cref="ArgumentException">Thrown when the value is null, blank, or invalid.</exception>
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

    /// <summary>
    /// Trims and validates the outer form of an LDAP filter.
    /// </summary>
    /// <param name="value">The filter to validate.</param>
    /// <param name="propertyName">The property name associated with validation failures.</param>
    /// <returns>The trimmed parenthesized filter.</returns>
    /// <exception cref="ArgumentException">Thrown when the value is null, blank, or not enclosed in parentheses.</exception>
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

    /// <summary>
    /// Trims and validates an absolute UNC URI or path.
    /// </summary>
    /// <param name="value">The path to validate.</param>
    /// <param name="propertyName">The property name associated with validation failures.</param>
    /// <returns>The trimmed UNC value.</returns>
    /// <exception cref="ArgumentException">Thrown when the value is null, blank, or not recognized as UNC.</exception>
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

    /// <summary>
    /// Requires and trims a text value.
    /// </summary>
    /// <param name="value">The text to validate.</param>
    /// <param name="propertyName">The property name associated with validation failures.</param>
    /// <returns>The trimmed nonempty text.</returns>
    /// <exception cref="ArgumentException">Thrown when the value is null, empty, or whitespace.</exception>
    private static string ValidateRequiredText(string value, string propertyName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("A text value is required.", propertyName);
        }

        return value.Trim();
    }

    /// <summary>
    /// Trims and validates text against the supported SAM account-name restrictions.
    /// </summary>
    /// <param name="value">The value to validate.</param>
    /// <param name="maximumLength">The positive maximum accepted length.</param>
    /// <returns>The trimmed validated value.</returns>
    /// <exception cref="ArgumentException">Thrown when the value is blank, contains a forbidden or control character, or ends in a period.</exception>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when <paramref name="maximumLength"/> is not positive or the value is too long.</exception>
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
