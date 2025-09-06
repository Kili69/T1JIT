using System.DirectoryServices;
using System.DirectoryServices.ActiveDirectory;
using System.DirectoryServices.AccountManagement;
using System.Security.Principal;
using System.Diagnostics;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Runtime.Versioning;
using System.Runtime;
namespace JustInTime
{
    /// <summary>
    /// JustInTime class for managing JIT configurations and operations.
    /// </summary>
    /// <remarks>
    /// This class is only supported on Windows operating systems.
    /// created by Kili 2025-08-29
    /// </remarks>
    [SupportedOSPlatform("windows")]
    public class JustInTime
    {
        #region Private Members
        /// <summary>
        /// Default path for the JIT configuration file.
        /// </summary>
        /// <remarks>
        /// This is a placeholder path and should be replaced with the actual domain name.
        /// </remarks>
        private const string DefaultconfigFilePath = "%domainName%\\Sysvol\\%domainName%\\Just-In-Time\\jit.config";
        /// <summary>
        /// Minimum elevation time in minutes.
        /// </summary>
        /// <remarks>
        /// This is the minimum time to elevate a user to a server. 
        /// Values below this threshold will be ignored.
        /// </remarks>
        private const int MinElevationTime = 5;
        /// <summary>
        /// The Event ID logged in the Just-In-Time Eventlog for a new JIT request.
        /// </summary>
        private const int EventIDNewRequest = 100;
        /// <summary>
        /// The environment variable used to store JIT configuration.
        /// </summary>
        private const string JITEnvVar = "JustInTimeConfig";
        /// <summary>
        /// The array of JIT access control lists (ACLs) to manage user permissions.
        /// </summary>
        JITacl[]? aclArray = [];
        /// <summary>
        /// This array contains the property names to retrieve from the user token.
        /// </summary>
        private static readonly string[] propertyNames = new[] { "tokenGroups" };

        #endregion
        #region Public Members
        /// <summary>
        /// Gets the JIT configuration.
        /// </summary>
        /// <remarks>
        /// This property will be set during the initialization of the JustInTime class.
        /// During the initialization process, the JIT configuration will be loaded from the JIT environment variable.
        /// or from the default configuration path \\%domainName%\Sysvol\%domainName%\Just-In-Time\jit.config
        /// </remarks>
        public JITconfig Config { get; private set; } = new JITconfig();
        #endregion
        #region Constructors
        /// <summary>
        /// Initializes a new instance of the JustInTime class.
        /// </summary>
        /// <remarks>
        /// This constructor will load the JIT configuration from the default path.
        /// </remarks>
        public JustInTime()
        {
            ReloadLoadConfig(null);
        }
        /// <summary>
        /// Initializes a new instance of the JustInTime class with a custom configuration file path.
        /// </summary>
        /// <param name="ConfigFilePath">If the path to the JIT configuration file.</param>
        public JustInTime(string ConfigFilePath)
        {
            ReloadLoadConfig(ConfigFilePath);
        }
        #endregion
        /// <summary>Escapes special characters in LDAP queries</summary>
        /// <param name="value">Is the LDAP string to escape</param>
        /// <returns>The escaped LDAP string</returns>
        private static string EscapeLdap(string value)
        {
            // LDAP-Escaping für Sonderzeichen
            return value.Replace("\\", "\\5c").Replace("*", "\\2a").Replace("(", "\\28").Replace(")", "\\29");
        }
        /// <summary>
        /// Gets the domain name from a existingcomputer name.
        /// </summary>
        /// <param name="computerName">The computer name to extract the domain from. The format can be NetBIOS, FQDN, or canonical name.</param>
        /// <returns>The domain name.</returns>
        /// <exception cref="ArgumentException">Thrown when the computer name could not be resolved in the current AD forest.</exception>
        /// <exception cref="ActiveDirectoryServerDownException">The ActiveDirectoryServerDownException is raised if the AD server is not reachable</exception>
        /// <exception cref="DirectoryServicesCOMException">Thrown when there is a COM error accessing Active Directory</exception>
        /// <exception cref="DirectoryServicesCOMException">Thrown when there is a COM error accessing Active Directory</exception>
        /// <exception cref="System.Runtime.InteropServices.COMException">Thrown when there is a COM error accessing Active Directory</exception>
        /// <exception cref="System.UnauthorizedAccessException">Thrown when the user does not have permission to access Active Directory</exception>   
        private static string GetDomainFromComputerName(string computerName)
        {
            DirectorySearcher searcher = new();
            String? result;
            switch (computerName)
            {
                case var s when s.Contains("/"):
                    //canonical name
                    string[] canonicalName = computerName.Split('/');
                    searcher.SearchRoot = new DirectoryEntry($"LDAP://{canonicalName[0]}");
                    searcher.Filter = "(&(objectClass=Computer)(name=" + EscapeLdap(canonicalName[1]) + "))";
                    result = canonicalName[0];
                    break;
                case var s when s.Contains("."):
                    // FQDN
                    string pattern = @"(^[^.]+)\.(.+)$"; // Regex to extract domain part
                    var match = System.Text.RegularExpressions.Regex.Match(computerName, pattern);
                    result = match.Groups[2].Value;
                    searcher.SearchRoot = new DirectoryEntry($"GC://");
                    searcher.Filter = "(&(objectClass=Computer)(DNSname=" + EscapeLdap(computerName) + "))";
                    break;
                case var s when s.Contains("\\"):
                    //NetBIOS name
                    result = ResolveDnsFromNetbios(computerName.Split('\\')[0]);
                    if (string.IsNullOrEmpty(result))
                        throw new ArgumentException($"{computerName} domain name not found in the current AD forest");
                    searcher.SearchRoot = new DirectoryEntry($"LDAP://{result}");
                    searcher.Filter = "(&(objectClass=Computer)(name=" + EscapeLdap(computerName.Split('\\')[1]) + "))";
                    break;
                default:
                    // hostname only
                    result = Domain.GetCurrentDomain().Name;
                    searcher.SearchRoot = new DirectoryEntry($"LDAP://{result}");
                    searcher.Filter = "(&(objectClass=Computer)(name=" + EscapeLdap(computerName) + "))";
                    break;
            }
            if (searcher.FindOne() == null)
                throw new ArgumentException($"{computerName} could not be resolved to a domain");
            return result;
        }

        static string GetUserDN()
        {
            string userUpn = WindowsIdentity.GetCurrent().Name;
            return GetUserDN(userUpn);
        }
        /// <summary>
        /// Finds the distinguished name (DN) of a user in Active Directory based on various input formats.
        /// Supports UPN (user@DNS), 
        /// NT nETBIOSDomainName\username, 
        /// Canonical name DNS/username, 
        /// and plain username (sAMAccountName).
        /// </summary>
        /// <param name="UserName"></param>
        /// <returns>The distinguised name of the user </returns>
        /// <exception cref="ArgumentException">The argument exception is raised if the user doesn't exist in the AD forest</exception>
        /// <exception cref="ActiveDirectoryServerDownException">The ActiveDirectoryServerDownException is raised if the AD server is not reachable</exception>
        /// <exception cref="DirectoryServicesCOMException">The DirectoryServicesCOMException is raised if the AD server returns an error</exception>
        /// <exception cref="System.Runtime.InteropServices.COMException">The COMException is raised if the AD server returns an error</exception>
        /// <exception cref="System.UnauthorizedAccessException">The UnauthorizedAccessException is raised if the user running the code doesn't have permission to read from the AD</exception>
        /// <examples>
        /// <code>
        /// string userDn1 = GetUserDN("myuser@contoso.com"); // UPN
        /// string userDn2 = GetUserDN("contoso\\myuser"); // NT nETBIOSDomainName\username
        /// string userDn3 = GetUserDN("contoso.com/myuser"); // Canonical name DNS/username
        /// string userDn4 = GetUserDN("myuser"); // sAMAccountName
        /// </code> </examples> 
        /// <remarks>
        /// The function uses the Global Catalog to search for users across all domains in the AD forest 
        /// </remarks>
        static string GetUserDN(string UserName)
        {
            // use the Global catalog as search root to find the user in any domain of the forest
            DirectoryEntry gcRoot = new($"GC://{Forest.GetCurrentForest().Name}");
            DirectorySearcher searcher = new(gcRoot);
            // Determine the format of the UserName and set the appropriate LDAP filter
            switch (UserName)
            {
                case var s when s.Contains("@"):
                    // UPN
                    searcher.Filter = $"(userPrincipalName={EscapeLdap(UserName)})";
                    break;
                case var s when s.Contains("\\"):
                    // DOMAIN\username 
                    var parts = UserName.Split('\\');
                    searcher.Filter = $"(sAMAccountName={EscapeLdap(parts[^1])})";
                    //change search root to the domain of the user
                    searcher.SearchRoot = new DirectoryEntry("LDAP://" + ResolveDnsFromNetbios(parts[0]));
                    break;
                case var s when s.Contains("/"):
                    // Canonical name DNS/username 
                    searcher.Filter = $"(sAMAccountName={EscapeLdap(UserName.Split('/')[1])})";
                    //change search root to the domain of the user
                    searcher.SearchRoot = new DirectoryEntry("LDAP://" + UserName.Split('/')[0]);
                    break;
                default:
                    // SamAccountName
                    searcher.Filter = $"(sAMAccountName={EscapeLdap(UserName)})";
                    //change search root to the current domain
                    searcher.SearchRoot = new DirectoryEntry("LDAP://" + Domain.GetCurrentDomain().Name);
                    break;
            }
            searcher.PropertiesToLoad.Add("distinguishedName");
            SearchResult? result = searcher.FindOne();
            if (result == null)
                throw new ArgumentException($"User {UserName} not found in AD");
            return result.Properties["distinguishedName"]?[0].ToString() ?? "";
        }
        /// <summary>
        /// Finds the OU of a computer in Active Directory based on various input formats.  
        /// Supports FQDN (computer.domain.com),
        /// NT nETBIOSDomainName\computername,
        /// Canonical name DNS/computername,
        /// and plain computername (sAMAccountName).
        /// </summary>
        /// <param name="ComputerName">Is the computer name </param>
        /// <returns>The OU of the computer</returns>
        /// <exception cref="ArgumentException">The argument exception is raised if the computer doesn't exist in the AD forest or if the OU can't be extracted from the DN</exception>
        /// <exception cref="ActiveDirectoryServerDownException">The ActiveDirectoryServerDownException is raised if the AD server is not reachable</exception>
        /// <exception cref="DirectoryServicesCOMException">The DirectoryServicesCOMException is raised if the AD server returns an error</exception>
        /// <exception cref="System.Runtime.InteropServices.COMException">The COMException is raised if the AD server returns an error</exception>
        /// <exception cref="System.UnauthorizedAccessException">The UnauthorizedAccessException is raised if the user running the code doesn't have permission to read from the AD</exception>
        /// <examples>
        /// <code>
        /// string ou1 = GetComputerOU("computer.contoso.com"); // FQDN
        /// string ou2 = GetComputerOU("contoso\\computer"); // NT nETBIOSDomainName\computername
        /// string ou3 = GetComputerOU("contoso.com/computer"); // Canonical name DNS/computername
        /// string ou4 = GetComputerOU("computer"); // sAMAccountName
        /// </code> </examples>
        /// <remarks>
        /// The function uses the Global Catalog to search for computers across all domains in the AD forest
        /// </remarks>    
        static string GetComputerOU(string ComputerName)
        {
            // Global catalog 
            DirectorySearcher searcher = new($"GC://{Forest.GetCurrentForest().Name}");
            // Determine the format of the ComputerName and set the appropriate LDAP filter
            switch (ComputerName)
            {
                case var s when s.Contains("."):
                    // FQDN
                    searcher.Filter = $"(&(objectclass=computer)(dNSHostName={EscapeLdap(ComputerName)}))";
                    break;
                case var s when s.Contains("\\"):
                    // DOMAIN\computername 
                    var parts = ComputerName.Split('\\');
                    searcher.Filter = $"(&(objectclass=computer)(sAMAccountName={EscapeLdap(parts[^1])}$))";
                    searcher.SearchRoot = new DirectoryEntry("LDAP://" + parts[0]);
                    break;
                case var s when s.Contains("/"):
                    // contoso.com/aa 
                    searcher.Filter = $"(&(objectclass=computer)(sAMAccountName={EscapeLdap(ComputerName.Split('/')[1])}$))";
                    searcher.SearchRoot = new DirectoryEntry("LDAP://" + ComputerName.Split('/')[0]);
                    break;
                default:
                    // SamAccountName
                    searcher.Filter = $"(&(objectclass=computer)(sAMAccountName={EscapeLdap(ComputerName)}$))";
                    searcher.SearchRoot = new DirectoryEntry("LDAP://" + Domain.GetCurrentDomain().Name);
                    break;
            }
            searcher.PropertiesToLoad.Add("distinguishedName");
            SearchResult? result = searcher.FindOne();
            if (result == null)
                throw new ArgumentException($"Computer {ComputerName} not found in AD");
            String pattern = @"^(CN=[^,]+),(.*)$"; // Regex to extract OU part
            var match = System.Text.RegularExpressions.Regex.Match(result.Properties["distinguishedName"]?[0].ToString() ?? "", pattern);
            /// if the regex matches, return the OU part; otherwise, throw an exception
            if (match.Success)
                return match.Groups[2].Value;
            else
                throw new ArgumentException($"Could not extract OU from computer {ComputerName} DN");
        }
        /// <summary>
        /// Reads the JIT delegation configuration file and deserializes it into the aclArray property
        /// </summary>
        /// <exception cref="FileNotFoundException">if the delegation file doesn't exist a FileNotFounException is raised</exception>
        /// <exception cref="JsonException">if the delegation file is not a valid json a JsonException is raised</exception>
        /// <remarks>
        /// The function reads the delegation config file and deserializes it into an array of JITacl objects
        /// </remarks>
        void ReadJITAcl()
        {
            // if delegation mode is not enabled, do nothing
            if (Config.EnableDelegation == false) return;
            // if the delegtion mode is enabled but the delegation file doesn't exists, raise a FileNotFoundException
            if (File.Exists(Config.DelegationConfigPath) == false)
                throw new FileNotFoundException($"Delegation file {Config.DelegationConfigPath} not found");
            string jsonString = File.ReadAllText(Config.DelegationConfigPath);
            aclArray = JsonSerializer.Deserialize<JITacl[]>(jsonString);
        }
        /// <summary>
        /// Validates if a user is authorized to request elevation for a specific computer OU based on the delegation config
        /// </summary>
        /// <param name="userDn">Is the distinguishedname of the user</param>
        /// <param name="ComputerOU">Is the OU path for validation</param>
        /// <returns>
        /// True if the user is authorized to request elevation for the computer OU, this means the user is member of a group who is allowed to request elevation for the computer OU
        /// False if the user is not authorized to request elevation for the computer OU, this means
        /// </returns>
        /// <remarks>
        /// The function always return True if delegtion mode is disbled
        /// The function checks if the user is member of a group who is allowed to request elevation for the computer OU
        /// </remarks>
        bool ValidateOUAccess(string userDn, string computerOU)
        {
            if (Config.EnableDelegation)
            {
                //update the ACL array
                JITacl? acl = aclArray != null
                    ? Array.Find(aclArray, a => a.ComputerOU.Equals(computerOU, StringComparison.OrdinalIgnoreCase))
                    : null;
                //return false is the OU is not defined in the ACLarray
                if (acl == null) return false;
                // read the group membership recursive of the user, and store all memberof SID in a HashSet 
                HashSet<string> userMemberOfSids = GetMemberOfSids(userDn);
                //walk through all memberof SID and validate at least one SID match to the OU SIDs
                foreach (string sid in acl.ADObject)
                {
                    if (userMemberOfSids.Contains(sid))
                        return true;
                }
                return false;
            }
            return true;
        }
        /// <summary>
        /// Gets the SIDs of all groups the user is member of, including nested groups
        /// </summary>
        /// <param name="userDn">Is the distinguishedname of the user</param>
        /// <returns>A HashSet of SIDs the user is member of</returns>
        /// <remarks>  
        /// The function uses the tokenGroups attribute to get the SIDs of all groups the user is member of, including nested groups
        /// </remarks> 
        HashSet<string> GetMemberOfSids(string userDn)
        {
            var MemberOFSids = new HashSet<string>();
            DirectoryEntry user = new($"LDAP://{userDn}");
            user.RefreshCache(propertyNames);
            foreach (byte[] sidBytes in user.Properties["tokenGroups"])
            {
                SecurityIdentifier sid = new SecurityIdentifier(sidBytes, 0);
                MemberOFSids.Add(sid.Value);
            }
            return MemberOFSids;
        }
        /// <summary>
        /// Resolves the DNS domain name from a NetBIOS domain name using the crossRef object in the configuration naming context
        /// </summary>  
        /// <param name="netbiosName">Is the NetBIOS domain name</param>
        /// <returns>The DNS domain name or null if the NetBIOS name could not be resolved</returns>
        /// <exception cref="ActiveDirectoryServerDownException">The ActiveDirectoryServerDownException is  raised if the AD server is not reachable</exception>
        /// <exception cref="DirectoryServicesCOMException">The DirectoryServicesCOMException is raised if the AD server returns an error</exception>
        /// <exception cref="System.Runtime.InteropServices.COMException">The COMException is raised if the AD server returns an error</exception>
        /// <exception cref="System.UnauthorizedAccessException">The UnauthorizedAccessException is raised if the user running the code doesn't have permission to read from the AD</exception>
        /// <remarks>
        /// The function queries the crossRef object in the configuration naming context to resolve the DNS domain name from a NetBIOS domain name
        /// </remarks>
        static string? ResolveDnsFromNetbios(string netbiosName)
        {
            var rootDse = new DirectoryEntry("LDAP://RootDSE");
#pragma warning disable CS8602 // Dereference of a possibly null reference.
            string? configNC = rootDse.Properties["configurationNamingContext"].Value.ToString();
            if (string.IsNullOrEmpty(configNC))
                throw new System.DirectoryServices.ActiveDirectory.ActiveDirectoryServerDownException("Could not retrieve configuration naming context from RootDSE.");
#pragma warning restore CS8602 // Dereference of a possibly null reference.
            var configEntry = new DirectoryEntry($"LDAP://{configNC}");
            var searcher = new DirectorySearcher(configEntry)
            {
                Filter = $"(&(objectClass=crossRef)(nETBIOSName={netbiosName}))",
                SearchScope = SearchScope.Subtree
            };
            searcher.PropertiesToLoad.Add("dnsRoot");
            var result = searcher.FindOne();
            if (result != null && result.Properties["dnsRoot"].Count > 0)
            {
                return result.Properties["dnsRoot"][0].ToString();
            }
            return null;
        }
        /// <summary>
        /// This function builds the JIT server group name from the server hostname
        /// </summary>
        /// <param name="ServerName">Mulitple formast are supported 
        ///     full quaified DNS name e.g.  myserver.contoso.com, 
        ///     canonical name e.g. contoso.com/myserver
        ///     netbios nme e.g. contoso\myserver
        ///     samaccount name e.g. myserver
        /// </param>
        /// <returns>the name of the JIT group in the format of {AdminPrefix}{<hostname}{domainsepartor>}{AD DNS Name}</returns>
        /// <exception cref="ArgumentException">The ArgumentException is raised if the computer doesn't exists in the Active Directory</exception>
        /// <remarks>
        /// The function queries the Active Directory to get the computer name and domain name
        /// </remarks>
        string GetJITGroupName(string ServerName)
        {
            string filter;
            string SearchRoot;
            string? serverDNSdomain;
            //Determins the format of the host name
            switch (ServerName)
            {
                case var s when s.Contains("/"):
                    //canonical name
                    filter = $"(&(objectclass=computer)(sAMAccountName={EscapeLdap(ServerName.Split('/')[1])}$))";
                    SearchRoot = "LDAP://" + ServerName.Split('/')[0];
                    serverDNSdomain = ServerName.Split('/')[0];
                    break;
                case var s when s.Contains("."):
                    // FQDN
                    filter = $"(&(objectclass=computer)(dNSHostName={EscapeLdap(ServerName)}))";
                    SearchRoot = "GC://" + Forest.GetCurrentForest().Name;
                    string pattern = @"^[^.]+\.(.+)$"; // Regex to extract domain part
                    var match = System.Text.RegularExpressions.Regex.Match(ServerName, pattern);
                    serverDNSdomain = match.Success ? match.Groups[1].Value : "";
                    break;
                case var s when s.Contains("\\"):
                    //NetBIOS name
                    filter = $"(&(objectclass=computer)(sAMAccountName={EscapeLdap(ServerName.Split('\\')[1])}$))";
                    serverDNSdomain = ResolveDnsFromNetbios(ServerName.Split('\\')[0]);
                    SearchRoot = "LDAP://" + serverDNSdomain;
                    break;
                default:
                    // hostname only
                    filter = $"(&(objectclass=computer)(sAMAccountName={EscapeLdap(ServerName)}$))";
                    serverDNSdomain = Domain.GetCurrentDomain().Name;
                    SearchRoot = "LDAP://" + serverDNSdomain;
                    break;
            }
            DirectorySearcher searcher = new DirectorySearcher(SearchRoot);
            searcher.Filter = filter;
            var result = searcher.FindOne();
            if (string.IsNullOrEmpty(serverDNSdomain))
                throw new ArgumentException($"{ServerName} domain name not found in the current AD forest");
            if (result == null)
                throw new ArgumentException($"Server {ServerName} not found in AD");
            return $"{Config.AdminPreFix}{serverDNSdomain}{Config.DomainSeparator}{result.Properties["Name"][0].ToString()}";
        }
        /// <summary>
        /// load the configuration from the configuration file
        /// </summary>
        /// <param name="ConfigFilePath">is the UNC path the configuration file.</param>
        /// <exception cref="FileNotFoundException">The FileNotFoundException is raied if the configuration file doesn't exists</exception>
        /// <exception cref="JsonException">The JsonException is raised if the configuration file is not a valid json</exception>
        /// <remarks>
        /// If the ConfigFilePath is null or empty, the function tries to read the path from the environment variable JITConfig.
        /// If the environment variable is not set, the function uses the default path \\%domainName%\Sysvol\%domainName%\JIT\jit.config
        /// </remarks>
        public void ReloadLoadConfig(string? ConfigFilePath)
        {
            // if no path is specified, try to read it from the environment variable JITConfig
            if (string.IsNullOrEmpty(ConfigFilePath))
            {
                if (Environment.GetEnvironmentVariable(JITEnvVar) != null)
                    ConfigFilePath = Environment.GetEnvironmentVariable(JITEnvVar) ?? string.Empty;
                else
                {
                    string domainName = Domain.GetCurrentDomain().Name;
                    ConfigFilePath = DefaultconfigFilePath.Replace("%domainName%", domainName);
                }
            }
            if (File.Exists(ConfigFilePath) == false)
                throw new FileNotFoundException($"Config file {ConfigFilePath} not found");
            Config = new JITconfig(ConfigFilePath);
            ReadJITAcl();
        }
        /// <summary>
        /// Creates a new JIT admin request
        /// </summary>
        /// <param name="UserName">Is the user name who shoould be elevated</param>
        /// <param name="ServerName">Is the target computer</param>
        /// <param name="ElevatedTime">Is the elevation time, how log a user will be added to the local administrator group</param>
        /// <param name="Requestor">Is the name of the requestor</param>
        /// <param name="BypassAcl">Validate the ACL in the request. Bypassing the ACL does not bypass the ACL during the elevation. This property can be used for performance requesting</param>
        /// <exception cref="ArgumentException">The ArgumentException is raised if the user, requestor or computer doesn't exists in the Active Directory</exception>
        /// <exception cref="UnauthorizedAccessException">the UnauthorizedAccessException is raised if the current user cannot acces AD</exception>
        /// <remarks>
        /// The function creates a new JIT admin request and writes it to the event log
        /// The function validates if the requestor is authorized to request elevation for the target computer based on the delegation config
        /// </remarks>
        public void NewAdminRequest(string UserName, string ServerName, int ElevatedTime, string Requestor, bool BypassAcl = false)
        {
            string? targetUserDN = GetUserDN(UserName);
            string? requestorDN = GetUserDN(Requestor);
            string? jITGroupName = GetJITGroupName(ServerName);
            string pattern = $@"{Config.AdminPreFix}(.*?){Config.DomainSeparator}";
            if (String.IsNullOrEmpty(targetUserDN))
                throw new ArgumentException($"User {UserName} not found in AD");
            if (String.IsNullOrEmpty(requestorDN))
                throw new ArgumentException($"Requestor {Requestor} not found in AD");
            if (String.IsNullOrEmpty(jITGroupName))
                throw new ArgumentException($"Server {Requestor} not found in AD");
            if (ElevatedTime > Config.MaxElevatedTime) _ = Config.MaxElevatedTime;
            if (ElevatedTime < MinElevationTime) _ = MinElevationTime;
            if (BypassAcl == false && Config.EnableDelegation)
            {
                if (ValidateOUAccess(targetUserDN, GetComputerOU(ServerName)) == false)
                    throw new UnauthorizedAccessException($"Requestor {Requestor} is not authorized to request elevation for server group {jITGroupName}");
            }
            JITRequest request = new JITRequest
            {
                UserDN = targetUserDN,
                ServerGroup = jITGroupName,
                ElevationTime = ElevatedTime,
                ServerDomain = GetDomainFromComputerName(ServerName),
                CallingUser = requestorDN
            };
            EventLog.WriteEntry(Config.EventSource, JsonSerializer.Serialize(request), EventLogEntryType.Information, EventIDNewRequest);
        }
        /// <summary>
        /// Gets the list of Organizational Units (OUs) the user has access to
        /// </summary>
        /// <param name="UserName"></param>
        /// <returns>A array with distinguishedname of OUs</returns>
        /// <exception cref="ArgumentException">Thrown when the user is not found</exception>
        public string[] GetOUWithAccess(string? UserName)
        {
            String userDN;
            if (Config.EnableDelegation == false)
                return Config.T1Searchbase.ToArray(); //if delegation mode is disabled return the T1 search base
            // format the user name into the distinguished name
            if (string.IsNullOrEmpty(UserName))
                userDN = GetUserDN();
            else
                userDN = GetUserDN(UserName);
            HashSet<string> userMemberOfSids = GetMemberOfSids(userDN);
            List<string> ous = new List<string>();
            if (aclArray != null)
            {
                foreach (JITacl acl in aclArray)
                {
                    foreach (string sid in acl.ADObject)
                    {
                        if (userMemberOfSids.Contains(sid))
                        {
                            ous.Add(acl.ComputerOU);
                            break;
                        }
                    }
                }
            }
            return ous.ToArray();
        }
        /// <summary>
        /// Gets the list of computers the user has access to
        /// </summary>
        /// <param name="UserName"></param>
        /// <returns>A array with distinguishedname of computers</returns>
        public string[] GetComputerWithAccess(string? UserName)
        {
            if (string.IsNullOrEmpty(UserName))
                UserName = GetUserDN();
            HashSet<string> computers = new HashSet<string>();
            foreach (string ou in GetOUWithAccess(UserName))
            {
                DirectorySearcher searcher = new()
                {
                    SearchRoot = new DirectoryEntry("LDAP://" + ou),
                    Filter = $"(objectClass=computer)",
                    SearchScope = SearchScope.Subtree,
                };
                SearchResultCollection results = searcher.FindAll();
                foreach (SearchResult result in results)
                {
                    computers.Add(result.Properties["DistinguishedName"][0].ToString() ?? "");
                }
            }
            return computers.ToArray();
        }
        /// <summary>
        /// Gets the current elevation for the specified user
        /// </summary>
        /// <param name="UserName">is the user name</param>
        /// <returns>A lost of hosts, with the current delegation</returns>
        public string[] GetCurrentElevation(string? UserName)
        {
            HashSet<string> result = new HashSet<string>();
            String pattern = $"{Config.DomainSeparator}(.+)$";
            Regex regex = new(pattern);
            UserName = GetUserDN(); // Get the user DN if not provided
            DirectoryEntry JITgroupOU = new($"LDAP://{Config.OU}");
            DirectorySearcher searcher = new(JITgroupOU)
            {
                Filter = $"(&(objectClass=group)(name={Config.AdminPreFix}*))",
                SearchScope = SearchScope.OneLevel
            };
            searcher.PropertiesToLoad.Add("member");
            searcher.PropertiesToLoad.Add("name");
            foreach (SearchResult searchResult in searcher.FindAll())
            {
                if (searchResult.Properties["member"] != null)
                {
                    foreach (string member in searchResult.Properties["member"])
                    {
                        if (member.Equals(UserName, StringComparison.OrdinalIgnoreCase))
                        { 
                            Match match = regex.Match(searchResult.Properties["name"][0].ToString() ?? "");
                            if (match.Success)
                            {
                                result.Add(match.Groups[1].Value);
                            }
                        }
                    }
                }
            }
            return result.ToArray();
        }
    }
}
