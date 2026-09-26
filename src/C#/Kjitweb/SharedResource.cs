/*
 * File: SharedResource.cs
 * Author: Andreas Lucas (aka Kili)
 *
 * Version history:
 * - 0.2.20260926.6: Added complete marker-type documentation.
 */

namespace KjitWeb;

/// <summary>
/// Identifies the shared localization resource set used across KjitWeb.
/// </summary>
/// <remarks>
/// This marker type intentionally contains no members; its fully qualified name is the
/// resource base name consumed by <c>IStringLocalizer&lt;SharedResource&gt;</c>.
/// </remarks>
public sealed class SharedResource
{
}