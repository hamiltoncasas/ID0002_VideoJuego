using Game.Core.Enums;
using Game.Core.Models;

namespace Game.Core.Interfaces;

/// <summary>
/// Algo que puede ser targeteado en combate.
/// </summary>
public interface ITargetable
{
    string Id { get; }
    string Name { get; }
    bool IsAlive { get; }
    Stats Stats { get; }
    FormationRow FormationRow { get; }
    LanePosition CurrentLane { get; }
    double Position { get; } // posición en el carril (0 = base, avanza hacia adelante)
}
