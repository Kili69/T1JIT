/*
 * File: IIdentityNormalizer.cs
 * Author: Andreas Lucas (aka Kili)
 *
 * Version history:
 * - 0.1.20260507: Initial identity-normalization contract.
 * - 0.2.20260926.6: Added complete API documentation.
 */

namespace KjitCore.Abstractions;

/// <summary>
/// Defines normalization of server identity strings used by the JIT components.
/// </summary>
public interface IIdentityNormalizer
{
    /// <summary>
    /// Normalizes a server identity to a host name or domain-qualified host name.
    /// </summary>
    /// <param name="value">The server identity to normalize.</param>
    /// <param name="defaultDomain">
    /// The optional DNS suffix appended to the final segment of slash-delimited identities.
    /// It is ignored for backslash-delimited and unqualified values.
    /// </param>
    /// <returns>
    /// The trimmed value; for a slash-delimited value, its final nonempty segment, optionally
    /// followed by <paramref name="defaultDomain"/>; or for a backslash-delimited value, the
    /// trimmed portion after the first backslash.
    /// </returns>
    /// <exception cref="ArgumentException">
    /// Thrown when <paramref name="value"/> is null, empty, or whitespace.
    /// </exception>
    string NormalizeServerName(string value, string? defaultDomain = null);
}
