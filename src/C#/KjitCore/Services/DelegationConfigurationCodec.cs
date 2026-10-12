using System.Collections;
using System.Globalization;
using KjitCore.Models;
#if NET48
using System.Web.Script.Serialization;
#else
using System.Text;
using System.Text.Json;
#endif

namespace KjitCore.Services;

/// <summary>Parses and serializes the canonical JIT delegation configuration schema.</summary>
internal static class DelegationConfigurationCodec
{
    internal static DelegationConfigurationObject Parse(string content)
    {
        if (string.IsNullOrWhiteSpace(content))
        {
            throw new InvalidOperationException("Delegation configuration must not be empty.");
        }

#if NET48
        var serializer = new JavaScriptSerializer();
        var root = serializer.DeserializeObject(content) as object[]
            ?? throw new InvalidOperationException(
                "Delegation configuration must contain a JSON array at the root.");
        var entries = root.Select(ParseEntry).ToList();
#else
        using var document = JsonDocument.Parse(content);
        if (document.RootElement.ValueKind != JsonValueKind.Array)
        {
            throw new InvalidOperationException(
                "Delegation configuration must contain a JSON array at the root.");
        }

        var entries = document.RootElement.EnumerateArray().Select(ParseEntry).ToList();
#endif
        return new DelegationConfigurationObject(entries);
    }

    internal static string Serialize(DelegationConfigurationObject configuration)
    {
        if (configuration is null)
        {
            throw new ArgumentNullException(nameof(configuration));
        }

#if NET48
        var values = configuration.Delegations
            .Select(entry => new Dictionary<string, object>
            {
                ["ComputerOU"] = entry.ComputerOU,
                ["ADObject"] = entry.ADObject.ToArray()
            })
            .ToArray();
        return new JavaScriptSerializer().Serialize(values);
#else
        using var stream = new MemoryStream();
        using (var writer = new Utf8JsonWriter(stream, new JsonWriterOptions { Indented = true }))
        {
            writer.WriteStartArray();
            foreach (var entry in configuration.Delegations)
            {
                writer.WriteStartObject();
                writer.WriteString("ComputerOU", entry.ComputerOU);
                writer.WritePropertyName("ADObject");
                writer.WriteStartArray();
                foreach (var securityIdentifier in entry.ADObject)
                {
                    writer.WriteStringValue(securityIdentifier);
                }

                writer.WriteEndArray();
                writer.WriteEndObject();
            }

            writer.WriteEndArray();
        }

        return Encoding.UTF8.GetString(stream.ToArray());
#endif
    }

    internal static string NormalizeComputerOU(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("ComputerOU must not be empty.", nameof(value));
        }

        return value.Trim();
    }

    internal static List<string> NormalizeSecurityIdentifiers(
        IEnumerable<string> securityIdentifiers)
    {
        if (securityIdentifiers is null)
        {
            throw new ArgumentNullException(nameof(securityIdentifiers));
        }

        var normalized = securityIdentifiers
            .Select(NormalizeSecurityIdentifier)
            .ToList();
        var duplicate = normalized
            .GroupBy(value => value, StringComparer.OrdinalIgnoreCase)
            .FirstOrDefault(group => group.Count() > 1);
        if (duplicate is not null)
        {
            throw new ArgumentException(
                $"Security identifier '{duplicate.Key}' appears more than once.",
                nameof(securityIdentifiers));
        }

        return normalized;
    }

    internal static string NormalizeSecurityIdentifier(string value)
    {
        var normalized = value?.Trim().ToUpperInvariant() ?? string.Empty;
        var parts = normalized.Split('-');
        var valid = parts.Length is >= 4 and <= 18
            && parts[0] == "S"
            && byte.TryParse(parts[1], NumberStyles.None, CultureInfo.InvariantCulture, out _)
            && ulong.TryParse(parts[2], NumberStyles.None, CultureInfo.InvariantCulture, out var authority)
            && authority <= 0xFFFFFFFFFFFF
            && parts.Skip(3).All(part =>
                uint.TryParse(part, NumberStyles.None, CultureInfo.InvariantCulture, out _));
        if (!valid)
        {
            throw new ArgumentException(
                $"'{value}' is not a valid security identifier.",
                nameof(value));
        }

        return normalized;
    }

#if NET48
    private static DelegationEntry ParseEntry(object value)
    {
        if (value is not IDictionary<string, object> entry
            || !TryGetValue(entry, "ComputerOU", out var computerOUValue)
            || computerOUValue is not string computerOU
            || !TryGetValue(entry, "ADObject", out var adObjectValue))
        {
            throw new InvalidOperationException(
                "Each delegation must contain ComputerOU and ADObject.");
        }

        return new DelegationEntry(computerOU, ReadSecurityIdentifiers(adObjectValue));
    }

    private static bool TryGetValue(
        IDictionary<string, object> values,
        string name,
        out object value)
    {
        var pair = values.FirstOrDefault(item =>
            item.Key.Equals(name, StringComparison.OrdinalIgnoreCase));
        value = pair.Value;
        return pair.Key is not null;
    }

    private static IEnumerable<string> ReadSecurityIdentifiers(object value)
    {
        if (value is string securityIdentifier)
        {
            return [securityIdentifier];
        }

        if (value is IEnumerable values)
        {
            return values.Cast<object>().Select(item => item as string
                ?? throw new InvalidOperationException(
                    "ADObject entries must be SID strings."));
        }

        throw new InvalidOperationException(
            "ADObject must be a SID string or an array of SID strings.");
    }
#else
    private static DelegationEntry ParseEntry(JsonElement element)
    {
        if (element.ValueKind != JsonValueKind.Object
            || !TryGetProperty(element, "ComputerOU", out var computerOUElement)
            || computerOUElement.ValueKind != JsonValueKind.String
            || !TryGetProperty(element, "ADObject", out var adObjectElement))
        {
            throw new InvalidOperationException(
                "Each delegation must contain ComputerOU and ADObject.");
        }

        return new DelegationEntry(
            computerOUElement.GetString() ?? string.Empty,
            ReadSecurityIdentifiers(adObjectElement));
    }

    private static IEnumerable<string> ReadSecurityIdentifiers(JsonElement element)
    {
        if (element.ValueKind == JsonValueKind.String)
        {
            return [element.GetString() ?? string.Empty];
        }

        if (element.ValueKind != JsonValueKind.Array)
        {
            throw new InvalidOperationException(
                "ADObject must be a SID string or an array of SID strings.");
        }

        return element.EnumerateArray().Select(item =>
            item.ValueKind == JsonValueKind.String
                ? item.GetString() ?? string.Empty
                : throw new InvalidOperationException(
                    "ADObject entries must be SID strings."));
    }

    private static bool TryGetProperty(
        JsonElement element,
        string name,
        out JsonElement value)
    {
        foreach (var property in element.EnumerateObject())
        {
            if (property.Name.Equals(name, StringComparison.OrdinalIgnoreCase))
            {
                value = property.Value;
                return true;
            }
        }

        value = default;
        return false;
    }
#endif
}