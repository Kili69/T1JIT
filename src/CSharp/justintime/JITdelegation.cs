using System.DirectoryServices;
using System.Security.Principal;
using System.Runtime.Versioning;

namespace JustInTime
{
    /// <summary>
    /// Represents the Access Control List (ACL) for Just-In-Time (JIT) requests.
    /// </summary> 
    /// <remarks>
    /// This class is only supported on Windows platforms.
    /// Kili 2025-08-27
    /// </remarks>
    [SupportedOSPlatform("windows")]
    public class JITacl
    {
        /// <summary>
        /// The distinguished name (DN) of the computer's organizational unit (OU).
        /// </summary>
        public string ComputerOU { get; set; } = "";
        /// <summary>
        /// A list of SIDs (Security Identifiers) for the objects in the ACL.
        /// </summary>
        public string[] ADObject { get; set; } = Array.Empty<string>();
        #region Constructors
        /// <summary>
        /// Initializes a new instance of the JITacl class.
        /// </summary>
        /// <remarks>
        /// This constructor sets the ComputerOU property to an empty string.
        /// Kili 2025-08-27
        /// </remarks>
        public JITacl() { }
        /// <summary>
        /// Initializes a new instance of the JITacl class.
        /// </summary>
        /// <param name="computerOU">The distinguished name (DN) of the computer's organizational unit (OU).</param>
        /// <exception cref="ArgumentException">Thrown when the LDAP path is not found.</exception>
        /// <remarks>
        /// This constructor sets the ComputerOU property by binding to the specified LDAP path.
        /// Kili 2025-08-27
        /// </remarks>
        public JITacl(string computerOU)
        {
            using DirectoryEntry entry = new($"LDAP://{computerOU}");
            // This will bind to the root of the current domain
            if (entry == null)
            {
                throw new ArgumentException($"Could not find the LDAP path {computerOU}");
            }
            else
            {
                var dnValue = entry.Properties["distinguishedName"].Value;
                if (dnValue != null)
                {
#pragma warning disable CS8601 // Possible null reference assignment.
                    ComputerOU = dnValue.ToString();
#pragma warning restore CS8601 // Possible null reference assignment.
                }
                else
                {
                    throw new ArgumentException($"distinguishedName property not found for LDAP path {computerOU}");
                }
            }
        }
        #endregion
        public int AddADobject(string ADObject)
        {
            try
            {
                NTAccount account = new NTAccount(ADObject);
                SecurityIdentifier sid = (SecurityIdentifier)account.Translate(typeof(SecurityIdentifier));
                if (Array.Exists(this.ADObject, element => element != sid.Value))
                {
                    this.ADObject = this.ADObject.Append(sid.Value).ToArray();
                }
                return 0;
            }
            catch (IdentityNotMappedException)
            {
                return -1; // Identity not found
            }
            catch (Exception)
            {
                return -2; // Other error   
            }
        }
        
    }
}