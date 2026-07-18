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
    private readonly Dictionary<string, double> _attackCooldowns = new();

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

        ProcessAttacks(playerEntities.Where(e => e.Stats.IsAlive), enemyEntities, deltaSeconds);
        ProcessAttacks(enemyEntities.Where(e => e.Stats.IsAlive), playerEntities, deltaSeconds);
    }

    private void ProcessAttacks(IEnumerable<Entity> attackers, List<Entity> targets, double deltaSeconds)
    {
        foreach (var attacker in attackers)
        {
            // Inicializar cooldown si no existe
            if (!_attackCooldowns.ContainsKey(attacker.Id))
                _attackCooldowns[attacker.Id] = 0;

            // Reducir cooldown
            _attackCooldowns[attacker.Id] -= deltaSeconds;

            // Si el cooldown llegó a 0, atacar
            if (_attackCooldowns[attacker.Id] <= 0)
            {
                var target = _targetSelector.SelectTarget(attacker, targets);
                if (target == null) continue;

                DealDamage(attacker, target);

                // Resetear cooldown basado en attack speed
                var attackInterval = 1.0 / Math.Max(attacker.Stats.AttackSpeed, 0.1);
                _attackCooldowns[attacker.Id] = attackInterval;
            }
        }
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

    /// <summary>
    /// Limpia los cooldowns (para nueva batalla).
    /// </summary>
    public void ResetCooldowns() => _attackCooldowns.Clear();
}
