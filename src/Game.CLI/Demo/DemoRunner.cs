using Game.Core.Enums;
using Game.Core.Events;
using Game.Core.Models;
using Game.Data.Config;
using Game.Engine.Simulation;

namespace Game.CLI.Demo;

/// <summary>
/// Modo demo automático — muestra el juego en acción sin input del usuario.
/// </summary>
public static class DemoRunner
{
    public static void Run()
    {
        Console.Clear();
        Console.WriteLine("╔══════════════════════════════════════════════╗");
        Console.WriteLine("║     MAGIC RUSH: LEGADO MUISCA — DEMO       ║");
        Console.WriteLine("╚══════════════════════════════════════════════╝");
        Console.WriteLine();

        // 1. Seleccionar héroe: Águila Guerrera (es la más vistosa)
        var template = GameBalance.HeroTemplates[3]; // Águila Guerrera
        var hero = new Hero(template.Id, template.Name, template.BaseStats.Clone(), template.Rarity);
        hero.FormationRow = template.FormationRow;
        if (template.Passive != null)
            hero.Passive = template.Passive;
        foreach (var st in template.Skills)
        {
            hero.AddSkill(new Skill(st.Id, st.Name, st.TargetType, st.Cooldown)
            {
                BaseDamage = st.BaseDamage, DamageMultiplier = st.DamageMultiplier,
                DamageType = st.DamageType, Description = st.Description
            });
        }

        Console.WriteLine($"🦸 Héroe: {hero.Name} [{hero.Rarity}]");
        Console.WriteLine($"   HP: {hero.Stats.MaxHp}  ATK: {hero.Stats.Attack}  DEF: {hero.Stats.Defense}  VEL: {hero.Stats.AttackSpeed}");
        Console.WriteLine($"   Pasiva: {hero.Passive?.Name} — {hero.Passive?.Description}");
        foreach (var s in hero.Skills)
            Console.WriteLine($"   ⚡ {s.Name}: {s.Description}");
        Console.WriteLine();

        // 2. Iniciar partida
        var game = new GameLoop();
        game.SetupPlayerTeam(hero, new List<Hero>(), new List<Building>());

        // Suscribir eventos
        var eventLog = new List<string>();
        var damageEvents = new List<string>();
        game.State.EventBus.Subscribe<DamageDealtEvent>(e =>
        {
            if (!e.Damage.IsDodged)
                damageEvents.Add($"     {e.Damage.SourceId} → {e.Damage.TargetId}: {e.Damage.FinalDamage}{(e.Damage.IsCritical ? " 💥" : "")}");
        });
        game.State.EventBus.Subscribe<WaveStartedEvent>(e =>
            eventLog.Add($"   ⚔️  OLEADA {e.WaveNumber} — {e.TotalEnemies} enemigos"));
        game.State.EventBus.Subscribe<BattleEndedEvent>(e =>
            eventLog.Add(e.Victory ? "   🏆 ¡VICTORIA!" : "   💀 DERROTA..."));
        game.State.EventBus.Subscribe<UnitTrainedEvent>(e =>
            eventLog.Add($"   🔰 {e.UnitName} desplegado"));

        Console.WriteLine("⚔️  Comenzando batalla en 3 segundos...");
        Thread.Sleep(500);

        // 3. Batalla
        game.StartFullBattle(1);
        Console.WriteLine("═════════════════ BATALLA ═════════════════\n");

        bool trained = false;
        for (int tick = 0; tick < 250; tick++)
        {
            game.Tick(0.1);

            // Entrenar unidades cuando tengamos oro
            if (!trained && game.State.Gold >= 80 && game.State.Phase == GamePhase.Battle)
            {
                game.TrainUnit(new Unit("demo_unit", "Arquero",
                    new Stats { MaxHp = 120, CurrentHp = 120, Attack = 30, Defense = 5, AttackSpeed = 1.5, Range = 5.0, MoveSpeed = 2.0 },
                    UnitClass.Archer, 80, 15, 3), LanePosition.Mid);
                trained = true;
            }

            if (tick % 15 == 0 && game.State.Phase == GamePhase.Battle)
            {
                var enemies = game.State.EnemyTeam.TotalAlive;
                var allies = game.State.PlayerTeam.TotalAlive;
                var hpPct = hero.Stats.IsAlive
                    ? $"{hero.Stats.CurrentHp}/{hero.Stats.MaxHp}"
                    : "❌ CAÍDO";
                Console.WriteLine($"  ⏱️  {(tick / 10) + 1}s | 🦸 {hpPct} | ⚔️ {allies} vs {enemies} | 🪙 {game.State.Gold}");
            }

            if (game.State.Phase != GamePhase.Battle &&
                game.State.Phase != GamePhase.Preparation)
                break;
        }

        // 4. Resultado
        Console.WriteLine();
        Console.WriteLine("═════════════════ RESULTADO ════════════════");
        Console.WriteLine($"  Estado final: {game.State.Phase}");
        Console.WriteLine($"  Duración: {(int)game.State.ElapsedTime}s");
        Console.WriteLine($"  Eventos de daño: {damageEvents.Count}");

        if (game.State.Phase == GamePhase.Victory)
        {
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("  🏆 ¡VICTORIA!");
            Console.ResetColor();
        }
        else if (game.State.Phase == GamePhase.Defeat)
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine("  💀 DERROTA");
            Console.ResetColor();
        }

        Console.WriteLine();
        Console.WriteLine("📋  Eventos:");
        foreach (var evt in eventLog)
            Console.WriteLine(evt);
        if (damageEvents.Any())
        {
            Console.WriteLine("\n   Últimos daños:");
            foreach (var d in damageEvents.TakeLast(8))
                Console.WriteLine(d);
        }

        Console.WriteLine();
        Console.WriteLine("✅ Demo completada.");
        Console.WriteLine("\n🎮 Para jugar interactivo: dotnet run --project src/Game.CLI");
        Console.WriteLine("\nPresiona ENTER para salir...");
        Console.ReadLine();
    }
}
