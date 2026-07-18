using Game.Core.Enums;

namespace Game.Core.Models;

/// <summary>
/// Habilidad que puede usar un héroe o unidad especial.
/// </summary>
public class Skill
{
    public string Id { get; set; }
    public string Name { get; set; }
    public string Description { get; set; } = string.Empty;
    public int Level { get; set; }
    public int MaxLevel { get; set; }
    public double CooldownSeconds { get; set; }
    public double CurrentCooldown { get; set; }
    public double CastTimeSeconds { get; set; }
    public SkillTargetType TargetType { get; set; }
    public DamageType DamageType { get; set; }
    public int BaseDamage { get; set; }
    public double DamageMultiplier { get; set; } // % del ataque del caster
    public double Range { get; set; }
    public double AoERadius { get; set; }
    public Buff? SelfBuff { get; set; } // buff que se aplica al caster
    public Buff? TargetBuff { get; set; } // buff/debuff que se aplica al target

    public Skill(string id, string name, SkillTargetType targetType, double cooldownSeconds = 10)
    {
        Id = id;
        Name = name;
        TargetType = targetType;
        CooldownSeconds = cooldownSeconds;
        Level = 1;
        MaxLevel = 5;
        DamageMultiplier = 1.0;
        DamageType = DamageType.Physical;
    }

    public bool IsReady => CurrentCooldown <= 0;

    public void Use()
    {
        CurrentCooldown = CooldownSeconds;
    }

    public void TickCooldown(double deltaSeconds)
    {
        if (CurrentCooldown > 0)
            CurrentCooldown = Math.Max(0, CurrentCooldown - deltaSeconds);
    }

    public void LevelUp()
    {
        if (Level >= MaxLevel) return;
        Level++;
        BaseDamage += (int)(BaseDamage * 0.15);
        DamageMultiplier += 0.1;
    }

    public int CalculateDamage(int casterAttack)
    {
        return BaseDamage + (int)(casterAttack * DamageMultiplier);
    }
}
