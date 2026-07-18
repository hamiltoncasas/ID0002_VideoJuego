using Game.Core.Enums;

namespace Game.Core.Models;

/// <summary>
/// Unidad de tropa que acompaña al héroe. Se invoca con recursos.
/// </summary>
public class Unit : Entity
{
    public int GoldCost { get; set; }
    public int FoodCost { get; set; }
    public int TrainingTime { get; set; } // segundos
    public UnitClass Class { get; set; }
    public int SquadSize { get; set; } // cantidad de soldados en este grupo
    public List<Buff> ActiveBuffs { get; private set; }

    public Unit(string id, string name, Stats baseStats, UnitClass unitClass,
                int goldCost = 50, int foodCost = 25, int squadSize = 1)
        : base(id, name, EntityType.Unit, baseStats)
    {
        GoldCost = goldCost;
        FoodCost = foodCost;
        Class = unitClass;
        SquadSize = squadSize;
        ActiveBuffs = new List<Buff>();
    }

    /// <summary>
    /// Daño total del escuadrón considerando el tamaño.
    /// </summary>
    public int SquadAttack => Stats.Attack * SquadSize;
    public int SquadHp => Stats.MaxHp * SquadSize;

    public void ApplyBuff(Buff buff) => ActiveBuffs.Add(buff);
    public void TickBuffs()
    {
        for (int i = ActiveBuffs.Count - 1; i >= 0; i--)
        {
            ActiveBuffs[i].Tick(this);
            if (ActiveBuffs[i].IsExpired)
                ActiveBuffs.RemoveAt(i);
        }
    }
}
