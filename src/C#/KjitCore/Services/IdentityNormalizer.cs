/*
 * File: IdentityNormalizer.cs
 * Author: Andreas Lucas (aka Kili)
 *
 * Version history:
 * - 0.1.20260507: Initial identity-normalization implementation.
 * - 0.2.20260926.6: Added complete implementation documentation.
 */

using KjitCore.Abstractions;

namespace KjitCore.Services;

/// <summary>
/// Normalizes server identities expressed as plain, slash-delimited, or backslash-delimited names.
/// </summary>
public sealed class IdentityNormalizer : IIdentityNormalizer
{
    /// <inheritdoc />
    public string NormalizeServerName(string value, string? defaultDomain = null)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("A server name is required.", nameof(value));
        }

        var normalized = value.Trim();

        if (normalized.Contains('/'))
        {
            var segments = normalized
                .Split(new[] { '/' }, StringSplitOptions.RemoveEmptyEntries)
                .Select(s => s.Trim())
                .ToArray();
            if (segments.Length >= 2)
            {
                return string.IsNullOrWhiteSpace(defaultDomain)
                    ? segments[segments.Length - 1]
                    : $"{segments[segments.Length - 1]}.{defaultDomain}";
            }
        }

        if (normalized.Contains('\\'))
        {
            var split = normalized.Split(new[] { '\\' }, 2, StringSplitOptions.None);
            return split.Length > 1 ? split[1].Trim() : split[0].Trim();
        }

        return normalized;
    }
}
