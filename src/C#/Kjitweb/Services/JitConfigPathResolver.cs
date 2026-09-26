// Author: Andreas Lucas (aka Kili)
// Documentation update: 0.2.20260926.6
// History: Completed API documentation; existing path resolution behavior is preserved.

namespace KjitWeb.Services;

/// <summary>Resolves the configured location of the just-in-time configuration file.</summary>
internal static class JitConfigPathResolver
{
    /// <summary>The application configuration key checked first.</summary>
    private const string ConfigKey = "ActiveDirectory:JitConfigPath";

    /// <summary>The fallback process environment variable.</summary>
    private const string EnvironmentVariableKey = "JustInTimeConfig";

    /// <summary>Resolves the JIT configuration path from configuration or the environment.</summary>
    /// <param name="configuration">The application configuration to inspect.</param>
    /// <returns>
    /// The configured value when it is not null, empty, or whitespace; otherwise, the environment
    /// variable value when nonblank; otherwise, <see langword="null"/>.
    /// </returns>
    /// <remarks>
    /// Values are returned verbatim and are not trimmed, normalized, made absolute, or checked for
    /// existence. The configuration value takes precedence. Reading the environment does not
    /// modify process state.
    /// </remarks>
    /// <exception cref="NullReferenceException">
    /// Thrown when <paramref name="configuration"/> is <see langword="null"/>.
    /// </exception>
    public static string? Resolve(IConfiguration configuration)
    {
        var configuredPath = configuration[ConfigKey];
        if (!string.IsNullOrWhiteSpace(configuredPath))
        {
            return configuredPath;
        }

        var environmentPath = Environment.GetEnvironmentVariable(EnvironmentVariableKey);
        return string.IsNullOrWhiteSpace(environmentPath) ? null : environmentPath;
    }
}