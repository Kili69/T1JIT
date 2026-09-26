// Author: Andreas Lucas (aka Kili)
// Documentation update: 0.2.20260926.6
// History: Existing implementation and security-sensitive authentication behavior are preserved.

using KjitWeb.Models;
using KjitWeb.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Localization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Localization;
using System.Globalization;
using System.Security.Claims;
using System.Text.Json;

namespace KjitWeb.Controllers;

/// <summary>
/// Handles the authenticated JIT elevation workflow, status polling, localization, and switched-user sign-in.
/// </summary>
/// <remarks>
/// Authorization is required by default. Only language selection and switched-user sign-in are anonymous.
/// Submitted server and duration values are revalidated against server-side configuration and directory results.
/// Credentials are accepted only by the switch-user POST action and are cleared from the returned model.
/// </remarks>
[Authorize]
public class HomeController : Controller
{
    private readonly IActiveDirectoryService _activeDirectoryService;
    private readonly IConfiguration _configuration;
    private readonly IEventLogWriter _eventLogWriter;
    private readonly IEventLogHealthMonitor _eventLogHealthMonitor;
    private readonly ILogger<HomeController> _logger;
    private readonly IStringLocalizer<SharedResource> _localizer;
    private readonly WindowsCredentialValidator _credentialValidator;

    /// <summary>Initializes the controller with its directory, configuration, logging, localization, and credential services.</summary>
    /// <param name="activeDirectoryService">Provides directory lookup and current-elevation data.</param>
    /// <param name="configuration">Provides the configured JIT configuration path.</param>
    /// <param name="eventLogWriter">Writes validated elevation requests to the management event log.</param>
    /// <param name="eventLogHealthMonitor">Provides the latest cached event-log health snapshot.</param>
    /// <param name="logger">Records operational and failure information; credentials are never intentionally logged.</param>
    /// <param name="localizer">Resolves localized UI and validation messages.</param>
    /// <param name="credentialValidator">Validates switched-user Windows credentials.</param>
    /// <remarks>The dependencies are stored as supplied; passing <see langword="null"/> causes later action execution to fail.</remarks>
    public HomeController(
        IActiveDirectoryService activeDirectoryService,
        IConfiguration configuration,
        IEventLogWriter eventLogWriter,
        IEventLogHealthMonitor eventLogHealthMonitor,
        ILogger<HomeController> logger,
        IStringLocalizer<SharedResource> localizer,
        WindowsCredentialValidator credentialValidator)
    {
        _activeDirectoryService = activeDirectoryService;
        _configuration = configuration;
        _eventLogWriter = eventLogWriter;
        _eventLogHealthMonitor = eventLogHealthMonitor;
        _logger = logger;
        _localizer = localizer;
        _credentialValidator = credentialValidator;
    }

    /// <summary>Displays the server-selection page for the current principal.</summary>
    /// <param name="selectedDomain">An optional requested domain; <see langword="null"/> selects the user's default domain.</param>
    /// <returns>A view populated with domains, servers, current elevations, and configured duration limits.</returns>
    /// <remarks>Performs Active Directory reads and loads JIT configuration; it does not grant elevation.</remarks>
    [HttpGet]
    public IActionResult Index(string? selectedDomain)
    {
        var model = CreateModel(selectedDomain);

        return View(model);
    }

    /// <summary>Returns the computers on which the current principal is elevated.</summary>
    /// <returns>A non-cacheable JSON result produced by the directory service.</returns>
    /// <remarks>The response is authorization-protected and may disclose privileged computer names to the authenticated caller.</remarks>
    [HttpGet]
    [ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
    public IActionResult CurrentElevatedComputers()
    {
        return Json(_activeDirectoryService.GetCurrentElevatedComputers(User));
    }

    /// <summary>
    ///     Returns the current event log health indicator (Ok/Warning/Error), computed periodically in
    ///     the background so this request does not need to query the Windows Event Log itself. Polled
    ///     by the footer script every 5 minutes to keep the indicator next to the version number current.
    /// </summary>
    /// <returns>A non-cacheable JSON object containing level, error and warning counts, and the UTC check time.</returns>
    /// <remarks>Returns cached monitor state and does not query the Windows Event Log during the request.</remarks>
    [HttpGet]
    [ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
    public IActionResult EventLogHealthStatus()
    {
        var status = _eventLogHealthMonitor.Current;
        return Json(new
        {
            level = status.Level.ToString(),
            errorCount = status.ErrorCount,
            warningCount = status.WarningCount,
            checkedAtUtc = status.CheckedAtUtc
        });
    }

    /// <summary>Sets the UI culture cookie and redirects to a safe local destination.</summary>
    /// <param name="culture">Requested culture. Values other than <c>de</c> or <c>en</c> fall back to <c>en</c>.</param>
    /// <param name="returnUrl">Optional local redirect URL; external, malformed, or <see langword="null"/> values use the index action.</param>
    /// <returns>A local redirect response.</returns>
    /// <remarks>
    /// This anonymous endpoint writes an essential, one-year culture cookie with <see cref="SameSiteMode.Lax"/>.
    /// <see cref="IUrlHelper.IsLocalUrl(string?)"/> prevents open redirects.
    /// </remarks>
    [HttpPost]
    [AllowAnonymous]
    public IActionResult SetLanguage(string culture, string? returnUrl)
    {
        var supportedCultures = new[] { "de", "en" };
        var selectedCulture = supportedCultures.Contains(culture, StringComparer.OrdinalIgnoreCase)
            ? culture.ToLowerInvariant()
            : "en";

        Response.Cookies.Append(
            CookieRequestCultureProvider.DefaultCookieName,
            CookieRequestCultureProvider.MakeCookieValue(new RequestCulture(selectedCulture)),
            new CookieOptions
            {
                Expires = DateTimeOffset.UtcNow.AddYears(1),
                IsEssential = true,
                SameSite = SameSiteMode.Lax
            });

        return LocalRedirect(Url.IsLocalUrl(returnUrl) ? returnUrl! : Url.Action(nameof(Index))!);
    }

    /// <summary>Shows an empty switch-user login form.</summary>
    /// <returns>The switch-user view.</returns>
    /// <remarks>
    /// This anonymous GET intentionally preserves any existing authentication cookie so the antiforgery token
    /// remains bound to the same identity between form rendering and submission.
    /// </remarks>
    [HttpGet]
    [AllowAnonymous]
    public IActionResult SwitchUser()
    {
        // Do NOT sign out here. The antiforgery token is bound to the currently
        // authenticated identity (cookie if present, otherwise Negotiate/Windows).
        // Signing out in GET would change the identity mid-request, causing the
        // POST antiforgery check to fail (HTTP 400) or crash (HTTP 404).
        // The cookie is cleared in the POST action after credential validation.
        return View(new SwitchUserViewModel());
    }

    /// <summary>Validates supplied Windows credentials and establishes a switched-user cookie.</summary>
    /// <param name="model">Form values. The password is cleared before redisplaying a rejected submission.</param>
    /// <returns>
    /// A redirect to <see cref="Index(string?)"/> after successful authentication; otherwise, the form view with
    /// a generic validation message that does not reveal which credential was invalid.
    /// </returns>
    /// <remarks>
    /// Requires an antiforgery token. On success, replaces the existing application cookie with a persistent,
    /// refreshable identity cookie. The password is passed to the validator but is not logged.
    /// </remarks>
    [HttpPost]
    [ValidateAntiForgeryToken]
    [AllowAnonymous]
    public async Task<IActionResult> SwitchUser(SwitchUserViewModel model)
    {
        if (string.IsNullOrWhiteSpace(model.Username) || string.IsNullOrWhiteSpace(model.Password))
        {
            model.ErrorMessage = "Benutzername und Kennwort sind erforderlich.";
            model.Password = null;
            return View(model);
        }

        if (_credentialValidator.Validate(model.Username, model.Password, out var normalizedIdentity))
        {
            // Clear any existing switched-user session before establishing the new one.
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);

            var identity = new ClaimsIdentity(
                new[] { new Claim(ClaimTypes.Name, normalizedIdentity) },
                CookieAuthenticationDefaults.AuthenticationScheme,
                ClaimTypes.Name,
                ClaimTypes.Role);
            var principal = new ClaimsPrincipal(identity);

            await HttpContext.SignInAsync(
                CookieAuthenticationDefaults.AuthenticationScheme,
                principal,
                new AuthenticationProperties { IsPersistent = true, AllowRefresh = true });

            _logger.LogInformation("User switched to {Identity}", normalizedIdentity);
            return RedirectToAction(nameof(Index));
        }

        model.ErrorMessage = "Ungültige Anmeldedaten.";
        model.Password = null;
        return View(model);
    }

    /// <summary>Validates and submits a JIT elevation request.</summary>
    /// <param name="model">The posted domain, server, and duration selection. Missing values are validated server-side.</param>
    /// <returns>The selection view with validation errors, an error message, or a success message.</returns>
    /// <remarks>
    /// Refreshes allowed domains and servers before accepting the request, preventing a client from selecting an
    /// unlisted server. A successful request writes security-relevant user, server, domain, and duration data to
    /// the Windows Event Log and application log; it does not return credentials.
    /// </remarks>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Index(ServerSelectionViewModel model)
    {
        var identityName = User?.Identity?.Name;
        ApplyJitSettings(model);
        ApplyDomainSelection(model);
        model.CurrentElevatedComputers = _activeDirectoryService.GetCurrentElevatedComputers(User);
        model.Servers = _activeDirectoryService.GetServerNames(User, model.SelectedDomain);

        if (string.IsNullOrWhiteSpace(model.SelectedDomain))
        {
            ModelState.AddModelError(nameof(model.SelectedDomain), _localizer["ValidationSelectDomain"]);
        }

        if (string.IsNullOrWhiteSpace(model.SelectedServer))
        {
            ModelState.AddModelError(nameof(model.SelectedServer), _localizer["ValidationSelectServer"]);
        }
        else if (!model.Servers.Contains(model.SelectedServer, StringComparer.OrdinalIgnoreCase))
        {
            ModelState.AddModelError(nameof(model.SelectedServer), _localizer["ValidationServerDomainMismatch"]);
        }

        if (model.ElevationDurationMinutes < model.MinElevationDurationMinutes
            || model.ElevationDurationMinutes > model.MaxElevationDurationMinutes)
        {
            ModelState.AddModelError(
                nameof(model.ElevationDurationMinutes),
                _localizer["ValidationElevationRange", model.MinElevationDurationMinutes, model.MaxElevationDurationMinutes]);
        }

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        try
        {
            var requestedServer = model.SelectedServer!;
            var userDn = _activeDirectoryService.GetUserDistinguishedName(identityName);
            var callingUserUpn = _activeDirectoryService.GetUserPrincipalName(identityName);

            var eventPayload = new
            {
                UserDN = userDn,
                ServerName = requestedServer,
                ServerDomain = model.SelectedDomain!,
                ElevationTime = model.ElevationDurationMinutes,
                CallingUser = callingUserUpn
            };

            _logger.LogInformation(
                "Elevation request received. EventPayload={EventPayload}",
                JsonSerializer.Serialize(eventPayload));

            _eventLogWriter.WriteManagementEvent(
                userDn,
                requestedServer,
                model.SelectedDomain!,
                model.ElevationDurationMinutes,
                callingUserUpn);

            _logger.LogInformation(
                "Elevation request written to Windows Event Log. Server={Server} Domain={Domain} DurationMinutes={Duration} CallingUser={CallingUser}",
                model.SelectedServer,
                model.SelectedDomain,
                model.ElevationDurationMinutes,
                callingUserUpn);

            model.CurrentElevatedComputers = _activeDirectoryService.GetCurrentElevatedComputers(User);

            model.SelectedServer = null;
            ModelState.Remove(nameof(model.SelectedServer));

            ViewBag.SuccessMessage = _localizer["SuccessUserElevated", requestedServer];
            ViewBag.SuccessComputerName = requestedServer;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error while writing to the event log.");
            ModelState.AddModelError(string.Empty, _localizer["EventLogWriteError"]);
        }

        return View(model);
    }

    /// <summary>Creates the initial selection model for the current authenticated principal.</summary>
    /// <param name="selectedDomain">Optional requested domain; <see langword="null"/> permits default-domain selection.</param>
    /// <returns>A fully populated, non-null selection model with the default elevation duration.</returns>
    /// <remarks>Reads JIT configuration and Active Directory state and may perform network I/O.</remarks>
    private ServerSelectionViewModel CreateModel(string? selectedDomain)
    {
        var model = new ServerSelectionViewModel
        {
            SelectedDomain = selectedDomain
        };

        ApplyJitSettings(model);
        ApplyDomainSelection(model);
        model.CurrentElevatedComputers = _activeDirectoryService.GetCurrentElevatedComputers(User);
        model.Servers = _activeDirectoryService.GetServerNames(User, model.SelectedDomain);
        model.ElevationDurationMinutes = model.DefaultElevationDurationMinutes;
        return model;
    }

    /// <summary>Populates domains and chooses or retains the model's selected domain.</summary>
    /// <param name="model">The non-null model to mutate.</param>
    /// <remarks>
    /// Performs directory lookups. If a selected/default domain is absent from a non-empty directory result, it is
    /// added, deduplicated case-insensitively, and sorted. A <see langword="null"/> model causes a null-reference failure.
    /// </remarks>
    private void ApplyDomainSelection(ServerSelectionViewModel model)
    {
        model.Domains = _activeDirectoryService.GetAvailableDomains();
        if (string.IsNullOrWhiteSpace(model.SelectedDomain))
        {
            model.SelectedDomain = _activeDirectoryService.GetDefaultDomainForUser(User);
        }

        if (!string.IsNullOrWhiteSpace(model.SelectedDomain)
            && model.Domains.Count > 0
            && !model.Domains.Contains(model.SelectedDomain, StringComparer.OrdinalIgnoreCase))
        {
            model.Domains.Add(model.SelectedDomain);
            model.Domains = model.Domains
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .OrderBy(domain => domain, StringComparer.OrdinalIgnoreCase)
                .ToList();
        }
    }

    /// <summary>Loads configured duration bounds into a selection model and supplies the default duration when needed.</summary>
    /// <param name="model">The non-null model to mutate.</param>
    /// <remarks>
    /// Reads the configured local or SYSVOL JIT configuration file. Invalid or inaccessible configuration is allowed
    /// to propagate so startup/request handling can report the administrative error. A <see langword="null"/> model fails.
    /// </remarks>
    /// <exception cref="ArgumentException">The configured explicit JIT configuration path is blank.</exception>
    /// <exception cref="FileNotFoundException">The resolved JIT configuration file does not exist.</exception>
    /// <exception cref="InvalidOperationException">The domain cannot be resolved or the configuration cannot be read or parsed.</exception>
    private void ApplyJitSettings(ServerSelectionViewModel model)
    {
        var jitConfigPath = JitConfigPathResolver.Resolve(_configuration);
        var jitConfiguration = string.IsNullOrWhiteSpace(jitConfigPath)
            ? new JitConfiguration()
            : new JitConfiguration(jitConfigPath);

        model.MinElevationDurationMinutes = JitConfiguration.MinimumElevationDurationMinutes;
        model.MaxElevationDurationMinutes = jitConfiguration.MaxElevatedTimeMinutes;
        model.DefaultElevationDurationMinutes = jitConfiguration.DefaultElevatedTimeMinutes;

        if (model.ElevationDurationMinutes <= 0)
        {
            model.ElevationDurationMinutes = model.DefaultElevationDurationMinutes;
        }
    }
}
