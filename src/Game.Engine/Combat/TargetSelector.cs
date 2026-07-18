using Game.Core.Enums;
using Game.Core.Models;

namespace Game.Engine.Combat;

/// <summary>
/// Selecciona el target óptimo para un atacante.
/// </summary>
public class TargetSelector
{
    /// <summary>
    /// Selecciona el mejor target según la prioridad del atacante.
    /// </summary>
    public Entity? SelectTarget(Entity attacker, List<Entity> potentialTargets)
    {
        var alive = potentialTargets.Where(e => e.Stats.IsAlive).ToList();
        if (!alive.Any()) return null;

        // Si el atacante es un héroe, usa su TargetPriority
        if (attacker is Hero hero)
        {
            return hero.TargetPriority switch
            {
                TargetPriority.Weakest => alive.OrderBy(e => e.Stats.CurrentHp).First(),
                TargetPriority.Strongest => alive.OrderByDescending(e => e.Stats.MaxHp).First(),
                TargetPriority.BackRow => alive.Where(e => e.FormationRow == FormationRow.Back)
                                               .OrderBy(e => e.Stats.CurrentHp)
                                               .FirstOrDefault() ?? alive.First(),
                _ => alive.OrderBy(e => e.FormationRow == FormationRow.Front ? 0 :
                                        e.FormationRow == FormationRow.Mid ? 1 : 2)
                         .ThenBy(e => e.Stats.CurrentHp)
                         .First()
            };
        }

        // Unidades atacan al más cercano en formación frontal
        return alive.OrderBy(e => e.FormationRow == FormationRow.Front ? 0 :
                                   e.FormationRow == FormationRow.Mid ? 1 : 2)
                    .ThenBy(e => e.Stats.CurrentHp)
                    .First();
    }
}
