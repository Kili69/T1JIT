using KjitWeb.Models;
using KjitWeb.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Localization;
using System.Security.Claims;
using System.Text.Json;

namespace KjitWeb.Controllers;

[Authorize]
public class HomeController : Controller
{
    private readonly IActiveDirectoryService _activeDirectoryService;
    private readonly IConfiguration _configuration;
    private readonly IEventLogWriter _eventLogWriter;
    private readonly ILogger<HomeController> _logger;
    private readonly IStringLocalizer<SharedResource> _localizer;
    private readonly WindowsCredentialValidator _credentialValidator;

    public HomeController(
        IActiveDirectoryService activeDirectoryService,
        IConfiguration configuration,
        IEventLogWriter eventLogWriter,
        ILogger<HomeController> logger,
        IStringLocalizer<SharedResource> localizer,
        WindowsCredentialValidator credentialValidator)
    {
        _activeDirectoryService = activeDirectoryService;
        _configuration = configuration;
        _eventLogWriter = eventLogWriter;
        _logger = logger;
        _localizer = localizer;
        _credentialValidator = credentialValidator;
    }

    [HttpGet]
    public IActionResult Index(string? selectedDomain)
    {
        var model = CreateModel(selectedDomain);

        return View(model);
    }

    /// <summary>Shows the switch-user login form.</summary>
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

    /// <summary>Validates the form credentials and sets a persistent switched-user cookie.</summary>
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

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Index(ServerSelectionViewModel model)
    {
        var identityName = User?.Identity?.Name;
        ApplyJitSettings(model);
        ApplyDomainSelection(model);
        model.CurrentElevationGroups = _activeDirectoryService.GetCurrentElevationGroups(User);
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
            var userDn = _activeDirectoryService.GetUserDistinguishedName(identityName);
            var callingUserUpn = _activeDirectoryService.GetUserPrincipalName(identityName);

            var eventPayload = new
            {
                UserDN = userDn,
                ServerName = model.SelectedServer!,
                ServerDomain = model.SelectedDomain!,
                ElevationTime = model.ElevationDurationMinutes,
                CallingUser = callingUserUpn
            };

            _logger.LogInformation(
                "Elevation request received. EventPayload={EventPayload}",
                JsonSerializer.Serialize(eventPayload));

            _eventLogWriter.WriteManagementEvent(
                userDn,
                model.SelectedServer!,
                model.SelectedDomain!,
                model.ElevationDurationMinutes,
                callingUserUpn);

            _logger.LogInformation(
                "Elevation request written to Windows Event Log. Server={Server} Domain={Domain} DurationMinutes={Duration} CallingUser={CallingUser}",
                model.SelectedServer,
                model.SelectedDomain,
                model.ElevationDurationMinutes,
                callingUserUpn);

            model.CurrentElevationGroups = _activeDirectoryService.GetCurrentElevationGroups(User);

            model.SelectedServer = null;
            ModelState.Remove(nameof(model.SelectedServer));

            ViewBag.SuccessMessage = _localizer["SuccessUserElevated"];
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error while writing to the event log.");
            ModelState.AddModelError(string.Empty, _localizer["EventLogWriteError"]);
        }

        return View(model);
    }

    private ServerSelectionViewModel CreateModel(string? selectedDomain)
    {
        var model = new ServerSelectionViewModel
        {
            SelectedDomain = selectedDomain
        };

        ApplyJitSettings(model);
        ApplyDomainSelection(model);
        model.CurrentElevationGroups = _activeDirectoryService.GetCurrentElevationGroups(User);
        model.Servers = _activeDirectoryService.GetServerNames(User, model.SelectedDomain);
        model.ElevationDurationMinutes = model.DefaultElevationDurationMinutes;
        return model;
    }

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
