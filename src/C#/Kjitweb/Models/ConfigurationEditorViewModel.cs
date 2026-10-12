namespace KjitWeb.Models;

/// <summary>Contains both editable configuration documents and their concurrency tokens.</summary>
public sealed class ConfigurationEditorViewModel
{
    /// <summary>Gets or sets the JIT configuration file path.</summary>
    public string JitConfigPath { get; set; } = string.Empty;

    /// <summary>Gets or sets the editable JIT configuration JSON.</summary>
    public string JitConfigContent { get; set; } = string.Empty;

    /// <summary>Gets or sets the hash of the loaded JIT configuration.</summary>
    public string JitConfigHash { get; set; } = string.Empty;

    /// <summary>Gets or sets the individually editable JIT configuration parameters.</summary>
    public List<JitConfigurationParameterEditModel> JitParameters { get; set; } = [];

    /// <summary>Gets or sets the delegation configuration file path.</summary>
    public string DelegationConfigPath { get; set; } = string.Empty;

    /// <summary>Gets or sets the editable delegation configuration JSON.</summary>
    public string DelegationConfigContent { get; set; } = string.Empty;

    /// <summary>Gets or sets the hash of the loaded delegation configuration.</summary>
    public string DelegationConfigHash { get; set; } = string.Empty;

    /// <summary>Gets or sets the individually editable delegation entries.</summary>
    public List<DelegationEditModel> Delegations { get; set; } = [];

    /// <summary>Gets or sets the tab selected when the page is rendered.</summary>
    public string ActiveTab { get; set; } = "jit";

    /// <summary>Gets or sets the localized success message shown after saving.</summary>
    public string? SuccessMessage { get; set; }
}

/// <summary>Contains one submitted configuration document and its concurrency token.</summary>
public sealed class ConfigurationFileEditModel
{
    /// <summary>Gets or sets the submitted JSON content.</summary>
    public string Content { get; set; } = string.Empty;

    /// <summary>Gets or sets the hash of the file version that was edited.</summary>
    public string ExpectedHash { get; set; } = string.Empty;
}

/// <summary>Identifies the Active Directory object type shown in the delegation editor.</summary>
public enum DelegationAdObjectKind
{
    /// <summary>The object could not be resolved in Active Directory.</summary>
    Unknown,

    /// <summary>An Active Directory user.</summary>
    User,

    /// <summary>An Active Directory group.</summary>
    Group
}

/// <summary>Contains one Active Directory object assigned to a delegation.</summary>
public sealed class DelegationAdObjectEditModel
{
    /// <summary>Gets or sets the security identifier persisted in the delegation file.</summary>
    public string SecurityIdentifier { get; set; } = string.Empty;

    /// <summary>Gets or sets the directory-derived display name.</summary>
    public string DisplayName { get; set; } = string.Empty;

    /// <summary>Gets or sets the directory-derived object type.</summary>
    public DelegationAdObjectKind Kind { get; set; }
}

/// <summary>Identifies a directory target available for a delegation.</summary>
public enum DelegationTargetKind
{
    /// <summary>An Active Directory organizational unit.</summary>
    OrganizationalUnit,

    /// <summary>An Active Directory computer.</summary>
    Computer
}

/// <summary>Contains one Active Directory target offered by the delegation picker.</summary>
public sealed class DelegationTargetEditModel
{
    /// <summary>Gets or sets the target distinguished name persisted in the delegation file.</summary>
    public string DistinguishedName { get; set; } = string.Empty;

    /// <summary>Gets or sets the directory-derived display name.</summary>
    public string DisplayName { get; set; } = string.Empty;

    /// <summary>Gets or sets the directory target type.</summary>
    public DelegationTargetKind Kind { get; set; }

    /// <summary>Gets or sets whether the target can be selected rather than only expanded.</summary>
    public bool CanSelect { get; set; } = true;
}

/// <summary>Contains one editable OU delegation and its assigned Active Directory objects.</summary>
public sealed class DelegationEditModel
{
    /// <summary>Gets or sets the distinguished name of the delegated computer OU.</summary>
    public string ComputerOu { get; set; } = string.Empty;

    /// <summary>Gets or sets the Active Directory objects assigned to the OU.</summary>
    public List<DelegationAdObjectEditModel> AdObjects { get; set; } = [];
}

/// <summary>Contains all submitted delegation entries and the concurrency token.</summary>
public sealed class DelegationConfigurationEditModel
{
    /// <summary>Gets or sets the submitted OU delegations.</summary>
    public List<DelegationEditModel> Delegations { get; set; } = [];

    /// <summary>Gets or sets the hash of the file version that was edited.</summary>
    public string ExpectedHash { get; set; } = string.Empty;
}

/// <summary>Identifies the editor control and JSON type used for a JIT parameter.</summary>
public enum JitConfigurationParameterKind
{
    /// <summary>A JSON string edited as text.</summary>
    String,

    /// <summary>A JSON integer edited as a whole number.</summary>
    Integer,

    /// <summary>A JSON number that may contain a fractional component.</summary>
    Number,

    /// <summary>A JSON Boolean edited as true or false.</summary>
    Boolean,

    /// <summary>An array of JSON strings edited one item per line.</summary>
    StringList,

    /// <summary>A nested JSON object or non-string array edited as JSON text.</summary>
    Json,

    /// <summary>A JSON null value that remains null.</summary>
    Null
}

/// <summary>Contains one editable top-level parameter from JIT.config.</summary>
public sealed class JitConfigurationParameterEditModel
{
    /// <summary>Gets or sets the JSON property name.</summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>Gets or sets the parameter's original JSON type.</summary>
    public JitConfigurationParameterKind Kind { get; set; }

    /// <summary>Gets or sets the value represented as form text.</summary>
    public string? Value { get; set; }

    /// <summary>Gets or sets whether the parameter is displayed but cannot be changed.</summary>
    public bool IsReadOnly { get; set; }

    /// <summary>Gets or sets whether the parameter belongs to the advanced configuration section.</summary>
    public bool IsAdvanced { get; set; }
}

/// <summary>Contains all individually submitted JIT parameters and the concurrency token.</summary>
public sealed class JitConfigurationEditModel
{
    /// <summary>Gets or sets the submitted parameters in source-file order.</summary>
    public List<JitConfigurationParameterEditModel> Parameters { get; set; } = [];

    /// <summary>Gets or sets the hash of the file version that was edited.</summary>
    public string ExpectedHash { get; set; } = string.Empty;
}

/// <summary>Provides one JIT parameter and its stable form collection index to the field partial.</summary>
public sealed class JitConfigurationParameterFieldViewModel
{
    /// <summary>Gets or sets the parameter rendered by the field partial.</summary>
    public JitConfigurationParameterEditModel Parameter { get; set; } = new();

    /// <summary>Gets or sets the parameter's index in the submitted collection.</summary>
    public int Index { get; set; }
}
