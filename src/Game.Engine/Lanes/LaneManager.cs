using Game.Core.Enums;
using Game.Core.Models;
using Game.Engine.Simulation;

namespace Game.Engine.Lanes;

/// <summary>
/// Gestiona las posiciones y movimiento en los 3 carriles.
/// </summary>
public class LaneManager
{
    public const double LaneLength = 100.0; // unidades de distancia
    public const double MeetingPoint = 50.0; // punto de encuentro

    /// <summary>
    /// Actualiza las posiciones de las entidades en todos los carriles.
    /// </summary>
    public void UpdatePositions(TeamState player, TeamState enemy, double deltaSeconds)
    {
        foreach (var lane in new[] { LanePosition.Top, LanePosition.Mid, LanePosition.Bot })
        {
            UpdateLanePositions(
                player.LaneEntities[lane].Where(e => e.Stats.IsAlive),
                enemy.LaneEntities[lane].Where(e => e.Stats.IsAlive),
                deltaSeconds
            );
        }
    }

    private void UpdateLanePositions(
        IEnumerable<Entity> playerEntities,
        IEnumerable<Entity> enemyEntities,
        double deltaSeconds)
    {
        var players = playerEntities.ToList();
        var enemies = enemyEntities.ToList();
        if (!players.Any() || !enemies.Any()) return;

        // Las unidades avanzan hasta encontrar un enemigo en rango
        foreach (var entity in players)
        {
            var nearestEnemy = GetNearestEnemy(entity, enemies);
            if (nearestEnemy == null) continue;

            var distance = Math.Abs(entity.Stats.Range); // simplificado
            if (distance > entity.Stats.Range)
            {
                // Avanzar hacia el enemigo
                // (en una implementación real, la posición se actualiza aquí)
            }
        }
    }

    private Entity? GetNearestEnemy(Entity source, List<Entity> enemies)
    {
        return enemies
            .Where(e => e.Stats.IsAlive)
            .OrderBy(e => Math.Abs(e.Stats.Range)) // simplificado
            .FirstOrDefault();
    }
}
