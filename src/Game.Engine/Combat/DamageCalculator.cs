using Game.Core.Enums;
using Game.Core.Models;

namespace Game.Engine.Combat;

/// <summary>
/// Calcula el daño aplicando todas las fórmulas del juego.
/// Incluye contadores de clase de unidad.
/// </summary>
public class DamageCalculator
{
    public double CurrentTime { get; set; }

    public DamageResult Calculate(Entity attacker, Entity target, DamageType damageType)
    {
        var result = new DamageResult
        {
            SourceId = attacker.Id,
            TargetId = target.Id,
            DamageType = damageType
        };

        // 1. Chequear esquive
        if (Random.Shared.NextDouble() < target.Stats.DodgeRate)
        {
            result.IsDodged = true;
            return result;
        }

        // 2. Daño base
        result.RawDamage = attacker.Stats.Attack;

        // 3. Multiplicador por counter de clase (si aplica)
        var classMultiplier = 1.0;
        if (attacker is Unit attackerUnit && target is Unit targetUnit)
        {
            classMultiplier = UnitClassCounters.GetMultiplier(attackerUnit.Class, targetUnit.Class);
        }
        result.RawDamage = (int)(result.RawDamage * classMultiplier);

        // 4. Aplicar defensa según tipo de daño
        var defense = damageType switch
        {
            DamageType.Physical => target.Stats.Defense,
            DamageType.Magic => target.Stats.MagicDefense,
            DamageType.TrueDamage => 0,
            _ => target.Stats.Defense
        };

        // 5. Fórmula: daño = ataque * 100 / (100 + defensa)
        var damageReduction = 100.0 / (100.0 + Math.Max(0, defense));
        result.FinalDamage = Math.Max(1, (int)(result.RawDamage * damageReduction));

        // 6. Chequear crítico
        if (Random.Shared.NextDouble() < attacker.Stats.CritRate)
        {
            result.IsCritical = true;
            result.FinalDamage = (int)(result.FinalDamage * attacker.Stats.CritDamage);
        }

        return result;
    }

    public DamageResult CalculateWithSkill(Entity attacker, Entity target, Skill skill, int skillDamage)
    {
        var result = new DamageResult
        {
            SourceId = attacker.Id,
            TargetId = target.Id,
            DamageType = skill.DamageType,
            RawDamage = skillDamage
        };

        if (Random.Shared.NextDouble() < target.Stats.DodgeRate)
        {
            result.IsDodged = true;
            return result;
        }

        // Multiplicador de clase para skills que escalan con ataque físico
        var classMultiplier = 1.0;
        if (attacker is Unit attackerUnit && target is Unit targetUnit && skill.DamageType == DamageType.Physical)
        {
            classMultiplier = UnitClassCounters.GetMultiplier(attackerUnit.Class, targetUnit.Class);
        }

        var defense = skill.DamageType switch
        {
            DamageType.Physical => target.Stats.Defense,
            DamageType.Magic => target.Stats.MagicDefense,
            DamageType.TrueDamage => 0,
            _ => target.Stats.Defense
        };

        var damageReduction = 100.0 / (100.0 + Math.Max(0, defense));
        result.FinalDamage = Math.Max(1, (int)(skillDamage * classMultiplier * damageReduction));

        if (Random.Shared.NextDouble() < attacker.Stats.CritRate)
        {
            result.IsCritical = true;
            result.FinalDamage = (int)(result.FinalDamage * attacker.Stats.CritDamage);
        }

        return result;
    }
}
