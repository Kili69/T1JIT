using System.Security.Claims;
using System.Security.Cryptography;
using System.Security.Principal;
using System.Text;
using System.Text.Json;

namespace KjitWeb.Services;

internal enum ConfigurationFileKind
{
    Jit,
    Delegation
}

internal sealed record ConfigurationEditorSnapshot(
    string JitConfigPath,
    string JitConfigContent,
    string JitConfigHash,
    string DelegationConfigPath,
    string DelegationConfigContent,
    string DelegationConfigHash);

internal sealed class ConfigurationEditConflictException : InvalidOperationException
{
    public ConfigurationEditConflictException()
        : base("The configuration file changed after it was loaded.")
    {
    }
}

/// <summary>Authorizes and edits the JIT configuration files under the current Windows user token.</summary>
public sealed class ConfigurationEditorService
{
    private static readonly JsonDocumentOptions JsonOptions = new()
    {
        AllowTrailingCommas = false,
        CommentHandling = JsonCommentHandling.Disallow
    };

    private readonly IConfiguration _configuration;
    private readonly ILogger<ConfigurationEditorService> _logger;

    /// <summary>Initializes the configuration editor service.</summary>
    /// <param name="configuration">Provides the configured JIT configuration path.</param>
    /// <param name="logger">Records access-check and save outcomes.</param>
    public ConfigurationEditorService(
        IConfiguration configuration,
        ILogger<ConfigurationEditorService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    internal bool CanEdit(ClaimsPrincipal user)
    {
        var identity = GetWindowsIdentity(user);
        if (identity is null)
        {
            return false;
        }

        try
        {
            return WindowsIdentity.RunImpersonated(identity.AccessToken, () =>
            {
                var paths = ResolvePaths();
                VerifyReadWriteAccess(paths.JitConfigPath);
                VerifyReadWriteAccess(paths.DelegationConfigPath);
                return true;
            });
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogDebug(ex, "Configuration access denied for {User}.", user.Identity?.Name);
            return false;
        }
        catch (IOException ex)
        {
            _logger.LogWarning(ex, "Configuration access check failed for {User}.", user.Identity?.Name);
            return false;
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Configuration paths could not be resolved for {User}.", user.Identity?.Name);
            return false;
        }
    }

    internal ConfigurationEditorSnapshot Load(ClaimsPrincipal user)
    {
        var identity = RequireWindowsIdentity(user);
        return WindowsIdentity.RunImpersonated(identity.AccessToken, () =>
        {
            var paths = ResolvePaths();
            VerifyReadWriteAccess(paths.JitConfigPath);
            VerifyReadWriteAccess(paths.DelegationConfigPath);
            return ReadSnapshot(paths);
        });
    }

    internal ConfigurationEditorSnapshot Save(
        ClaimsPrincipal user,
        ConfigurationFileKind fileKind,
        string content,
        string expectedHash)
    {
        var identity = RequireWindowsIdentity(user);
        return WindowsIdentity.RunImpersonated(identity.AccessToken, () =>
        {
            var paths = ResolvePaths();
            VerifyReadWriteAccess(paths.JitConfigPath);
            VerifyReadWriteAccess(paths.DelegationConfigPath);

            var targetPath = fileKind == ConfigurationFileKind.Jit
                ? paths.JitConfigPath
                : paths.DelegationConfigPath;
            EnsureUnchanged(targetPath, expectedHash);
            var candidateDelegationPath = Validate(fileKind, content);
            if (candidateDelegationPath is not null)
            {
                VerifyReadWriteAccess(candidateDelegationPath);
            }

            WriteContent(targetPath, content);

            _logger.LogInformation(
                "{ConfigurationType} configuration saved by {User}.",
                fileKind,
                user.Identity?.Name);

            return ReadSnapshot(ResolvePaths());
        });
    }

    private static WindowsIdentity? GetWindowsIdentity(ClaimsPrincipal user)
    {
        return user.Identities
            .OfType<WindowsIdentity>()
            .FirstOrDefault(identity => identity.IsAuthenticated);
    }

    private static WindowsIdentity RequireWindowsIdentity(ClaimsPrincipal user)
    {
        return GetWindowsIdentity(user)
            ?? throw new UnauthorizedAccessException(
                "A Windows access token is required to edit configuration files.");
    }

    private (string JitConfigPath, string DelegationConfigPath) ResolvePaths()
    {
        var configuredPath = JitConfigPathResolver.Resolve(_configuration);
        var jitConfiguration = string.IsNullOrWhiteSpace(configuredPath)
            ? new JitConfiguration()
            : new JitConfiguration(configuredPath);

        if (string.IsNullOrWhiteSpace(jitConfiguration.DelegationConfigPath))
        {
            throw new InvalidOperationException(
                "JIT.config does not define a DelegationConfigPath.");
        }

        return (jitConfiguration.JitConfigPath, jitConfiguration.DelegationConfigPath);
    }

    private static void VerifyReadWriteAccess(string path)
    {
        using var stream = new FileStream(
            path,
            FileMode.Open,
            FileAccess.ReadWrite,
            FileShare.ReadWrite | FileShare.Delete);
    }

    private static ConfigurationEditorSnapshot ReadSnapshot(
        (string JitConfigPath, string DelegationConfigPath) paths)
    {
        var jitBytes = File.ReadAllBytes(paths.JitConfigPath);
        var delegationBytes = File.ReadAllBytes(paths.DelegationConfigPath);

        return new ConfigurationEditorSnapshot(
            paths.JitConfigPath,
            DecodeText(jitBytes),
            Convert.ToHexString(SHA256.HashData(jitBytes)),
            paths.DelegationConfigPath,
            DecodeText(delegationBytes),
            Convert.ToHexString(SHA256.HashData(delegationBytes)));
    }

    private static string DecodeText(byte[] bytes)
    {
        using var stream = new MemoryStream(bytes);
        using var reader = new StreamReader(
            stream,
            Encoding.UTF8,
            detectEncodingFromByteOrderMarks: true);
        return reader.ReadToEnd();
    }

    private static void EnsureUnchanged(string path, string expectedHash)
    {
        byte[] submittedHash;
        try
        {
            submittedHash = Convert.FromHexString(expectedHash);
        }
        catch (FormatException)
        {
            throw new ConfigurationEditConflictException();
        }

        var currentHash = SHA256.HashData(File.ReadAllBytes(path));
        if (submittedHash.Length != currentHash.Length
            || !CryptographicOperations.FixedTimeEquals(submittedHash, currentHash))
        {
            throw new ConfigurationEditConflictException();
        }
    }

    private static string? Validate(ConfigurationFileKind fileKind, string content)
    {
        if (string.IsNullOrWhiteSpace(content))
        {
            throw new JsonException("Configuration content must not be empty.");
        }

        if (fileKind == ConfigurationFileKind.Delegation)
        {
            try
            {
                _ = global::KjitCore.KjitCore.ParseDelegationConfiguration(content);
                return null;
            }
            catch (Exception ex) when (ex is InvalidOperationException or ArgumentException)
            {
                throw new JsonException(ex.Message, ex);
            }
        }

        using var document = JsonDocument.Parse(content, JsonOptions);
        return ValidateJitConfiguration(document.RootElement);
    }

    private static string ValidateJitConfiguration(JsonElement root)
    {
        if (root.ValueKind != JsonValueKind.Object)
        {
            throw new JsonException("JIT configuration must be a JSON object.");
        }

        if (!HasNonEmptyString(root, "EventLogSource")
            && !HasNonEmptyString(root, "EventSource"))
        {
            throw new JsonException(
                "JIT configuration must contain a non-empty EventLogSource or EventSource.");
        }

        if (!TryGetProperty(root, "DelegationConfigPath", out var delegationPath)
            || delegationPath.ValueKind != JsonValueKind.String
            || string.IsNullOrWhiteSpace(delegationPath.GetString()))
        {
            throw new JsonException(
                "JIT configuration must contain a non-empty DelegationConfigPath.");
        }

        return delegationPath.GetString()!.Trim();
    }

    private static bool HasNonEmptyString(JsonElement root, string propertyName)
    {
        return TryGetProperty(root, propertyName, out var value)
            && value.ValueKind == JsonValueKind.String
            && !string.IsNullOrWhiteSpace(value.GetString());
    }

    private static bool TryGetProperty(
        JsonElement root,
        string propertyName,
        out JsonElement value)
    {
        foreach (var property in root.EnumerateObject())
        {
            if (property.Name.Equals(propertyName, StringComparison.OrdinalIgnoreCase))
            {
                value = property.Value;
                return true;
            }
        }

        value = default;
        return false;
    }

    private static void WriteContent(string path, string content)
    {
        using var stream = new FileStream(
            path,
            FileMode.Create,
            FileAccess.Write,
            FileShare.Read,
            bufferSize: 4096,
            FileOptions.WriteThrough);
        using var writer = new StreamWriter(stream, new UTF8Encoding(false));
        writer.Write(content);
        writer.Flush();
        stream.Flush(flushToDisk: true);
    }
}
