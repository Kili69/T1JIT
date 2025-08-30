using System.DirectoryServices.ActiveDirectory;
using System.Reflection.Metadata;
using System.Text.Json;
namespace JustInTime
{
    public class JITconfig
    {
        public string AdminPreFix { get; set; } = "Admin_";
        public string OU { get; set; } = "";
        public int MaxElevatedTime { get; set; } = 20;
        public int DefaultElevatedTime { get; set; } = 15;
        public int ElevateEventID { get; set; } = 100;
        public string Tier0ServerGroupName { get; set; } = "CN=Tier 0 Computers,OU=Groups,OU=Tier 0,OU=Admin,%DomainDN%";
        public string LDAPT0Computers { get; set; } = "(& (ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))";
        public string[] LDAPT0ComputerPath { get; set; } = [];
        public string LDAPT1Computers { get; set; } = "(& (OperatingSystem=*Windows*)(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))";
        public string EventSource { get; set; } = "T1Mgmt";
        public string EventLog { get; set; } = "Tier 1 Management";
        public int GroupManagementTaskRerun { get; set; } = 10;
        public string GroupManagedServiceAccountName { get; set; } = "T1GroupMgmt";
        public string Domain { get; set; } = "%DomainName%";
        public string DelegationConfigPath { get; set; } = "\\\\%DomainName%\\SYSVOL\\%DomainName%\\Just-In-time\\Tier1delegation.config";
        public bool EnableDelegation { get; set; } = true;
        public bool EnableMultiDomainSupport { get; set; } = true;
        public List<string> T1Searchbase { get; set; } = new List<string> { "OU=Servers,%DomainDN%" };
        public string DomainSeparator { get; set; } = "#";
        public bool UseManagedByforDelegation { get; set; } = true;
        public int MaxConcurrentServer { get; set; } = 50;
        public string ConfigScriptVersion { get; set; } = "";

        public JITconfig()
        {
            // default constructor
        }
        public JITconfig(string Path) : this()
        {
            if (File.Exists(Path) == false)
            {
                throw new FileNotFoundException($"Config file {Path} not found");
            }
            try
            {
                string json = File.ReadAllText(Path);
                JITconfig? tempConfig = JsonSerializer.Deserialize<JITconfig>(json);
                if (tempConfig != null)
                {
                    AdminPreFix = tempConfig.AdminPreFix;
                    OU = tempConfig.OU;
                    MaxElevatedTime = tempConfig.MaxElevatedTime;
                    DefaultElevatedTime = tempConfig.DefaultElevatedTime;
                    ElevateEventID = tempConfig.ElevateEventID;
                    Tier0ServerGroupName = tempConfig.Tier0ServerGroupName;
                    LDAPT0Computers = tempConfig.LDAPT0Computers;
                    LDAPT0ComputerPath = tempConfig.LDAPT0ComputerPath;
                    LDAPT1Computers = tempConfig.LDAPT1Computers;
                    EventSource = tempConfig.EventSource;
                    EventLog = tempConfig.EventLog;
                    GroupManagementTaskRerun = tempConfig.GroupManagementTaskRerun;
                    GroupManagedServiceAccountName = tempConfig.GroupManagedServiceAccountName;
                    Domain = tempConfig.Domain;
                    EnableDelegation = tempConfig.EnableDelegation;
                    EnableMultiDomainSupport = tempConfig.EnableMultiDomainSupport;
                    T1Searchbase = tempConfig.T1Searchbase;
                    DomainSeparator = tempConfig.DomainSeparator;
                    UseManagedByforDelegation = tempConfig.UseManagedByforDelegation;
                    MaxConcurrentServer = tempConfig.MaxConcurrentServer;
                    DelegationConfigPath = tempConfig.DelegationConfigPath;
                }
            }
            catch (Exception ex)
            {
                throw new Exception($"Error reading config file {Path}: {ex.Message}");
            }
        }
    }
}