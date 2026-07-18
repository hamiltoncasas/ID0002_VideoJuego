using Game.Core.Models;

namespace Game.Data.Serialization;

/// <summary>
/// Perfil persistente del jugador (para guardar progreso).
/// </summary>
public class PlayerProfile
{
    public string PlayerName { get; set; } = "Arqueólogo";
    public int Level { get; set; } = 1;
    public int Experience { get; set; }
    public int TotalGoldEarned { get; set; }
    public int TotalGemsEarned { get; set; }
    public int CurrentGems { get; set; }
    public int HighestWaveCleared { get; set; }
    public List<SavedHero> OwnedHeroes { get; set; } = new();
    public Dictionary<string, int> Resources { get; set; } = new()
    {
        ["gold"] = 500,
        ["food"] = 200,
        ["wood"] = 100,
        ["stone"] = 50
    };

    public void AddExperience(int amount)
    {
        Experience += amount;
        var expToNext = Level * 150;
        while (Experience >= expToNext)
        {
            Experience -= expToNext;
            Level++;
            expToNext = Level * 150;
        }
    }
}

public class SavedHero
{
    public string HeroId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public int Level { get; set; } = 1;
    public int Stars { get; set; } = 1;
    public int Experience { get; set; }
    public int SkillLevel { get; set; } = 1;
    public bool IsMain { get; set; }
}

/// <summary>
/// Serializador simple a JSON.
/// </summary>
public static class SaveManager
{
    private static readonly string SavePath = "savegame.json";

    public static void Save(PlayerProfile profile)
    {
        var json = System.Text.Json.JsonSerializer.Serialize(profile, new System.Text.Json.JsonSerializerOptions
        {
            WriteIndented = true
        });
        File.WriteAllText(SavePath, json);
    }

    public static PlayerProfile? Load()
    {
        if (!File.Exists(SavePath)) return null;
        var json = File.ReadAllText(SavePath);
        return System.Text.Json.JsonSerializer.Deserialize<PlayerProfile>(json);
    }
}
