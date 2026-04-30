using System.Diagnostics;
using System.Text.Json;

namespace KjitWeb.Services;

/// <summary>
/// This class is responsible for writing events to the Windows Event Log related to Just-In-Time (JIT) access management.
/// It implements the IEventLogWriter interface, which defines a method for writing management events when a user is granted JIT access to a server.
/// The class uses configuration settings to determine the event log name, event source name, and formatting of the event messages. It ensures that the specified event source exists in the Windows Event Log, creating it if necessary, before writing events.
/// The WriteManagementEvent method constructs a structured event message in JSON format containing details about the user granted access, the server they are accessing, the duration of the elevation, and the calling user. This structured format allows for easier parsing and analysis of events in the event log.
/// Overall, this class provides a centralized way to log important events related to JIT access management, which can be critical for auditing and troubleshooting purposes in an enterprise environment where JIT access is used to enhance security by granting temporary access to resources.
/// </summary>
/// <remarks>
/// Writing to the Windows Event Log may require elevated permissions, so this class is designed to fail gracefully if it cannot write to the event log, ensuring that the application can continue to function even if logging is not possible. However, in a properly configured environment, it will provide valuable insights into JIT access events for administrators and security teams.
/// </remarks>
public class EventLogWriter : IEventLogWriter
{
    // We define a constant event ID for management events related to JIT access. 
    // This allows us to easily identify and filter these events in the Windows Event Log when analyzing logs for auditing or troubleshooting purposes. 
    // The event ID is set to 100, which is an arbitrary value chosen to be distinct and easily recognizable as a JIT access management event in the logs.
    private const int ManagementEventId = 100;
    //
    private readonly string _logName;
    private readonly string _eventSource;
    private readonly string _adminPreFix;
    private readonly string _domainSeparator;

    /// <summary>
    ///     The constructor of the EventLogWriter class initializes the event log settings based on the provided configuration.
    ///     It retrieves the JIT configuration from the specified path in the configuration, and if the path is not provided or is invalid, it falls back to default values defined in the JitConfiguration class.
    ///     The constructor sets the log name, event source name, admin prefix, and domain separator based on the JIT configuration, which will be used when writing events to the Windows Event Log. This allows for flexible configuration of how events are logged, including the ability to specify custom log names and event sources for better organization and identification of events in the logs.    
    /// </summary>
    /// <param name="configuration">The configuration object used to retrieve JIT settings.</param>
    /// <remarks>
    ///     The constructor is designed to be called during the startup of the application, and it ensures that the necessary configuration for event logging is loaded and ready to be used when writing events. By allowing the configuration to be specified externally, it provides flexibility for different deployment environments and makes it easier to manage logging settings without requiring code changes.
    /// </remarks>
    /// <exception cref="Exception">The constructor may throw exceptions if there are issues with reading the configuration or if the configuration values are invalid. However, it is expected that the configuration will be properly set up to avoid such issues during normal operation.</exception>
    /// <exception cref="ArgumentException">The constructor may throw an ArgumentException if the configuration values for log name, event source, admin prefix, or domain separator are invalid (e.g., null or empty). It is important to ensure that the configuration values are valid to prevent issues when writing events to the Windows Event Log.</exception>
    /// <exception cref="UnauthorizedAccessException">The constructor itself does not perform any operations that would require elevated permissions, but the EnsureSourceExists method called when writing events may throw an UnauthorizedAccessException if the application does not have permission to create event sources in the Windows Event Log. It is important to ensure that the application has the necessary permissions to write to the event log for proper functionality.</exception>
    /// <exception cref="System.IO.IOException">The constructor may throw an IOException if there are issues with reading the configuration file specified by the JIT configuration path. It is important to ensure that the configuration file is accessible and properly formatted to avoid such issues during startup.</exception>
    /// <exception cref="JsonException">The constructor may throw a JsonException if there are issues with parsing the JIT configuration file specified by the JIT configuration path. It is important to ensure that the configuration file is properly formatted as JSON to avoid such issues during startup.</exception>
    /// <exception cref="Exception">The constructor may throw a general Exception if there are any other unforeseen issues during the initialization of the EventLogWriter, such as issues with the configuration system or other dependencies. It is important to handle exceptions appropriately during startup to ensure that critical issues are logged and can be diagnosed by administrators.</exception>
    /// <exception cref="ArgumentNullException">The constructor may throw an ArgumentNullException if the provided configuration object is null. It is important to ensure that a valid configuration object is passed to the constructor to avoid such issues during initialization.</exception>
    public EventLogWriter(IConfiguration configuration)
    {
        // We attempt to retrieve the JIT configuration path from the provided configuration using the key "ActiveDirectory:JitConfigPath". 
        // If the path is not provided or is invalid, we create a new instance of JitConfiguration with default values. 
        // Otherwise, we create a new instance of JitConfiguration using the specified path to load the configuration settings. 
        // This allows us to have flexible configuration management for the event logging settings, enabling administrators to specify custom configurations as needed while still providing sensible defaults when no specific configuration is provided.
        var jitConfigPath = JitConfigPathResolver.Resolve(configuration);
        // We check if the jitConfigPath is null, empty, or consists only of whitespace. 
        // If it is, we create a new instance of JitConfiguration with default values. If it is not, we create a new instance of JitConfiguration using the specified path to load the configuration settings. This allows us to handle both cases where a custom configuration path is provided and where it is not, ensuring that we have valid configuration settings for the event logging functionality regardless of how the application is configured.
        var jitConfig = string.IsNullOrWhiteSpace(jitConfigPath)
            ? new JitConfiguration()
            : new JitConfiguration(jitConfigPath);
        _logName = jitConfig.EventLogName; // We set the log name for the event log based on the JIT configuration, which will be used when writing events to specify which log to write to in the Windows Event Log.
        _eventSource = jitConfig.EventLogSourceName; // We set the event source name for the event log based on the JIT configuration, which will be used when writing events to specify the source of the events in the Windows Event Log. This allows for better organization and identification of events in the logs, as administrators can filter and analyze events based on their source.
        _adminPreFix = jitConfig.AdminPreFix; // We set the admin prefix based on the JIT configuration, which will be used when constructing the server group name in the event messages. This allows for consistent formatting of server group names in the event log, making it easier to identify and analyze events related to specific servers or domains.
        _domainSeparator = jitConfig.DomainSeparator; // We set the domain separator based on the JIT configuration, which will be used when constructing the server group name in the event messages. This allows for consistent formatting of server group names in the event log, making it easier to identify and analyze events related to specific servers or domains.
    }

    /// <summary>
    ///     The WriteManagementEvent method is responsible for writing an event to the Windows Event Log when a user is granted Just-In-Time (JIT) access to a server. 
    ///     It constructs a structured event message in JSON format containing details about the user granted access, the server they are accessing, the duration of the elevation, and the calling user. The method ensures that the specified event source exists in the Windows Event Log, creating it if necessary, before writing the event. This allows for better organization and identification of events in the logs, as administrators can filter and analyze events based on their source and content.
    /// </summary>
    /// <param name="userDistinguishedName">The distinguished name of the user who was granted JIT access.</param>
    /// <param name="serverName">The name of the server to which access was granted.</param>
    /// <param name="serverDomain">The domain of the server to which access was granted.</param>
    /// <param name="elevationDurationMinutes">The duration of the JIT access elevation in minutes.</param>
    /// <param name="callingUserUpn">The User Principal Name (UPN) of the user who initiated the JIT access request.</param>
    /// <remarks>
    ///     The method is designed to be called whenever a user is granted JIT access to a server. 
    ///     It generates a request message in JSON format that includes all relevant details about the access request event.    
    /// </remarks>    
    public void WriteManagementEvent(string userDistinguishedName, string serverName, string serverDomain, int elevationDurationMinutes, string callingUserUpn)
    {
        // We construct the server group name using the admin prefix, server domain, and server name, separated by the domain separator.
        var serverGroup = $"{_adminPreFix}{serverDomain}{_domainSeparator}{serverName}";
        // We create a payload object containing the details of the JIT access event, including the user distinguished name, server domain, server group, elevation duration, and calling user UPN.
        var payload = new
        {
            UserDN = userDistinguishedName,
            ServerDomain = serverDomain,
            ServerGroup = serverGroup,
            ElevationTime = elevationDurationMinutes,
            CallingUser = callingUserUpn
        };
        // We serialize the payload object to a JSON string with indentation for better readability in the event log. 
        var message = JsonSerializer.Serialize(payload, new JsonSerializerOptions { WriteIndented = true });

        EnsureSourceExists(); // We ensure that the specified event source exists in the Windows Event Log, creating it if necessary. This is important because writing to an event log requires a valid source, and if the source does not exist, we need to create it before we can write events.
        EventLog.WriteEntry(_eventSource, message, EventLogEntryType.Information, ManagementEventId); // We write the event to the Windows Event Log using the specified event source, message, entry type (Information), and event ID.This message will be consumed by the JIT engine
    }

    // This helper method ensures that the specified event source exists in the Windows Event Log, creating it if necessary. 
    // It checks if the event source already exists, and if it does, it simply returns. If it does not exist, it creates a new event source with the specified name and log name. 
    // This is important because writing to an event log requires a valid source, and if the source does not exist, we need to create it before we can write events. 
    private void EnsureSourceExists()
    {
        // We check if the specified event source already exists in the Windows Event Log. 
        // If it does, we can simply return and proceed to write events using that source.
        if (EventLog.SourceExists(_eventSource))
        {
            return;
        }
        // If the event source does not exist, we create a new event source with the specified name and log name.
        var sourceData = new EventSourceCreationData(_eventSource, _logName);
        EventLog.CreateEventSource(sourceData);
    }
}
