using Game.Core.Enums;
using Game.Core.Models;
using Xunit;

namespace Game.Tests;

public class CoreModelsTests
{
    [Fact]
    public void Hero_TakeDamage_ReducesHp()
    {
        var hero = CreateTestHero();
        hero.TakeDamage(100);

        Assert.Equal(1100, hero.Stats.CurrentHp);
    }

    [Fact]
    public void Hero_TakeDamage_DoesNotGoBelowZero()
    {
        var hero = CreateTestHero();
        hero.TakeDamage(9999);

        Assert.Equal(0, hero.Stats.CurrentHp);
        Assert.False(hero.Stats.IsAlive);
    }

    [Fact]
    public void Hero_Heal_RestoresHp()
    {
        var hero = CreateTestHero();
        hero.TakeDamage(500);

        Assert.Equal(700, hero.Stats.CurrentHp);

        hero.Heal(200);
        Assert.Equal(900, hero.Stats.CurrentHp);
    }

    [Fact]
    public void Hero_Heal_DoesNotExceedMax()
    {
        var hero = CreateTestHero();
        hero.Heal(500);

        Assert.Equal(hero.Stats.MaxHp, hero.Stats.CurrentHp);
    }

    [Fact]
    public void Hero_LevelUp_IncreasesStats()
    {
        var hero = CreateTestHero();
        var oldAtk = hero.Stats.Attack;
        var oldHp = hero.Stats.MaxHp;

        hero.AddExperience(1000); // suficiente para subir varios niveles

        Assert.True(hero.Level > 1);
        Assert.True(hero.Stats.Attack > oldAtk);
        Assert.True(hero.Stats.MaxHp > oldHp);
    }

    [Fact]
    public void Hero_UpgradeStars_IncreasesStats()
    {
        var hero = CreateTestHero();
        var oldAtk = hero.Stats.Attack;

        hero.UpgradeStars();

        Assert.Equal(2, hero.Stars);
        Assert.True(hero.Stats.Attack > oldAtk);
    }

    [Fact]
    public void Skill_Cooldown_TicksDown()
    {
        var skill = new Skill("test", "Test Skill", SkillTargetType.SingleEnemy, 5.0);

        Assert.True(skill.IsReady);

        skill.Use();
        Assert.False(skill.IsReady);

        skill.TickCooldown(5.0);
        Assert.True(skill.IsReady);
    }

    [Fact]
    public void Skill_LevelUp_IncreasesDamage()
    {
        var skill = new Skill("test", "Test", SkillTargetType.SingleEnemy)
        {
            BaseDamage = 100,
            DamageMultiplier = 1.0
        };

        skill.LevelUp();

        Assert.Equal(2, skill.Level);
        Assert.Equal(115, skill.BaseDamage); // 100 * 1.15
    }

    [Fact]
    public void DamageCalculation_Physical_ReducesByDefense()
    {
        var calc = new Game.Engine.Combat.DamageCalculator();
        var attacker = CreateTestHero();
        var target = CreateTestHero();
        target.Stats.Defense = 100; // 100 def = 50% reduction

        var result = calc.Calculate(attacker, target, DamageType.Physical);

        Assert.False(result.IsDodged);
        Assert.True(result.FinalDamage > 0);
        Assert.True(result.FinalDamage < result.RawDamage); // defense reduced it
    }

    [Fact]
    public void DamageCalculation_TrueDamage_IgnoresDefense()
    {
        var calc = new Game.Engine.Combat.DamageCalculator();
        var attacker = CreateTestHero();
        attacker.Stats.Attack = 100;
        var target = CreateTestHero();
        target.Stats.Defense = 1000; // mucha defensa

        var result = calc.Calculate(attacker, target, DamageType.TrueDamage);

        Assert.Equal(100, result.FinalDamage); // true damage ignora defensa
    }

    [Fact]
    public void Stats_Clone_CreatesIndependentCopy()
    {
        var original = new Stats { MaxHp = 1000, Attack = 50 };
        var clone = original.Clone();

        clone.Attack = 999;

        Assert.Equal(50, original.Attack);
        Assert.Equal(999, clone.Attack);
    }

    [Fact]
    public void Entity_ResetHp_FullyHeals()
    {
        var hero = CreateTestHero();
        hero.TakeDamage(500);
        Assert.NotEqual(hero.Stats.MaxHp, hero.Stats.CurrentHp);

        hero.ResetHp();

        Assert.Equal(hero.Stats.MaxHp, hero.Stats.CurrentHp);
    }

    [Fact]
    public void Buff_Tick_DamageOverTime_DealsDamage()
    {
        var hero = CreateTestHero();
        var dot = new Buff("dot_test", "Veneno", BuffType.DamageOverTime, 5.0)
        {
            TickInterval = 1,
            ValuePerTick = 50
        };
        var initialHp = hero.Stats.CurrentHp;

        // Simular 12 ticks de 100ms para pasar el intervalo de 1s
        for (int i = 0; i < 12; i++)
        {
            dot.Tick(hero);
        }

        Assert.True(hero.Stats.CurrentHp < initialHp);
    }

    private static Hero CreateTestHero()
    {
        return new Hero("test_hero", "Test Hero", new Stats
        {
            MaxHp = 1200,
            CurrentHp = 1200,
            Attack = 80,
            Defense = 30,
            AttackSpeed = 1.0,
            Range = 2.0
        });
    }
}
