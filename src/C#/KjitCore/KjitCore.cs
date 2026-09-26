/*
 * File: KjitCore.cs
 * Author: Andreas Lucas (aka Kili)
 *
 * Version history:
 * - 0.1.20260507: Initial public facade for shared identity, distinguished-name,
 *   and JIT configuration services.
 * - 0.2.20260926.4: Documented the public API and configuration-source routing.
 */

using KjitCore.Abstractions;
using KjitCore.Models;
using KjitCore.Services;

namespace KjitCore;

/// <summary>
/// Provides the public entry point for shared Just-In-Time identity,
/// distinguished-name, and configuration services.
/// </summary>
/// <remarks>
/// The class exposes stateless service instances and selects the appropriate
/// configuration reader based on whether the supplied source is a file path or
/// an Active Directory object identifier.
/// </remarks>
public static class KjitCore
{
	/// <summary>
	/// Gets the service used to normalize user and group identities.
	/// </summary>
	/// <value>
	/// A shared <see cref="IIdentityNormalizer"/> instance.
	/// </value>
	public static IIdentityNormalizer Identity { get; } = new IdentityNormalizer();

	/// <summary>
	/// Gets the service used for distinguished-name operations.
	/// </summary>
	/// <value>
	/// A shared <see cref="IDistinguishedNameService"/> instance.
	/// </value>
	public static IDistinguishedNameService DistinguishedName { get; } = new DistinguishedNameService();

	/// <summary>
	/// Loads a JIT configuration from a file or Active Directory.
	/// </summary>
	/// <param name="source">
	/// An absolute local or UNC file path, an absolute UNC URI, an Active Directory
	/// common name, or a complete distinguished name.
	/// </param>
	/// <returns>
	/// The validated <see cref="JitConfigurationObject"/> loaded from the selected source.
	/// </returns>
	/// <exception cref="ArgumentException">
	/// Thrown when <paramref name="source"/> is null, empty, or whitespace, or when
	/// the loaded configuration contains an invalid value.
	/// </exception>
	/// <exception cref="FileNotFoundException">
	/// Thrown when <paramref name="source"/> is recognized as a file path but the file
	/// does not exist.
	/// </exception>
	/// <exception cref="InvalidOperationException">
	/// Thrown when the configuration file has an invalid root value or when the
	/// requested Active Directory configuration cannot be resolved unambiguously.
	/// </exception>
	/// <remarks>
	/// Absolute paths are read as JSON files. Other values are resolved through
	/// Active Directory as common names or distinguished names.
	/// </remarks>
	public static JitConfigurationObject LoadJitConfiguration(string source)
	{
		if (string.IsNullOrWhiteSpace(source))
		{
			throw new ArgumentException("A configuration source value is required.", nameof(source));
		}

		return IsUncPath(source)
			? JitConfigurationReader.LoadFromFile(source)
			: JitConfigurationReader.LoadFromActiveDirectory(source);
	}

	/// <summary>
	/// Determines whether a configuration source represents an absolute file location.
	/// </summary>
	/// <param name="value">The configuration source to classify.</param>
	/// <returns>
	/// <see langword="true"/> for UNC paths, rooted local paths, and absolute UNC URIs;
	/// otherwise, <see langword="false"/>.
	/// </returns>
	/// <remarks>
	/// A <see langword="false"/> result indicates that the caller should interpret the
	/// value as an Active Directory common name or distinguished name.
	/// </remarks>
	private static bool IsUncPath(string value)
	{
		var normalized = value.Trim();

		if (normalized.StartsWith("\\\\", StringComparison.Ordinal))
		{
			return true;
		}

		if (Path.IsPathRooted(normalized))
		{
			return true;
		}

		if (Uri.TryCreate(normalized, UriKind.Absolute, out var uri) && uri.IsUnc)
		{
			return true;
		}

		return false;
	}
}
