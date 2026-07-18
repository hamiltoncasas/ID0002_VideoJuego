using Game.Core.Enums;
using Game.Core.Events;
using Game.Core.Models;

namespace Game.Engine.Combat;

/// <summary>
/// Procesa el combate entre entidades en un carril.
/// </summary>
public class CombatSystem
{
    private readonly EventBus _eventBus;
    private readonly DamageCalculator _damageCalc;
    private readonly TargetSelector _targetSelector;

    public CombatSystem(EventBus eventBus)
    {
        _eventBus = eventBus;
        _damageCalc = new DamageCalculator();
        _targetSelector = new TargetSelector();
    }

    /// <summary>
    /// Procesa un tick de combate en un carril específico.
    /// </summary>
    public void ProcessLane(LanePosition lane, List<Entity> playerEntities,
        List<Entity> enemyEntities, double deltaSeconds)
    {
        if (!playerEntities.Any() || !enemyEntities.Any()) return;

        // Procesar ataques del jugador → enemigos
        foreach (var attacker in playerEntities.Where(e => e.Stats.IsAlive))
        {
            var target = _targetSelector.SelectTarget(attacker, enemyEntities);
            if (target == null) continue;

            TryAttack(attacker, target, deltaSeconds);
        }

        // Procesar ataques de enemigos → jugador
        foreach (var attacker in enemyEntities.Where(e => e.Stats.IsAlive))
        {
            var target = _targetSelector.SelectTarget(attacker, playerEntities);
            if (target == null) continue;

            TryAttack(attacker, target, deltaSeconds);
        }
    }

    private void TryAttack(Entity attacker, Entity target, double deltaSeconds)
    {
        // Ataque automático basado en attack speed
        var attackInterval = 1.0 / Math.Max(attacker.Stats.AttackSpeed, 0.01);
        attacker.Stats.Range -= deltaSeconds; // hack temporal para cooldown — esto se refactoriza
        // Nota: En una versión real el cooldown de ataque se maneja con un campo separado
        _damageCalc.CurrentTime += deltaSeconds;
    }

    /// <summary>
    /// Calcula y aplica daño de un atacante a un target.
    /// </summary>
    public DamageResult DealDamage(Entity attacker, Entity target, DamageType damageType = DamageType.Physical)
    {
        var result = _damageCalc.Calculate(attacker, target, damageType);
        target.TakeDamage(result.FinalDamage);
        _eventBus.Publish(new DamageDealtEvent(result));
        return result;
    }

    /// <summary>
    /// Calcula y aplica daño de una skill.
    /// </summary>
    public DamageResult DealSkillDamage(Entity attacker, Entity target, Skill skill)
    {
        var baseDamage = skill.CalculateDamage(attacker.Stats.Attack);
        var result = _damageCalc.CalculateWithSkill(attacker, target, skill, baseDamage);
        target.TakeDamage(result.FinalDamage);
        _eventBus.Publish(new DamageDealtEvent(result));
        return result;
    }
}
