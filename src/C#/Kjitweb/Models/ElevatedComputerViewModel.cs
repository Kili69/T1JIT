/*
 * File: ElevatedComputerViewModel.cs
 * Author: Andreas Lucas (aka Kili)
 *
 * Version history:
 * - 0.2.20260926.6: Added complete type and property documentation.
 */

namespace KjitWeb.Models;

/// <summary>
/// Represents a computer on which the current user has active Just-In-Time access.
/// </summary>
public class ElevatedComputerViewModel
{
    /// <summary>
    /// Gets the computer name displayed to the user.
    /// </summary>
    /// <value>A non-null computer name supplied when the model is initialized.</value>
    public required string ComputerName { get; init; }

    /// <summary>
    /// Gets the DNS domain associated with the computer.
    /// </summary>
    /// <value>The domain name, or <see langword="null"/> when no domain is available.</value>
    public string? Domain { get; init; }

    /// <summary>
    /// Gets the estimated time remaining for the elevation.
    /// </summary>
    /// <value>
    /// The remaining duration in seconds, or <see langword="null"/> when it cannot be determined.
    /// </value>
    public int? RemainingSeconds { get; init; }
}