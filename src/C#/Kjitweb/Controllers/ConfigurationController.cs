using System.Text.Json;
using KjitWeb.Models;
using KjitWeb.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Localization;

namespace KjitWeb.Controllers;

/// <summary>Provides authorized editing of the JIT and delegation configuration files.</summary>
[Authorize]
public sealed class ConfigurationController : Controller
{
    private readonly ConfigurationEditorService _configurationEditor;
    private readonly IActiveDirectoryService _activeDirectory;
    private readonly ILogger<ConfigurationController> _logger;
    private readonly IStringLocalizer<SharedResource> _localizer;

    /// <summary>Initializes the configuration controller.</summary>
    /// <param name="configurationEditor">Loads, authorizes, validates, and saves configuration files.</param>
    /// <param name="activeDirectory">Resolves delegation users, groups, and SIDs.</param>
    /// <param name="logger">Records configuration editing failures and successful operations.</param>
    /// <param name="localizer">Provides localized UI messages.</param>
    public ConfigurationController(
        ConfigurationEditorService configurationEditor,
        IActiveDirectoryService activeDirectory,
        ILogger<ConfigurationController> logger,
        IStringLocalizer<SharedResource> localizer)
    {
        _configurationEditor = configurationEditor;
        _activeDirectory = activeDirectory;
        _logger = logger;
        _localizer = localizer;
    }

    /// <summary>Displays both configuration documents when the Windows user can write both files.</summary>
    /// <returns>The editor view, or HTTP 403 when the required file access is unavailable.</returns>
    [HttpGet]
    [ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
    public IActionResult Index()
    {
        if (!_configurationEditor.CanEdit(User))
        {
            return Forbid();
        }

        return View(CreateViewModel(_configurationEditor.Load(User), "jit"));
    }

    /// <summary>Validates and saves the submitted JIT configuration.</summary>
    /// <param name="model">The edited JSON and hash of the originally loaded file.</param>
    /// <returns>The refreshed editor, or HTTP 403 when file access is unavailable.</returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult SaveJit(JitConfigurationEditModel model)
    {
        if (model.Parameters.Count == 0)
        {
            ModelState.AddModelError(
                nameof(model.Parameters),
                _localizer["ConfigurationContentRequired"]);
        }

        if (!ModelState.IsValid)
        {
            return RenderWithSubmittedJitParameters(model);
        }

        try
        {
            var currentSnapshot = _configurationEditor.Load(User);
            var content = JitConfigurationFormMapper.WriteParameters(
                currentSnapshot.JitConfigContent,
                model.Parameters);
            var savedSnapshot = _configurationEditor.Save(
                User,
                ConfigurationFileKind.Jit,
                content,
                model.ExpectedHash);
            var viewModel = CreateViewModel(savedSnapshot, "jit");
            viewModel.SuccessMessage = _localizer["JitConfigurationSaved"];
            return View("Index", viewModel);
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "Configuration save denied for {User}.", User.Identity?.Name);
            return Forbid();
        }
        catch (ConfigurationEditConflictException)
        {
            ModelState.AddModelError(nameof(model.Parameters), _localizer["ConfigurationConflict"]);
        }
        catch (JsonException ex)
        {
            ModelState.AddModelError(
                nameof(model.Parameters),
                _localizer["ConfigurationInvalidJson", ex.Message]);
        }
        catch (InvalidOperationException ex)
        {
            ModelState.AddModelError(
                nameof(model.Parameters),
                _localizer["ConfigurationInvalidJson", ex.Message]);
        }
        catch (ArgumentException ex)
        {
            ModelState.AddModelError(
                nameof(model.Parameters),
                _localizer["ConfigurationInvalidJson", ex.Message]);
        }
        catch (IOException ex)
        {
            _logger.LogError(ex, "Configuration save failed for {User}.", User.Identity?.Name);
            ModelState.AddModelError(
                nameof(model.Parameters),
                _localizer["ConfigurationSaveFailed"]);
        }

        return RenderWithSubmittedJitParameters(model);
    }

    /// <summary>Validates and saves the submitted delegation configuration.</summary>
    /// <param name="model">The edited delegations and hash of the originally loaded file.</param>
    /// <returns>The refreshed editor, or HTTP 403 when file access is unavailable.</returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult SaveDelegation(DelegationConfigurationEditModel model)
    {
        if (!ModelState.IsValid)
        {
            return RenderWithSubmittedDelegations(model);
        }

        try
        {
            ResolveSubmittedDelegations(model.Delegations);
            var content = DelegationConfigurationFormMapper.WriteDelegations(model.Delegations);
            var snapshot = _configurationEditor.Save(
                User,
                ConfigurationFileKind.Delegation,
                content,
                model.ExpectedHash);
            var viewModel = CreateViewModel(snapshot, "delegation");
            viewModel.SuccessMessage = _localizer["DelegationConfigurationSaved"];
            return View("Index", viewModel);
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "Configuration save denied for {User}.", User.Identity?.Name);
            return Forbid();
        }
        catch (ConfigurationEditConflictException)
        {
            ModelState.AddModelError(nameof(model.Delegations), _localizer["ConfigurationConflict"]);
        }
        catch (JsonException ex)
        {
            ModelState.AddModelError(
                nameof(model.Delegations),
                _localizer["ConfigurationInvalidJson", ex.Message]);
        }
        catch (IOException ex)
        {
            _logger.LogError(ex, "Configuration save failed for {User}.", User.Identity?.Name);
            ModelState.AddModelError(nameof(model.Delegations), _localizer["ConfigurationSaveFailed"]);
        }

        return RenderWithSubmittedDelegations(model);
    }

    /// <summary>Resolves one Active Directory identity for the delegation editor.</summary>
    /// <param name="identity">A SID, SAM account name, Windows account name, or UPN.</param>
    /// <returns>The resolved delegation object, HTTP 404 when it is unknown, or HTTP 403 without file access.</returns>
    [HttpGet]
    [ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
    public IActionResult ResolveDelegationObject(string? identity)
    {
        if (!_configurationEditor.CanEdit(User))
        {
            return Forbid();
        }

        var resolved = _activeDirectory.ResolveDelegationAdObject(identity);
        if (resolved is null)
        {
            return NotFound();
        }

        return Json(new
        {
            resolved.SecurityIdentifier,
            resolved.DisplayName,
            Kind = resolved.Kind.ToString().ToLowerInvariant()
        });
    }

    /// <summary>Resolves an organizational unit for the delegation editor.</summary>
    /// <param name="identity">The organizational-unit distinguished name.</param>
    /// <returns>The canonical distinguished name, HTTP 404 when it is unknown, or HTTP 403 without file access.</returns>
    [HttpGet]
    [ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
    public IActionResult ResolveDelegationOrganizationalUnit(string? identity)
    {
        if (!_configurationEditor.CanEdit(User))
        {
            return Forbid();
        }

        var computerOu = _activeDirectory.ResolveDelegationOrganizationalUnit(identity);
        return computerOu is null
            ? NotFound()
            : Json(new { ComputerOu = computerOu });
    }

    /// <summary>Browses configured Active Directory delegation targets one level at a time.</summary>
    /// <param name="parentDistinguishedName">The parent OU to expand, or null for T1 search-base roots.</param>
    /// <returns>Configured root OUs or direct child OUs and computers, or HTTP 403 without file access.</returns>
    [HttpGet]
    [ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
    public IActionResult BrowseDelegationTargets(string? parentDistinguishedName)
    {
        if (!_configurationEditor.CanEdit(User))
        {
            return Forbid();
        }

        return Json(_activeDirectory.BrowseDelegationTargets(parentDistinguishedName).Select(target => new
        {
            target.DistinguishedName,
            target.DisplayName,
            Kind = target.Kind.ToString().ToLowerInvariant()
        }));
    }

    /// <summary>Returns Active Directory domains available in the current forest.</summary>
    [HttpGet]
    [ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
    public IActionResult GetConfigurationDomains()
    {
        return _configurationEditor.CanEdit(User)
            ? Json(_activeDirectory.GetAvailableDomains())
            : Forbid();
    }

    /// <summary>Browses an allowed forest domain's organizational units one level at a time.</summary>
    [HttpGet]
    [ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
    public IActionResult BrowseConfigurationOrganizationalUnits(
        string? domainFqdn,
        string? parentDistinguishedName)
    {
        if (!_configurationEditor.CanEdit(User))
        {
            return Forbid();
        }

        return Json(_activeDirectory
            .BrowseConfigurationOrganizationalUnits(domainFqdn, parentDistinguishedName)
            .Select(target => new
            {
                target.DistinguishedName,
                target.DisplayName,
                Kind = target.Kind.ToString().ToLowerInvariant(),
                target.CanSelect
            }));
    }

    private IActionResult RenderWithSubmittedDelegations(DelegationConfigurationEditModel submitted)
    {
        try
        {
            var viewModel = CreateViewModel(_configurationEditor.Load(User), "delegation");
            viewModel.Delegations = submitted.Delegations;
            EnrichDelegations(viewModel.Delegations);
            viewModel.DelegationConfigHash = submitted.ExpectedHash;
            return View("Index", viewModel);
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "Configuration reload denied for {User}.", User.Identity?.Name);
            return Forbid();
        }
    }

    private IActionResult RenderWithSubmittedJitParameters(JitConfigurationEditModel submitted)
    {
        try
        {
            var viewModel = CreateViewModel(_configurationEditor.Load(User), "jit");
            viewModel.JitParameters = JitConfigurationFormMapper.MergeSubmittedParameters(
                viewModel.JitConfigContent,
                submitted.Parameters);
            viewModel.JitConfigHash = submitted.ExpectedHash;
            return View("Index", viewModel);
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "Configuration reload denied for {User}.", User.Identity?.Name);
            return Forbid();
        }
    }

    private ConfigurationEditorViewModel CreateViewModel(
        ConfigurationEditorSnapshot snapshot,
        string activeTab)
    {
        var viewModel = new ConfigurationEditorViewModel
        {
            JitConfigPath = snapshot.JitConfigPath,
            JitConfigContent = snapshot.JitConfigContent,
            JitConfigHash = snapshot.JitConfigHash,
            JitParameters = JitConfigurationFormMapper.ReadParameters(snapshot.JitConfigContent),
            DelegationConfigPath = snapshot.DelegationConfigPath,
            DelegationConfigContent = snapshot.DelegationConfigContent,
            DelegationConfigHash = snapshot.DelegationConfigHash,
            Delegations = DelegationConfigurationFormMapper.ReadDelegations(
                snapshot.DelegationConfigContent),
            ActiveTab = activeTab
        };

        EnrichDelegations(viewModel.Delegations);
        return viewModel;
    }

    private void EnrichDelegations(IEnumerable<DelegationEditModel> delegations)
    {
        foreach (var adObject in delegations.SelectMany(delegation => delegation.AdObjects))
        {
            var resolved = _activeDirectory.ResolveDelegationAdObject(adObject.SecurityIdentifier);
            if (resolved is not null)
            {
                adObject.DisplayName = resolved.DisplayName;
                adObject.Kind = resolved.Kind;
            }
        }
    }

    private void ResolveSubmittedDelegations(IEnumerable<DelegationEditModel> delegations)
    {
        foreach (var delegation in delegations)
        {
            delegation.ComputerOu = _activeDirectory.ResolveDelegationOrganizationalUnit(
                    delegation.ComputerOu)
                ?? throw new JsonException(
                    $"Active Directory organizational unit '{delegation.ComputerOu}' could not be resolved.");

            foreach (var adObject in delegation.AdObjects)
            {
                var resolved = _activeDirectory.ResolveDelegationAdObject(adObject.SecurityIdentifier)
                    ?? throw new JsonException(
                        $"Active Directory object '{adObject.SecurityIdentifier}' could not be resolved.");
                adObject.SecurityIdentifier = resolved.SecurityIdentifier;
                adObject.DisplayName = resolved.DisplayName;
                adObject.Kind = resolved.Kind;
            }
        }
    }
}
