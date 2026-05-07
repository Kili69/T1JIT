using KjitCore.Models;

static void PrintUsage()
{
	Console.WriteLine("Usage:");
	Console.WriteLine("  dotnet run -- --unc \\\\server\\share\\JIT.config");
	Console.WriteLine("  dotnet run -- --ad Jit-Configuration");
	Console.WriteLine("  dotnet run -- --ad \"CN=Jit-Configuration,CN=Just-In-Time Administration,CN=Services,CN=Configuration,DC=example,DC=com\"");
}

if (args.Length < 2)
{
	PrintUsage();
	return;
}

var mode = args[0];
var source = args[1];
JitConfigurationObject config;

if (string.Equals(mode, "--unc", StringComparison.OrdinalIgnoreCase))
{
	config = global::KjitCore.KjitCore.LoadJitConfiguration(source);
}
else if (string.Equals(mode, "--ad", StringComparison.OrdinalIgnoreCase))
{
	config = global::KjitCore.KjitCore.LoadJitConfiguration(source);
}
else
{
	PrintUsage();
	return;
}

Console.WriteLine($"ConfigScriptVersion: {config.ConfigScriptVersion}");
Console.WriteLine($"AdminPreFix: {config.AdminPreFix}");
Console.WriteLine($"AdminGroupOU: {config.AdminGroupOU}");
Console.WriteLine($"Domain: {string.Join(";", config.Domain)}");
Console.WriteLine($"EventLog: {config.EventLog}");
Console.WriteLine($"EventSource: {config.EventSource}");
Console.WriteLine($"EnableDelegation: {config.EnableDelegation}");
Console.WriteLine($"ElevateEventID: {config.ElevateEventID}");
