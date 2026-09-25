namespace KjitWeb.Services;

/// <summary>
///     Exposes the most recently computed <see cref="EventLogHealthSnapshot"/> so that controllers
///     can serve it to the website without querying the Windows Event Log on every request.
/// </summary>
public interface IEventLogHealthMonitor
{
    /// <summary>The health snapshot as of the last background scan.</summary>
    EventLogHealthSnapshot Current { get; }
}
