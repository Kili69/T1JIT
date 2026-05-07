namespace KjitCore.Abstractions;

public interface IDistinguishedNameService
{
    string? ConvertDomainDnToDnsName(string distinguishedName);
}
