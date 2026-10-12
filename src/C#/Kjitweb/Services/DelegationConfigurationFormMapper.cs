using System.Text.Json;
using KjitCore.Models;
using KjitWeb.Models;

namespace KjitWeb.Services;

/// <summary>Maps delegation configuration entries to typed form fields and back.</summary>
internal static class DelegationConfigurationFormMapper
{
    internal static List<DelegationEditModel> ReadDelegations(string content)
    {
        try
        {
            return global::KjitCore.KjitCore.ParseDelegationConfiguration(content)
                .Delegations
                .Select(entry => new DelegationEditModel
                {
                    ComputerOu = entry.ComputerOU,
                    AdObjects = entry.ADObject.Select(securityIdentifier =>
                        new DelegationAdObjectEditModel
                        {
                            SecurityIdentifier = securityIdentifier,
                            DisplayName = securityIdentifier,
                            Kind = DelegationAdObjectKind.Unknown
                        }).ToList()
                })
                .ToList();
        }
        catch (Exception ex) when (ex is InvalidOperationException or ArgumentException)
        {
            throw new JsonException(ex.Message, ex);
        }
    }

    internal static string WriteDelegations(IReadOnlyCollection<DelegationEditModel> delegations)
    {
        try
        {
            var configuration = new DelegationConfigurationObject(
                delegations.Select(delegation => new DelegationEntry(
                    delegation.ComputerOu,
                    delegation.AdObjects.Select(adObject => adObject.SecurityIdentifier))));
            return global::KjitCore.KjitCore.SerializeDelegationConfiguration(configuration);
        }
        catch (Exception ex) when (ex is InvalidOperationException or ArgumentException)
        {
            throw new JsonException(ex.Message, ex);
        }
    }
}