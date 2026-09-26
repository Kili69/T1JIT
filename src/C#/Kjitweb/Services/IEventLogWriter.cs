/*
 * File: IEventLogWriter.cs
 * Author: Andreas Lucas (aka Kili)
 *
 * Version history:
 * - 0.2.20260926.6: Added complete event-writing contract documentation.
 */

namespace KjitWeb.Services;

/// <summary>
/// Defines Windows Event Log output for Just-In-Time management requests.
/// </summary>
public interface IEventLogWriter
{
    /// <summary>
    /// Writes one informational management event describing an elevation request.
    /// </summary>
    /// <param name="userDistinguishedName">The distinguished name of the user receiving access.</param>
    /// <param name="serverName">The target server name.</param>
    /// <param name="serverDomain">The target server's domain.</param>
    /// <param name="elevationDurationMinutes">The requested elevation duration, in minutes.</param>
    /// <param name="callingUserUpn">The user principal name of the identity initiating the request.</param>
    /// <remarks>
    /// Implementations may create an event source as a side effect before writing the event.
    /// String arguments are expected to be non-null; implementations need not normalize them.
    /// </remarks>
    void WriteManagementEvent(string userDistinguishedName, string serverName, string serverDomain, int elevationDurationMinutes, string callingUserUpn);
}
