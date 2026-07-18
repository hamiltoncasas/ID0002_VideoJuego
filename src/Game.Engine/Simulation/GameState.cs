using Game.Core.Enums;
using Game.Core.Events;
using Game.Core.Models;

namespace Game.Engine.Simulation;

/// <summary>
/// Estado completo de una partida.
/// </summary>
public class GameState
{
    public string SessionId { get; set; }
    public GamePhase Phase { get; set; }
    public TeamState PlayerTeam { get; set; }
    public TeamState EnemyTeam { get; set; }
    public EventBus EventBus { get; set; }
    public double ElapsedTime { get; set; }
    public int CurrentWave { get; set; }
    public int MaxWaves { get; set; }
    public bool IsPaused { get; set; }
    public double GameSpeedMultiplier { get; set; }

    // Economía del jugador
    public int Gold { get; set; }
    public int Food { get; set; }
    public int Gems { get; set; }

    public GameState()
    {
        SessionId = Guid.NewGuid().ToString()[..8];
        EventBus = new EventBus();
        Phase = GamePhase.Preparation;
        PlayerTeam = new TeamState("Player");
        EnemyTeam = new TeamState("Enemy");
        GameSpeedMultiplier = 1.0;
        Gold = 200; // gold inicial
        Food = 100;
        CurrentWave = 0;
        MaxWaves = 10;
    }

    public void StartBattle()
    {
        Phase = GamePhase.Battle;
        ElapsedTime = 0;
        EventBus.Publish(new PhaseChangedEvent("Battle"));
    }

    public void EndBattle(bool victory)
    {
        Phase = victory ? GamePhase.Victory : GamePhase.Defeat;
        EventBus.Publish(new BattleEndedEvent(victory));
    }

    public void Tick(double deltaSeconds)
    {
        if (Phase != GamePhase.Battle || IsPaused) return;

        var effectiveDelta = deltaSeconds * GameSpeedMultiplier;
        ElapsedTime += effectiveDelta;

        PlayerTeam.Tick(effectiveDelta);
        EnemyTeam.Tick(effectiveDelta);
    }
}
