using Game.Core.Enums;

namespace Game.Core.Models;

/// <summary>
/// Habilidad pasiva de un héroe. Siempre activa, sin cooldown.
/// </summary>
public class PassiveAbility
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public PassiveTrigger Trigger { get; set; }
    public PassiveEffect Effect { get; set; }
    public double Value { get; set; }       // magnitud del efecto
    public double ValuePerLevel { get; set; } // escalado por nivel
    public int Level { get; set; } = 1;

    /// <summary>
    /// Calcula el valor actual de la pasiva escalado por nivel.
    /// </summary>
    public double CurrentValue => Value + ValuePerLevel * (Level - 1);
}

/// <summary>
/// Cuándo se activa la pasiva.
/// </summary>
public enum PassiveTrigger
{
    BattleStart,    // al comenzar la batalla
    OnSpawn,        // al entrar en el campo
    OnKill,         // al matar un enemigo
    OnDamageTaken,  // al recibir daño
    OnSkillUse,     // al usar una habilidad
    AlwaysOn,       // siempre activa (modifica stats permanentemente)
    Periodic        // cada cierto tiempo
}

/// <summary>
/// Qué hace la pasiva cuando se activa.
/// </summary>
public enum PassiveEffect
{
    StatBoost,          // aumenta stats del héroe
    TeamStatBoost,      // aumenta stats de todo el equipo
    DamageAura,         // daño periódico a enemigos cercanos
    LifeSteal,          // roba vida al atacar
    Thorns,             // refleja daño
    HealOnKill,         // cura al matar
    Shield,             // escudo al iniciar
    SpeedBoost,         // aumenta velocidad de ataque
    GoldBonus,          // más oro por kill
    SecondChance,       // revive una vez
    ChainLightning,     // ataque en cadena
    SplashAttack        // daño en área al atacar
}
