/*
 * File: ServerSelectionViewModel.cs
 * Author: Andreas Lucas (aka Kili)
 *
 * Version history:
 * - 0.2.20260926.6: Added complete type and property documentation.
 */

namespace KjitWeb.Models;

/// <summary>
/// Carries the domain, server, and elevation-duration state used by the server-selection view.
/// </summary>
public class ServerSelectionViewModel
{
    /// <summary>
    /// Gets or sets the domains available for selection.
    /// </summary>
    /// <value>A mutable list that is empty by default.</value>
    public List<string> Domains { get; set; } = new();

    /// <summary>
    /// Gets or sets the selected domain.
    /// </summary>
    /// <value>The selected domain name, or <see langword="null"/> when none is selected.</value>
    public string? SelectedDomain { get; set; }

    /// <summary>
    /// Gets or sets the computers on which the user currently has elevated access.
    /// </summary>
    /// <value>A mutable list that is empty by default.</value>
    public List<ElevatedComputerViewModel> CurrentElevatedComputers { get; set; } = new();

    /// <summary>
    /// Gets or sets the servers available in the selected domain.
    /// </summary>
    /// <value>A mutable list that is empty by default.</value>
    public List<string> Servers { get; set; } = new();

    /// <summary>
    /// Gets or sets the server selected for elevation.
    /// </summary>
    /// <value>The selected server name, or <see langword="null"/> when none is selected.</value>
    public string? SelectedServer { get; set; }

    /// <summary>
    /// Gets or sets the requested elevation duration, in minutes.
    /// </summary>
    public int ElevationDurationMinutes { get; set; }

    /// <summary>
    /// Gets or sets the minimum permitted elevation duration, in minutes.
    /// </summary>
    public int MinElevationDurationMinutes { get; set; }

    /// <summary>
    /// Gets or sets the maximum permitted elevation duration, in minutes.
    /// </summary>
    public int MaxElevationDurationMinutes { get; set; }

    /// <summary>
    /// Gets or sets the configured default elevation duration, in minutes.
    /// </summary>
    public int DefaultElevationDurationMinutes { get; set; }
}
