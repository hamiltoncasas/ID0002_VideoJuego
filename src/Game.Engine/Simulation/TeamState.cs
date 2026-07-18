using Game.Core.Enums;
using Game.Core.Events;
using Game.Core.Models;

namespace Game.Engine.Simulation;

/// <summary>
/// Estado de un equipo en la partida.
/// </summary>
public class TeamState
{
    public string Name { get; set; }
    public Building? Castle { get; set; }
    public List<Hero> Heroes { get; set; }
    public List<Unit> Units { get; set; }
    public List<Building> Buildings { get; set; }
    public Dictionary<LanePosition, List<Entity>> LaneEntities { get; set; }
    public bool IsAlive => Castle?.Stats.IsAlive != false;

    public TeamState(string name)
    {
        Name = name;
        Heroes = new List<Hero>();
        Units = new List<Unit>();
        Buildings = new List<Building>();
        LaneEntities = new Dictionary<LanePosition, List<Entity>>
        {
            [LanePosition.Top] = new(),
            [LanePosition.Mid] = new(),
            [LanePosition.Bot] = new()
        };
    }

    public void AddHero(Hero hero, LanePosition lane)
    {
        Heroes.Add(hero);
        LaneEntities[lane].Add(hero);
    }

    public void AddUnit(Unit unit, LanePosition lane)
    {
        Units.Add(unit);
        LaneEntities[lane].Add(unit);
    }

    public void RemoveDeadEntities()
    {
        foreach (var lane in LaneEntities.Keys)
        {
            LaneEntities[lane].RemoveAll(e => !e.Stats.IsAlive);
        }
        Heroes.RemoveAll(h => !h.Stats.IsAlive);
        Units.RemoveAll(u => !u.Stats.IsAlive);
    }

    public int TotalAlive => LaneEntities.Sum(kv => kv.Value.Count(e => e.Stats.IsAlive));

    public void Tick(double delta)
    {
        foreach (var hero in Heroes.Where(h => h.Stats.IsAlive))
        {
            hero.TickBuffs();
        }
        foreach (var unit in Units.Where(u => u.Stats.IsAlive))
        {
            unit.TickBuffs();
        }
    }
}
