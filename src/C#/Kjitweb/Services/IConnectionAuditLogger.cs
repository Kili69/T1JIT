// Author: Andreas Lucas (aka Kili)
// Documentation update: 0.2.20260926.6
// History: Completed API contract documentation; existing behavior is preserved.

namespace KjitWeb.Services;

/// <summary>Defines a sink for recording incoming connection audit events.</summary>
public interface IConnectionAuditLogger
{
    /// <summary>Records a connection associated with an optional identity and remote address.</summary>
    /// <param name="userName">
    /// The connected user's name, or <see langword="null"/> when no identity is available.
    /// Implementations determine whether and how this potentially sensitive value is persisted.
    /// </param>
    /// <param name="remoteIp">
    /// The remote IP address text, or <see langword="null"/> when it is unavailable.
    /// Implementations determine whether and how this value is persisted.
    /// </param>
    /// <remarks>Implementations may perform I/O and may propagate failures from their audit sink.</remarks>
    void LogConnection(string? userName, string? remoteIp);
}