namespace KjitWeb.Services;

public interface IConnectionAuditLogger
{
    void LogConnection(string? userName, string? remoteIp);
}