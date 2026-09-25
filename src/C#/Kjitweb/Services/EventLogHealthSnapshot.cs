namespace KjitWeb.Services;

/// <summary>
///     Severity levels reported by the event log health indicator shown on the KjitWeb website.
/// </summary>
public enum EventLogHealthLevel
{
    /// <summary>No qualifying Error or Warning entries were found within the look-back window.</summary>
    Ok,

    /// <summary>At least one qualifying Warning entry was found, but no Error entries.</summary>
    Warning,

    /// <summary>At least one qualifying Error entry was found.</summary>
    Error
}

/// <summary>
///     Represents the outcome of the most recent scan of the configured Windows Event Log for
///     Error and Warning entries within the monitored look-back window (last 24 hours).
/// </summary>
public sealed class EventLogHealthSnapshot
{
    /// <summary>The overall severity to display: Error takes precedence over Warning, which takes precedence over Ok.</summary>
    public EventLogHealthLevel Level { get; init; } = EventLogHealthLevel.Ok;

    /// <summary>The number of qualifying Error entries found within the look-back window.</summary>
    public int ErrorCount { get; init; }

    /// <summary>The number of qualifying Warning entries found within the look-back window.</summary>
    public int WarningCount { get; init; }

    /// <summary>The UTC timestamp of the last time the event log was scanned.</summary>
    public DateTime CheckedAtUtc { get; init; }
}
