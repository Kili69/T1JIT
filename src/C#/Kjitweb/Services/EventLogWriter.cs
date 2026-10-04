/*
 * File: EventLogWriter.cs
 * Author: Andreas Lucas (aka Kili)
 *
 * Version history:
 * - 0.2.20260926.6: Added complete event-writer and side-effect documentation.
 */

using System.Diagnostics;
using System.Text.Json;

namespace KjitWeb.Services;

/// <summary>
/// Writes structured Just-In-Time elevation requests to the Windows Event Log.
/// </summary>
/// <remarks>
/// The destination log, event source, administrative prefix, and domain separator are loaded
/// from the JIT configuration during construction. The writer creates the configured source
/// on first use when it does not already exist.
/// </remarks>
public class EventLogWriter : IEventLogWriter
{
    /// <summary>The event identifier assigned to management requests.</summary>
    private const int ManagementEventId = 100;

    /// <summary>The Windows Event Log that owns a newly created source.</summary>
    private readonly string _logName;

    /// <summary>The source under which management events are written.</summary>
    private readonly string _eventSource;

    /// <summary>The prefix used to construct the target server-group name.</summary>
    private readonly string _adminPreFix;

    /// <summary>The separator inserted between the server domain and name.</summary>
    private readonly string _domainSeparator;

    /// <summary>Whether target group names include the server DNS domain.</summary>
    private readonly bool _enableMultiDomainSupport;

    /// <summary>
    /// Initializes a new instance of the <see cref="EventLogWriter"/> class.
    /// </summary>
    /// <param name="configuration">
    /// Application configuration used to resolve the JIT configuration path.
    /// </param>
    /// <remarks>
    /// When no explicit JIT configuration path is available, the default
    /// <see cref="JitConfiguration"/> source is loaded.
    /// </remarks>
    /// <exception cref="ArgumentException">The resolved JIT configuration path is invalid.</exception>
    /// <exception cref="IOException">The JIT configuration file cannot be read.</exception>
    /// <exception cref="JsonException">The JIT configuration file contains invalid JSON.</exception>
    public EventLogWriter(IConfiguration configuration)
    {
        var jitConfigPath = JitConfigPathResolver.Resolve(configuration);
        var jitConfig = string.IsNullOrWhiteSpace(jitConfigPath)
            ? new JitConfiguration()
            : new JitConfiguration(jitConfigPath);
        _logName = jitConfig.EventLogName; // We set the log name for the event log based on the JIT configuration, which will be used when writing events to specify which log to write to in the Windows Event Log.
        _eventSource = jitConfig.EventLogSourceName; // We set the event source name for the event log based on the JIT configuration, which will be used when writing events to specify the source of the events in the Windows Event Log. This allows for better organization and identification of events in the logs, as administrators can filter and analyze events based on their source.
        _adminPreFix = jitConfig.AdminPreFix; // We set the admin prefix based on the JIT configuration, which will be used when constructing the server group name in the event messages. This allows for consistent formatting of server group names in the event log, making it easier to identify and analyze events related to specific servers or domains.
        _domainSeparator = jitConfig.DomainSeparator; // We set the domain separator based on the JIT configuration, which will be used when constructing the server group name in the event messages. This allows for consistent formatting of server group names in the event log, making it easier to identify and analyze events related to specific servers or domains.
        _enableMultiDomainSupport = jitConfig.EnableMultiDomainSupport;
    }

    /// <summary>
    /// Writes an informational event containing a JSON elevation-request payload.
    /// </summary>
    /// <param name="userDistinguishedName">The distinguished name of the user receiving access.</param>
    /// <param name="serverName">The target server name.</param>
    /// <param name="serverDomain">The target server's domain.</param>
    /// <param name="elevationDurationMinutes">The requested elevation duration, in minutes.</param>
    /// <param name="callingUserUpn">The user principal name of the request initiator.</param>
    /// <remarks>
    /// The payload includes the user, server domain, constructed server-group name, duration,
    /// and calling user. The method creates the configured event source when it is absent, then
    /// writes event ID 100. String arguments are serialized as supplied and are expected to be
    /// non-null.
    /// </remarks>
    /// <exception cref="ArgumentException">
    /// The configured source is invalid or is registered to a different log.
    /// </exception>
    /// <exception cref="InvalidOperationException">
    /// The event log is unavailable or the source cannot be opened or created.
    /// </exception>
    /// <exception cref="System.Security.SecurityException">
    /// The process lacks permission to inspect, create, or write the event source.
    /// </exception>
    public void WriteManagementEvent(string userDistinguishedName, string serverName, string serverDomain, int elevationDurationMinutes, string callingUserUpn)
    {
        var serverGroup = _enableMultiDomainSupport
            ? $"{_adminPreFix}{serverDomain}{_domainSeparator}{serverName}"
            : $"{_adminPreFix}{serverName}";
        var payload = new
        {
            UserDN = userDistinguishedName,
            ServerDomain = serverDomain,
            ServerGroup = serverGroup,
            ElevationTime = elevationDurationMinutes,
            CallingUser = callingUserUpn
        };
        var message = JsonSerializer.Serialize(payload, new JsonSerializerOptions { WriteIndented = true });

        EnsureSourceExists(); // We ensure that the specified event source exists in the Windows Event Log, creating it if necessary. This is important because writing to an event log requires a valid source, and if the source does not exist, we need to create it before we can write events.
        EventLog.WriteEntry(_eventSource, message, EventLogEntryType.Information, ManagementEventId); // We write the event to the Windows Event Log using the specified event source, message, entry type (Information), and event ID.This message will be consumed by the JIT engine
    }

    /// <summary>
    /// Ensures that the configured event source is registered.
    /// </summary>
    /// <remarks>
    /// Creates a machine-wide Windows Event Log source associated with the configured log when
    /// the source does not exist. Event-source registration may require administrative privileges.
    /// </remarks>
    /// <exception cref="ArgumentException">The source or log name is invalid.</exception>
    /// <exception cref="InvalidOperationException">The source cannot be queried or created.</exception>
    /// <exception cref="System.Security.SecurityException">
    /// The process lacks permission to inspect or create event sources.
    /// </exception>
    private void EnsureSourceExists()
    {
        if (EventLog.SourceExists(_eventSource))
        {
            return;
        }

        var sourceData = new EventSourceCreationData(_eventSource, _logName);
        EventLog.CreateEventSource(sourceData);
    }
}
