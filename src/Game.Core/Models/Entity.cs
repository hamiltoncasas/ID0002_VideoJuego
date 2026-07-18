using Game.Core.Enums;

namespace Game.Core.Models;

/// <summary>
/// Base de toda entidad en el juego (héroes, unidades, edificios).
/// </summary>
public abstract class Entity
{
    public string Id { get; protected set; }
    public string Name { get; protected set; }
    public EntityType EntityType { get; protected set; }
    public Stats Stats { get; protected set; }
    public int Level { get; set; }
    public Rarity Rarity { get; set; }
    public FormationRow FormationRow { get; set; }

    protected Entity(string id, string name, EntityType entityType, Stats stats)
    {
        Id = id;
        Name = name;
        EntityType = entityType;
        Stats = stats;
        Level = 1;
        Rarity = Rarity.Common;
        FormationRow = FormationRow.Mid;
    }

    public virtual void TakeDamage(int damage)
    {
        Stats.CurrentHp = Math.Max(0, Stats.CurrentHp - damage);
    }

    public virtual void Heal(int amount)
    {
        Stats.CurrentHp = Math.Min(Stats.MaxHp, Stats.CurrentHp + amount);
    }

    public virtual void ResetHp()
    {
        Stats.CurrentHp = Stats.MaxHp;
    }

    public override string ToString() => $"{Name} [Lv.{Level}] HP:{Stats.CurrentHp}/{Stats.MaxHp}";
}
