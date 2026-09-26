/*
 * File: SwitchUserViewModel.cs
 * Author: Andreas Lucas (aka Kili)
 *
 * Version history:
 * - 0.2.20260926.6: Added complete type and property documentation.
 */

namespace KjitWeb.Models;

/// <summary>
/// Carries credentials and validation feedback for the switch-user form.
/// </summary>
/// <remarks>
/// The password is transient form input and callers clear it before redisplaying a failed request.
/// </remarks>
public class SwitchUserViewModel
{
    /// <summary>
    /// Gets or sets the identity to validate.
    /// </summary>
    /// <value>The entered user name, or <see langword="null"/> when omitted.</value>
    public string? Username { get; set; }

    /// <summary>
    /// Gets or sets the password submitted for validation.
    /// </summary>
    /// <value>The entered password, or <see langword="null"/> when omitted or cleared.</value>
    public string? Password { get; set; }

    /// <summary>
    /// Gets or sets the validation message displayed by the form.
    /// </summary>
    /// <value>A user-facing error message, or <see langword="null"/> when no error is present.</value>
    public string? ErrorMessage { get; set; }
}
