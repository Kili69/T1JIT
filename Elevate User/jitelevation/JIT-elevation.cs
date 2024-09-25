using System;
using System.IO;
using System.Diagnostics;
using System.Threading.Tasks.Dataflow;
using System.Text.Json;
using WindowsJustInTime;
using System.Diagnostics.Eventing.Reader;

namespace WindowsJustInTime{
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
    }
    public class JustInTime
    #pragma warning restore CA1050 // Declare types in namespaces
    {
        #pragma warning disable CA1416 // Validate platform compatibility
        private readonly int iMaxLogFileSize = 1048576;
        private readonly string LogFilePath = Environment.SpecialFolder.CommonApplicationData + "\\Just-In-Time\\Elevation.log";
        private readonly JitConfig  Configuration;
        
        private enum SeverityType { Debug, Information, Warning, Error}
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
        public void ElevateUser(int RequestID){
            writelog("ElevateUser process started (RequestID $eventRecordID). Detailed logging available" + LogFilePath,SeverityType.Information,2106);
            string queryString = "*[System/Provider/@Name='"+ Configuration.EventSource + "']";
            EventLogQuery eventQuery = new EventLogQuery(Configuration.EventLog,PathType.LogName,queryString);
            EventLogReader logReader= new EventLogReader(eventQuery);
            EventRecord eventinstance;
            while ((eventinstance = logReader.ReadEvent())!= null){
                if (eventinstance.Properties[0].Value.ToString() == RequestID.ToString()){
                    string EventMessage = eventinstance.FormatDescription();
                    writelog("Raw Event from Record " + RequestID + ": " + EventMessage, SeverityType.Debug,0);
                    ElevationInfo UserRequest = JsonSerializer.Deserialize<ElevationInfo>(EventMessage);                        
                    ElevateUser(UserRequest);
                    return;
                }
            }
            if (eventinstance == null){
                writelog("A event record with event ID "+ RequestID + " is not available in Eventlog", SeverityType.Warning, 2006 );
            }
        }
        public void ElevateUser(ElevationInfo UserElevationInfo){
//check Server gruppe
//check user
//check delegation
//add user to group
        }
        //constructor
        public JustInTime(){
            InitLogFile();
            if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("JustInTimeConfig"))){
                Configuration = ReadJITconfiguration(Environment.GetEnvironmentVariable("JustInTimeConfig"));
            } else {
                Configuration = ReadJITconfiguration("jit.config");
            }
        }
        public JustInTime(string ConfigurationFile){
            InitLogFile();
            Configuration = ReadJITconfiguration(ConfigurationFile);        
        }
}
