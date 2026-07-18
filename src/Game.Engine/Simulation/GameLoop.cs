using Game.Core.Enums;
using Game.Core.Events;
using Game.Core.Models;
using Game.Engine.AI;
using Game.Engine.Combat;
using Game.Engine.Economy;
using Game.Engine.Lanes;

namespace Game.Engine.Simulation;

/// <summary>
/// Game loop principal. Coordina todos los sistemas.
/// </summary>
public class GameLoop
{
    public GameState State { get; private set; }
    public CombatSystem Combat { get; private set; }
    public LaneManager LaneManager { get; private set; }
    public WaveSpawner WaveSpawner { get; private set; }
    public EconomyManager Economy { get; private set; }

    private const double BattlePrepTime = 3.0; // 3 segundos de preparación
    private double _prepTimer;

    public GameLoop()
    {
        State = new GameState();
        Combat = new CombatSystem(State.EventBus);
        LaneManager = new LaneManager();
        WaveSpawner = new WaveSpawner(this);
        Economy = new EconomyManager(this);
    }

    /// <summary>
    /// Configura la partida con héroes del jugador.
    /// </summary>
    public void SetupPlayerTeam(Hero mainHero, List<Hero> supportHeroes, List<Building> buildings)
    {
        // Castillo del jugador
        var castle = new Building("player_castle", "Castillo Muisca",
            new Stats { MaxHp = 5000, CurrentHp = 5000, Defense = 50 },
            BuildingType.Castle, isMainCastle: true);
        State.PlayerTeam.Castle = castle;

        // Héroe principal al medio
        mainHero.FormationRow = FormationRow.Mid;
        State.PlayerTeam.AddHero(mainHero, LanePosition.Mid);

        // Héroes de soporte
        foreach (var (hero, idx) in supportHeroes.Select((h, i) => (h, i)))
        {
            var lane = (LanePosition)(idx % 3);
            hero.FormationRow = FormationRow.Back;
            State.PlayerTeam.AddHero(hero, lane);
        }

        foreach (var b in buildings)
            State.PlayerTeam.Buildings.Add(b);
    }

    /// <summary>
    /// Configura el equipo enemigo para la oleada actual.
    /// </summary>
    public void SetupEnemyWave(int waveNumber)
    {
        State.EnemyTeam = WaveSpawner.GenerateEnemyWave(waveNumber);
    }

    /// <summary>
    /// Avanza la simulación un tick.
    /// </summary>
    public void Tick(double deltaSeconds)
    {
        if (State.Phase != GamePhase.Battle && State.Phase != GamePhase.Preparation)
            return;

        if (State.Phase == GamePhase.Preparation)
        {
            _prepTimer += deltaSeconds;
            if (_prepTimer >= BattlePrepTime)
            {
                State.StartBattle();
                WaveSpawner.SpawnWave(State.CurrentWave);
            }
            return;
        }

        State.Tick(deltaSeconds);
        Economy.Tick(deltaSeconds);

        // Procesar combate por cada carril
        foreach (var lane in new[] { LanePosition.Top, LanePosition.Mid, LanePosition.Bot })
        {
            var playerEntities = State.PlayerTeam.LaneEntities[lane]
                .Where(e => e.Stats.IsAlive).ToList();
            var enemyEntities = State.EnemyTeam.LaneEntities[lane]
                .Where(e => e.Stats.IsAlive).ToList();

            Combat.ProcessLane(lane, playerEntities, enemyEntities, deltaSeconds);
        }

        // Mover unidades por el carril
        LaneManager.UpdatePositions(State.PlayerTeam, State.EnemyTeam, deltaSeconds);

        // Limpiar muertos
        State.PlayerTeam.RemoveDeadEntities();
        State.EnemyTeam.RemoveDeadEntities();

        // Verificar condiciones de fin de batalla
        CheckBattleEnd();
    }

    private void CheckBattleEnd()
    {
        // Si el castillo enemigo cayó o no quedan enemigos → victoria
        if (!State.EnemyTeam.IsAlive || State.EnemyTeam.TotalAlive == 0)
        {
            State.EndBattle(true);
            State.EventBus.Publish(new WaveCompletedEvent(State.CurrentWave));
        }
        // Si el castillo del jugador cayó → derrota
        else if (!State.PlayerTeam.IsAlive)
        {
            State.EndBattle(false);
        }
    }

    /// <summary>
    /// Inicia una batalla completa (preparación + oleadas).
    /// </summary>
    public void StartFullBattle(int startingWave = 1)
    {
        State.CurrentWave = startingWave;
        _prepTimer = 0;
        State.Phase = GamePhase.Preparation;
        SetupEnemyWave(startingWave);
        State.EventBus.Publish(new WaveStartedEvent(startingWave, State.EnemyTeam.TotalAlive));
    }

    /// <summary>
    /// Invoca una unidad aliada en un carril.
    /// </summary>
    public bool TrainUnit(Unit unitTemplate, LanePosition lane)
    {
        if (State.Gold < unitTemplate.GoldCost || State.Food < unitTemplate.FoodCost)
            return false;

        State.Gold -= unitTemplate.GoldCost;
        State.Food -= unitTemplate.FoodCost;

        var unit = new Unit(
            Guid.NewGuid().ToString()[..8],
            unitTemplate.Name,
            unitTemplate.Stats.Clone(),
            unitTemplate.Class,
            unitTemplate.GoldCost,
            unitTemplate.FoodCost,
            unitTemplate.SquadSize
        );
        unit.FormationRow = FormationRow.Front;

        State.PlayerTeam.AddUnit(unit, lane);
        State.EventBus.Publish(new UnitTrainedEvent(unit.Id, unit.Name));
        return true;
    }
}
