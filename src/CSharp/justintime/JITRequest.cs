using System.Runtime.Versioning;
namespace JustInTime
{
    /// <summary>
    /// Represents a Just-In-Time (JIT) request. This class contains all the necessary information for processing a JIT request.
    /// The object will be serialized to JSON format for transmission in the Windows event log
    /// </summary>
    /// <remarks>
    /// This class is only supported on Windows platforms.
    /// Kili 2025-08-27
    /// </remarks>
    [SupportedOSPlatform("windows")]
    class JITRequest
    {
        int _elevationTime;
        #region properties
        /// <summary>
        /// The distinguished name (DN) of the user making the request.
        /// </summary>
        public string UserDN { get; set; } = "";
        /// <summary>
        /// The name of the Active Directory group the request is targeting.
        /// </summary>
        public string ServerGroup { get; set; } = "";
        /// <summary>
        /// The time (in minutes) the user is requesting for elevation.
        /// </summary>
        public int ElevationTime
        {
            get { return _elevationTime; }
            set
            {
                if (value < 5)
                    _elevationTime = 5;
                else if (value > 1440)
                    _elevationTime = 1440;
                else
                    _elevationTime = value;
            }
        }
        /// <summary>
        /// The doma dns name of the target server
        /// </summary>
        public string ServerDomain { get; set; } = "";
        /// <summary>
        /// The distinguishedname of the user who initated the request
        /// </summary>
        public string CallingUser { get; set; } = "";
        #endregion

        /// <summary>
        /// Initializes the JITRequest class
        /// </summary>
        public JITRequest() { }
        /// <summary>
        /// Initializes the JITRequest call with properties
        /// </summary>
        /// <param name="userdn">Is the target user</param>
        /// <param name="servergroup">Is the name of the AD group for elevation</param>
        /// <param name="elevationtime">Is the elevation time in minutes. It must be a value between 5 and 1440 minutes</param>
        /// <param name="serverdomain">Is the AD domain DNS name</param>
        /// <param name="callinguser">Is the name of the user who initated the request</param>
        /// <exception cref="ArgumentException">Is thrown if elevationtime is out of range</exception>
        /// <remarks>
        /// This constructor set all properties of the object
        /// created by Kili 2025-08-27
        /// </remarks>
        public JITRequest(string userdn, string servergroup, int elevationtime, string serverdomain, string callinguser)
        {
            UserDN = userdn;
            ServerGroup = servergroup;
            ElevationTime = elevationtime;
            ServerDomain = serverdomain;
            CallingUser = callinguser;
        }
    }
}