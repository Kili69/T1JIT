using System.Globalization;
using KjitCore.Models;
#if NET48
using System.Collections;
using System.Web.Script.Serialization;
#else
using System.Text;
using System.Text.Json;
#endif

namespace KjitCore.Services;

/// <summary>Reads and updates top-level JIT configuration parameters without changing their JSON types.</summary>
internal static class JitConfigurationCodec
{
    public static IReadOnlyList<JitConfigurationParameter> ParseParameters(string content)
    {
#if NET48
        var root = DeserializeRoot(content);
        return root.Select(pair => CreateParameter(pair.Key, pair.Value)).ToList();
#else
        using var document = ParseRoot(content);
        return document.RootElement.EnumerateObject().Select(CreateParameter).ToList();
#endif
    }

    public static string UpdateParameters(
        string content,
        IReadOnlyCollection<JitConfigurationParameter> parameters,
        IReadOnlyCollection<string>? readOnlyNames)
    {
        var submitted = parameters
            .GroupBy(parameter => parameter.Name, StringComparer.Ordinal)
            .ToDictionary(
                group => group.Key,
                group => group.Count() == 1
                    ? group.Single()
                    : throw new InvalidOperationException($"Parameter '{group.Key}' was submitted more than once."),
                StringComparer.Ordinal);
        var readOnly = new HashSet<string>(readOnlyNames ?? Array.Empty<string>(), StringComparer.OrdinalIgnoreCase);

#if NET48
        var root = DeserializeRoot(content);
        var updated = new Dictionary<string, object>();
        foreach (var pair in root)
        {
            if (!submitted.TryGetValue(pair.Key, out var parameter))
            {
                throw new InvalidOperationException($"Parameter '{pair.Key}' is missing.");
            }

            updated[pair.Key] = readOnly.Contains(pair.Key)
                ? pair.Value
                : ParseSubmittedValue(pair.Key, pair.Value, parameter.Value);
            submitted.Remove(pair.Key);
        }

        EnsureNoUnknownParameters(submitted);
        var result = new JavaScriptSerializer().Serialize(updated);
        JitConfigurationReader.ParseJson(result);
        return result;
#else
        using var document = ParseRoot(content);
        using var stream = new MemoryStream();
        using (var writer = new Utf8JsonWriter(stream, new JsonWriterOptions { Indented = true }))
        {
            writer.WriteStartObject();
            foreach (var property in document.RootElement.EnumerateObject())
            {
                if (!submitted.TryGetValue(property.Name, out var parameter))
                {
                    throw new InvalidOperationException($"Parameter '{property.Name}' is missing.");
                }

                writer.WritePropertyName(property.Name);
                if (readOnly.Contains(property.Name))
                {
                    property.Value.WriteTo(writer);
                }
                else
                {
                    WriteSubmittedValue(writer, property, parameter.Value);
                }

                submitted.Remove(property.Name);
            }
            writer.WriteEndObject();
        }

        EnsureNoUnknownParameters(submitted);
        var result = Encoding.UTF8.GetString(stream.ToArray());
        JitConfigurationReader.ParseJson(result);
        return result;
#endif
    }

    public static string AddStringListValue(string content, string parameterName, string value)
    {
        var parameters = ParseParameters(content).ToList();
        var parameter = FindStringList(parameters, parameterName);
        var values = SplitList(parameter.Value);
        if (!values.Contains(value, StringComparer.OrdinalIgnoreCase))
        {
            values.Add(value);
            parameter.Value = string.Join(Environment.NewLine, values);
        }
        return UpdateParameters(content, parameters, null);
    }

    public static string RemoveStringListValue(string content, string parameterName, string value)
    {
        var parameters = ParseParameters(content).ToList();
        var parameter = FindStringList(parameters, parameterName);
        parameter.Value = string.Join(
            Environment.NewLine,
            SplitList(parameter.Value).Where(item => !item.Equals(value, StringComparison.OrdinalIgnoreCase)));
        return UpdateParameters(content, parameters, null);
    }

    private static JitConfigurationParameter FindStringList(
        IEnumerable<JitConfigurationParameter> parameters,
        string parameterName)
    {
        var parameter = parameters.SingleOrDefault(item => item.Name.Equals(parameterName, StringComparison.Ordinal));
        if (parameter is null || parameter.Kind != JitConfigurationParameterKind.StringList)
        {
            throw new InvalidOperationException($"Parameter '{parameterName}' must be a string array.");
        }
        return parameter;
    }

    private static List<string> SplitList(string value) => value
        .Split(new[] { "\r\n", "\n" }, StringSplitOptions.RemoveEmptyEntries)
        .Select(item => item.Trim())
        .Where(item => item.Length > 0)
        .ToList();

    private static void EnsureNoUnknownParameters(IReadOnlyDictionary<string, JitConfigurationParameter> submitted)
    {
        if (submitted.Count != 0)
        {
            throw new InvalidOperationException("The submitted configuration contains unknown parameters.");
        }
    }

#if NET48
    private static IDictionary<string, object> DeserializeRoot(string content)
    {
        var root = new JavaScriptSerializer().DeserializeObject(content) as IDictionary<string, object>;
        return root ?? throw new InvalidOperationException("JIT configuration must be a JSON object.");
    }

    private static JitConfigurationParameter CreateParameter(string name, object value)
    {
        var kind = GetKind(value);
        return new JitConfigurationParameter { Name = name, Kind = kind, Value = GetFormValue(value, kind) };
    }

    private static JitConfigurationParameterKind GetKind(object value)
    {
        if (value is null) return JitConfigurationParameterKind.Null;
        if (value is string) return JitConfigurationParameterKind.String;
        if (value is bool) return JitConfigurationParameterKind.Boolean;
        if (value is int || value is long) return JitConfigurationParameterKind.Integer;
        if (value is decimal || value is double || value is float) return JitConfigurationParameterKind.Number;
        if (value is object[] array && array.All(item => item is string)) return JitConfigurationParameterKind.StringList;
        return JitConfigurationParameterKind.Json;
    }

    private static string GetFormValue(object value, JitConfigurationParameterKind kind)
    {
        if (kind == JitConfigurationParameterKind.StringList)
        {
            return string.Join(Environment.NewLine, ((object[])value).Cast<string>());
        }
        if (kind == JitConfigurationParameterKind.Json)
        {
            return new JavaScriptSerializer().Serialize(value);
        }
        return value is null ? string.Empty : Convert.ToString(value, CultureInfo.InvariantCulture) ?? string.Empty;
    }

    private static object ParseSubmittedValue(string name, object original, string submitted)
    {
        switch (GetKind(original))
        {
            case JitConfigurationParameterKind.String: return submitted;
            case JitConfigurationParameterKind.Integer:
                if (long.TryParse(submitted, NumberStyles.Integer, CultureInfo.InvariantCulture, out var integer)) return integer;
                break;
            case JitConfigurationParameterKind.Number:
                if (decimal.TryParse(submitted, NumberStyles.Number, CultureInfo.InvariantCulture, out var number)) return number;
                break;
            case JitConfigurationParameterKind.Boolean:
                if (bool.TryParse(submitted, out var boolean)) return boolean;
                break;
            case JitConfigurationParameterKind.StringList: return SplitList(submitted).Cast<object>().ToArray();
            case JitConfigurationParameterKind.Json:
                return new JavaScriptSerializer().DeserializeObject(submitted);
            case JitConfigurationParameterKind.Null: return null!;
        }
        throw new InvalidOperationException($"Parameter '{name}' has an invalid value.");
    }
#else
    private static JsonDocument ParseRoot(string content)
    {
        var document = JsonDocument.Parse(content);
        if (document.RootElement.ValueKind != JsonValueKind.Object)
        {
            document.Dispose();
            throw new InvalidOperationException("JIT configuration must be a JSON object.");
        }
        return document;
    }

    private static JitConfigurationParameter CreateParameter(JsonProperty property)
    {
        var kind = GetKind(property.Value);
        return new JitConfigurationParameter
        {
            Name = property.Name,
            Kind = kind,
            Value = GetFormValue(property.Value, kind)
        };
    }

    private static JitConfigurationParameterKind GetKind(JsonElement value) => value.ValueKind switch
    {
        JsonValueKind.String => JitConfigurationParameterKind.String,
        JsonValueKind.Number when value.TryGetInt64(out _) => JitConfigurationParameterKind.Integer,
        JsonValueKind.Number => JitConfigurationParameterKind.Number,
        JsonValueKind.True or JsonValueKind.False => JitConfigurationParameterKind.Boolean,
        JsonValueKind.Array when value.EnumerateArray().All(item => item.ValueKind == JsonValueKind.String) => JitConfigurationParameterKind.StringList,
        JsonValueKind.Array or JsonValueKind.Object => JitConfigurationParameterKind.Json,
        JsonValueKind.Null => JitConfigurationParameterKind.Null,
        _ => throw new InvalidOperationException("Unsupported JIT configuration value.")
    };

    private static string GetFormValue(JsonElement value, JitConfigurationParameterKind kind) => kind switch
    {
        JitConfigurationParameterKind.String => value.GetString() ?? string.Empty,
        JitConfigurationParameterKind.Boolean => value.GetBoolean() ? "true" : "false",
        JitConfigurationParameterKind.StringList => string.Join(Environment.NewLine, value.EnumerateArray().Select(item => item.GetString())),
        JitConfigurationParameterKind.Null => string.Empty,
        _ => value.GetRawText()
    };

    private static void WriteSubmittedValue(Utf8JsonWriter writer, JsonProperty original, string submitted)
    {
        switch (GetKind(original.Value))
        {
            case JitConfigurationParameterKind.String: writer.WriteStringValue(submitted); return;
            case JitConfigurationParameterKind.Integer:
                if (long.TryParse(submitted, NumberStyles.Integer, CultureInfo.InvariantCulture, out var integer)) { writer.WriteNumberValue(integer); return; }
                break;
            case JitConfigurationParameterKind.Number:
                if (decimal.TryParse(submitted, NumberStyles.Number, CultureInfo.InvariantCulture, out var number)) { writer.WriteNumberValue(number); return; }
                break;
            case JitConfigurationParameterKind.Boolean:
                if (bool.TryParse(submitted, out var boolean)) { writer.WriteBooleanValue(boolean); return; }
                break;
            case JitConfigurationParameterKind.StringList:
                writer.WriteStartArray();
                foreach (var item in SplitList(submitted)) writer.WriteStringValue(item);
                writer.WriteEndArray();
                return;
            case JitConfigurationParameterKind.Json:
                using (var value = JsonDocument.Parse(submitted)) value.RootElement.WriteTo(writer);
                return;
            case JitConfigurationParameterKind.Null: writer.WriteNullValue(); return;
        }
        throw new InvalidOperationException($"Parameter '{original.Name}' has an invalid value.");
    }
#endif
}