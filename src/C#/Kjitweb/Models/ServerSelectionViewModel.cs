namespace KjitWeb.Models;

public class ServerSelectionViewModel
{
    public List<string> Domains { get; set; } = new();
    public string? SelectedDomain { get; set; }
    public List<string> CurrentElevationGroups { get; set; } = new();
    public List<string> Servers { get; set; } = new();
    public string? SelectedServer { get; set; }
    public int ElevationDurationMinutes { get; set; }
    public int MinElevationDurationMinutes { get; set; }
    public int MaxElevationDurationMinutes { get; set; }
    public int DefaultElevationDurationMinutes { get; set; }
}
