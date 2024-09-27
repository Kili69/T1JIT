using System.Diagnostics;
using System.Text.Json;
using WindowsJustInTime;
using System.Diagnostics.Eventing.Reader;
using System.DirectoryServices.AccountManagement;
using System.DirectoryServices;
using System.ComponentModel.DataAnnotations;

namespace WindowsJustInTime
{
    public class JitConfig{
        public string ConfigScriptVersion = "0.1.20240123";
        public string AdminPreFix =  "Admin_";
        public string OU = "OU=JIT-Administrator Groups,OU=Tier 1,OU=Admin,DC=contoso,DC=com";
        public int MaxElevatedTime = 1440;
        public int DefaultElevatedTime = 60;
        public int ElevateEventID = 100;
        public string Tier0ServerGroupName ="Tier 0 computers";
        public string LDAPT0Computers = "(\\u0026(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))";
        public string LDAPT0ComputerPath = "OU=Tier 0,OU=Admin";
        public string LDAPT1Computers = "(\\u0026(OperatingSystem=*Windows*)(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))";
        public string EventSource = "T1Mgmt";
        public string EventLog ="Tier 1 Management";
        public int GroupManagementTaskRerun =   5;
        public string GroupManagedServiceAccountName = "T1GroupMgmt";
        public string Domain = "contoso.com";
        public string DelegationConfigPath ="C:\\T1JIT\\delegation.config";
        public bool EnableDelegation = true;
        public bool EnableMultiDomainSupport =true;
        public string[] T1Searchbase = ["OU=Servers,DC=contoso,DC=com","OU=Servers,DC=child,DC=contoso,DC=com"];
        public string DomainSeparator =  "#";
    }
    public class ElevationInfo{
        public string? UserDN;
        public string? ServerGroup;
        public string? ServerDomain;
        public int ElevationTime;
        public string? CallingUser;
    }
    public class JustInTime
    #pragma warning restore CA1050 // Declare types in namespaces
    {
        #pragma warning disable CA1416 // Validate platform compatibility
        private readonly int iMaxLogFileSize = 1048576;
        private readonly string LogFilePath = Environment.SpecialFolder.CommonApplicationData + "\\Just-In-Time\\Elevation.log";
        private readonly JitConfig  Configuration;
        private const int MinimumTTL = 10;
        
        private enum SeverityType { Debug, Information, Warning, Error}
        public enum ElevationResult {Success,ServerNotAvailable,UserNotAvailable,AccessDenied, RequestNotFound, InvalidElevationTime}
        private void writelog(string Message, SeverityType Serverity, int EventID){
            string EventSource = "JIT";
            StreamWriter swLogFile = new StreamWriter(LogFilePath);
            string strLogLine = DateTime.Now.ToString() + ":" + Serverity + ":" + Message;
            
            switch(Serverity){
                case SeverityType.Debug:
                    Console.WriteLine(strLogLine);
                    swLogFile.WriteLine(strLogLine);
                    break;
                case SeverityType.Error:
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine(strLogLine);
                    swLogFile.WriteLine(strLogLine);
                    EventLog.WriteEntry(EventSource, Message, EventLogEntryType.Error, EventID);
                    break;
                case SeverityType.Information:
                    Console.WriteLine(strLogLine);
                    swLogFile.WriteLine(strLogLine);
                    EventLog.WriteEntry(EventSource, Message, EventLogEntryType.Information, EventID);
                    break;
                case SeverityType.Warning:
                    Console.WriteLine(strLogLine);
                    swLogFile.WriteLine(strLogLine);
                    EventLog.WriteEntry(EventSource, Message, EventLogEntryType.Warning, EventID);
                    break;
            }
            
        }
        private void InitLogFile(){
            if (File.Exists(LogFilePath)){
                FileInfo LogFileInfo = new(LogFilePath);
                if (LogFileInfo.Length > iMaxLogFileSize){
                    if (File.Exists(LogFilePath+".001")){
                        File.Delete(LogFilePath+".001");
                    }
                    File.Move(LogFilePath,LogFileInfo+".001");
                }
            }
        }
        public static JitConfig ReadJITconfiguration(string ConfigurationFile ){
            string JsonString = File.ReadAllText(ConfigurationFile);
            return JsonSerializer.Deserialize<JitConfig>(JsonString);
        }
        //<summary>
        // Validates a user based on the eventlog ID and add the user of the request in to the AD Administrator gorup
        //</summary>
        //<param name="RequestID">Is the event ID of the elevation request</param>
        //<returns>The status of the elevation</returns>
        public ElevationResult ElevateUser(int RequestID){
            writelog("ElevateUser process started by eventlog (RequestID $eventRecordID). Detailed logging available" + LogFilePath,SeverityType.Information,2106);
            //Searching the eventlog for the request ID
            string queryString = "*[System/Provider/@Name='"+ Configuration.EventSource + "']";
            EventLogQuery eventQuery = new EventLogQuery(Configuration.EventLog,PathType.LogName,queryString);
            EventLogReader logReader= new EventLogReader(eventQuery);
            EventRecord eventinstance;
            // walking through the event log and search for the event ID
            while ((eventinstance = logReader.ReadEvent())!= null){
                if (eventinstance.Properties[0].Value.ToString() == RequestID.ToString()){
                    string EventMessage = eventinstance.FormatDescription();
                    writelog("Raw Event from Record " + RequestID + ": " + EventMessage, SeverityType.Debug,0);
                    //Reading the event message and convert the JSON into a ElevationInfo object
                    ElevationInfo? UserRequest = JsonSerializer.Deserialize<ElevationInfo>(EventMessage);
                    if (UserRequest != null){
                        return ElevateUser(UserRequest);
                    }
                    break;
                }
            }
            writelog("A event record with event ID "+ RequestID + " is not available in Eventlog", SeverityType.Warning, 2006 );
            return ElevationResult.RequestNotFound;
        }
        //<summary>
        // validates the elevation request and add the user into the  Administrator group
        //</summary>
        // < param name="UserElevationInfo">The user object who needs to be elevated</param>
        // <returns>the status of the elevation request</return>
        public ElevationResult ElevateUser(ElevationInfo UserElevationInfo){
            //Validating the TTL in the request. 
            //If the TTL is below the minimum TTL the TTL will be changed to the MinimumTTL
            //if the TTL is above the confiugred TTL the Maximum TTL in the configuration will be used
            switch (UserElevationInfo.ElevationTime){
                case int ittl when ittl < MinimumTTL:
                    writelog("The requested time " + UserElevationInfo.ElevationTime + " for user " + UserElevationInfo.UserDN + " is lower then minimum time to live " + Configuration.MaxElevatedTime +  " the TTL is changed to 10 minutes", SeverityType.Warning,2003);
                    UserElevationInfo.ElevationTime = MinimumTTL;
                    break;
                case int ittl when ittl > Configuration.MaxElevatedTime:
                    writelog("The requested time " + UserElevationInfo.ElevationTime + " for user " + UserElevationInfo.UserDN + " is higher then maximum time to live " + Configuration.MaxElevatedTime +  " the TTL is changed to the maxmimum elevated time", SeverityType.Warning,2003);
                    UserElevationInfo.ElevationTime = Configuration.MaxElevatedTime;
                    break;
            }
            TimeSpan ttl = TimeSpan.FromMinutes(UserElevationInfo.ElevationTime); //conveting the TTL in Minutes
            // Seaching the group exists. If the group could not be found write a eventlog entry and return with ServerNotAvailable
            PrincipalContext ADcontext = new PrincipalContext (ContextType.Domain);
            GroupPrincipal ElevationGroup = GroupPrincipal.FindByIdentity(ADcontext,UserElevationInfo.ServerGroup);
            if (ElevationGroup == null ){
                writelog("The server " + UserElevationInfo.ServerGroup + " doesn't exists", SeverityType.Warning,2001);
                return ElevationResult.ServerNotAvailable;
            } else {
                //Search the user via global catalog. If the user is not available return with UserNotAvailable 
                DirectorySearcher GlobalCatalogSeracher = new("GC://" + Environment.UserDomainName);
                GlobalCatalogSeracher.PropertiesToLoad.Add("ObjectSID");

                GlobalCatalogSeracher.Filter = "DistinguishedName='" +UserElevationInfo.UserDN + "'";
                SearchResult? User  = GlobalCatalogSeracher.FindOne();
                if (User == null){
                    writelog("Can't find user " + UserElevationInfo.UserDN,SeverityType.Warning,2001);
                    return ElevationResult.UserNotAvailable;
                } else {
                    if (Configuration.EnableDelegation){
                        //ACL verifizierung
                        // Memberof holen
                        // und durch die delegation.config gehen
                        //whenn delegation fehlerhaft mit
                        return ElevationResult.AccessDenied;
                    }
                    // Add the user timebase to the admin group  
                    DirectoryEntry GroupDirEntry = (DirectoryEntry)ElevationGroup.GetUnderlyingObject();
                    GroupDirEntry.Properties["member"].Add(UserElevationInfo.UserDN);
                    GroupDirEntry.Properties["msDS-GroupMSAMembershipExpirationTime"].Value = DateTime.UtcNow.Add(ttl).ToFileTimeUtc();
                    GroupDirEntry.CommitChanges();
                    writelog("User " + UserElevationInfo.UserDN + " added to group " + UserElevationInfo.ServerGroup,SeverityType.Information,2104 );
                    return ElevationResult.Success;
                }
            }
        }
        #region Constructor
        //<summary>
        //Constructor
        //Initializes a new instance of the JustInTime class. This constructor is used if the configuration file
        //if defined with the system variable JustInTimeConfig or in the local directory available
        //</summary>
        //<exception cref="configuration">configuration file not found or invalid</exception>
        //<param></param>
        public JustInTime(){
            InitLogFile();
            if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("JustInTimeConfig"))){
                Configuration = ReadJITconfiguration(Environment.GetEnvironmentVariable("JustInTimeConfig"));
            } else {
                Configuration = ReadJITconfiguration("jit.config");
            }
        }
         //<summary>
        // Constructor
        //Initializes a new instance of the JustInTime class.
        //</summary>
        //<exception cref="configuration">configuration file not found or invalid</exception>
        //<param ConfigurationFile>Is path to the configuration file</param>
        public JustInTime(string ConfigurationFile){
            InitLogFile();
            Configuration = ReadJITconfiguration(ConfigurationFile);        
        }
        #endregion
    }
}
