// Author: Andreas Lucas (aka Kili)
// Documentation update: 0.2.20260926.6
// History: Existing implementation and inline operational notes are preserved.

using KjitWeb.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Localization;
using Microsoft.AspNetCore.Server.HttpSys;
using Microsoft.Extensions.Hosting.WindowsServices;
using System.Diagnostics;
using System.Globalization;
using System.Text.RegularExpressions;
using System.Security.Principal;

try
{
    // Create the web host and load configuration from appsettings, environment and arguments.
    var builder = WebApplication.CreateBuilder(args);
    var mutualTlsOptions = builder.Configuration
        .GetSection(MutualTlsOptions.SectionName)
        .Get<MutualTlsOptions>() ?? new MutualTlsOptions();
    var requiredMutualTlsEkuOids = mutualTlsOptions.RequiredEkuOids
        .Where(oid => !string.IsNullOrWhiteSpace(oid))
        .Select(oid => oid.Trim())
        .Distinct(StringComparer.Ordinal)
        .ToArray();

    if (mutualTlsOptions.Enabled)
    {
        if (requiredMutualTlsEkuOids.Length == 0)
        {
            throw new InvalidOperationException(
                "MutualTls:RequiredEkuOids must contain at least one EKU OID when mutual TLS is enabled.");
        }

        var invalidEkuOid = requiredMutualTlsEkuOids.FirstOrDefault(
            oid => !Regex.IsMatch(oid, @"^\d+(\.\d+)+$", RegexOptions.CultureInvariant));
        if (invalidEkuOid is not null)
        {
            throw new InvalidOperationException(
                $"MutualTls:RequiredEkuOids contains an invalid OID: '{invalidEkuOid}'.");
        }
    }

    // KjitWeb is hosted on HTTP.sys (not Kestrel) so Windows Authentication (Negotiate/Kerberos/
    // NTLM) is performed in kernel mode by the OS, exactly like IIS does. The managed Negotiate
    // authentication handler used with Kestrel requires the process itself to hold usable
    // Kerberos/NTLM keys for the computer's own identity, which only LocalSystem or a domain
    // account with an SPN can do; NetworkService cannot, causing all logins to fail (see
    // CHANGELOG). HTTP.sys instead authenticates the connection before the request reaches the
    // app and hands us an already-authenticated Windows identity, so NetworkService works fine.
    builder.WebHost.UseHttpSys(options =>
    {
        options.Authentication.Schemes = AuthenticationSchemes.Negotiate | AuthenticationSchemes.NTLM;
        // Anonymous connections must be allowed at the HTTP.sys level: KjitWeb also supports a
        // cookie-based "switched user" identity and a Basic-Auth fallback for remote clients,
        // both handled by the ASP.NET Core authentication/authorization pipeline further down,
        // not by HTTP.sys itself. Rejecting anonymous connections here would prevent those
        // requests from ever reaching the app.
        options.Authentication.AllowAnonymous = true;
        options.ClientCertificateMethod = mutualTlsOptions.Enabled
            ? ClientCertificateMethod.AllowCertificate
            : ClientCertificateMethod.NoCertificate;
    });

    // Enable proper lifetime handling when the app is hosted as a Windows Service.
    builder.Host.UseWindowsService(options =>
    {
        options.ServiceName = builder.Configuration["WindowsService:ServiceName"] ?? "KjitWeb";
    });

    // Use a policy scheme so switched users can persist via cookie while other requests
    // continue to use integrated Windows authentication.
    builder.Services.AddAuthentication(options =>
        {
            options.DefaultScheme = "AppAuthentication";
            options.DefaultAuthenticateScheme = "AppAuthentication";
            options.DefaultChallengeScheme = HttpSysDefaults.AuthenticationScheme;
        })
        .AddPolicyScheme("AppAuthentication", "Application authentication", options =>
        {
            options.ForwardDefaultSelector = context =>
            {
                var hasSwitchUserCookie = context.Request.Cookies.ContainsKey("KjitWeb.SwitchUser");
                return hasSwitchUserCookie
                    ? CookieAuthenticationDefaults.AuthenticationScheme
                    : HttpSysDefaults.AuthenticationScheme;
            };
        })
        .AddCookie(CookieAuthenticationDefaults.AuthenticationScheme, options =>
        {
            options.Cookie.Name = "KjitWeb.SwitchUser";
            options.Cookie.HttpOnly = true;
            options.Cookie.SameSite = SameSiteMode.Lax;
            // SwitchUser shows an HTML form, so cookie-auth redirects go there correctly.
            options.LoginPath = "/Home/SwitchUser";
            options.AccessDeniedPath = "/Home/Index";
            options.ExpireTimeSpan = TimeSpan.FromHours(8);
            options.SlidingExpiration = true;
            // Do NOT redirect 401 responses to login page for non-cookie challenges.
            // The OnRedirectToLogin event fires only when the Cookie scheme itself challenges.
        })
        // Kerberos/NTLM negotiation itself happens in the kernel via HTTP.sys (configured
        // above with UseHttpSys); the HttpSysDefaults.AuthenticationScheme referenced here just
        // lets ASP.NET Core surface the already-negotiated Windows identity to the app. No
        // explicit .AddScheme(...) registration is required or possible for this scheme.
        .AddScheme<AuthenticationSchemeOptions, BasicAuthenticationHandler>(
            "BasicAuthentication", options => { });

    // Require authentication by default unless explicitly overridden on an endpoint.
    builder.Services.AddAuthorization(options =>
    {
        options.FallbackPolicy = new AuthorizationPolicyBuilder()
            .RequireAuthenticatedUser()
            .Build();
    });

    // Register MVC + app services.
    builder.Services.AddLocalization(options => options.ResourcesPath = "Resources");
    builder.Services.AddControllersWithViews();
    builder.Services.AddScoped<IActiveDirectoryService, ActiveDirectoryService>();
    builder.Services.AddSingleton<IEventLogWriter, EventLogWriter>();
    builder.Services.AddSingleton<DebugLogFileWriter>();
    builder.Services.AddSingleton<IConnectionAuditLogger, ConnectionAuditLogger>();
    builder.Services.AddSingleton<WindowsCredentialValidator>();
    // The event log health monitor is registered once as a singleton so that the background scan
    // loop (IHostedService) and the HTTP-facing IEventLogHealthMonitor share the same instance/state.
    builder.Services.AddSingleton<EventLogHealthMonitor>();
    builder.Services.AddSingleton<IEventLogHealthMonitor>(sp => sp.GetRequiredService<EventLogHealthMonitor>());
    builder.Services.AddHostedService(sp => sp.GetRequiredService<EventLogHealthMonitor>());
    builder.Logging.Services.AddSingleton<ILoggerProvider, DebugFileLoggerProvider>();

    // Configure localization with supported cultures and a default culture.
    var supportedCultures = new[]
    {
        //current supported cultures, can be extended in the future as needed. 
        // Culture-specific resources will be used if available, otherwise fallback to default resources.
        new CultureInfo("en"),
        new CultureInfo("de")
    };

    // Set default culture to English. 
    // This will be used if no culture can be resolved from the request or if a specific culture's resources are not available.
    builder.Services.Configure<RequestLocalizationOptions>(options =>
    {
        options.DefaultRequestCulture = new RequestCulture("en");
        options.SupportedCultures = supportedCultures;
        options.SupportedUICultures = supportedCultures;
    });

    // Build the app.
    var app = builder.Build();

    // Force startup validation so service terminates immediately on invalid JIT.config.
    string? resolvedDebugLogPath = null;
    using (var startupScope = app.Services.CreateScope())
    {
        // Resolve critical services to trigger any configuration or connectivity issues at startup instead of runtime.
        _ = startupScope.ServiceProvider.GetRequiredService<IActiveDirectoryService>();
        _ = startupScope.ServiceProvider.GetRequiredService<IEventLogWriter>();
        var debugLogFileWriter = startupScope.ServiceProvider.GetRequiredService<DebugLogFileWriter>();
        resolvedDebugLogPath = debugLogFileWriter.LogFilePath;
    }

    if (WindowsServiceHelpers.IsWindowsService() && !string.IsNullOrWhiteSpace(resolvedDebugLogPath))
    {
        TryWriteStartupInformationToApplicationLog($"KjitWeb started. Debug log path: {resolvedDebugLogPath}");
    }

    // If we reach this point, the app has started successfully and any critical configuration issues would have been caught by now.
    var requestLocalizationOptions = app.Services
        .GetRequiredService<Microsoft.Extensions.Options.IOptions<RequestLocalizationOptions>>()
        .Value;

    // Localization must run early so controllers/views resolve the correct culture.
    if (mutualTlsOptions.Enabled)
    {
        app.Use(async (context, next) =>
        {
            var logger = context.RequestServices
                .GetRequiredService<ILoggerFactory>()
                .CreateLogger("MutualTls");
            var remoteAddress = context.Connection.RemoteIpAddress?.ToString() ?? "unknown-address";

            // HTTP.sys negotiates the client certificate but, unlike Kestrel, does not offer a
            // hook to validate it during the TLS handshake, so the chain/EKU checks that used to
            // run in Kestrel's ClientCertificateValidation callback are performed here instead.
            var clientCertificate = context.Request.IsHttps
                ? await context.Connection.GetClientCertificateAsync()
                : null;
            if (clientCertificate is null)
            {
                logger.LogWarning(
                    "Rejected request from {RemoteAddress} because mutual TLS is enabled but no HTTPS client certificate is available.",
                    remoteAddress);
                context.Response.StatusCode = StatusCodes.Status403Forbidden;
                return;
            }

            using var chain = new System.Security.Cryptography.X509Certificates.X509Chain
            {
                ChainPolicy =
                {
                    RevocationMode = mutualTlsOptions.CheckCertificateRevocation
                        ? System.Security.Cryptography.X509Certificates.X509RevocationMode.Online
                        : System.Security.Cryptography.X509Certificates.X509RevocationMode.NoCheck,
                    RevocationFlag = System.Security.Cryptography.X509Certificates.X509RevocationFlag.ExcludeRoot,
                }
            };
            var policyErrors = chain.Build(clientCertificate)
                ? System.Net.Security.SslPolicyErrors.None
                : System.Net.Security.SslPolicyErrors.RemoteCertificateChainErrors;

            if (!MutualTlsCertificateValidator.Validate(clientCertificate, policyErrors, requiredMutualTlsEkuOids))
            {
                logger.LogWarning(
                    "Rejected request from {RemoteAddress} because the HTTPS client certificate failed mutual TLS validation.",
                    remoteAddress);
                context.Response.StatusCode = StatusCodes.Status403Forbidden;
                return;
            }

            await next();
        });
    }

    app.UseRequestLocalization(requestLocalizationOptions);
    // Use HSTS and HTTPS redirection in production for better security, but allow HTTP in development and service modes for flexibility.
    if (!app.Environment.IsDevelopment())
    {
        // Production safety defaults.
        app.UseExceptionHandler("/Home/Error");
        app.UseHsts();
    }
    // In service mode, HTTPS may not be used if the service is behind a reverse proxy that handles TLS termination.
    var enableHttpsRedirection = builder.Configuration.GetValue<bool?>("Hosting:UseHttpsRedirection")
        ?? (!app.Environment.IsDevelopment() && !WindowsServiceHelpers.IsWindowsService());

    if (enableHttpsRedirection)
    {
        // Optional in service mode: can be disabled when only HTTP termination is used.
        app.UseHttpsRedirection();
    }

    // Serve static files (e.g. CSS, JS, images).
    app.UseStaticFiles();

    // Standard ASP.NET Core request pipeline.
    app.UseRouting();
    app.Use(async (context, next) =>
    {
        try
        {
            await next();
        }
        catch (Exception ex)
        {
            var logger = context.RequestServices
                .GetRequiredService<ILoggerFactory>()
                .CreateLogger("UnhandledRequestException");
            logger.LogError(
                ex,
                "Unhandled exception while processing {Method} {Path} for user {User}",
                context.Request.Method,
                context.Request.Path,
                context.User?.Identity?.Name ?? "unknown-user");
            throw;
        }
    });
    // Authentication must come before authorization, and both must come before endpoint routing.
    app.UseAuthentication();
    app.Use(async (context, next) =>
    {
        var user = context.User;
        if (user?.Identity?.IsAuthenticated == true)
        {
            var connectionAuditLogger = context.RequestServices.GetRequiredService<IConnectionAuditLogger>();
            connectionAuditLogger.LogConnection(
                user.Identity?.Name,
                context.Connection.RemoteIpAddress?.ToString());
        }

        await next();
    });
    app.UseAuthorization();

    app.MapGet("/images/kjitlogo.png", (IWebHostEnvironment environment) =>
            Results.File(
                Path.Combine(environment.ContentRootPath, "kjitlogo.png"),
                "image/png"))
        .AllowAnonymous();

    app.MapControllerRoute(
        name: "default",
        pattern: "{controller=Home}/{action=Index}/{id?}");

    app.Run();
}
catch (Exception ex)
{
    // Ensure startup failures are visible in Windows Application log for service troubleshooting.
    TryWriteStartupErrorToApplicationLog(ex);
    throw;
}

// Records a fatal startup exception in the local Windows Application event log with event ID 5000.
// Event-log failures are suppressed so they cannot replace the original startup failure. Exception
// details can contain sensitive configuration or path data and must remain in the administrative log.
static void TryWriteStartupErrorToApplicationLog(Exception ex)
{
    TryWriteToApplicationEventLog($"KjitWeb startup failed. {ex}", EventLogEntryType.Error, 5000);
}

// Records a non-sensitive informational startup message in the local Windows Application event log
// with event ID 5001. Event-log failures are intentionally suppressed.
static void TryWriteStartupInformationToApplicationLog(string message)
{
    TryWriteToApplicationEventLog(message, EventLogEntryType.Information, 5001);
}

// Writes an event through the KjitWeb source and falls back to the standard .NET Runtime source.
// Creating the source can require administrative rights and modifies machine-wide registration.
// All failures are suppressed; callers must not include credentials or other secrets in the message.
static void TryWriteToApplicationEventLog(string message, EventLogEntryType entryType, int eventId)
{
    const string sourceName = "KjitWeb";
    const string fallbackSourceName = ".NET Runtime";

    try
    {
        if (!EventLog.SourceExists(sourceName))
        {
            // Creating a custom source may require elevated privileges.
            var sourceData = new EventSourceCreationData(sourceName, "Application");
            EventLog.CreateEventSource(sourceData);
        }

        EventLog.WriteEntry(sourceName, message, entryType, eventId);
        return;
    }
    catch
    {
        // Fallback to a standard source if custom source creation/write is not permitted.
    }

    try
    {
        EventLog.WriteEntry(fallbackSourceName, message, entryType, eventId);
    }
    catch
    {
        // Do not mask original startup exception.
    }
}
