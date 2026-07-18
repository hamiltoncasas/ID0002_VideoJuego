using Game.Core.Enums;

namespace Game.Core.Models;

/// <summary>
/// Edificio en el mapa (Castillo, Cuartel, etc).
/// </summary>
public class Building : Entity
{
    public BuildingType BuildingType { get; set; }
    public bool IsMainCastle { get; set; }
    public int UpgradeLevel { get; set; }
    public Dictionary<string, int> ResourcesRequired { get; set; } // resource -> amount
    public int GoldProductionPerSecond { get; set; }
    public int FoodProductionPerSecond { get; set; }

    public Building(string id, string name, Stats stats, BuildingType buildingType, bool isMainCastle = false)
        : base(id, name, EntityType.Building, stats)
    {
        BuildingType = buildingType;
        IsMainCastle = isMainCastle;
        UpgradeLevel = 1;
        ResourcesRequired = new Dictionary<string, int>();
    }

    public void Upgrade()
    {
        UpgradeLevel++;
        Stats.MaxHp += (int)(Stats.MaxHp * 0.15);
        Stats.Defense += (int)(Stats.Defense * 0.1);
        Stats.CurrentHp = Stats.MaxHp;
    }
}

public enum BuildingType
{
    Castle,
    Barracks,       // entrena infantería
    ArcheryRange,   // entrena arqueros
    Stable,         // entrena caballería
    MageTower,      // entrena magos
    Workshop,       // entrena unidades de asedio
    Farm,           // produce comida
    GoldMine,       // produce oro
    Laboratory      // mejora habilidades
}
