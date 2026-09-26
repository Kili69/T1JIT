/*
 * File: EventLogHealthMonitor.cs
 * Author: Andreas Lucas (aka Kili)
 *
 * Version history:
 * - 0.2.20260926.6: Added complete monitor, lifecycle, and scan documentation.
 */

using System.Diagnostics;

namespace KjitWeb.Services;

/// <summary>
/// Periodically scans the configured Windows Event Log and publishes a cached health snapshot.
/// </summary>
/// <remarks>
/// The monitor scans the previous 24 hours every five minutes. Event IDs 2003 (duration capped)
/// and 2009 (concurrent-server limit reached) are expected warnings and are excluded.
/// </remarks>
public sealed class EventLogHealthMonitor : BackgroundService, IEventLogHealthMonitor
{
    /// <summary>The delay between completed scan attempts.</summary>
    private static readonly TimeSpan RefreshInterval = TimeSpan.FromMinutes(5);

    /// <summary>The age range included in each scan.</summary>
    private static readonly TimeSpan LookBackWindow = TimeSpan.FromHours(24);

    /// <summary>The routine warning event identifiers excluded from health counts.</summary>
    private static readonly HashSet<int> IgnoredEventIds = new() { 2003, 2009 };

    /// <summary>The configured Windows Event Log name.</summary>
    private readonly string _logName;

    /// <summary>The logger used to report scan failures.</summary>
    private readonly ILogger<EventLogHealthMonitor> _logger;

    /// <summary>The latest snapshot, accessed atomically through <see cref="Volatile"/>.</summary>
    private EventLogHealthSnapshot _current = new() { CheckedAtUtc = DateTime.MinValue };

    /// <summary>
    /// Initializes a new instance of the <see cref="EventLogHealthMonitor"/> class.
    /// </summary>
    /// <param name="configuration">
    /// Application configuration used to resolve the JIT configuration file.
    /// </param>
    /// <param name="logger">The logger that receives non-fatal scan failures.</param>
    /// <remarks>
    /// Loads the configured event-log name immediately. When no explicit JIT configuration path
    /// exists, the default <see cref="JitConfiguration"/> source is used.
    /// </remarks>
    /// <exception cref="ArgumentException">The resolved JIT configuration path is invalid.</exception>
    /// <exception cref="IOException">The JIT configuration file cannot be read.</exception>
    public EventLogHealthMonitor(IConfiguration configuration, ILogger<EventLogHealthMonitor> logger)
    {
        _logger = logger;
        var jitConfigPath = JitConfigPathResolver.Resolve(configuration);
        var jitConfig = string.IsNullOrWhiteSpace(jitConfigPath)
            ? new JitConfiguration()
            : new JitConfiguration(jitConfigPath);
        _logName = jitConfig.EventLogName;
    }

    /// <inheritdoc/>
    /// <remarks>The returned reference is read atomically and is never <see langword="null"/>.</remarks>
    public EventLogHealthSnapshot Current => Volatile.Read(ref _current);

    /// <summary>
    /// Runs scans until host shutdown is requested.
    /// </summary>
    /// <param name="stoppingToken">The token signaled when the hosted service must stop.</param>
    /// <returns>A task that completes after cancellation ends the monitoring loop.</returns>
    /// <remarks>
    /// A scan runs immediately, then after each refresh interval. Cancellation during the delay
    /// is treated as normal shutdown and is not propagated.
    /// </remarks>
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            RefreshStatus();

            try
            {
                await Task.Delay(RefreshInterval, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                // Expected when the host is shutting down; the loop condition will exit next iteration.
            }
        }
    }

    /// <summary>
    /// Scans recent entries and atomically replaces the cached health snapshot.
    /// </summary>
    /// <remarks>
    /// Entries are traversed newest-first until the look-back cutoff. On any read failure, the
    /// method logs a warning and publishes an <see cref="EventLogHealthLevel.Ok"/> snapshot so the
    /// background service and website remain available.
    /// </remarks>
    private void RefreshStatus()
    {
        try
        {
            var cutoff = DateTime.Now - LookBackWindow;
            var errorCount = 0;
            var warningCount = 0;

            using var eventLog = new EventLog(_logName);
            var entries = eventLog.Entries;
            // The event log is append-only, so entries are stored in chronological order. Scanning
            // backwards from the newest entry and stopping once we reach one older than the look-back
            // window avoids a full scan of potentially large logs.
            for (var i = entries.Count - 1; i >= 0; i--)
            {
                var entry = entries[i];
                if (entry.TimeGenerated < cutoff)
                {
                    break;
                }

                // EventLogEntry.InstanceId encodes severity/facility bits in the upper 16 bits; the
                // event ID originally passed to EventLog.WriteEntry is stored in the lower 16 bits.
                var eventId = (int)(entry.InstanceId & 0xFFFF);
                if (IgnoredEventIds.Contains(eventId))
                {
                    continue;
                }

                switch (entry.EntryType)
                {
                    case EventLogEntryType.Error:
                        errorCount++;
                        break;
                    case EventLogEntryType.Warning:
                        warningCount++;
                        break;
                }
            }

            var level = errorCount > 0
                ? EventLogHealthLevel.Error
                : warningCount > 0
                    ? EventLogHealthLevel.Warning
                    : EventLogHealthLevel.Ok;

            Volatile.Write(ref _current, new EventLogHealthSnapshot
            {
                Level = level,
                ErrorCount = errorCount,
                WarningCount = warningCount,
                CheckedAtUtc = DateTime.UtcNow
            });
        }
        catch (Exception ex)
        {
            // Reading the event log can fail (log missing, insufficient permissions, etc.). We log the
            // failure but keep the application running; the health indicator simply reports "Ok" in
            // that case rather than causing the site to malfunction.
            _logger.LogWarning(ex, "Failed to scan the '{LogName}' event log for the health indicator.", _logName);
            Volatile.Write(ref _current, new EventLogHealthSnapshot { Level = EventLogHealthLevel.Ok, CheckedAtUtc = DateTime.UtcNow });
        }
    }
}
