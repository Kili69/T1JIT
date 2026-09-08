namespace KjitWeb.Services;

public sealed class MutualTlsOptions
{
    public const string SectionName = "MutualTls";

    public bool Enabled { get; set; }

    public bool CheckCertificateRevocation { get; set; } = true;

    public string[] RequiredEkuOids { get; set; } = [];
}