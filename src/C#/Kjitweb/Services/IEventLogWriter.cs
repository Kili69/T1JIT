namespace KjitWeb.Services;

/// <summary>
///     Interface for writing events to the Windows Event Log. 
///     This service provides methods to log management events, including user and server information, elevation duration, and calling user details.
/// </summary>
public interface IEventLogWriter
{
    /// <summary>
    ///     Writes a management event to the Windows Event Log.
    /// </summary>
    /// <param name="userDistinguishedName">The distinguished name of the user.</param>
    /// <param name="serverName">The name of the server.</param>
    /// <param name="serverDomain">The domain of the server.</param>
    /// <param name="elevationDurationMinutes">The duration of the elevation in minutes.</param>
    /// <param name="callingUserUpn">The user principal name (UPN) of the calling user.</param>
    void WriteManagementEvent(string userDistinguishedName, string serverName, string serverDomain, int elevationDurationMinutes, string callingUserUpn);
}
