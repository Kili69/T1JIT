// See https://aka.ms/new-console-template for more information
using JustInTime;
using System.DirectoryServices.AccountManagement;
using System.Security.Principal;
public class JITcmnd
{
    public static void Main(string[] args)
    {
        JustInTime.JustInTime jit;
        if (args.Length == 0)
        {
            ShowHelp();
            return;
        }
        string action = args[0];
        var parameters = ParseParameters(args);

        Console.WriteLine("connect to JustInTime");
        try
        {
            jit = new JustInTime.JustInTime();
        }
        catch (FileNotFoundException ex)
        {
            Console.WriteLine($"Could not find configuration file {ex.FileName}. Please ensure it is present in the application directory.");
            Console.WriteLine("Validate the JustInTimeConfig environment variable is set correctly.");
            return;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"An error occurred while initializing JustInTime: {ex.Message}");
            return;
        }
        switch (action.ToLower())
        {
            case "new":
                if (parameters.TryGetValue("user", out string? targetuser) == false)
                    parameters["user"] = GetCurrentUserUpnOrDomainUser();
                if (parameters.TryGetValue("host", out string? host) == false)
                    ShowHelp();
                if (parameters.TryGetValue("duration", out string? duration) == false)
                    parameters["duration"] = "60";
                if (parameters.TryGetValue("requestor", out string? requestor) == false)
                    parameters["requestor"] = GetCurrentUserUpnOrDomainUser();
                Console.WriteLine($"Creating new JIT request {parameters["host"]}...");
                jit.NewAdminRequest(parameters["user"], parameters["host"], int.Parse(parameters["duration"]), parameters["requestor"]);
                break;
            case "listserver":
                if (parameters.TryGetValue("user", out string? listHost) == false)
                    parameters["user"] = GetCurrentUserUpnOrDomainUser();
                Console.WriteLine($"Listing servers for user {parameters["user"]}...");
                var servers = jit.GetComputerWithAccess(parameters["user"]);
                int col = 0;
                foreach (var server in servers)
                {
                    Console.Write(server.PadRight(35) +  " ");
                    col++;
                    if (col % 3 == 0)
                        Console.WriteLine();
                }
                if (col % 3 != 0)
                    Console.WriteLine();
                break;
            case "current":
                if (parameters.TryGetValue("user", out string? currentUser) == false)
                    parameters["user"] = GetCurrentUserUpnOrDomainUser();
                Console.WriteLine($"Getting current elevation for user {parameters["user"]}...");
                var currentElevation = jit.GetCurrentElevation(parameters["user"]);
                foreach (var evalhost in currentElevation)
                {
                    Console.WriteLine($" - {evalhost}");
                }
                break;
            default:
                ShowHelp();
                break;
        }
    }
        static Dictionary<string, string> ParseParameters(string[] args)
    {
        var dict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        for (int i = 1; i < args.Length; i++)
        {
            var parts = args[i].Split('=');
            if (parts.Length == 2)
            {
                dict[parts[0]] = parts[1];
            }
        }
        return dict;
    }

    static string GetCurrentUserUpnOrDomainUser() {
        string userUpn = WindowsIdentity.GetCurrent().Name;
        if (userUpn.Contains("@"))
            return userUpn;
        using (PrincipalContext context = new PrincipalContext(ContextType.Domain))
        {
            UserPrincipal user = UserPrincipal.FindByIdentity(context, userUpn);
            if (user != null && !string.IsNullOrEmpty(user.UserPrincipalName))
            {
                return user.UserPrincipalName;
            }
        }
        return userUpn; // Fallback to domain\username format
    }

    static void ShowHelp()
    {
        Console.WriteLine("This program is a command-line tool for managing Just-In-Time (JIT) access requests.");
        Console.WriteLine("Usage:");
        Console.WriteLine("  jitcmd <action> [options]");
        Console.WriteLine("Actions:");
        Console.WriteLine("  new       Create a new JIT access request");
        Console.WriteLine("  current   Show the current JIT access request");
        Console.WriteLine("  listServer List servers the user has access to");
        Console.WriteLine("Options:");
        Console.WriteLine("  user=<username>       Specify the user for the JIT request");
        Console.WriteLine("  host=<hostname>       Specify the host for the JIT request");
        Console.WriteLine("  duration=<minutes>    Specify the duration for the JIT request");
        Console.WriteLine("  requestor=<username>  Specify the requestor for the JIT request");
        Console.WriteLine("Examples:");
        Console.WriteLine("  jitcmd new user=myuser@contoso.com host=Server0.contoso.com duration=15");
        Console.WriteLine("     creates a JIT request for the user myuser@contoso.com on the server server0.contoso.com");
        Console.WriteLine("  jitcmd new host=Server0.contoso ");
        Console.WriteLine(" jitcmd new host=Server0.contoso.com");
        Console.WriteLine("     creates a JIT request for the current user on the server server0.contoso.com");
        Console.WriteLine("  jitcmd listServer user=myuser@contoso.com");
        Console.WriteLine("     lists all servers the user myuser@contoso.com has access to");
    }
}
