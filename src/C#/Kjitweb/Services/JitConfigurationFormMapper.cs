using KjitCore.Models;
using KjitWeb.Models;
using CoreParameterKind = KjitCore.Models.JitConfigurationParameterKind;
using WebParameterKind = KjitWeb.Models.JitConfigurationParameterKind;

namespace KjitWeb.Services;

/// <summary>Maps top-level JIT configuration properties to typed form fields and back.</summary>
internal static class JitConfigurationFormMapper
{
    private static readonly HashSet<string> ReadOnlyParameterNames = new(
        [
            "ConfigScriptVersion",
            "ElevateEventID",
            "EventSource",
            "EventLog",
            "GroupManagedServiceAccountName",
            "DomainSeparator",
            "EnableDelegation",
            "EnableMultiDomainSupport"
        ],
        StringComparer.OrdinalIgnoreCase);

    private static readonly HashSet<string> AdvancedParameterNames = new(
        [
            "ConfigScriptVersion",
            "AdminPreFix",
            "OU",
            "ElevateEventID",
            "Tier0ServerGroupName",
            "LDAPT0Computers",
            "LDAPT0ComputerPath",
            "LDAPT1Computers",
            "EventSource",
            "EventLog",
            "DebugLogPath",
            "GroupManagementTaskRerun",
            "GroupManagedServiceAccountName",
            "DelegationConfigPath",
            "EnableDelegation",
            "EnableMultiDomainSupport",
            "DomainSeparator"
        ],
        StringComparer.OrdinalIgnoreCase);

    internal static List<JitConfigurationParameterEditModel> ReadParameters(string content)
    {
        return global::KjitCore.KjitCore.ParseJitConfigurationParameters(content)
            .Select(parameter => new JitConfigurationParameterEditModel
            {
                Name = parameter.Name,
                Kind = (WebParameterKind)parameter.Kind,
                Value = parameter.Value,
                IsReadOnly = ReadOnlyParameterNames.Contains(parameter.Name),
                IsAdvanced = AdvancedParameterNames.Contains(parameter.Name)
            })
            .ToList();
    }

    internal static string WriteParameters(
        string originalContent,
        IReadOnlyCollection<JitConfigurationParameterEditModel> submittedParameters)
    {
        var parameters = submittedParameters.Select(parameter => new JitConfigurationParameter
        {
            Name = parameter.Name,
            Kind = (CoreParameterKind)parameter.Kind,
            Value = parameter.Value ?? string.Empty
        }).ToList();
        return global::KjitCore.KjitCore.UpdateJitConfigurationParameters(
            originalContent,
            parameters,
            ReadOnlyParameterNames.ToList());
    }

    internal static List<JitConfigurationParameterEditModel> MergeSubmittedParameters(
        string originalContent,
        IReadOnlyCollection<JitConfigurationParameterEditModel> submittedParameters)
    {
        var parameters = ReadParameters(originalContent);
        var submittedByName = submittedParameters
            .GroupBy(parameter => parameter.Name, StringComparer.Ordinal)
            .Where(group => group.Count() == 1)
            .ToDictionary(group => group.Key, group => group.Single(), StringComparer.Ordinal);

        foreach (var parameter in parameters.Where(parameter => !parameter.IsReadOnly))
        {
            if (submittedByName.TryGetValue(parameter.Name, out var submitted))
            {
                parameter.Value = submitted.Value;
            }
        }

        return parameters;
    }

}