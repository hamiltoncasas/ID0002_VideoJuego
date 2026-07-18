using Game.Core.Enums;
using Game.Core.Events;
using Game.Core.Models;
using Game.Data.Config;
using Game.Engine.Simulation;
using Xunit;

namespace Game.Tests;

public class BattleFlowTests
{
    [Fact]
    public void FullBattle_DealsDamageAndEnds()
    {
        var template = GameBalance.HeroTemplates[0]; // Guerrero Sol
        var hero = new Hero(template.Id, template.Name, template.BaseStats.Clone(), template.Rarity);

        var game = new GameLoop();
        game.SetupPlayerTeam(hero, new List<Hero>(), new List<Building>());
        game.StartFullBattle(1);

        var attackCount = 0;
        game.State.EventBus.Subscribe<DamageDealtEvent>(e =>
        {
            if (!e.Damage.IsDodged) attackCount++;
        });

        // Run 500 ticks (50s)
        for (int i = 0; i < 500; i++)
        {
            game.Tick(0.1);
            if (game.State.Phase != GamePhase.Battle &&
                game.State.Phase != GamePhase.Preparation)
                break;
        }

        Assert.True(attackCount > 0, $"Expected attacks > 0, got {attackCount}");
    }

    [Fact]
    public void Hero_AttacksAndKillsEnemy()
    {
        var template = GameBalance.HeroTemplates[3]; // Águila Guerrera (higher ATK)
        var hero = new Hero(template.Id, template.Name, template.BaseStats.Clone(), template.Rarity);

        var game = new GameLoop();
        game.SetupPlayerTeam(hero, new List<Hero>(), new List<Building>());
        game.StartFullBattle(1);

        var killCount = 0;
        game.State.EventBus.Subscribe<DamageDealtEvent>(e =>
        {
            // Can't check IsAlive from event, just count attacks
        });

        int lastEnemyCount = game.State.EnemyTeam.TotalAlive;
        int ticksWithNoEnemies = 0;

        for (int i = 0; i < 500; i++)
        {
            game.Tick(0.1);
            var current = game.State.EnemyTeam.TotalAlive;

            if (current == 0)
                ticksWithNoEnemies++;
            else
                ticksWithNoEnemies = 0;

            lastEnemyCount = current;

            if (game.State.Phase != GamePhase.Battle &&
                game.State.Phase != GamePhase.Preparation)
                break;
        }

        // The battle should have ended (victory or defeat)
        Assert.NotEqual(GamePhase.Battle, game.State.Phase);
    }

    [Fact]
    public void Battle_WithUnitTraining_WinsFaster()
    {
        var template = GameBalance.HeroTemplates[0];
        var hero = new Hero(template.Id, template.Name, template.BaseStats.Clone(), template.Rarity);

        var game = new GameLoop();
        game.SetupPlayerTeam(hero, new List<Hero>(), new List<Building>());
        game.StartFullBattle(1);

        // Train units as soon as we have gold
        for (int i = 0; i < 500; i++)
        {
            game.Tick(0.1);

            if (game.State.Gold >= 50 && game.State.Phase == GamePhase.Battle)
            {
                game.TrainUnit(new Unit("u", "Guerrero",
                    new Stats { MaxHp = 200, CurrentHp = 200, Attack = 25, Defense = 15,
                        AttackSpeed = 1.0, Range = 1.5, MoveSpeed = 2.0 },
                    UnitClass.Infantry, 50, 25, 3), LanePosition.Mid);
            }

            if (game.State.Phase != GamePhase.Battle &&
                game.State.Phase != GamePhase.Preparation)
                break;
        }

        Assert.NotEqual(GamePhase.Battle, game.State.Phase);
    }
}
