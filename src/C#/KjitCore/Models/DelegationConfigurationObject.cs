namespace KjitCore.Models;

using global::KjitCore.Services;

/// <summary>Represents one organizational-unit delegation and its security identifiers.</summary>
public sealed class DelegationEntry
{
    private readonly List<string> _securityIdentifiers;

    /// <summary>Initializes a delegation entry.</summary>
    /// <param name="computerOU">The delegated organizational-unit distinguished name.</param>
    /// <param name="securityIdentifiers">The user and group security identifiers.</param>
    public DelegationEntry(string computerOU, IEnumerable<string> securityIdentifiers)
    {
        ComputerOU = DelegationConfigurationCodec.NormalizeComputerOU(computerOU);
        _securityIdentifiers = DelegationConfigurationCodec.NormalizeSecurityIdentifiers(
            securityIdentifiers);
    }

    /// <summary>Gets the delegated organizational-unit distinguished name.</summary>
    public string ComputerOU { get; }

    /// <summary>Gets the normalized user and group security identifiers.</summary>
    public IReadOnlyList<string> ADObject => _securityIdentifiers;

    internal bool AddSecurityIdentifier(string securityIdentifier)
    {
        var normalized = DelegationConfigurationCodec.NormalizeSecurityIdentifier(
            securityIdentifier);
        if (_securityIdentifiers.Contains(normalized, StringComparer.OrdinalIgnoreCase))
        {
            return false;
        }

        _securityIdentifiers.Add(normalized);
        return true;
    }

    internal bool RemoveSecurityIdentifier(string securityIdentifier)
    {
        var normalized = DelegationConfigurationCodec.NormalizeSecurityIdentifier(
            securityIdentifier);
        return _securityIdentifiers.RemoveAll(value =>
            value.Equals(normalized, StringComparison.OrdinalIgnoreCase)) > 0;
    }
}

/// <summary>Represents a complete delegation configuration document.</summary>
public sealed class DelegationConfigurationObject
{
    private readonly List<DelegationEntry> _delegations;

    /// <summary>Initializes an empty delegation configuration.</summary>
    public DelegationConfigurationObject()
        : this(Array.Empty<DelegationEntry>())
    {
    }

    /// <summary>Initializes a delegation configuration from validated entries.</summary>
    /// <param name="delegations">The delegation entries to include.</param>
    public DelegationConfigurationObject(IEnumerable<DelegationEntry> delegations)
    {
        if (delegations is null)
        {
            throw new ArgumentNullException(nameof(delegations));
        }

        _delegations = delegations.ToList();

        var duplicate = _delegations
            .GroupBy(entry => entry.ComputerOU, StringComparer.OrdinalIgnoreCase)
            .FirstOrDefault(group => group.Count() > 1);
        if (duplicate is not null)
        {
            throw new ArgumentException(
                $"ComputerOU '{duplicate.Key}' appears more than once.",
                nameof(delegations));
        }
    }

    /// <summary>Gets the delegation entries in document order.</summary>
    public IReadOnlyList<DelegationEntry> Delegations => _delegations;

    /// <summary>Adds a security identifier to a new or existing OU delegation.</summary>
    /// <param name="computerOU">The organizational-unit distinguished name.</param>
    /// <param name="securityIdentifier">The user or group security identifier.</param>
    /// <returns><see langword="true"/> when the document changed; otherwise <see langword="false"/>.</returns>
    public bool AddDelegation(string computerOU, string securityIdentifier)
    {
        var normalizedOU = DelegationConfigurationCodec.NormalizeComputerOU(computerOU);
        var existing = _delegations.FirstOrDefault(entry =>
            entry.ComputerOU.Equals(normalizedOU, StringComparison.OrdinalIgnoreCase));
        if (existing is not null)
        {
            return existing.AddSecurityIdentifier(securityIdentifier);
        }

        _delegations.Add(new DelegationEntry(normalizedOU, [securityIdentifier]));
        return true;
    }

    /// <summary>Removes a complete OU delegation.</summary>
    /// <param name="computerOU">The organizational-unit distinguished name.</param>
    /// <returns><see langword="true"/> when an entry was removed; otherwise <see langword="false"/>.</returns>
    public bool RemoveDelegation(string computerOU)
    {
        var normalizedOU = DelegationConfigurationCodec.NormalizeComputerOU(computerOU);
        return _delegations.RemoveAll(entry =>
            entry.ComputerOU.Equals(normalizedOU, StringComparison.OrdinalIgnoreCase)) > 0;
    }

    /// <summary>Removes one security identifier from an OU delegation.</summary>
    /// <param name="computerOU">The organizational-unit distinguished name.</param>
    /// <param name="securityIdentifier">The user or group security identifier.</param>
    /// <returns><see langword="true"/> when an identifier was removed; otherwise <see langword="false"/>.</returns>
    public bool RemoveDelegation(string computerOU, string securityIdentifier)
    {
        var normalizedOU = DelegationConfigurationCodec.NormalizeComputerOU(computerOU);
        var existing = _delegations.FirstOrDefault(entry =>
            entry.ComputerOU.Equals(normalizedOU, StringComparison.OrdinalIgnoreCase));
        return existing?.RemoveSecurityIdentifier(securityIdentifier) == true;
    }
}