namespace KjitCore.Abstractions;

public interface IIdentityNormalizer
{
    string NormalizeServerName(string value, string? defaultDomain = null);
}
