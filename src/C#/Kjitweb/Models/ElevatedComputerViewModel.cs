namespace KjitWeb.Models;

public class ElevatedComputerViewModel
{
    public required string ComputerName { get; init; }
    public string? Domain { get; init; }
    public int? RemainingSeconds { get; init; }
}