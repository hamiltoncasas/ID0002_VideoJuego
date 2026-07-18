using Game.Core.Enums;
using Game.Core.Events;
using Game.Core.Models;
using Game.Engine.Combat;
using Xunit;

namespace Game.Tests;

public class CombatTests
{
    [Fact]
    public void CombatSystem_DealDamage_EntityTakesDamage()
    {
        var bus = new EventBus();
        var combat = new CombatSystem(bus);
        var attacker = CreateEntity("attacker", 100);
        var target = CreateEntity("target", 500);

        var result = combat.DealDamage(attacker, target);

        Assert.False(result.IsDodged);
        Assert.True(target.Stats.CurrentHp < 500);
    }

    [Fact]
    public void CombatSystem_DealSkillDamage_AppliesSkillMultiplier()
    {
        var bus = new EventBus();
        var combat = new CombatSystem(bus);
        var attacker = CreateEntity("mage", 80);
        var target = CreateEntity("target", 1000);

        var skill = new Skill("fireball", "Fireball", SkillTargetType.SingleEnemy)
        {
            BaseDamage = 50,
            DamageMultiplier = 2.0,
            DamageType = DamageType.Magic
        };

        var result = combat.DealSkillDamage(attacker, target, skill);

        Assert.True(target.Stats.CurrentHp < 1000);
        Assert.Equal(DamageType.Magic, result.DamageType);
    }

    [Fact]
    public void TargetSelector_SelectsWeakest_WhenPriorityIsWeakest()
    {
        var selector = new TargetSelector();
        var attacker = new Hero("hero", "Hero", new Stats { Attack = 50, Range = 5 })
        {
            TargetPriority = TargetPriority.Weakest
        };
        var targets = new List<Entity>
        {
            CreateEntity("strong", 1000),
            CreateEntity("weak", 50),
            CreateEntity("medium", 500)
        };

        var selected = selector.SelectTarget(attacker, targets);

        Assert.NotNull(selected);
        Assert.Equal("weak", selected.Id);
    }

    [Fact]
    public void TargetSelector_SelectsBackRow_WhenPriorityIsBackRow()
    {
        var selector = new TargetSelector();
        var attacker = new Hero("hero", "Hero", new Stats { Attack = 50, Range = 5 })
        {
            TargetPriority = TargetPriority.BackRow
        };
        var targets = new List<Entity>
        {
            CreateEntity("front", 500, FormationRow.Front),
            CreateEntity("back", 300, FormationRow.Back),
            CreateEntity("mid", 400, FormationRow.Mid)
        };

        var selected = selector.SelectTarget(attacker, targets);

        Assert.NotNull(selected);
        Assert.Equal("back", selected.Id);
    }

    [Fact]
    public void CombatSystem_DoesNotAttack_DeadTargets()
    {
        var bus = new EventBus();
        var combat = new CombatSystem(bus);
        var attacker = CreateEntity("attacker", 100);
        var deadTarget = CreateEntity("dead", 1);
        deadTarget.TakeDamage(1); // lo matamos

        // No debería crashear
        var result = combat.DealDamage(attacker, deadTarget);

        Assert.True(deadTarget.Stats.CurrentHp <= 0);
    }

    [Fact]
    public void DamageCalculator_CanCrit()
    {
        var calc = new DamageCalculator();
        var attacker = CreateEntity("critter", 100);
        attacker.Stats.CritRate = 1.0; // 100% crit
        attacker.Stats.CritDamage = 2.0; // 200% damage
        var target = CreateEntity("target", 9999);
        target.Stats.Defense = 0;

        var result = new DamageResult();
        // Run many times to verify crit works
        for (int i = 0; i < 50; i++)
        {
            result = calc.Calculate(attacker, target, DamageType.Physical);
            if (result.IsCritical) break;
        }

        Assert.True(result.IsCritical);
        Assert.True(result.FinalDamage >= result.RawDamage * 2);
    }

    private static Entity CreateEntity(string id, int hp, FormationRow row = FormationRow.Mid)
    {
        var hero = new Hero(id, id, new Stats
        {
            MaxHp = hp,
            CurrentHp = hp,
            Attack = 50,
            Defense = 10,
            AttackSpeed = 1.0,
            Range = 2.0
        });
        hero.FormationRow = row;
        return hero;
    }
}
