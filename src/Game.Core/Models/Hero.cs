using Game.Core.Enums;

namespace Game.Core.Models;

/// <summary>
/// Un héroe controlado por el jugador. Tiene skills, equipo y puede subir de nivel.
/// </summary>
public class Hero : Entity
{
    public List<Skill> Skills { get; private set; }
    public List<Buff> ActiveBuffs { get; private set; }
    public double SkillCooldownReduction { get; set; } // 0.0 a 1.0
    public int Experience { get; set; }
    public int ExperienceToNextLevel { get; set; }
    public int Stars { get; set; } // 1-7, como Magic Rush
    public TargetPriority TargetPriority { get; set; }
    public PassiveAbility? Passive { get; set; }
    public int ShieldHp { get; set; } // HP de escudo temporal
    public bool HasSecondChance { get; set; }
    public List<Equipment> Equipment { get; private set; }

    /// <summary>
    /// Stats totales = stats base + bonus de equipo.
    /// </summary>
    public Stats TotalStats
    {
        get
        {
            var total = Stats.Clone();
            foreach (var eq in Equipment)
            {
                total += eq.BonusStats;
            }
            return total;
        }
    }

    public Hero(string id, string name, Stats stats, Rarity rarity = Rarity.Common)
        : base(id, name, EntityType.Hero, stats)
    {
        Skills = new List<Skill>();
        ActiveBuffs = new List<Buff>();
        Equipment = new List<Equipment>();
        Rarity = rarity;
        Stars = 1;
        TargetPriority = TargetPriority.Nearest;
        ExperienceToNextLevel = CalculateExpToLevel(Level);
    }

    public void EquipItem(Equipment item)
    {
        // Remover equipo existente en el mismo slot
        Equipment.RemoveAll(e => e.Slot == item.Slot);
        Equipment.Add(item);
    }

    public void UnequipSlot(EquipmentSlot slot)
    {
        Equipment.RemoveAll(e => e.Slot == slot);
    }

    public void AddSkill(Skill skill)
    {
        Skills.Add(skill);
    }

    public void AddExperience(int amount)
    {
        Experience += amount;
        while (Experience >= ExperienceToNextLevel)
        {
            LevelUp();
        }
    }

    public void LevelUp()
    {
        Experience -= ExperienceToNextLevel;
        Level++;
        ExperienceToNextLevel = CalculateExpToLevel(Level);

        // Mejora de stats por nivel
        Stats.MaxHp += (int)(Stats.MaxHp * 0.08);
        Stats.Attack += (int)(Stats.Attack * 0.06);
        Stats.Defense += (int)(Stats.Defense * 0.05);
        Stats.MagicDefense += (int)(Stats.MagicDefense * 0.05);
        Stats.CurrentHp = Stats.MaxHp;
    }

    public void UpgradeStars()
    {
        if (Stars >= 7) return;
        Stars++;
        var multiplier = 1.0 + Stars * 0.1;
        Stats.MaxHp = (int)(Stats.MaxHp * multiplier);
        Stats.Attack = (int)(Stats.Attack * multiplier);
        Stats.Defense = (int)(Stats.Defense * multiplier);
        Stats.MagicDefense = (int)(Stats.MagicDefense * multiplier);
    }

    public void ApplyBuff(Buff buff)
    {
        ActiveBuffs.Add(buff);
    }

    public void TickBuffs()
    {
        for (int i = ActiveBuffs.Count - 1; i >= 0; i--)
        {
            ActiveBuffs[i].Tick(this);
            if (ActiveBuffs[i].IsExpired)
                ActiveBuffs.RemoveAt(i);
        }
    }

    private static int CalculateExpToLevel(int level) => level * 100 + 50;
}
