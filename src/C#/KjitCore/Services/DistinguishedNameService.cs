/*
 * File: DistinguishedNameService.cs
 * Author: Andreas Lucas (aka Kili)
 *
 * Version history:
 * - 0.1.20260507: Initial distinguished-name conversion implementation.
 * - 0.2.20260926.6: Added complete implementation documentation.
 */

using System.Text.RegularExpressions;
using KjitCore.Abstractions;

namespace KjitCore.Services;

/// <summary>
/// Extracts DNS domain names from Active Directory distinguished names.
/// </summary>
public sealed class DistinguishedNameService : IDistinguishedNameService
{
    /// <summary>
    /// Matches domain-component values without regard to the casing of the <c>DC</c> prefix.
    /// </summary>
    private static readonly Regex DomainComponentRegex =
        new("dc=([^,]+)", RegexOptions.IgnoreCase | RegexOptions.Compiled);

    /// <inheritdoc />
    public string? ConvertDomainDnToDnsName(string distinguishedName)
    {
        if (string.IsNullOrWhiteSpace(distinguishedName))
        {
            return null;
        }

        var matches = DomainComponentRegex.Matches(distinguishedName);
        if (matches.Count == 0)
        {
            return null;
        }

        var labels = new List<string>(matches.Count);
        foreach (Match match in matches)
        {
            labels.Add(match.Groups[1].Value);
        }

        return string.Join(".", labels);
    }
}
