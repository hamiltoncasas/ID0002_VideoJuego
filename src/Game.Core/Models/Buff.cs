using Game.Core.Enums;

namespace Game.Core.Models;

/// <summary>
/// Efecto temporal sobre una entidad (buff/debuff).
/// </summary>
public class Buff
{
    public string Id { get; set; }
    public string Name { get; set; }
    public BuffType Type { get; set; }
    public double DurationSeconds { get; set; }
    public double RemainingSeconds { get; set; }
    public int TickInterval { get; set; } // cada cuantos segundos aplica efecto
    public double TickTimer { get; set; }
    public int ValuePerTick { get; set; } // daño o curación por tick
    public double StatModifierPercent { get; set; } // modificador de stats en %
    public bool IsExpired => RemainingSeconds <= 0;

    public Buff(string id, string name, BuffType type, double durationSeconds)
    {
        Id = id;
        Name = name;
        Type = type;
        DurationSeconds = durationSeconds;
        RemainingSeconds = durationSeconds;
        TickInterval = 1;
    }

    public void Tick(Entity target, double deltaSeconds = 0.1)
    {
        RemainingSeconds -= deltaSeconds;
        TickTimer += deltaSeconds;

        if (TickTimer + 0.001 >= TickInterval) // epsilon por precisión floating-point
        {
            TickTimer = 0;

            switch (Type)
            {
                case BuffType.DamageOverTime:
                    target.TakeDamage(ValuePerTick);
                    break;
                case BuffType.HealOverTime:
                    target.Heal(ValuePerTick);
                    break;
            }
        }
    }

    public Buff Clone()
    {
        return new Buff(Id, Name, Type, DurationSeconds)
        {
            TickInterval = TickInterval,
            ValuePerTick = ValuePerTick,
            StatModifierPercent = StatModifierPercent
        };
    }
}
