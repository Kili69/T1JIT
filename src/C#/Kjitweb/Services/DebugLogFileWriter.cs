/*
 * File: DebugLogFileWriter.cs
 * Author: Andreas Lucas (aka Kili)
 *
 * Version history:
 * - 0.2.20260926.6: Added complete file-writer and rotation documentation.
 */

using System.Text;

namespace KjitWeb.Services;

/// <summary>
/// Appends diagnostic and connection records to a size-limited UTF-8 text file.
/// </summary>
/// <remarks>
/// Writes are serialized per writer instance. Before an entry would make the active file exceed
/// one MiB, the active file replaces the sibling <c>.sav</c> archive.
/// </remarks>
public sealed class DebugLogFileWriter
{
    /// <summary>The maximum size of an active log file and of a single stored entry.</summary>
    private const long MaxLogFileSizeBytes = 1 * 1024 * 1024;

    /// <summary>The suffix used when an oversized entry is shortened.</summary>
    private const string TruncatedEntryMarker = "... [log entry truncated]";

    /// <summary>The BOM-free UTF-8 encoding used for size calculations and persistence.</summary>
    private static readonly Encoding Utf8WithoutBom = new UTF8Encoding(encoderShouldEmitUTF8Identifier: false);

    /// <summary>Coordinates file access performed through this writer instance.</summary>
    private readonly object _syncRoot = new();

    /// <summary>The resolved path of the active diagnostic log.</summary>
    private readonly string _logFilePath;

    /// <summary>
    /// Initializes a new instance of the <see cref="DebugLogFileWriter"/> class.
    /// </summary>
    /// <param name="configuration">
    /// Application configuration used after the <c>DebugLog__Path</c> environment variable
    /// to resolve <c>DebugLog:Path</c>.
    /// </param>
    /// <remarks>
    /// Creates the containing directory when necessary and immediately writes an initialization
    /// record. If no configured path exists, the file defaults to
    /// <c>%APPDATA%\KjitWeb\debug.log</c>.
    /// </remarks>
    /// <exception cref="IOException">The directory or initialization record cannot be created.</exception>
    /// <exception cref="UnauthorizedAccessException">The process cannot access the resolved path.</exception>
    public DebugLogFileWriter(IConfiguration configuration)
    {
        _logFilePath = ResolveLogFilePath(configuration);
        EnsureDirectoryExists(_logFilePath);
        WriteLine($"{DateTimeOffset.Now:yyyy-MM-dd HH:mm:ss.fff zzz} | INFO | Debug log initialized. Path={_logFilePath}");
    }

    /// <summary>
    /// Gets the resolved path of the active diagnostic log file.
    /// </summary>
    public string LogFilePath => _logFilePath;

    /// <summary>
    /// Writes a structured diagnostic record and an optional exception.
    /// </summary>
    /// <param name="level">The severity included in the record.</param>
    /// <param name="category">The logger category included in the record.</param>
    /// <param name="message">The formatted message included in the record.</param>
    /// <param name="exception">
    /// The exception appended on a new line, or <see langword="null"/> when none is associated.
    /// </param>
    /// <remarks>The operation may truncate the entry or rotate the active file.</remarks>
    /// <exception cref="IOException">The log file cannot be written or rotated.</exception>
    /// <exception cref="UnauthorizedAccessException">The process cannot access the log path.</exception>
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

    /// <summary>
    /// Writes a connection audit record.
    /// </summary>
    /// <param name="userName">
    /// The connecting identity; <c>unknown-user</c> is written when it is null, empty, or whitespace.
    /// </param>
    /// <param name="remoteIp">
    /// The remote address; <c>unknown-ip</c> is written when it is null, empty, or whitespace.
    /// </param>
    /// <remarks>The operation may rotate the active file.</remarks>
    /// <exception cref="IOException">The log file cannot be written or rotated.</exception>
    /// <exception cref="UnauthorizedAccessException">The process cannot access the log path.</exception>
    public void WriteConnection(string? userName, string? remoteIp)
    {
        var resolvedUser = string.IsNullOrWhiteSpace(userName) ? "unknown-user" : userName;
        var resolvedRemoteIp = string.IsNullOrWhiteSpace(remoteIp) ? "unknown-ip" : remoteIp;
        WriteLine($"{DateTimeOffset.Now:yyyy-MM-dd HH:mm:ss.fff zzz} | CONNECTION | User={resolvedUser} | RemoteIp={resolvedRemoteIp}");
    }

    /// <summary>
    /// Appends one line while serializing access, enforcing the entry limit, and rotating as needed.
    /// </summary>
    /// <param name="line">The record text without its final platform newline.</param>
    /// <exception cref="IOException">The log file cannot be written or rotated.</exception>
    /// <exception cref="UnauthorizedAccessException">The process cannot access the log path.</exception>
    private void WriteLine(string line)
    {
        lock (_syncRoot)
        {
            var logEntry = LimitLogEntrySize(line);
            RotateLogIfRequired(_logFilePath, Utf8WithoutBom.GetByteCount(logEntry));
            File.AppendAllText(_logFilePath, logEntry, Utf8WithoutBom);
        }
    }

    /// <summary>
    /// Adds the platform newline and truncates an entry that would exceed the file-size limit.
    /// </summary>
    /// <param name="line">The entry text without its final newline.</param>
    /// <returns>
    /// A newline-terminated entry whose UTF-8 representation is no larger than
    /// <see cref="MaxLogFileSizeBytes"/>.
    /// </returns>
    private static string LimitLogEntrySize(string line)
    {
        var lineTerminator = Environment.NewLine;
        var completeEntry = line + lineTerminator;
        if (Utf8WithoutBom.GetByteCount(completeEntry) <= MaxLogFileSizeBytes)
        {
            return completeEntry;
        }

        var suffix = TruncatedEntryMarker + lineTerminator;
        var availableContentBytes = checked((int)MaxLogFileSizeBytes - Utf8WithoutBom.GetByteCount(suffix));
        var contentBuffer = new byte[availableContentBytes];
        Utf8WithoutBom.GetEncoder().Convert(
            line.AsSpan(),
            contentBuffer.AsSpan(),
            flush: true,
            out _,
            out var bytesUsed,
            out _);

        return Utf8WithoutBom.GetString(contentBuffer, 0, bytesUsed) + suffix;
    }

    /// <summary>
    /// Resolves the diagnostic log path according to the supported precedence rules.
    /// </summary>
    /// <param name="configuration">The configuration containing an optional <c>DebugLog:Path</c>.</param>
    /// <returns>
    /// The environment-variable path when present, then the configured path, or the default
    /// application-data path.
    /// </returns>
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

    /// <summary>
    /// Creates the parent directory of a log path when the path includes one.
    /// </summary>
    /// <param name="logFilePath">The active log file path.</param>
    /// <remarks>A path without a directory component causes no side effect.</remarks>
    /// <exception cref="IOException">The directory cannot be created.</exception>
    /// <exception cref="UnauthorizedAccessException">The process cannot create the directory.</exception>
    private static void EnsureDirectoryExists(string logFilePath)
    {
        var directoryPath = Path.GetDirectoryName(logFilePath);
        if (string.IsNullOrWhiteSpace(directoryPath))
        {
            return;
        }

        Directory.CreateDirectory(directoryPath);
    }

    /// <summary>
    /// Archives the active log when appending an entry would exceed the size limit.
    /// </summary>
    /// <param name="logFilePath">The active log file path.</param>
    /// <param name="incomingByteCount">The UTF-8 byte count of the entry to append.</param>
    /// <remarks>
    /// If rotation is required, an existing <c>.sav</c> file is deleted before the active log
    /// is moved to that archive path.
    /// </remarks>
    /// <exception cref="IOException">File inspection, deletion, or movement fails.</exception>
    /// <exception cref="UnauthorizedAccessException">The process cannot access either log file.</exception>
    private static void RotateLogIfRequired(string logFilePath, int incomingByteCount)
    {
        if (!File.Exists(logFilePath))
        {
            return;
        }

        var logFileInfo = new FileInfo(logFilePath);
        if (logFileInfo.Length + incomingByteCount <= MaxLogFileSizeBytes)
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