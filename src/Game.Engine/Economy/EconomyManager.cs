using Game.Core.Events;
using Game.Engine.Simulation;

namespace Game.Engine.Economy;

/// <summary>
/// Gestiona la economía del jugador durante la partida.
/// </summary>
public class EconomyManager
{
    private readonly GameLoop _gameLoop;
    private double _goldTimer;
    private double _foodTimer;

    // Producción base por segundo
    private const double BaseGoldPerSecond = 2.0;
    private const double BaseFoodPerSecond = 1.0;

    public EconomyManager(GameLoop gameLoop)
    {
        _gameLoop = gameLoop;
    }

    public void Tick(double deltaSeconds)
    {
        var state = _gameLoop.State;
        if (state.Phase != Core.Enums.GamePhase.Battle) return;

        // Producción pasiva de recursos
        _goldTimer += deltaSeconds;
        _foodTimer += deltaSeconds;

        var goldPerSec = BaseGoldPerSecond;
        var foodPerSec = BaseFoodPerSecond;

        // Bonus por edificios
        foreach (var building in state.PlayerTeam.Buildings)
        {
            goldPerSec += building.GoldProductionPerSecond;
            foodPerSec += building.FoodProductionPerSecond;
        }

        if (_goldTimer >= 1.0)
        {
            var goldGain = (int)(goldPerSec * _goldTimer);
            state.Gold += goldGain;
            _goldTimer = 0;
            state.EventBus.Publish(new GoldChangedEvent(state.Gold, goldGain));
        }

        if (_foodTimer >= 1.0)
        {
            var foodGain = (int)(foodPerSec * _foodTimer);
            state.Food += foodGain;
            _foodTimer = 0;
        }
    }

    /// <summary>
    /// Intenta gastar oro. Devuelve false si no alcanza.
    /// </summary>
    public bool SpendGold(int amount)
    {
        var state = _gameLoop.State;
        if (state.Gold < amount) return false;
        state.Gold -= amount;
        state.EventBus.Publish(new GoldChangedEvent(state.Gold, -amount));
        return true;
    }

    /// <summary>
    /// Recompensa por matar enemigos.
    /// </summary>
    public void AddKillReward(int enemyLevel)
    {
        var goldReward = 5 + enemyLevel * 2;
        var xpReward = 10 + enemyLevel * 5;
        _gameLoop.State.Gold += goldReward;
        _gameLoop.State.EventBus.Publish(new GoldChangedEvent(_gameLoop.State.Gold, goldReward));
    }

    /// <summary>
    /// Recompensa por completar oleada.
    /// </summary>
    public void AddWaveReward(int waveNumber)
    {
        _gameLoop.State.Gold += 50 + waveNumber * 25;
        _gameLoop.State.Food += 25 + waveNumber * 10;
        _gameLoop.State.Gems += 1;
    }
}
