using Game.Core.Models;

namespace Game.Core.Interfaces;

/// <summary>
/// Entidad que puede lanzar habilidades.
/// </summary>
public interface ISkillCaster
{
    List<Skill> Skills { get; }
    double SkillCooldownReduction { get; }
    Stats Stats { get; }

    Skill? GetNextReadySkill();
    void UseSkill(Skill skill);
}
