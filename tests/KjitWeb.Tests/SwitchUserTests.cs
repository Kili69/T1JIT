using System.DirectoryServices.Protocols;
using System.Reflection;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using KjitWeb;
using KjitWeb.Controllers;
using KjitWeb.Models;
using KjitWeb.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ViewFeatures;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Localization;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;
using Xunit;

namespace KjitWeb.Tests;

public sealed class SwitchUserTests : IDisposable
{
    private readonly Mock<ISmartCardAuthenticationService> _smartCard = new();
    private readonly Mock<IAuthenticationService> _authentication = new();
    private readonly ServiceProvider _services;
    private readonly HomeController _controller;
    private readonly DefaultHttpContext _context;

    public SwitchUserTests()
    {
        _services = new ServiceCollection()
            .AddSingleton(_authentication.Object)
            .BuildServiceProvider();
        _context = new DefaultHttpContext { RequestServices = _services };
        _context.Request.Scheme = "https";
        _smartCard.SetupGet(service => service.Enabled).Returns(true);
        var configuration = new ConfigurationBuilder().Build();
        var localizer = new Mock<IStringLocalizer<SharedResource>>();
        localizer.Setup(value => value[It.IsAny<string>()]).Returns((string key) => new LocalizedString(key, key));
        _controller = new HomeController(
            Mock.Of<IActiveDirectoryService>(),
            configuration,
            Mock.Of<IEventLogWriter>(),
            Mock.Of<IEventLogHealthMonitor>(),
            NullLogger<HomeController>.Instance,
            localizer.Object,
            new WindowsCredentialValidator(configuration, NullLogger<WindowsCredentialValidator>.Instance),
            _smartCard.Object)
        {
            ControllerContext = new ControllerContext { HttpContext = _context },
            TempData = new TempDataDictionary(_context, Mock.Of<ITempDataProvider>()),
            Url = Mock.Of<IUrlHelper>()
        };
    }

    [Fact]
    public async Task WindowsIdentityReturnOnlyClearsTheOverrideCookie()
    {
        var result = Assert.IsType<RedirectToActionResult>(await _controller.UseWindowsIdentity());
        Assert.Equal("Index", result.ActionName);
        _authentication.Verify(service => service.SignOutAsync(_context, CookieAuthenticationDefaults.AuthenticationScheme, null), Times.Once);
        _authentication.VerifyNoOtherCalls();
        _smartCard.Verify(service => service.Authenticate(It.IsAny<X509Certificate2>()), Times.Never);
    }

    [Fact]
    public async Task DisabledSmartCardEndpointIsNotAvailable()
    {
        _smartCard.SetupGet(service => service.Enabled).Returns(false);
        Assert.IsType<NotFoundResult>(await _controller.SmartCardSignIn());
        _authentication.VerifyNoOtherCalls();
    }

    [Fact]
    public async Task HttpIsRejectedWithoutTouchingTheExistingSession()
    {
        _context.Request.Scheme = "http";
        var view = Assert.IsType<ViewResult>(await _controller.SmartCardSignIn());
        Assert.Equal("SmartCardHttpsRequired", Assert.IsType<SwitchUserViewModel>(view.Model).ErrorMessage);
        Assert.Equal(400, _context.Response.StatusCode);
        _smartCard.Verify(service => service.Authenticate(It.IsAny<X509Certificate2>()), Times.Never);
        _authentication.VerifyNoOtherCalls();
    }

    [Fact]
    public async Task MissingCertificateFailsClearlyWithoutSwitching()
    {
        var view = Assert.IsType<ViewResult>(await _controller.SmartCardSignIn());
        Assert.Equal("SmartCardCertificateMissing", Assert.IsType<SwitchUserViewModel>(view.Model).ErrorMessage);
        Assert.Equal(403, _context.Response.StatusCode);
        _authentication.VerifyNoOtherCalls();
    }

    [Fact]
    public async Task ForwardedCertificateHeaderIsNotTrustedAsProofOfPossession()
    {
        _context.Request.Headers["X-ARR-ClientCert"] = "untrusted-forwarded-certificate";
        Assert.IsType<ViewResult>(await _controller.SmartCardSignIn());
        Assert.Equal(403, _context.Response.StatusCode);
        _smartCard.Verify(service => service.Authenticate(It.IsAny<X509Certificate2>()), Times.Never);
        _authentication.VerifyNoOtherCalls();
    }

    [Fact]
    public async Task RejectedCertificatePreservesThePreviousSession()
    {
        using var certificate = CreateCertificate();
        _context.Connection.ClientCertificate = certificate;
        _smartCard.Setup(service => service.Authenticate(certificate)).Returns((ClaimsPrincipal?)null);
        var view = Assert.IsType<ViewResult>(await _controller.SmartCardSignIn());
        Assert.Equal("SmartCardSignInRejected", Assert.IsType<SwitchUserViewModel>(view.Model).ErrorMessage);
        Assert.Equal(403, _context.Response.StatusCode);
        _authentication.VerifyNoOtherCalls();
    }

    [Fact]
    public async Task DirectoryFailureIsUnavailableNotASuccessfulFallback()
    {
        using var certificate = CreateCertificate();
        _context.Connection.ClientCertificate = certificate;
        _smartCard.Setup(service => service.Authenticate(certificate)).Throws(new LdapException(81));
        var view = Assert.IsType<ViewResult>(await _controller.SmartCardSignIn());
        Assert.Equal("SmartCardDirectoryUnavailable", Assert.IsType<SwitchUserViewModel>(view.Model).ErrorMessage);
        Assert.Equal(503, _context.Response.StatusCode);
        _authentication.VerifyNoOtherCalls();
    }

    [Theory]
    [InlineData(5)]
    [InlineData(60)]
    public async Task SmartCardSessionUsesMappedIdentityAndNeverOutlivesCertificateOrThirtyMinutes(int validMinutes)
    {
        using var certificate = CreateCertificate(validMinutes);
        _context.Connection.ClientCertificate = certificate;
        var principal = new ClaimsPrincipal(new ClaimsIdentity(
            new[] { new Claim(ClaimTypes.Name, "mapped-admin@contoso.local") }, "SmartCard"));
        _smartCard.Setup(service => service.Authenticate(certificate)).Returns(principal);
        var before = DateTimeOffset.UtcNow;
        var result = Assert.IsType<RedirectToActionResult>(await _controller.SmartCardSignIn());
        Assert.Equal("Index", result.ActionName);
        _authentication.Verify(service => service.SignOutAsync(_context, CookieAuthenticationDefaults.AuthenticationScheme, null), Times.Once);
        _authentication.Verify(service => service.SignInAsync(
            _context,
            CookieAuthenticationDefaults.AuthenticationScheme,
            principal,
            It.Is<AuthenticationProperties>(properties =>
                !properties.IsPersistent
                && properties.AllowRefresh == false
                && properties.ExpiresUtc > before
                && properties.ExpiresUtc <= DateTimeOffset.UtcNow.AddMinutes(30)
                && properties.ExpiresUtc <= new DateTimeOffset(certificate.NotAfter.ToUniversalTime()))), Times.Once);
    }

    [Theory]
    [InlineData(nameof(HomeController.SmartCardSignIn))]
    [InlineData(nameof(HomeController.UseWindowsIdentity))]
    public void IdentityChangingActionsRequirePostAndAntiforgery(string action)
    {
        var method = typeof(HomeController).GetMethod(action)!;
        Assert.NotNull(method.GetCustomAttribute<HttpPostAttribute>());
        Assert.NotNull(method.GetCustomAttribute<ValidateAntiForgeryTokenAttribute>());
    }

    [Fact]
    public async Task ExistingPasswordFormStillRejectsMissingPasswordWithoutSwitching()
    {
        var result = Assert.IsType<ViewResult>(await _controller.SwitchUser(new SwitchUserViewModel { Username = "user" }));
        Assert.NotNull(Assert.IsType<SwitchUserViewModel>(result.Model).ErrorMessage);
        _authentication.VerifyNoOtherCalls();
    }

    public void Dispose() => _services.Dispose();

    private static X509Certificate2 CreateCertificate(int validMinutes = 60)
    {
        using var key = RSA.Create(2048);
        var request = new CertificateRequest("CN=TLS-test-only", key, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
        return request.CreateSelfSigned(DateTimeOffset.UtcNow.AddMinutes(-1), DateTimeOffset.UtcNow.AddMinutes(validMinutes));
    }
}
