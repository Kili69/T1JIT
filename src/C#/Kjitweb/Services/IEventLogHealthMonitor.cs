/*
 * File: IEventLogHealthMonitor.cs
 * Author: Andreas Lucas (aka Kili)
 *
 * Version history:
 * - 0.2.20260926.6: Added complete contract and snapshot documentation.
 */

namespace KjitWeb.Services;

/// <summary>
/// Exposes the most recently computed event-log health state.
/// </summary>
/// <remarks>
/// Consumers read the cached snapshot without querying the Windows Event Log on the request path.
/// </remarks>
public interface IEventLogHealthMonitor
{
    /// <summary>
    /// Gets the health snapshot produced by the latest completed background scan.
    /// </summary>
    /// <value>A non-null immutable snapshot reference.</value>
    EventLogHealthSnapshot Current { get; }
}
