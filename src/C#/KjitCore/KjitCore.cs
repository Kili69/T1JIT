using KjitCore.Abstractions;
using KjitCore.Models;
using KjitCore.Services;

namespace KjitCore;

public static class KjitCore
{
	public static IIdentityNormalizer Identity { get; } = new IdentityNormalizer();

	public static IDistinguishedNameService DistinguishedName { get; } = new DistinguishedNameService();

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

	private static bool IsUncPath(string value)
	{
		var normalized = value.Trim();
		
		// Check for UNC network path
		if (normalized.StartsWith("\\\\", StringComparison.Ordinal))
		{
			return true;
		}

		// Check for local absolute path (C:\, D:\, etc. or /... on non-Windows)
		if (Path.IsPathRooted(normalized))
		{
			return true;
		}

		// Check for URI-based UNC
		if (Uri.TryCreate(normalized, UriKind.Absolute, out var uri) && uri.IsUnc)
		{
			return true;
		}

		// Relative or AD CN only if it doesn't look like a file path
		return false;
	}
}
