// Author: Andreas Lucas (aka Kili)
// Documentation update: 0.2.20260926.6
// History: Completed API documentation; existing audit behavior is preserved.

namespace KjitWeb.Services;

/// <summary>
/// Records connection audit events through a <see cref="DebugLogFileWriter"/>.
/// </summary>
/// <remarks>
/// This class performs no normalization or redaction; it forwards nullable user and address
/// values to the writer, which determines the destination, formatting, and I/O behavior.
/// </remarks>
public sealed class ConnectionAuditLogger : IConnectionAuditLogger
{
    /// <summary>The writer that persists connection audit events.</summary>
    private readonly DebugLogFileWriter _writer;

    /// <summary>Initializes a new instance of the <see cref="ConnectionAuditLogger"/> class.</summary>
    /// <param name="writer">The writer to which connection events are delegated.</param>
    /// <remarks>The argument is stored without an explicit null check.</remarks>
    public ConnectionAuditLogger(DebugLogFileWriter writer)
    {
        _writer = writer;
    }

    /// <inheritdoc />
    public void LogConnection(string? userName, string? remoteIp)
    {
        _writer.WriteConnection(userName, remoteIp);
    }
}