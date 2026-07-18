using Game.Core.Enums;
using Game.Core.Models;

namespace Game.Data.Config;

/// <summary>
/// Tablas de balance del juego. Configuración centralizada.
/// </summary>
public static class GameBalance
{
    // ─── HÉROES DISPONIBLES ───
    public static List<HeroTemplate> HeroTemplates => new()
    {
        new HeroTemplate
        {
            Id = "hero_guerrero",
            Name = "Guerrero Sol",
            BaseStats = new Stats
            {
                MaxHp = 1200, CurrentHp = 1200,
                Attack = 80, Defense = 45, MagicDefense = 25,
                AttackSpeed = 1.2, Range = 2.0, MoveSpeed = 2.5,
                CritRate = 0.10, CritDamage = 1.5, DodgeRate = 0.05
            },
            Rarity = Rarity.Common,
            FormationRow = FormationRow.Front,
            Passive = new PassiveAbility
            {
                Id = "passive_guerrero", Name = "Furia Solar",
                Description = "Al matar un enemigo, recupera 10% de su HP máximo.",
                Trigger = PassiveTrigger.OnKill, Effect = PassiveEffect.HealOnKill, Value = 0.10, ValuePerLevel = 0.02
            },
            Skills = new List<SkillTemplate>
            {
                new() { Id = "skill_golpe_poderoso", Name = "Golpe Poderoso",
                        TargetType = SkillTargetType.SingleEnemy, Cooldown = 8,
                        BaseDamage = 50, DamageMultiplier = 1.5, DamageType = DamageType.Physical,
                        Description = "Un golpe devastador que causa 150% de daño físico." }
            }
        },
        new HeroTemplate
        {
            Id = "hero_chaman",
            Name = "Chamán del Sol",
            BaseStats = new Stats
            {
                MaxHp = 800, CurrentHp = 800,
                Attack = 60, Defense = 20, MagicDefense = 50,
                AttackSpeed = 0.8, Range = 5.0, MoveSpeed = 2.0,
                CritRate = 0.15, CritDamage = 1.8, DodgeRate = 0.10
            },
            Rarity = Rarity.Rare,
            FormationRow = FormationRow.Back,
            Passive = new PassiveAbility
            {
                Id = "passive_chaman", Name = "Sabiduría Ancestral",
                Description = "Todas las unidades aliadas tienen +8% de ataque.",
                Trigger = PassiveTrigger.AlwaysOn, Effect = PassiveEffect.TeamStatBoost, Value = 0.08, ValuePerLevel = 0.02
            },
            Skills = new List<SkillTemplate>
            {
                new() { Id = "skill_rayo_solar", Name = "Rayo Solar",
                        TargetType = SkillTargetType.SingleEnemy, Cooldown = 6,
                        BaseDamage = 80, DamageMultiplier = 2.0, DamageType = DamageType.Magic,
                        Description = "Invoca un rayo de energía solar que causa 200% de daño mágico." }
            }
        },
        new HeroTemplate
        {
            Id = "hero_guardiana",
            Name = "Guardiana Dorada",
            BaseStats = new Stats
            {
                MaxHp = 1800, CurrentHp = 1800,
                Attack = 50, Defense = 70, MagicDefense = 40,
                AttackSpeed = 0.7, Range = 2.0, MoveSpeed = 2.0,
                CritRate = 0.05, CritDamage = 1.2, DodgeRate = 0.02
            },
            Rarity = Rarity.Common,
            FormationRow = FormationRow.Front,
            Passive = new PassiveAbility
            {
                Id = "passive_guardiana", Name = "Escudo Sagrado",
                Description = "Al iniciar la batalla, obtiene un escudo que absorbe 15% de su HP máximo.",
                Trigger = PassiveTrigger.BattleStart, Effect = PassiveEffect.Shield, Value = 0.15, ValuePerLevel = 0.03
            },
            Skills = new List<SkillTemplate>
            {
                new() { Id = "skill_escudo_sagrado", Name = "Escudo Sagrado",
                        TargetType = SkillTargetType.Self, Cooldown = 12,
                        BaseDamage = 0, DamageMultiplier = 0, DamageType = DamageType.Physical,
                        SelfBuff = new Buff("buff_escudo", "Protección Solar", BuffType.Invulnerability, 3.0),
                        Description = "Se vuelve invulnerable por 3 segundos." }
            }
        },
        new HeroTemplate
        {
            Id = "hero_aguila",
            Name = "Águila Guerrera",
            BaseStats = new Stats
            {
                MaxHp = 900, CurrentHp = 900,
                Attack = 100, Defense = 25, MagicDefense = 20,
                AttackSpeed = 1.8, Range = 2.5, MoveSpeed = 3.5,
                CritRate = 0.20, CritDamage = 2.0, DodgeRate = 0.12
            },
            Rarity = Rarity.Epic,
            FormationRow = FormationRow.Front,
            Passive = new PassiveAbility
            {
                Id = "passive_aguila", Name = "Garra Veloz",
                Description = "Cada ataque tiene 20% de chance de golpear dos veces.",
                Trigger = PassiveTrigger.AlwaysOn, Effect = PassiveEffect.SplashAttack, Value = 0.20, ValuePerLevel = 0.03
            },
            Skills = new List<SkillTemplate>
            {
                new() { Id = "skill_rafaga", Name = "Ráfaga de Plumas",
                        TargetType = SkillTargetType.AllEnemies, Cooldown = 10,
                        BaseDamage = 30, DamageMultiplier = 1.2, DamageType = DamageType.Physical,
                        Description = "Ataca a todos los enemigos causando 120% de daño físico." }
            }
        },
        new HeroTemplate
        {
            Id = "hero_curandera",
            Name = "Sacerdotisa Lunar",
            BaseStats = new Stats
            {
                MaxHp = 700, CurrentHp = 700,
                Attack = 40, Defense = 15, MagicDefense = 60,
                AttackSpeed = 0.6, Range = 5.0, MoveSpeed = 2.0,
                CritRate = 0.05, CritDamage = 1.5, DodgeRate = 0.15
            },
            Rarity = Rarity.Rare,
            FormationRow = FormationRow.Back,
            Passive = new PassiveAbility
            {
                Id = "passive_curandera", Name = "Luz Sanadora",
                Description = "Cada 5 segundos, cura al héroe más herido del equipo por 5% de su HP.",
                Trigger = PassiveTrigger.Periodic, Effect = PassiveEffect.HealOnKill, Value = 0.05, ValuePerLevel = 0.01
            },
            Skills = new List<SkillTemplate>
            {
                new() { Id = "skill_curacion", Name = "Plegaria Lunar",
                        TargetType = SkillTargetType.AllAllies, Cooldown = 8,
                        BaseDamage = 0, DamageMultiplier = 0, DamageType = DamageType.Magic,
                        Description = "Cura a todos los aliados por 20% de su HP máximo." }
            }
        }
    };

    // ─── UNIDADES INVOCABLES ───
    public static List<UnitTemplate> UnitTemplates => new()
    {
        new UnitTemplate
        {
            Id = "unit_guerrero", Name = "Guerrero",
            BaseStats = new Stats
            { MaxHp = 200, CurrentHp = 200, Attack = 25, Defense = 15,
              AttackSpeed = 1.0, Range = 1.5, MoveSpeed = 2.0 },
            UnitClass = UnitClass.Infantry, GoldCost = 50, FoodCost = 25, SquadSize = 3,
            Description = "Soldados de infantería básicos. Buena defensa."
        },
        new UnitTemplate
        {
            Id = "unit_arquero", Name = "Arquero",
            BaseStats = new Stats
            { MaxHp = 120, CurrentHp = 120, Attack = 30, Defense = 5,
              AttackSpeed = 1.5, Range = 5.0, MoveSpeed = 2.0 },
            UnitClass = UnitClass.Archer, GoldCost = 80, FoodCost = 15, SquadSize = 3,
            Description = "Atacan desde lejos. Frágiles pero letales en grupo."
        },
        new UnitTemplate
        {
            Id = "unit_jinete", Name = "Jinete Muisca",
            BaseStats = new Stats
            { MaxHp = 300, CurrentHp = 300, Attack = 35, Defense = 20,
              AttackSpeed = 0.8, Range = 1.5, MoveSpeed = 4.0 },
            UnitClass = UnitClass.Cavalry, GoldCost = 120, FoodCost = 40, SquadSize = 2,
            Description = "Rápidos y poderosos. Ideales para flanquear."
        },
        new UnitTemplate
        {
            Id = "unit_mago", Name = "Sacerdote Solar",
            BaseStats = new Stats
            { MaxHp = 100, CurrentHp = 100, Attack = 40, Defense = 3, MagicDefense = 20,
              AttackSpeed = 0.7, Range = 5.0, MoveSpeed = 1.5 },
            UnitClass = UnitClass.Mage, GoldCost = 150, FoodCost = 20, SquadSize = 2,
            Description = "Poderoso daño mágico. Devasta formaciones enemigas."
        }
    };

    // ─── SINERGIAS ENTRE HÉROES ───
    public static List<Synergy> Synergies => new()
    {
        new Synergy
        {
            Id = "syn_sol_luna", Name = "Sol y Luna",
            Description = "La dualidad solar y lunar otorga +12% a todos los stats.",
            RequiredCount = 2, RequiredHeroIds = new() { "hero_guerrero", "hero_curandera" },
            Effect = SynergyEffect.AllStatsPercent, Value = 0.12
        },
        new Synergy
        {
            Id = "syn_sabiduria", Name = "Sabiduría Ancestral",
            Description = "Chamán + Sacerdotisa: +15% velocidad de ataque para todos.",
            RequiredCount = 2, RequiredHeroIds = new() { "hero_chaman", "hero_curandera" },
            Effect = SynergyEffect.AttackSpeedPercent, Value = 0.15
        },
        new Synergy
        {
            Id = "syn_guardianes", Name = "Guardianes del Templo",
            Description = "Guerrero + Guardiana: +10% reducción de daño recibido.",
            RequiredCount = 2, RequiredHeroIds = new() { "hero_guerrero", "hero_guardiana" },
            Effect = SynergyEffect.DamageReduction, Value = 0.10
        },
        new Synergy
        {
            Id = "syn_cazadores", Name = "Cazadores del Cielo",
            Description = "Águila Guerrera en el equipo: +8% chance de crítico para todas las unidades.",
            RequiredCount = 1, RequiredHeroIds = new() { "hero_aguila" },
            Effect = SynergyEffect.CriticalChance, Value = 0.08
        }
    };
}

// ─── CLASES AUXILIARES ───

public class HeroTemplate
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public Stats BaseStats { get; set; } = new();
    public Rarity Rarity { get; set; }
    public FormationRow FormationRow { get; set; }
    public PassiveAbility? Passive { get; set; }
    public List<SkillTemplate> Skills { get; set; } = new();
}

public class SkillTemplate
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public SkillTargetType TargetType { get; set; }
    public int Cooldown { get; set; }
    public int BaseDamage { get; set; }
    public double DamageMultiplier { get; set; }
    public DamageType DamageType { get; set; }
    public Buff? SelfBuff { get; set; }
    public string Description { get; set; } = string.Empty;
}

public class UnitTemplate
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public Stats BaseStats { get; set; } = new();
    public UnitClass UnitClass { get; set; }
    public int GoldCost { get; set; }
    public int FoodCost { get; set; }
    public int SquadSize { get; set; }
    public string Description { get; set; } = string.Empty;
}
