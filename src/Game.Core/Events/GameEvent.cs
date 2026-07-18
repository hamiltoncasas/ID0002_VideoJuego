using Game.Core.Models;

namespace Game.Core.Events;

/// <summary>
/// Evento base del sistema de eventos del juego.
/// </summary>
public abstract record GameEvent
{
    public DateTime Timestamp { get; init; } = DateTime.UtcNow;
}

public record EntitySpawnedEvent(string EntityId, string EntityName, string Lane, string Team) : GameEvent;
public record EntityDiedEvent(string EntityId, string EntityName, string KilledBy) : GameEvent;
public record DamageDealtEvent(DamageResult Damage) : GameEvent;
public record SkillUsedEvent(string CasterId, string SkillName) : GameEvent;
public record WaveStartedEvent(int WaveNumber, int TotalEnemies) : GameEvent;
public record WaveCompletedEvent(int WaveNumber) : GameEvent;
public record GoldChangedEvent(int NewAmount, int Delta) : GameEvent;
public record PhaseChangedEvent(string NewPhase) : GameEvent;
public record UnitTrainedEvent(string UnitId, string UnitName) : GameEvent;
public record BuildingUpgradedEvent(string BuildingId, int NewLevel) : GameEvent;
public record BattleEndedEvent(bool Victory) : GameEvent;

/// <summary>
/// Bus de eventos global. Suscribite y escuchá.
/// </summary>
public class EventBus
{
    private readonly Dictionary<Type, List<Delegate>> _handlers = new();

    public void Subscribe<T>(Action<T> handler) where T : GameEvent
    {
        var type = typeof(T);
        if (!_handlers.ContainsKey(type))
            _handlers[type] = new List<Delegate>();
        _handlers[type].Add(handler);
    }

    public void Unsubscribe<T>(Action<T> handler) where T : GameEvent
    {
        var type = typeof(T);
        if (_handlers.ContainsKey(type))
            _handlers[type].Remove(handler);
    }

    public void Publish<T>(T gameEvent) where T : GameEvent
    {
        var type = typeof(T);
        if (!_handlers.ContainsKey(type)) return;

        foreach (var handler in _handlers[type].ToList())
        {
            ((Action<T>)handler)(gameEvent);
        }
    }

    public void Clear() => _handlers.Clear();
}
