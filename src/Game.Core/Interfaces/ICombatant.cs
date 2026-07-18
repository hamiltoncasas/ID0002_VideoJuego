using Game.Core.Models;

namespace Game.Core.Interfaces;

/// <summary>
/// Cualquier entidad que pueda participar en combate.
/// </summary>
public interface ICombatant
{
    string Id { get; }
    string Name { get; }
    Stats Stats { get; }
    bool IsAlive { get; }
    double CurrentAttackCooldown { get; }
    void TakeDamage(int damage);
    void Heal(int amount);
    void ResetAttackCooldown();
    void TickAttackCooldown(double deltaSeconds);
    bool CanAttack();
}
