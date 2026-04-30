using System.Text;

namespace KjitWeb.Services;

public sealed class DebugLogFileWriter
{
    private const long MaxLogFileSizeBytes = 1 * 1024 * 1024;
    private readonly object _syncRoot = new();
    private readonly string _logFilePath;

    public DebugLogFileWriter(IConfiguration configuration)
    {
        _logFilePath = ResolveLogFilePath(configuration);
        EnsureDirectoryExists(_logFilePath);
        RotateLogAtStartup(_logFilePath);
        WriteLine($"{DateTimeOffset.Now:yyyy-MM-dd HH:mm:ss.fff zzz} | INFO | Debug log initialized. Path={_logFilePath}");
    }

    public string LogFilePath => _logFilePath;

    public void WriteError(LogLevel level, string category, string message, Exception? exception)
    {
        var builder = new StringBuilder();
        builder.Append(DateTimeOffset.Now.ToString("yyyy-MM-dd HH:mm:ss.fff zzz"));
        builder.Append(" | ");
        builder.Append(level);
        builder.Append(" | ");
        builder.Append(category);
        builder.Append(" | ");
        builder.Append(message);

        if (exception != null)
        {
            builder.AppendLine();
            builder.Append(exception);
        }

        WriteLine(builder.ToString());
    }

    public void WriteConnection(string? userName, string? remoteIp)
    {
        var resolvedUser = string.IsNullOrWhiteSpace(userName) ? "unknown-user" : userName;
        var resolvedRemoteIp = string.IsNullOrWhiteSpace(remoteIp) ? "unknown-ip" : remoteIp;
        WriteLine($"{DateTimeOffset.Now:yyyy-MM-dd HH:mm:ss.fff zzz} | CONNECTION | User={resolvedUser} | RemoteIp={resolvedRemoteIp}");
    }

    private void WriteLine(string line)
    {
        lock (_syncRoot)
        {
            File.AppendAllText(_logFilePath, line + Environment.NewLine, Encoding.UTF8);
        }
    }

    private static string ResolveLogFilePath(IConfiguration configuration)
    {
        // First, try environment variable (set by service installer).
        var envVarPath = System.Environment.GetEnvironmentVariable("DebugLog__Path");
        if (!string.IsNullOrWhiteSpace(envVarPath))
        {
            return envVarPath;
        }

        // Then try configuration hierarchy (appsettings.json).
        var configuredPath = configuration["DebugLog:Path"];
        if (!string.IsNullOrWhiteSpace(configuredPath))
        {
            return configuredPath;
        }

        // Default: APPDATA
        var appDataPath = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
        return Path.Combine(appDataPath, "KjitWeb", "debug.log");
    }

    private static void EnsureDirectoryExists(string logFilePath)
    {
        var directoryPath = Path.GetDirectoryName(logFilePath);
        if (string.IsNullOrWhiteSpace(directoryPath))
        {
            return;
        }

        Directory.CreateDirectory(directoryPath);
    }

    private static void RotateLogAtStartup(string logFilePath)
    {
        if (!File.Exists(logFilePath))
        {
            return;
        }

        var logFileInfo = new FileInfo(logFilePath);
        if (logFileInfo.Length <= MaxLogFileSizeBytes)
        {
            return;
        }

        var archivePath = Path.ChangeExtension(logFilePath, ".sav");
        if (!string.IsNullOrWhiteSpace(archivePath) && File.Exists(archivePath))
        {
            File.Delete(archivePath);
        }

        if (!string.IsNullOrWhiteSpace(archivePath))
        {
            File.Move(logFilePath, archivePath, overwrite: false);
        }
    }
}