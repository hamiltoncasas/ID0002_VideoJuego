namespace Game.Core.Models;

/// <summary>
/// Sinergia entre dos o más héroes. Si están juntos en el equipo,
/// se activan bonificaciones adicionales.
/// </summary>
public class Synergy
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int RequiredCount { get; set; } = 2; // cuantos héroes se necesitan
    public List<string> RequiredHeroIds { get; set; } = new();
    public SynergyEffect Effect { get; set; }
    public double Value { get; set; }
    public bool IsActive { get; set; }
}

/// <summary>
/// Efecto que otorga la sinergia.
/// </summary>
public enum SynergyEffect
{
    AllStatsPercent,        // % a todos los stats
    AttackSpeedPercent,     // % velocidad de ataque
    DamageReduction,        // reducción de daño recibido
    CriticalChance,         // +% chance crítico
    GoldBonus,              // +% oro obtenido
    HealingPerSecond,       // curación por segundo a todos
    ShieldOnStart           // escudo al iniciar batalla
}

/// <summary>
/// Evalúa sinergias entre los héroes de un equipo.
/// </summary>
public class SynergyEvaluator
{
    public static List<Synergy> Evaluate(List<Hero> heroes, List<Synergy> availableSynergies)
    {
        var heroIds = heroes.Select(h => h.Id).ToHashSet();
        var activated = new List<Synergy>();

        foreach (var synergy in availableSynergies)
        {
            var matching = synergy.RequiredHeroIds.Count(id => heroIds.Contains(id));
            if (matching >= synergy.RequiredCount)
            {
                synergy.IsActive = true;
                activated.Add(synergy);
            }
        }

        return activated;
    }

    /// <summary>
    /// Aplica los efectos de sinergia a los stats de los héroes.
    /// </summary>
    public static void ApplySynergyBuffs(List<Hero> heroes, List<Synergy> synergies)
    {
        foreach (var synergy in synergies.Where(s => s.IsActive))
        {
            foreach (var hero in heroes)
            {
                switch (synergy.Effect)
                {
                    case SynergyEffect.AllStatsPercent:
                        hero.Stats.MaxHp += (int)(hero.Stats.MaxHp * synergy.Value);
                        hero.Stats.Attack += (int)(hero.Stats.Attack * synergy.Value);
                        hero.Stats.Defense += (int)(hero.Stats.Defense * synergy.Value);
                        break;
                    case SynergyEffect.AttackSpeedPercent:
                        hero.Stats.AttackSpeed *= (1.0 + synergy.Value);
                        break;
                    case SynergyEffect.CriticalChance:
                        hero.Stats.CritRate = Math.Min(1.0, hero.Stats.CritRate + synergy.Value);
                        break;
                }
            }
        }
    }
}
