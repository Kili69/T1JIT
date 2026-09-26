/*
 * File: EventLogHealthSnapshot.cs
 * Author: Andreas Lucas (aka Kili)
 *
 * Version history:
 * - 0.2.20260926.6: Added complete health-level and snapshot documentation.
 */

namespace KjitWeb.Services;

/// <summary>
/// Defines the severity reported by the KjitWeb event-log health indicator.
/// </summary>
public enum EventLogHealthLevel
{
    /// <summary>No qualifying error or warning entries were found.</summary>
    Ok,

    /// <summary>At least one qualifying warning, but no qualifying error, was found.</summary>
    Warning,

    /// <summary>At least one qualifying error was found.</summary>
    Error
}

/// <summary>
/// Represents the outcome of a scan of the configured Windows Event Log.
/// </summary>
public sealed class EventLogHealthSnapshot
{
    /// <summary>
    /// Gets the overall severity.
    /// </summary>
    /// <value>
    /// <see cref="EventLogHealthLevel.Error"/> when errors exist; otherwise
    /// <see cref="EventLogHealthLevel.Warning"/> when warnings exist; otherwise
    /// <see cref="EventLogHealthLevel.Ok"/>.
    /// </value>
    public EventLogHealthLevel Level { get; init; } = EventLogHealthLevel.Ok;

    /// <summary>
    /// Gets the number of qualifying error entries found in the monitored window.
    /// </summary>
    public int ErrorCount { get; init; }

    /// <summary>
    /// Gets the number of qualifying warning entries found in the monitored window.
    /// </summary>
    public int WarningCount { get; init; }

    /// <summary>
    /// Gets the UTC time at which the scan completed.
    /// </summary>
    public DateTime CheckedAtUtc { get; init; }
}
