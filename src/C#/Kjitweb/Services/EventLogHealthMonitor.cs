using System.Diagnostics;

namespace KjitWeb.Services;

/// <summary>
///     Periodically scans the configured Windows Event Log (the "Tier 1 Management" log by default)
///     for Error and Warning entries written within the last 24 hours, so that the website can show a
///     symbolized health indicator next to the version number. The scan is refreshed every 5 minutes by
///     a background timer rather than on every page request, keeping event log I/O off the request path.
/// </summary>
/// <remarks>
///     Event IDs 2003 (elevation duration capped to the configured maximum) and 2009 (user exceeded
///     MaxConcurrentServer) are expected, routine Warning-level events raised by ElevateUser.ps1 during
///     normal operation. They are intentionally excluded from the health indicator so that these
///     non-actionable warnings do not trigger it.
/// </remarks>
public sealed class EventLogHealthMonitor : BackgroundService, IEventLogHealthMonitor
{
    private static readonly TimeSpan RefreshInterval = TimeSpan.FromMinutes(5);
    private static readonly TimeSpan LookBackWindow = TimeSpan.FromHours(24);
    private static readonly HashSet<int> IgnoredEventIds = new() { 2003, 2009 };

    private readonly string _logName;
    private readonly ILogger<EventLogHealthMonitor> _logger;
    private EventLogHealthSnapshot _current = new() { CheckedAtUtc = DateTime.MinValue };

    public EventLogHealthMonitor(IConfiguration configuration, ILogger<EventLogHealthMonitor> logger)
    {
        _logger = logger;
        var jitConfigPath = JitConfigPathResolver.Resolve(configuration);
        var jitConfig = string.IsNullOrWhiteSpace(jitConfigPath)
            ? new JitConfiguration()
            : new JitConfiguration(jitConfigPath);
        _logName = jitConfig.EventLogName;
    }

    /// <inheritdoc />
    public EventLogHealthSnapshot Current => Volatile.Read(ref _current);

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
