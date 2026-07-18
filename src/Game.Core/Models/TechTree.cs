namespace Game.Core.Models;

/// <summary>
/// Tecnología que se puede investigar para mejorar edificios, unidades o economía.
/// Inspirado en el árbol de tecnología de Age of Empires.
/// </summary>
public class Technology
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public TechCategory Category { get; set; }
    public int Level { get; set; } = 0;
    public int MaxLevel { get; set; } = 3;
    public int GoldCost { get; set; }
    public int FoodCost { get; set; }
    public TechEffect Effect { get; set; }
    public double ValuePerLevel { get; set; } // valor agregado por nivel
    public bool IsResearched => Level >= MaxLevel;

    /// <summary>
    /// Valor acumulado actual de la tecnología.
    /// </summary>
    public double CurrentValue => Level * ValuePerLevel;
}

public enum TechCategory
{
    Military,     // mejora unidades
    Economy,      // mejora producción de recursos
    Defense,      // mejora castillo y defensas
    Magic         // mejora habilidades mágicas
}

public enum TechEffect
{
    UnitAttack,         // +% ataque de unidades
    UnitDefense,        // +% defensa de unidades
    UnitSpeed,          // +% velocidad de unidades
    GoldProduction,     // +% producción de oro
    FoodProduction,     // +% producción de comida
    CastleHp,           // +% HP del castillo
    HeroAttack,         // +% ataque de héroes
    HeroSkillDamage,    // +% daño de habilidades
    TrainingSpeed,      // +% velocidad de entrenamiento
    ResourceCost        // -% costo de recursos
}

/// <summary>
/// Árbol de tecnologías completo del jugador.
/// </summary>
public class TechTree
{
    public List<Technology> Technologies { get; set; } = new();

    /// <summary>
    /// Investiga una tecnología si hay recursos suficientes.
    /// </summary>
    public bool Research(string techId, ref int gold, ref int food)
    {
        var tech = Technologies.Find(t => t.Id == techId);
        if (tech == null || tech.IsResearched) return false;

        if (gold < tech.GoldCost || food < tech.FoodCost) return false;

        gold -= tech.GoldCost;
        food -= tech.FoodCost;
        tech.Level++;
        tech.GoldCost = (int)(tech.GoldCost * 1.5);
        tech.FoodCost = (int)(tech.FoodCost * 1.5);
        return true;
    }

    /// <summary>
    /// Aplica los efectos de las tecnologías investigadas a las stats.
    /// </summary>
    public double GetEffectValue(TechEffect effect)
    {
        return Technologies
            .Where(t => t.Effect == effect)
            .Sum(t => t.CurrentValue);
    }

    public static TechTree CreateDefault()
    {
        return new TechTree
        {
            Technologies = new List<Technology>
            {
                new() { Id = "forge", Name = "Forja", Description = "Mejora el ataque de todas las unidades.", Category = TechCategory.Military, Effect = TechEffect.UnitAttack, ValuePerLevel = 0.10, GoldCost = 100, FoodCost = 50 },
                new() { Id = "armor", Name = "Armadura", Description = "Mejora la defensa de todas las unidades.", Category = TechCategory.Military, Effect = TechEffect.UnitDefense, ValuePerLevel = 0.08, GoldCost = 80, FoodCost = 60 },
                new() { Id = "farming", Name = "Cultivos", Description = "Aumenta la producción de comida.", Category = TechCategory.Economy, Effect = TechEffect.FoodProduction, ValuePerLevel = 0.15, GoldCost = 60, FoodCost = 30 },
                new() { Id = "mining", Name = "Minería", Description = "Aumenta la producción de oro.", Category = TechCategory.Economy, Effect = TechEffect.GoldProduction, ValuePerLevel = 0.15, GoldCost = 70, FoodCost = 40 },
                new() { Id = "fortifications", Name = "Fortificaciones", Description = "Aumenta la vida del castillo.", Category = TechCategory.Defense, Effect = TechEffect.CastleHp, ValuePerLevel = 0.12, GoldCost = 120, FoodCost = 80 },
                new() { Id = "runes", Name = "Runas de Poder", Description = "Aumenta el daño de habilidades.", Category = TechCategory.Magic, Effect = TechEffect.HeroSkillDamage, ValuePerLevel = 0.10, GoldCost = 150, FoodCost = 100 },
                new() { Id = "logistics", Name = "Logística", Description = "Reduce el costo de unidades.", Category = TechCategory.Economy, Effect = TechEffect.ResourceCost, ValuePerLevel = 0.05, GoldCost = 90, FoodCost = 60 },
            }
        };
    }
}
