namespace KjitWeb.Services;

public sealed class ConnectionAuditLogger : IConnectionAuditLogger
{
    private readonly DebugLogFileWriter _writer;

    public ConnectionAuditLogger(DebugLogFileWriter writer)
    {
        _writer = writer;
    }

    public void LogConnection(string? userName, string? remoteIp)
    {
        _writer.WriteConnection(userName, remoteIp);
    }
}