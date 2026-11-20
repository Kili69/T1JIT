using KjitWeb.Services;
using Xunit;

namespace KjitWeb.Tests;

public sealed class JitConfigurationTests
{
    [Fact]
    public void ReadsComputerSearchFilterFromLegacyConfigurationKey()
    {
        const string filter = "(&(OperatingSystem=*Windows*)(ObjectClass=Computer))";
        var path = WriteConfiguration($$"""
            {
              "EventSource": "KjitWeb.Tests",
              "LDAPT1Computers": "{{filter}}"
            }
            """);

        try
        {
            var configuration = new JitConfiguration(path);

            Assert.Equal(filter, configuration.ComputerSearchFilter);
        }
        finally
        {
            File.Delete(path);
        }
    }

    [Fact]
    public void ComputerSearchTakesPrecedenceOverLegacyFilter()
    {
        var path = WriteConfiguration("""
            {
              "EventSource": "KjitWeb.Tests",
              "ComputerSearch": "(objectCategory=computer)",
              "LDAPT1Computers": "(objectClass=computer)"
            }
            """);

        try
        {
            var configuration = new JitConfiguration(path);

            Assert.Equal("(objectCategory=computer)", configuration.ComputerSearchFilter);
        }
        finally
        {
            File.Delete(path);
        }
    }

    [Fact]
    public void UsesBackwardCompatibleComputerFilterWhenConfigurationOmitsOne()
    {
        var path = WriteConfiguration("""
            {
              "EventSource": "KjitWeb.Tests"
            }
            """);

        try
        {
            var configuration = new JitConfiguration(path);

            Assert.Equal("(&(objectCategory=computer)(name=*))", configuration.ComputerSearchFilter);
        }
        finally
        {
            File.Delete(path);
        }
    }

    private static string WriteConfiguration(string json)
    {
        var path = Path.Combine(Path.GetTempPath(), $"{Guid.NewGuid():N}.json");
        File.WriteAllText(path, json);
        return path;
    }
}
