using System.Diagnostics;
namespace JustInTime
{
    class JITLogging
    {
        private JITconfig jITconfig;
        private const string logName = "Tier 1 Management";
        private const string defaultLogPath = "%AppData%\\T1Mgmt.log";
        private const long maxLogSize = 1024 * 1024; //1MB
        private string logPath;
        public JITLogging(JITconfig config)
        {
            logPath = defaultLogPath;
            jITconfig = config;
        }
        public JITLogging(JITconfig config, string path)
        {
            jITconfig = config;
            if (path == null)
            {
                logPath = defaultLogPath;
            }
            else
            {
                var dirName = Path.GetDirectoryName(path);
                if (dirName != null && Directory.Exists(dirName) == false)
                {
                    try
                    { Directory.CreateDirectory(dirName); }
                    catch
                    {
                        logPath = defaultLogPath;
                    }
                }
            }
            if (File.Exists(logPath) && new FileInfo(logPath).Length > maxLogSize)
            {
                string backupLog = Path.ChangeExtension(logPath, ".bak");
                if (File.Exists(backupLog)) File.Delete(backupLog);
                File.Move(logPath, backupLog);
            }
            RegisterEventSource();
        }
        public void RegisterEventSource()
        {
            if (!EventLog.SourceExists(jITconfig.EventSource))
            {
                EventLog.CreateEventSource(jITconfig.EventSource, logName);
            }
        }

        public void NewLogEntry(string message, EventLogEntryType type, int eventID)
        {
            EventLog.WriteEntry(jITconfig.EventSource, message, type, eventID);
            using (StreamWriter Writer = new StreamWriter(logPath, append: true))
            {
                //Date;Type;EventID;Message
                Writer.WriteLine($"{DateTime.Now:yyyy-MM-dd HH:mm:ss};{type.ToString().ToUpper()};{eventID};{message}");
            }
        }

    }
}