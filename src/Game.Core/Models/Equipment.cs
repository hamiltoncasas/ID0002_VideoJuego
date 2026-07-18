using Game.Core.Enums;

namespace Game.Core.Models;

/// <summary>
/// Equipamiento que puede llevar un héroe para mejorar sus stats.
/// </summary>
public class Equipment
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public EquipmentSlot Slot { get; set; }
    public Rarity Rarity { get; set; }
    public int Level { get; set; }
    public Stats BonusStats { get; set; } = new();
    public string Description { get; set; } = string.Empty;
    public string Icon { get; set; } = string.Empty; // referencia al asset

    public void Upgrade()
    {
        Level++;
        BonusStats.MaxHp += (int)(BonusStats.MaxHp * 0.1);
        BonusStats.Attack += (int)(BonusStats.Attack * 0.1);
        BonusStats.Defense += (int)(BonusStats.Defense * 0.1);
    }

    public Equipment Clone()
    {
        return new Equipment
        {
            Id = Id,
            Name = Name,
            Slot = Slot,
            Rarity = Rarity,
            Level = Level,
            BonusStats = BonusStats.Clone(),
            Description = Description,
            Icon = Icon
        };
    }
}

public enum EquipmentSlot
{
    Weapon,     // arma
    Armor,      // armadura
    Helmet,     // casco
    Accessory,  // accesorio (anillo, amuleto)
    Boots       // botas
}
