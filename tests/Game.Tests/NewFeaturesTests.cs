using Game.Core.Enums;
using Game.Core.Models;
using Game.Data.Config;
using Xunit;

namespace Game.Tests;

public class NewFeaturesTests
{
    // ─── PASIVAS ───

    [Fact]
    public void HeroPassive_CanBeAssigned()
    {
        var hero = CreateTestHero("hero_test");
        hero.Passive = new PassiveAbility
        {
            Id = "passive_test", Name = "Test Passive",
            Trigger = PassiveTrigger.AlwaysOn, Effect = PassiveEffect.StatBoost,
            Value = 0.10, ValuePerLevel = 0.02
        };

        Assert.NotNull(hero.Passive);
        Assert.Equal(0.10, hero.Passive.CurrentValue);
    }

    [Fact]
    public void Passive_ValueScalesWithLevel()
    {
        var passive = new PassiveAbility
        {
            Id = "p", Name = "Scaling",
            Value = 0.10, ValuePerLevel = 0.05, Level = 3
        };

        Assert.Equal(0.20, passive.CurrentValue); // 0.10 + 0.05 * (3-1) = 0.20
    }

    // ─── SINERGIAS ───

    [Fact]
    public void SynergyEvaluator_ActivatesMatchingSynergies()
    {
        var heroes = new List<Hero>
        {
            CreateTestHero("hero_guerrero"),
            CreateTestHero("hero_curandera")
        };

        var active = SynergyEvaluator.Evaluate(heroes, GameBalance.Synergies);

        Assert.Contains(active, s => s.Id == "syn_sol_luna");
    }

    [Fact]
    public void SynergyEvaluator_DoesNotActivateWithoutMatch()
    {
        var heroes = new List<Hero>
        {
            CreateTestHero("hero_aguila")
        };

        var active = SynergyEvaluator.Evaluate(heroes, GameBalance.Synergies);

        // "Cazadores del Cielo" requiere solo hero_aguila
        Assert.Single(active);
    }

    [Fact]
    public void SynergyEvaluator_AllStatsBoostApplied()
    {
        var hero = CreateTestHero("hero_guerrero");
        var hero2 = CreateTestHero("hero_curandera");
        var heroes = new List<Hero> { hero, hero2 };

        var active = SynergyEvaluator.Evaluate(heroes, GameBalance.Synergies);

        Assert.Contains(active, s => s.Id == "syn_sol_luna");

        var oldAtk = hero.Stats.Attack;
        SynergyEvaluator.ApplySynergyBuffs(heroes, active);
        Assert.True(hero.Stats.Attack > oldAtk);
    }

    // ─── ÁRBOL DE TECNOLOGÍA ───

    [Fact]
    public void TechTree_Research_IncreasesLevel()
    {
        var tree = TechTree.CreateDefault();
        var forge = tree.Technologies.Find(t => t.Id == "forge");
        Assert.NotNull(forge);
        Assert.Equal(0, forge.Level);

        var gold = 200;
        var food = 100;
        var result = tree.Research("forge", ref gold, ref food);

        Assert.True(result);
        Assert.Equal(1, forge.Level);
    }

    [Fact]
    public void TechTree_Research_FailsWithoutResources()
    {
        var tree = TechTree.CreateDefault();
        var gold = 0;
        var food = 0;

        var result = tree.Research("forge", ref gold, ref food);

        Assert.False(result);
        Assert.Equal(0, tree.Technologies[0].Level);
    }

    [Fact]
    public void TechTree_Research_CantExceedMaxLevel()
    {
        var tree = TechTree.CreateDefault();
        var tech = tree.Technologies[0];
        var gold = 9999;
        var food = 9999;

        for (int i = 0; i < tech.MaxLevel; i++)
            tree.Research(tech.Id, ref gold, ref food);

        Assert.True(tech.IsResearched);
        Assert.False(tree.Research(tech.Id, ref gold, ref food));
    }

    [Fact]
    public void TechTree_EffectValues_Accumulate()
    {
        var tree = TechTree.CreateDefault();

        Assert.Equal(0, tree.GetEffectValue(TechEffect.GoldProduction));

        var g = 999; var f = 999;
        tree.Research("mining", ref g, ref f);
        tree.Research("mining", ref g, ref f);

        Assert.Equal(0.30, tree.GetEffectValue(TechEffect.GoldProduction));
    }

    // ─── NUEVOS HÉROES ───

    [Fact]
    public void GameBalance_HasFiveHeroes()
    {
        Assert.Equal(5, GameBalance.HeroTemplates.Count);
    }

    [Fact]
    public void AllHeroesHavePassives()
    {
        foreach (var hero in GameBalance.HeroTemplates)
        {
            Assert.NotNull(hero.Passive);
            Assert.False(string.IsNullOrEmpty(hero.Passive.Name));
        }
    }

    [Fact]
    public void NewHero_Aguila_HighCritRate()
    {
        var aguila = GameBalance.HeroTemplates.Find(h => h.Id == "hero_aguila");
        Assert.NotNull(aguila);
        Assert.Equal(Rarity.Epic, aguila.Rarity);
        Assert.Equal(0.20, aguila.BaseStats.CritRate);
    }

    [Fact]
    public void NewHero_Curandera_HealingSkill()
    {
        var curandera = GameBalance.HeroTemplates.Find(h => h.Id == "hero_curandera");
        Assert.NotNull(curandera);
        Assert.Contains(curandera.Skills, s => s.TargetType == SkillTargetType.AllAllies);
    }

    private static Hero CreateTestHero(string id)
    {
        return new Hero(id, id, new Stats
        {
            MaxHp = 1000, CurrentHp = 1000,
            Attack = 50, Defense = 20,
            AttackSpeed = 1.0, Range = 2.0
        });
    }
}
