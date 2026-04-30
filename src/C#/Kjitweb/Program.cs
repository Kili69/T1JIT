using KjitWeb.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.Negotiate;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Localization;
using Microsoft.AspNetCore.Server.Kestrel.Core;
using Microsoft.Extensions.Hosting.WindowsServices;
using System.Diagnostics;
using System.Globalization;
using System.Security.Principal;

try
{
    // Create the web host and load configuration from appsettings, environment and arguments.
    var builder = WebApplication.CreateBuilder(args);

    // Negotiate/NTLM handshakes are connection-oriented and can fail with HTTP/2 multiplexing.
    // Force HTTP/1.1 to prevent interleaved anonymous/authenticated requests on one connection.
    builder.WebHost.ConfigureKestrel(options =>
    {
        options.ConfigureEndpointDefaults(listenOptions =>
        {
            listenOptions.Protocols = HttpProtocols.Http1;
        });
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
            options.DefaultChallengeScheme = NegotiateDefaults.AuthenticationScheme;
        })
        .AddPolicyScheme("AppAuthentication", "Application authentication", options =>
        {
            options.ForwardDefaultSelector = context =>
            {
                var hasSwitchUserCookie = context.Request.Cookies.ContainsKey("KjitWeb.SwitchUser");
                return hasSwitchUserCookie
                    ? CookieAuthenticationDefaults.AuthenticationScheme
                    : NegotiateDefaults.AuthenticationScheme;
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
    // Use Kerberos as primary authentication (prefer Kerberos over NTLM).
    // Kerberos provides mutual authentication, encryption, and better security than NTLM.
        .AddNegotiate(options =>
        {
            // Persist Kerberos credentials for ticket reuse and performance.
            options.PersistKerberosCredentials = true;
            // Disable NTLM persistence; only use NTLM as fallback if Kerberos unavailable.
            options.PersistNtlmCredentials = false;
        })
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
    // Gracefully handle rare Negotiate handshake interleaving errors from remote clients.
    app.Use(async (context, next) =>
    {
        try
        {
            await next();
        }
        catch (InvalidOperationException ex) when (IsNegotiateHandshakeInterleaving(ex))
        {
            var logger = context.RequestServices
                .GetRequiredService<ILoggerFactory>()
                .CreateLogger("NegotiateHandshake");
            logger.LogWarning(ex, "Negotiate handshake interleaving detected for {Path}. Returning 401.", context.Request.Path);

            if (!context.Response.HasStarted)
            {
                context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                context.Response.Headers.WWWAuthenticate = NegotiateDefaults.AuthenticationScheme;
            }
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

// This method attempts to write startup exceptions to the Windows Application event log under a custom source. If that fails (e.g. due to permissions), it falls back to a standard source. Any exceptions during logging are swallowed to avoid masking the original startup exception.
// This ensures that critical startup issues (like misconfiguration or connectivity problems) are recorded in the event log for administrators to diagnose, even if the service fails to start properly.
// Note: Writing to the event log may require elevated permissions, so this method is designed to fail gracefully without throwing additional exceptions if logging is not possible.
// The event ID 5000 is chosen to be distinct and easily identifiable as a KjitWeb startup error in the logs.
// The log message includes the full exception details to aid in troubleshooting.
// The fallback to the ".NET Runtime" source is a common practice when custom source creation is not permitted, as it is a standard source that should exist on all Windows systems.
// This method is static and self-contained to ensure it can be called from the catch block without relying on any services or state that may not be available during startup failure scenarios.
// By logging startup errors to the event log, administrators can quickly identify and address issues that prevent the service from running, improving reliability and maintainability.
static void TryWriteStartupErrorToApplicationLog(Exception ex)
{
    TryWriteToApplicationEventLog($"KjitWeb startup failed. {ex}", EventLogEntryType.Error, 5000);
}

static void TryWriteStartupInformationToApplicationLog(string message)
{
    TryWriteToApplicationEventLog(message, EventLogEntryType.Information, 5001);
}

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

static bool IsNegotiateHandshakeInterleaving(Exception ex)
{
    return ex.Message.Contains(
        "An anonymous request was received in between authentication handshake requests.",
        StringComparison.OrdinalIgnoreCase);
}
