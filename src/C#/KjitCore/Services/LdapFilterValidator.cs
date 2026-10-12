using System.Text.RegularExpressions;

namespace KjitCore.Services;

/// <summary>Validates the structural grammar of LDAP search filters defined by RFC 4515.</summary>
internal static class LdapFilterValidator
{
    private static readonly Regex AttributeDescriptionPattern = new(
        "^(?:[A-Za-z][A-Za-z0-9-]*|[0-9]+(?:\\.[0-9]+)*)(?:;[A-Za-z0-9-]+)*$",
        RegexOptions.Compiled);

    private static readonly Regex ExtensibleLeftSidePattern = new(
        "^(?:(?:[A-Za-z][A-Za-z0-9-]*|[0-9]+(?:\\.[0-9]+)*)(?:;[A-Za-z0-9-]+)*)?(?::dn)?(?::(?:[A-Za-z][A-Za-z0-9-]*|[0-9]+(?:\\.[0-9]+)*))?$",
        RegexOptions.Compiled | RegexOptions.IgnoreCase);

    public static bool IsValid(string value)
    {
        var index = 0;
        return ParseFilter(value, ref index) && index == value.Length;
    }

    private static bool ParseFilter(string value, ref int index)
    {
        if (!Consume(value, ref index, '(') || index >= value.Length)
        {
            return false;
        }

        if (value[index] is '&' or '|')
        {
            index++;
            var childCount = 0;
            while (index < value.Length && value[index] == '(')
            {
                if (!ParseFilter(value, ref index))
                {
                    return false;
                }
                childCount++;
            }
            return childCount > 0 && Consume(value, ref index, ')');
        }

        if (value[index] == '!')
        {
            index++;
            return ParseFilter(value, ref index) && Consume(value, ref index, ')');
        }

        var itemStart = index;
        while (index < value.Length && value[index] != ')')
        {
            if (value[index] == '(')
            {
                return false;
            }
            if (value[index] == '\\')
            {
                if (index + 2 >= value.Length || !IsHex(value[index + 1]) || !IsHex(value[index + 2]))
                {
                    return false;
                }
                index += 3;
                continue;
            }
            index++;
        }

        if (index >= value.Length || !ValidateItem(value.Substring(itemStart, index - itemStart)))
        {
            return false;
        }
        return Consume(value, ref index, ')');
    }

    private static bool ValidateItem(string item)
    {
        var operatorIndex = FindOperator(item, out var filterOperator);
        if (operatorIndex <= 0 && filterOperator != ":=")
        {
            return false;
        }
        if (operatorIndex < 0)
        {
            return false;
        }

        var left = item.Substring(0, operatorIndex);
        var assertionValue = item.Substring(operatorIndex + filterOperator.Length);
        if (filterOperator == ":=")
        {
            if (left.Length == 0 || !ExtensibleLeftSidePattern.IsMatch(left))
            {
                return false;
            }
            var hasAttribute = left[0] != ':';
            var hasMatchingRule = left.Split(':').Any(part =>
                part.Length > 0 && !part.Equals("dn", StringComparison.OrdinalIgnoreCase))
                && (!hasAttribute || left.Count(character => character == ':') > (left.IndexOf(":dn", StringComparison.OrdinalIgnoreCase) >= 0 ? 1 : 0));
            return hasAttribute || hasMatchingRule;
        }

        if (!AttributeDescriptionPattern.IsMatch(left))
        {
            return false;
        }
        return filterOperator == "=" || assertionValue.IndexOf('*') < 0;
    }

    private static int FindOperator(string item, out string filterOperator)
    {
        for (var index = 0; index < item.Length; index++)
        {
            if (item[index] == '\\')
            {
                index += 2;
                continue;
            }
            if (index + 1 < item.Length)
            {
                var candidate = item.Substring(index, 2);
                if (candidate is "~=" or ">=" or "<=" or ":=")
                {
                    filterOperator = candidate;
                    return index;
                }
            }
            if (item[index] == '=')
            {
                filterOperator = "=";
                return index;
            }
        }
        filterOperator = string.Empty;
        return -1;
    }

    private static bool Consume(string value, ref int index, char expected)
    {
        if (index >= value.Length || value[index] != expected)
        {
            return false;
        }
        index++;
        return true;
    }

    private static bool IsHex(char value) =>
        value is >= '0' and <= '9'
        || value is >= 'A' and <= 'F'
        || value is >= 'a' and <= 'f';
}