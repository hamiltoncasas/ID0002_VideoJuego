using Game.Core.Enums;

namespace Game.Core.Models;

/// <summary>
/// Resultado de un cálculo de daño.
/// </summary>
public class DamageResult
{
    public int RawDamage { get; set; }
    public int FinalDamage { get; set; }
    public bool IsCritical { get; set; }
    public bool IsDodged { get; set; }
    public bool IsBlocked { get; set; }
    public DamageType DamageType { get; set; }
    public string SourceId { get; set; } = string.Empty;
    public string TargetId { get; set; } = string.Empty;

    public override string ToString()
    {
        if (IsDodged) return $"{SourceId} ataca a {TargetId} → ESQUIVADO";
        if (IsCritical) return $"{SourceId} ataca a {TargetId} → {FinalDamage} ¡CRÍTICO!";
        return $"{SourceId} ataca a {TargetId} → {FinalDamage}";
    }
}
