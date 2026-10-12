namespace KjitCore.Models;

/// <summary>Identifies the JSON representation of a top-level JIT configuration parameter.</summary>
public enum JitConfigurationParameterKind
{
    /// <summary>A JSON string.</summary>
    String,
    /// <summary>A whole JSON number.</summary>
    Integer,
    /// <summary>A JSON number with an optional fractional component.</summary>
    Number,
    /// <summary>A JSON Boolean.</summary>
    Boolean,
    /// <summary>An array containing only JSON strings.</summary>
    StringList,
    /// <summary>A nested JSON object or non-string array.</summary>
    Json,
    /// <summary>A JSON null value.</summary>
    Null
}

/// <summary>Represents one top-level JIT configuration parameter as editable text.</summary>
public sealed class JitConfigurationParameter
{
    /// <summary>Gets or sets the JSON property name.</summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>Gets or sets the original JSON value kind.</summary>
    public JitConfigurationParameterKind Kind { get; set; }

    /// <summary>Gets or sets the value represented as text.</summary>
    public string Value { get; set; } = string.Empty;
}