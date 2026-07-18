using Game.Core.Enums;
using Game.Core.Models;
using Game.Engine.Simulation;

namespace Game.Engine.AI;

/// <summary>
/// Genera las oleadas enemigas.
/// </summary>
public class WaveSpawner
{
    private readonly GameLoop _gameLoop;
    private static readonly Random _rng = new();

    // Templates de unidades enemigas por dificultad
    private class EnemyTemplate
    {
        public string Name { get; init; } = "";
        public UnitClass Class { get; init; }
        public Func<int, Stats> StatsFn { get; init; } = _ => new Stats();
    }

    private static readonly List<EnemyTemplate> EnemyTemplates = new()
    {
        new EnemyTemplate
        {
            Name = "Guerrero Muisca", Class = UnitClass.Infantry,
            StatsFn = (level) => new Stats
            {
                MaxHp = 80 + level * 20, CurrentHp = 80 + level * 20,
                Attack = 10 + level * 3, Defense = 5 + level * 2,
                AttackSpeed = 1.0, Range = 2.0, MoveSpeed = 2.0
            }
        },
        new EnemyTemplate
        {
            Name = "Arquero", Class = UnitClass.Archer,
            StatsFn = (level) => new Stats
            {
                MaxHp = 50 + level * 15, CurrentHp = 50 + level * 15,
                Attack = 12 + level * 4, Defense = 2 + level * 1,
                AttackSpeed = 1.5, Range = 6.0, MoveSpeed = 2.5
            }
        },
        new EnemyTemplate
        {
            Name = "Jinete", Class = UnitClass.Cavalry,
            StatsFn = (level) => new Stats
            {
                MaxHp = 100 + level * 25, CurrentHp = 100 + level * 25,
                Attack = 15 + level * 4, Defense = 8 + level * 2,
                AttackSpeed = 0.8, Range = 1.5, MoveSpeed = 4.0
            }
        },
        new EnemyTemplate
        {
            Name = "Chamán", Class = UnitClass.Mage,
            StatsFn = (level) => new Stats
            {
                MaxHp = 60 + level * 15, CurrentHp = 60 + level * 15,
                Attack = 18 + level * 5, Defense = 3 + level * 1,
                MagicDefense = 10 + level * 3,
                AttackSpeed = 0.7, Range = 5.0, MoveSpeed = 2.0
            }
        }
    };

    public WaveSpawner(GameLoop gameLoop)
    {
        _gameLoop = gameLoop;
    }

    /// <summary>
    /// Genera el equipo enemigo para una oleada.
    /// </summary>
    public TeamState GenerateEnemyWave(int waveNumber)
    {
        var team = new TeamState($"Enemy Wave {waveNumber}");

        // Castillo enemigo
        var castleHp = 3000 + waveNumber * 500;
        team.Castle = new Building("enemy_castle", "Castillo Enemigo",
            new Stats { MaxHp = castleHp, CurrentHp = castleHp, Defense = 30 + waveNumber * 5 },
            BuildingType.Castle, isMainCastle: true);

        // Generar unidades enemigas según la oleada
        var unitCount = Math.Min(3 + waveNumber / 2, 12);
        // En oleadas tempranas, todos los enemigos vienen al carril central
        // (así el héroe puede enfrentarlos sin units de soporte)
        var targetLane = waveNumber <= 3 ? LanePosition.Mid : LanePosition.Mid;
        var lanes = new[] { LanePosition.Mid, LanePosition.Mid, LanePosition.Bot };

        for (int i = 0; i < unitCount; i++)
        {
            var template = GetRandomTemplate();
            var level = Math.Max(1, waveNumber);
            var stats = template.StatsFn(level);

            var unit = new Unit(
                $"enemy_u_{i}",
                template.Name,
                stats,
                template.Class,
                squadSize: 1
            );
            unit.Level = level;

            var lane = waveNumber <= 3 ? LanePosition.Mid : lanes[i % 3];
            unit.FormationRow = FormationRow.Front;
            team.AddUnit(unit, lane);
        }

        // Jefe cada 5 oleadas
        if (waveNumber % 5 == 0)
        {
            var bossStats = new Stats
            {
                MaxHp = 500 + waveNumber * 100,
                CurrentHp = 500 + waveNumber * 100,
                Attack = 30 + waveNumber * 8,
                Defense = 20 + waveNumber * 4,
                AttackSpeed = 0.5,
                Range = 2.0,
                MoveSpeed = 1.5
            };
            var boss = new Unit($"boss_w{waveNumber}", $"Jefe {waveNumber}", bossStats,
                (UnitClass)(waveNumber / 5 % 4), squadSize: 1);
            boss.Rarity = Rarity.Epic;
            boss.FormationRow = FormationRow.Mid;
            team.AddUnit(boss, LanePosition.Mid);
        }

        return team;
    }

    public void SpawnWave(int waveNumber)
    {
        var wave = GenerateEnemyWave(waveNumber);
        _gameLoop.State.EnemyTeam = wave;
    }

    private EnemyTemplate GetRandomTemplate()
    {
        return EnemyTemplates[_rng.Next(EnemyTemplates.Count)];
    }
}
