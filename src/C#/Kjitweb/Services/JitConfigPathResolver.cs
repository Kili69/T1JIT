namespace KjitWeb.Services;

internal static class JitConfigPathResolver
{
    private const string ConfigKey = "ActiveDirectory:JitConfigPath";
    private const string EnvironmentVariableKey = "JustInTimeConfig";

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