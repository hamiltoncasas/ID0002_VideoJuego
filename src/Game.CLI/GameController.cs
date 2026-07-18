using Game.Core.Enums;
using Game.Core.Events;
using Game.Core.Models;
using Game.Data.Config;
using Game.Data.Serialization;
using Game.Engine.Simulation;

namespace Game.CLI;

public class GameController
{
    private GameLoop? _gameLoop;
    private PlayerProfile _profile;
    private Hero? _mainHero;
    private bool _running = true;
    private bool _battleActive;
    private double _autoTickTimer;
    private const double AutoTickInterval = 0.1;

    private readonly List<string> _eventLog = new();
    private const int MaxEventLog = 8;

    // Estadísticas de la batalla actual
    private int _battleKills;
    private int _battleGoldEarned;
    private int _battleXpEarned;

    public GameController()
    {
        _profile = SaveManager.Load() ?? new PlayerProfile();
    }

    public void Run()
    {
        ShowIntro();
        ShowMainMenu();
    }

    private void ShowIntro()
    {
        Console.Clear();
        RenderTitle("MAGIC RUSH: LEGADO MUISCA", ConsoleColor.Yellow);
        Console.WriteLine();
        AnimatedText(@"
   AÑO 2026 — SIERRA NEVADA, COLOMBIA

   Una densa niebla cubre las montañas mientras excavás
   en lo que parece ser un antiguo templo MUISCA...

   De repente, entre el barro y las raíces, algo brilla.
   Un ANILLO de oro con grabados que palpitan con luz propia.

   Al tocarlo, el mundo se distorsiona...
   Una fuerza ancestral te arranca de tu tiempo.

   25.000 AÑOS AL PASADO.

   Ahora despertás en una tierra gobernada por el SOL y la LUNA.
   Los clanes Muisca están en guerra. Tu castillo necesita un líder.
   El anillo te eligió. No sabés por qué.

   Pero una cosa es clara: si no DEFENDÉS tu tierra,
   no hay forma de volver a casa.
", ConsoleColor.Cyan, 10);
        RenderText("\nPresiona ENTER para comenzar tu aventura...", ConsoleColor.Gray);
        Console.ReadLine();
    }

    private void ShowMainMenu()
    {
        while (_running)
        {
            Console.Clear();
            RenderTitle("LEGADO MUISCA — MENÚ PRINCIPAL", ConsoleColor.Yellow);

            var mainName = _mainHero?.Name ?? "❌ No seleccionado";
            Console.WriteLine($"  🏆 Arqueólogo Nv.{_profile.Level}   ⭐ XP: {_profile.Experience}/{_profile.Level * 150}");
            Console.WriteLine($"  🦸 Héroe: {mainName}");
            Console.WriteLine($"  💰 Oro: {_profile.Resources["gold"]}   🌾 Comida: {_profile.Resources["food"]}");
            Console.WriteLine($"  💎 Gemas: {_profile.CurrentGems}   🏔️ Récord: Oleada {_profile.HighestWaveCleared}");
            Console.WriteLine();
            Console.WriteLine("  1. ⚔️  JUGAR CAMPAÑA");
            Console.WriteLine("  2. 🦸  Seleccionar héroe principal");
            Console.WriteLine("  3. 📜  Ver héroes y equipo");
            Console.WriteLine("  4. 💾  Guardar progreso");
            Console.WriteLine("  5. 🚪  Salir");
            Console.WriteLine();

            var choice = Prompt("Elige: ");
            switch (choice)
            {
                case "1": StartCampaign(); break;
                case "2": SelectMainHero(); break;
                case "3": ShowHeroDetails(); break;
                case "4": SaveGame(); break;
                case "5":
                    SaveGame();
                    _running = false;
                    RenderText("\n¡Hasta la próxima, Arqueólogo! El anillo te espera...", ConsoleColor.Yellow);
                    Thread.Sleep(1500);
                    return;
            }
        }
    }

    private void SaveGame()
    {
        _profile.Resources["gold"] = Math.Max(_profile.Resources["gold"], 0);
        SaveManager.Save(_profile);
        RenderText("\n✅ Progreso guardado.", ConsoleColor.Green);
        Prompt("Presiona ENTER...");
    }

    private void SelectMainHero()
    {
        Console.Clear();
        RenderTitle("SELECCIONA TU HÉROE PRINCIPAL", ConsoleColor.Cyan);

        var templates = GameBalance.HeroTemplates;
        for (int i = 0; i < templates.Count; i++)
        {
            var t = templates[i];
            var rarityColor = GetRarityColor(t.Rarity);
            Console.ForegroundColor = rarityColor;
            Console.WriteLine($"  {i + 1}. {t.Name} [{t.Rarity}]");
            Console.ResetColor();
            Console.WriteLine($"     Fila: {t.FormationRow}  HP: {t.BaseStats.MaxHp}  ATK: {t.BaseStats.Attack}  DEF: {t.BaseStats.Defense}");
            foreach (var s in t.Skills)
                Console.WriteLine($"     ⚡ {s.Name}: {s.Description}");
            Console.WriteLine();
        }

        var choice = Prompt("Elige héroe (1-3): ");
        if (int.TryParse(choice, out int idx) && idx >= 1 && idx <= templates.Count)
        {
            var template = templates[idx - 1];
            _mainHero = new Hero(template.Id, template.Name, template.BaseStats.Clone(), template.Rarity);
            _mainHero.FormationRow = template.FormationRow;

            foreach (var st in template.Skills)
            {
                var skill = new Skill(st.Id, st.Name, st.TargetType, st.Cooldown)
                {
                    BaseDamage = st.BaseDamage,
                    DamageMultiplier = st.DamageMultiplier,
                    DamageType = st.DamageType,
                    Description = st.Description,
                    SelfBuff = st.SelfBuff?.Clone()
                };
                _mainHero.AddSkill(skill);
            }

            // Guardar en perfil
            var saved = _profile.OwnedHeroes.FirstOrDefault(h => h.HeroId == _mainHero.Id);
            if (saved == null)
            {
                _profile.OwnedHeroes.Add(new SavedHero
                {
                    HeroId = _mainHero.Id,
                    Name = _mainHero.Name,
                    Level = 1,
                    Stars = 1,
                    IsMain = true
                });
            }

            RenderText($"\n✅ {_mainHero.Name} te acompañará en esta aventura.", ConsoleColor.Green);
            Prompt("\nPresiona ENTER...");
        }
    }

    private void ShowHeroDetails()
    {
        Console.Clear();
        RenderTitle("HÉROES Y EQUIPO", ConsoleColor.Cyan);

        if (_mainHero != null)
        {
            var rarityColor = GetRarityColor(_mainHero.Rarity);
            Console.ForegroundColor = rarityColor;
            Console.WriteLine($"  🦸 {_mainHero.Name} Lv.{_mainHero.Level} ⭐{_mainHero.Stars} [{_mainHero.Rarity}]");
            Console.ResetColor();
            Console.WriteLine($"  HP: {_mainHero.Stats.MaxHp}  ATK: {_mainHero.Stats.Attack}");
            Console.WriteLine($"  DEF: {_mainHero.Stats.Defense}  DEF Mágica: {_mainHero.Stats.MagicDefense}");
            Console.WriteLine($"  Vel.Ataque: {_mainHero.Stats.AttackSpeed}  Rango: {_mainHero.Stats.Range}");
            Console.WriteLine($"  Crítico: {_mainHero.Stats.CritRate:P0}  Daño Crítico: {_mainHero.Stats.CritDamage:P0}");
            Console.WriteLine($"  Esquive: {_mainHero.Stats.DodgeRate:P0}  Prioridad: {_mainHero.TargetPriority}");
            Console.WriteLine($"  Fila: {_mainHero.FormationRow}");

            // Equipo
            Console.WriteLine($"\n  ─── EQUIPO ───");
            if (_mainHero.Equipment.Any())
            {
                foreach (var eq in _mainHero.Equipment)
                {
                    Console.ForegroundColor = GetRarityColor(eq.Rarity);
                    Console.WriteLine($"  [{eq.Slot}] {eq.Name} +{eq.Level} ({eq.Rarity})");
                    Console.ResetColor();
                    Console.WriteLine($"     HP+{eq.BonusStats.MaxHp} ATK+{eq.BonusStats.Attack} DEF+{eq.BonusStats.Defense}");
                }
            }
            else
            {
                RenderText("  (sin equipo equipado)", ConsoleColor.DarkGray);
            }

            // Habilidades
            Console.WriteLine($"\n  ─── HABILIDADES ───");
            foreach (var skill in _mainHero.Skills)
            {
                Console.WriteLine($"  ⚡ {skill.Name} (Nv.{skill.Level}) CD:{skill.CooldownSeconds}s");
                Console.WriteLine($"     {skill.Description}");
            }

            Console.WriteLine($"\n  XP: {_mainHero.Experience}/{_mainHero.ExperienceToNextLevel}");
        }
        else
        {
            RenderText("  ⚠️  No has seleccionado héroe principal.", ConsoleColor.Yellow);
        }

        // Todos los héroes del perfil
        if (_profile.OwnedHeroes.Any())
        {
            Console.WriteLine($"\n  ─── COLECCIÓN ({_profile.OwnedHeroes.Count} héroes) ───");
            foreach (var h in _profile.OwnedHeroes)
            {
                var mark = h.IsMain ? " ⭐" : "";
                Console.WriteLine($"  • {h.Name} Lv.{h.Level} ⭐{h.Stars}{mark}");
            }
        }

        Prompt("\nPresiona ENTER...");
    }

    // ═══════════════════════════════════════════════
    //  CAMPAÑA Y BATALLA
    // ═══════════════════════════════════════════════

    private void StartCampaign()
    {
        if (_mainHero == null)
        {
            RenderText("⚠️  Primero seleccioná un héroe principal.", ConsoleColor.Yellow);
            Prompt("Presiona ENTER...");
            return;
        }

        var startWave = Math.Max(1, _profile.HighestWaveCleared);
        RenderText($"\n⚔️  Preparando campaña — Oleada {startWave}...", ConsoleColor.Cyan);
        Thread.Sleep(500);

        _gameLoop = new GameLoop();
        _gameLoop.SetupPlayerTeam(_mainHero, new List<Hero>(), new List<Building>());
        _eventLog.Clear();
        _battleActive = true;
        _autoTickTimer = 0;
        _battleKills = 0;
        _battleGoldEarned = 0;
        _battleXpEarned = 0;

        SubscribeEvents();

        _gameLoop.StartFullBattle(startWave);
        BattleLoop();
    }

    private void SubscribeEvents()
    {
        _gameLoop!.State.EventBus.Subscribe<DamageDealtEvent>(e =>
        {
            if (!e.Damage.IsDodged)
            {
                var crit = e.Damage.IsCritical ? " 💥" : "";
                _eventLog.Add($"  {e.Damage.SourceId} → {e.Damage.TargetId}: {e.Damage.FinalDamage}{crit}");
            }
            TrimEventLog();
        });

        _gameLoop.State.EventBus.Subscribe<WaveStartedEvent>(e =>
        {
            _eventLog.Add($"══════════ ⚔️  OLEADA {e.WaveNumber} ⚔️  ══════════");
            _eventLog.Add($"  {e.TotalEnemies} enemigos se aproximan...");
            TrimEventLog();
        });

        _gameLoop.State.EventBus.Subscribe<WaveCompletedEvent>(e =>
        {
            _eventLog.Add($"🎉 OLEADA {e.WaveNumber} COMPLETADA");
            TrimEventLog();
        });

        _gameLoop.State.EventBus.Subscribe<BattleEndedEvent>(e =>
        {
            if (e.Victory)
            {
                _eventLog.Add("🏆 ¡VICTORIA!");
                // Recompensas
                var wave = _gameLoop!.State.CurrentWave;
                _battleGoldEarned = 50 + wave * 25;
                _battleXpEarned = 30 + wave * 15;
                _gameLoop.State.Gold += _battleGoldEarned;
                _mainHero?.AddExperience(_battleXpEarned);
                _profile.AddExperience(_battleXpEarned);
            }
            else
            {
                _eventLog.Add("💀 DERROTA...");
            }
            TrimEventLog();
        });

        _gameLoop.State.EventBus.Subscribe<UnitTrainedEvent>(e =>
        {
            _eventLog.Add($"  🔰 {e.UnitName} listo!");
            TrimEventLog();
        });

        _gameLoop.State.EventBus.Subscribe<GoldChangedEvent>(e =>
        {
            if (e.Delta > 0)
                _eventLog.Add($"  +{e.Delta} 🪙");
            TrimEventLog();
        });
    }

    private void BattleLoop()
    {
        while (_battleActive && _gameLoop != null)
        {
            RenderBattle();

            bool battleEnded = false;

            if (_gameLoop.State.Phase == GamePhase.Battle || _gameLoop.State.Phase == GamePhase.Preparation)
            {
                if (_gameLoop.State.Phase == GamePhase.Battle)
                {
                    _autoTickTimer += AutoTickInterval;
                    _gameLoop.Tick(AutoTickInterval);
                }
                else
                {
                    // Fase de preparación — solo avanzar timer
                    _gameLoop.Tick(AutoTickInterval);
                }
            }

            // Verificar fin de oleada
            if (_gameLoop.State.Phase == GamePhase.Victory)
            {
                battleEnded = true;
                RenderBattle();
                ShowVictoryScreen();
            }
            else if (_gameLoop.State.Phase == GamePhase.Defeat)
            {
                battleEnded = true;
                RenderBattle();
                ShowDefeatScreen();
            }

            if (battleEnded) break;

            // Input
            if (Console.KeyAvailable)
            {
                var key = Console.ReadKey(true);
                HandleBattleInput(key);
            }

            Thread.Sleep(80);
        }
    }

    private void ShowVictoryScreen()
    {
        if (_gameLoop == null) return;

        var wave = _gameLoop.State.CurrentWave;
        _profile.HighestWaveCleared = Math.Max(_profile.HighestWaveCleared, wave);
        _profile.Resources["gold"] += _battleGoldEarned;

        Console.Clear();
        RenderTitle("🏆  VICTORIA  🏆", ConsoleColor.Green);
        Console.WriteLine();
        Console.WriteLine($"  Oleada completada: {wave}");
        Console.WriteLine($"  Enemigos derrotados: {_battleKills}");
        Console.WriteLine();
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine($"  Recompensas:");
        Console.WriteLine($"    +{_battleGoldEarned} 🪙 Oro");
        Console.WriteLine($"    +{_battleXpEarned} ⭐ Experiencia");
        Console.ResetColor();
        Console.WriteLine();

        if (_mainHero != null)
        {
            Console.WriteLine($"  {_mainHero.Name}: Lv.{_mainHero.Level}  XP: {_mainHero.Experience}/{_mainHero.ExperienceToNextLevel}");
        }

        // Drop aleatorio de equipo cada 3 oleadas
        if (wave % 3 == 0)
        {
            var loot = GenerateRandomEquipment(wave);
            _mainHero?.EquipItem(loot);
            Console.ForegroundColor = ConsoleColor.Magenta;
            Console.WriteLine($"\n  🎁 ¡EQUIPO ENCONTRADO! {loot.Name} [{loot.Rarity}]");
            Console.WriteLine($"     {loot.Description}");
            Console.ResetColor();
        }

        SaveManager.Save(_profile);

        Console.WriteLine();
        Console.WriteLine("  [1] Siguiente oleada");
        Console.WriteLine("  [2] Volver al menú");
        Console.WriteLine();

        var choice = Prompt("Elige: ");
        if (choice == "1")
        {
            _gameLoop.StartFullBattle(wave + 1);
            _eventLog.Clear();
            _battleKills = 0;
            _battleGoldEarned = 0;
            _battleXpEarned = 0;
            BattleLoop();
        }
    }

    private void ShowDefeatScreen()
    {
        Console.Clear();
        RenderTitle("💀  DERROTA  💀", ConsoleColor.Red);
        Console.WriteLine();
        RenderText("  Tu castillo ha caído... pero el anillo aún te sostiene.", ConsoleColor.Red);
        RenderText("  Volvé más fuerte, Arqueólogo.", ConsoleColor.Gray);
        Console.WriteLine();
        RenderText($"  Oro ganado: {_battleGoldEarned}", ConsoleColor.Yellow);
        RenderText($"  Mejor oleada: {_profile.HighestWaveCleared}", ConsoleColor.Cyan);
        Console.WriteLine();

        SaveManager.Save(_profile);
        Prompt("Presiona ENTER para volver al menú...");
    }

    private void HandleBattleInput(ConsoleKeyInfo key)
    {
        if (_gameLoop == null) return;

        switch (key.Key)
        {
            case ConsoleKey.D1: TrainUnit("unit_guerrero", LanePosition.Mid); break;
            case ConsoleKey.D2: TrainUnit("unit_arquero", LanePosition.Mid); break;
            case ConsoleKey.D3: TrainUnit("unit_jinete", LanePosition.Mid); break;
            case ConsoleKey.D4: UseHeroSkill(); break;
            case ConsoleKey.Q: TrainUnit("unit_guerrero", LanePosition.Top); break;
            case ConsoleKey.W: TrainUnit("unit_arquero", LanePosition.Top); break;
            case ConsoleKey.E: TrainUnit("unit_jinete", LanePosition.Bot); break;
            case ConsoleKey.R: TrainUnit("unit_mago", LanePosition.Mid); break;
            case ConsoleKey.Spacebar:
                if (_gameLoop.State.Phase == GamePhase.Battle)
                    _gameLoop.State.IsPaused = !_gameLoop.State.IsPaused;
                break;
            case ConsoleKey.Escape: _battleActive = false; break;
        }
    }

    private void TrainUnit(string unitId, LanePosition lane)
    {
        if (_gameLoop == null || _gameLoop.State.Phase != GamePhase.Battle) return;

        var template = GameBalance.UnitTemplates.FirstOrDefault(u => u.Id == unitId);
        if (template == null) return;

        var unit = new Unit(template.Id, template.Name, template.BaseStats.Clone(),
            template.UnitClass, template.GoldCost, template.FoodCost, template.SquadSize);
        if (_gameLoop.TrainUnit(unit, lane))
        {
            _eventLog.Add($"  🔰 {template.Name} en {lane}");
            TrimEventLog();
        }
    }

    private void UseHeroSkill()
    {
        if (_gameLoop == null || _mainHero == null) return;

        var skill = _mainHero.Skills.FirstOrDefault(s => s.IsReady);
        if (skill == null)
        {
            _eventLog.Add("  ⚠️  Habilidades en cooldown!");
            TrimEventLog();
            return;
        }

        skill.Use();
        _eventLog.Add($"  ⚡ {_mainHero.Name} usa {skill.Name}!");
        TrimEventLog();

        var enemies = _gameLoop.State.EnemyTeam.LaneEntities[LanePosition.Mid]
            .Where(e => e.Stats.IsAlive).ToList();

        if (enemies.Any() && skill.TargetType == SkillTargetType.SingleEnemy)
        {
            var target = enemies.First();
            var damage = _gameLoop.Combat.DealSkillDamage(_mainHero, target, skill);
            _eventLog.Add(damage.ToString());
            TrimEventLog();

            if (!target.Stats.IsAlive)
            {
                _battleKills++;
                _gameLoop.State.Gold += 10;
            }
        }
        else if (skill.TargetType == SkillTargetType.AllEnemies)
        {
            foreach (var target in enemies)
            {
                var damage = _gameLoop.Combat.DealSkillDamage(_mainHero, target, skill);
                _eventLog.Add(damage.ToString());
                if (!target.Stats.IsAlive) _battleKills++;
            }
            TrimEventLog();
        }
    }

    // ═══════════════════════════════════════════════
    //  RENDERIZADO
    // ═══════════════════════════════════════════════

    private void RenderBattle()
    {
        if (_gameLoop == null) return;
        Console.Clear();

        var state = _gameLoop.State;
        var phaseColor = state.Phase switch
        {
            GamePhase.Preparation => ConsoleColor.Cyan,
            GamePhase.Battle => ConsoleColor.Yellow,
            GamePhase.Victory => ConsoleColor.Green,
            GamePhase.Defeat => ConsoleColor.Red,
            _ => ConsoleColor.Gray
        };

        var phaseName = state.Phase switch
        {
            GamePhase.Preparation => "PREPARACIÓN",
            GamePhase.Battle => "BATALLA",
            GamePhase.Victory => "VICTORIA",
            GamePhase.Defeat => "DERROTA",
            _ => ""
        };

        RenderTitle($"⚔️  OLEADA {state.CurrentWave}/{state.MaxWaves}  |  {phaseName}  |  🪙 {state.Gold}  🌾 {state.Food}",
            phaseColor);

        if (state.IsPaused)
            RenderText("  ⏸️  PAUSADO — Presiona ESPACIO para reanudar\n", ConsoleColor.Gray);

        Console.WriteLine($"  Enemigos vivos: {state.EnemyTeam.TotalAlive}  |  Tus unidades: {state.PlayerTeam.TotalAlive}");
        Console.WriteLine();

        // Carriles
        foreach (var lane in new[] { LanePosition.Top, LanePosition.Mid, LanePosition.Bot })
        {
            var laneIcon = lane switch
            {
                LanePosition.Top => "🏔️ TOP",
                LanePosition.Mid => "🏟️ MEDIO",
                LanePosition.Bot => "🌿 BOT",
                _ => ""
            };

            var players = state.PlayerTeam.LaneEntities[lane].Where(e => e.Stats.IsAlive).ToList();
            var enemies = state.EnemyTeam.LaneEntities[lane].Where(e => e.Stats.IsAlive).ToList();

            var pStr = string.Join("  ", players.Select(e =>
                $"{Truncate(e.Name, 8)}[{e.Stats.CurrentHp}]"));
            var eStr = string.Join("  ", enemies.Select(e =>
                $"{Truncate(e.Name, 8)}[{e.Stats.CurrentHp}]"));

            Console.Write($"  {laneIcon}  ");
            Console.ForegroundColor = ConsoleColor.Green;
            Console.Write($"{Truncate(pStr, 28),-28}");
            Console.ResetColor();
            Console.Write(" ⚔️ ");
            Console.ForegroundColor = ConsoleColor.Red;
            Console.Write($"{Truncate(eStr, 28),-28}");
            Console.ResetColor();
            Console.WriteLine();

            // Barra de HP simplificada
            if (players.Any())
            {
                var avgHpPct = players.Average(e => (double)e.Stats.CurrentHp / e.Stats.MaxHp);
                DrawHealthBar(avgHpPct, "  ══════════════════════", false);
            }
            if (enemies.Any())
            {
                var avgHpPct = enemies.Average(e => (double)e.Stats.CurrentHp / e.Stats.MaxHp);
                DrawHealthBar(avgHpPct, "  ══════════════════════", true);
            }
            Console.WriteLine();
        }

        // Héroe
        if (_mainHero != null && _mainHero.Stats.IsAlive)
        {
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine($"  🦸 {_mainHero.Name} Lv.{_mainHero.Level} ⭐{_mainHero.Stars}" +
                $"  HP: {_mainHero.Stats.CurrentHp}/{_mainHero.Stats.MaxHp}");
            Console.ResetColor();
            foreach (var skill in _mainHero.Skills)
            {
                var status = skill.IsReady ? "✅ LISTO" : $"⏳ {skill.CurrentCooldown:F1}s";
                Console.WriteLine($"     {skill.Name,-16} {status}");
            }
        }

        // Castillo
        if (state.PlayerTeam.Castle != null)
        {
            var c = state.PlayerTeam.Castle;
            var pct = (double)c.Stats.CurrentHp / c.Stats.MaxHp;
            Console.Write("  🏰 Castillo [");
            DrawHealthBarInline(pct);
            Console.WriteLine($"] {c.Stats.CurrentHp}/{c.Stats.MaxHp}");
        }

        // Log de eventos
        Console.WriteLine();
        RenderText($"  ─── ÚLTIMOS EVENTOS ───", ConsoleColor.DarkGray);
        foreach (var evt in _eventLog.TakeLast(6))
            Console.WriteLine($"  {evt}");

        // Comandos
        Console.WriteLine();
        Console.ForegroundColor = ConsoleColor.DarkGray;
        Console.WriteLine("  ─── COMANDOS ───");
        Console.WriteLine("  [1] Guerrero  [2] Arquero  [3] Jinete  [4] Habilidad  [R] Mago");
        Console.WriteLine("  [Q] Guerrero TOP  [W] Arquero TOP  [E] Jinete BOT");
        Console.WriteLine("  [ESPACIO] Pausa  [ESC] Salir");
        Console.ResetColor();
    }

    private static void DrawHealthBar(double pct, string bar, bool enemy)
    {
        var filled = (int)(pct * bar.Length);
        var color = pct > 0.5 ? ConsoleColor.Green : pct > 0.25 ? ConsoleColor.Yellow : ConsoleColor.Red;
        Console.ForegroundColor = enemy ? ConsoleColor.Red : color;
        var fill = new string('█', filled);
        var empty = new string('▒', bar.Length - filled);
        Console.Write($"  {fill}{empty}");
        Console.ResetColor();
        Console.WriteLine($" {(pct * 100):F0}%");
    }

    private static void DrawHealthBarInline(double pct)
    {
        var color = pct > 0.5 ? ConsoleColor.Green : pct > 0.25 ? ConsoleColor.Yellow : ConsoleColor.Red;
        Console.ForegroundColor = color;
        var barLen = 15;
        var filled = (int)(pct * barLen);
        Console.Write(new string('█', filled));
        Console.ForegroundColor = ConsoleColor.DarkGray;
        Console.Write(new string('▒', barLen - filled));
        Console.ResetColor();
    }

    // ═══════════════════════════════════════════════
    //  UTILIDADES
    // ═══════════════════════════════════════════════

    private Equipment GenerateRandomEquipment(int wave)
    {
        var rand = Random.Shared;
        var slots = Enum.GetValues<EquipmentSlot>();
        var slot = slots[rand.Next(slots.Length)];
        var rarity = wave switch
        {
            < 3 => Rarity.Common,
            < 6 => Rarity.Rare,
            < 10 => Rarity.Epic,
            _ => Rarity.Legendary
        };

        var tier = 1 + wave / 3;
        var names = new Dictionary<EquipmentSlot, string[]>
        {
            [EquipmentSlot.Weapon] = new[] { "Mazo Solar", "Lanza del Sol", "Hacha Dorada", "Báculo Lunar" },
            [EquipmentSlot.Armor] = new[] { "Coraza Muisca", "Armadura Dorada", "Túnica de Plumas" },
            [EquipmentSlot.Helmet] = new[] { "Casco de Águila", "Corona Solar", "Máscara de Jade" },
            [EquipmentSlot.Accessory] = new[] { "Amuleto del Sol", "Anillo Lunar", "Pectoral Dorado" },
            [EquipmentSlot.Boots] = new[] { "Botas del Viento", "Sandalias Sagradas", "Grebas Doradas" },
        };

        var name = names[slot][rand.Next(names[slot].Length)];
        var rarityMult = rarity switch
        {
            Rarity.Common => 1.0,
            Rarity.Rare => 1.5,
            Rarity.Epic => 2.5,
            Rarity.Legendary => 4.0,
            _ => 1.0
        };

        return new Equipment
        {
            Id = $"eq_{Guid.NewGuid().ToString()[..6]}",
            Name = name,
            Slot = slot,
            Rarity = rarity,
            Level = tier,
            BonusStats = new Stats
            {
                MaxHp = (int)(20 * tier * rarityMult),
                Attack = (int)(5 * tier * rarityMult),
                Defense = (int)(3 * tier * rarityMult),
            },
            Description = $"+{(int)(5 * tier * rarityMult)} ATK, +{(int)(20 * tier * rarityMult)} HP. Nv.{tier}."
        };
    }

    private void TrimEventLog()
    {
        while (_eventLog.Count > MaxEventLog)
            _eventLog.RemoveAt(0);
    }

    private static ConsoleColor GetRarityColor(Rarity rarity) => rarity switch
    {
        Rarity.Common => ConsoleColor.White,
        Rarity.Rare => ConsoleColor.Blue,
        Rarity.Epic => ConsoleColor.Magenta,
        Rarity.Legendary => ConsoleColor.Yellow,
        Rarity.Mythic => ConsoleColor.Red,
        _ => ConsoleColor.Gray
    };

    private static void RenderTitle(string text, ConsoleColor color)
    {
        Console.ForegroundColor = color;
        var border = new string('═', text.Length + 4);
        Console.WriteLine($"  ╔{border}╗");
        Console.WriteLine($"  ║  {text}  ║");
        Console.WriteLine($"  ╚{border}╝");
        Console.ResetColor();
    }

    private static void RenderText(string text, ConsoleColor color)
    {
        Console.ForegroundColor = color;
        Console.WriteLine(text);
        Console.ResetColor();
    }

    private static void AnimatedText(string text, ConsoleColor color, int delayMs = 5)
    {
        Console.ForegroundColor = color;
        foreach (var line in text.Split('\n'))
        {
            Console.WriteLine(line);
            Thread.Sleep(delayMs);
        }
        Console.ResetColor();
    }

    private static string Truncate(string text, int maxLen)
    {
        if (string.IsNullOrEmpty(text)) return "";
        return text.Length <= maxLen ? text : text[..(maxLen - 2)] + "..";
    }

    private static string Prompt(string message)
    {
        Console.Write(message);
        Console.ForegroundColor = ConsoleColor.Cyan;
        var input = Console.ReadLine()?.Trim() ?? "";
        Console.ResetColor();
        return input;
    }
}
