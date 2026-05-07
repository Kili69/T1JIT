using System.Text.RegularExpressions;
using KjitCore.Abstractions;

namespace KjitCore.Services;

public sealed class DistinguishedNameService : IDistinguishedNameService
{
    private static readonly Regex DomainComponentRegex =
        new("dc=([^,]+)", RegexOptions.IgnoreCase | RegexOptions.Compiled);

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
