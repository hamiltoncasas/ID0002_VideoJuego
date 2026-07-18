extends Control

# ─── CONFIG ───
var prep_time = 3.0
var wave = 1
var phase = "preparation"
var paused = false
var elapsed = 0.0
var prep_timer = 0.0
var gold: int; var food: int

var hero_data: Dictionary
var hero_node: Node2D
var hero_hp: int; var hero_max_hp: int
var hero_atk: int; var hero_def: int; var hero_speed: float; var hero_range: float
var hero_skill_cooldown = 0.0; var hero_skill_max_cooldown = 8.0

var player_castle_hp = 3000; var enemy_castle_hp = 3000
var player_units = []; var enemy_units = []
var selected_units = []
var lane_names = ["top", "mid", "bot"]

@onready var gold_label = $HUD/GoldLabel
@onready var food_label = $HUD/FoodLabel
@onready var wave_label = $HUD/WaveLabel
@onready var status_label = $HUD/StatusLabel
@onready var hero_name_label = $HeroPanel/HeroNameLabel
@onready var hero_hp_label = $HeroPanel/HeroHPLabel
@onready var skill_label = $HeroPanel/SkillLabel
@onready var top_units = $Lanes/Top/TopUnits
@onready var mid_units = $Lanes/Mid/MidUnits
@onready var bot_units = $Lanes/Bot/BotUnits

var unit_scene = preload("res://scenes/UnitNode.tscn")

func _ready():
	gold = Globals.gold; food = Globals.food
	hero_data = Globals.get_hero(Globals.selected_hero_id)
	hero_max_hp = hero_data["hp"]; hero_hp = hero_max_hp
	hero_atk = hero_data["atk"]; hero_def = hero_data["def"]
	hero_speed = hero_data["speed"]; hero_range = hero_data["range"]
	
	hero_name_label.text = "🦸 " + hero_data["name"] + " [" + hero_data["rarity"] + "]"
	skill_label.text = "⚡ [Q] " + hero_data["skill_name"]
	
	# Decoración de terreno
	_decorate_terrain()
	
	_create_hero_unit()
	_spawn_enemy_wave(1)
	_update_ui()
	
	phase = "preparation"; prep_timer = prep_time
	status_label.text = "PREPARACIÓN..."

func _decorate_terrain():
	# Add terrain details to each lane
	var lane_bgs = [$Lanes/Top/TopBg, $Lanes/Mid/MidBg, $Lanes/Bot/BotBg]
	var colors = [Color(0.15, 0.3, 0.1, 0.3), Color(0.25, 0.2, 0.08, 0.3), Color(0.1, 0.18, 0.25, 0.3)]
	for i in range(lane_bgs.size()):
		lane_bgs[i].color = colors[i]

func _create_hero_unit():
	var unit = unit_scene.instantiate()
	mid_units.add_child(unit)
	unit.setup(hero_data["name"], "hero", "player", hero_data["color"], 42, 32)
	unit.hp = hero_hp; unit.max_hp = hero_max_hp
	unit.attack = hero_atk; unit.defense = hero_def
	unit.attack_speed = hero_speed; unit.attack_range = hero_range
	unit.position = Vector2(80, 95)
	unit.is_hero = true
	unit.unit_clicked.connect(_on_unit_clicked)
	hero_node = unit; player_units.append(unit)
	
	# Rarity glow
	var glow = ColorRect.new()
	glow.name = "Glow"
	glow.size = Vector2(50, 40)
	glow.position = Vector2(-25, -20)
	glow.color = Color(1, 0.8, 0, 0.15)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unit.add_child(glow)

func _spawn_enemy_wave(wave_num):
	var count = 2 + wave_num
	var types = ["warrior", "archer", "cavalry"]
	var names = ["Guerrero", "Arquero", "Jinete"]
	var lanes = [top_units, mid_units, bot_units]
	
	for li in range(3):
		var lane = lanes[li]
		for i in range(count):
			var t = i % types.size()
			var def = Globals.unit_defs[types[t]]
			var unit = unit_scene.instantiate()
			lane.add_child(unit)
			var col = def["color"]
			unit.setup("E_" + def["name"], types[t], "enemy", col, 28, 22)
			unit.hp = def["hp"]; unit.max_hp = def["hp"]
			unit.attack = def["atk"]; unit.defense = def["def"]
			unit.attack_speed = def["speed"]; unit.attack_range = def["range"]
			unit.unit_class = def["class"]
			unit.position = Vector2(1000 - i * 30, 40 + i * 35)
			enemy_units.append(unit)
	
	wave_label.text = "⚔️ OLEADA " + str(wave_num)

func _process(delta):
	if paused or phase in ["victory", "defeat"]: return
	elapsed += delta
	
	if phase == "preparation":
		prep_timer -= delta
		status_label.text = "⚔️ EN " + str(ceil(prep_timer)) + "s" if prep_timer > 0 else ""
		if prep_timer <= 0:
			phase = "battle"; status_label.text = "⚔️ BATALLA"
		return
	
	if phase == "battle":
		if int(elapsed) != int(elapsed - delta):
			gold += 3; _update_ui()
		
		if hero_skill_cooldown > 0: hero_skill_cooldown -= delta
		
		_process_combat(delta)
		_cleanup_dead()
		_check_victory()

func _process_combat(delta):
	# Process each lane
	for lane_parent in [top_units, mid_units, bot_units]:
		var players = []
		var enemies = []
		for u in player_units:
			if is_instance_valid(u) and u.alive and u.get_parent() == lane_parent:
				players.append(u)
		for u in enemy_units:
			if is_instance_valid(u) and u.alive and u.get_parent() == lane_parent:
				enemies.append(u)
		
		for unit in players:
			if enemies.size() > 0:
				var target = _find_nearest(unit, enemies)
				if target:
					_do_auto_combat(unit, target, delta)
		
		for unit in enemies:
			if players.size() > 0:
				var target = _find_nearest(unit, players)
				if target:
					_do_auto_combat(unit, target, delta)

func _find_nearest(unit, targets):
	var nearest = null; var min_d = 99999.0
	for t in targets:
		if is_instance_valid(t) and t.alive:
			var d = unit.global_position.distance_to(t.global_position)
			if d < min_d: min_d = d; nearest = t
	return nearest

func _do_auto_combat(unit, target, delta):
	var dist = unit.global_position.distance_to(target.global_position)
	
	if dist > unit.attack_range:
		var dir = (target.global_position - unit.global_position).normalized()
		unit.position += dir * (60.0 if unit.is_hero else 80.0) * delta
	else:
		unit.cooldown_timer -= delta
		if unit.cooldown_timer <= 0:
			_deal_damage(unit, target)
			unit.cooldown_timer = 1.0 / max(unit.attack_speed, 0.1)

func _deal_damage(attacker, target):
	var raw = attacker.attack
	var def_red = 100.0 / (100.0 + max(1, target.defense))
	var final_dmg = max(1, int(raw * def_red))
	var crit = randf() < 0.15
	if crit: final_dmg = int(final_dmg * 1.8)
	
	target.take_damage(final_dmg, crit)
	
	if not target.alive:
		if target in player_units: player_units.erase(target)
		if target in enemy_units:
			enemy_units.erase(target)
			gold += 5
			_show_floating_text(target.global_position + Vector2(0, -20), "+5 🪙", Color(1, 0.8, 0))
			_update_ui()
	
	if target == hero_node or attacker == hero_node:
		if is_instance_valid(hero_node) and hero_node.alive:
			hero_hp = hero_node.hp
			hero_hp_label.text = "HP: " + str(hero_hp) + "/" + str(hero_max_hp)
		else:
			hero_hp = 0
			hero_hp_label.text = "HP: 0/" + str(hero_max_hp)

func _show_floating_text(pos, text, color):
	var label = Label.new()
	label.text = text
	label.modulate = color
	label.add_theme_font_size_override("font_size", 12)
	label.position = pos - Vector2(30, 0)
	label.size = Vector2(60, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", pos - Vector2(30, 40), 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

func _cleanup_dead():
	player_units = player_units.filter(func(u): return is_instance_valid(u) and u.alive)
	enemy_units = enemy_units.filter(func(u): return is_instance_valid(u) and u.alive)

func _check_victory():
	var ae = 0; var ap = 0
	for e in enemy_units:
		if is_instance_valid(e) and e.alive: ae += 1
	for p in player_units:
		if is_instance_valid(p) and p.alive: ap += 1
	
	if ae == 0:
		phase = "victory"
		status_label.text = "🏆 ¡VICTORIA! 🏆"
		status_label.modulate = Color(0.3, 1, 0.3)
		_show_victory_screen()
	elif ap == 0:
		phase = "defeat"
		status_label.text = "💀 DERROTA"
		status_label.modulate = Color(1, 0.3, 0.3)

func _show_victory_screen():
	await get_tree().create_timer(1.5).timeout
	# Transition to next wave
	wave += 1
	if wave > 5:
		status_label.text = "🏆 ¡CAMPAÑA COMPLETADA! 🏆"
		return
	_spawn_enemy_wave(wave)
	phase = "battle"
	status_label.text = "⚔️ BATALLA"
	status_label.modulate = Color(1, 1, 1)

func _spawn_player_unit(type_name):
	if phase != "battle": return
	var defs = Globals.unit_defs
	if not defs.has(type_name): return
	var d = defs[type_name]
	if gold < d["gold"] or food < d["food"]:
		status_label.text = "¡SIN RECURSOS!"
		return
	
	gold -= d["gold"]; food -= d["food"]
	
	var target_lane = mid_units
	if selected_units.size() > 0:
		var u = selected_units[0]
		if is_instance_valid(u) and u.alive:
			var p = u.get_parent()
			target_lane = p if p in [top_units, mid_units, bot_units] else mid_units
	
	var unit = unit_scene.instantiate()
	target_lane.add_child(unit)
	unit.setup(d["name"], type_name, "player", d["color"], 28, 22)
	unit.hp = d["hp"]; unit.max_hp = d["hp"]
	unit.attack = d["atk"]; unit.defense = d["def"]
	unit.attack_speed = d["speed"]; unit.attack_range = d["range"]
	unit.unit_class = d["class"]
	unit.position = Vector2(80, 40 + player_units.size() * 25)
	unit.unit_clicked.connect(_on_unit_clicked)
	player_units.append(unit)
	_update_ui()

func _use_hero_skill():
	if phase != "battle": return
	if hero_skill_cooldown > 0: return
	if not is_instance_valid(hero_node) or not hero_node.alive: return
	
	hero_skill_cooldown = hero_skill_max_cooldown
	var s_dmg = hero_data["skill_dmg"]
	
	if s_dmg > 0:
		for e in enemy_units:
			if is_instance_valid(e) and e.alive:
				e.take_damage(int(hero_atk * s_dmg), true)
				if not e.alive: enemy_units.erase(e); gold += 5
	else:
		for p in player_units:
			if is_instance_valid(p) and p.alive: p.heal(int(p.max_hp * 0.25))
		if is_instance_valid(hero_node) and hero_node.alive:
			hero_node.heal(int(hero_max_hp * 0.25))
			hero_hp = hero_node.hp
	
	status_label.text = "⚡ " + hero_data["skill_name"] + "!"
	_update_ui()

func _on_unit_clicked(unit):
	if unit.team != "player" or not unit.alive: return
	_deselect_all(); unit.select(); selected_units.append(unit)

func _deselect_all():
	for u in selected_units:
		if is_instance_valid(u): u.deselect()
	selected_units.clear()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_deselect_all()
		elif event.button_index == MOUSE_BUTTON_RIGHT and selected_units.size() > 0:
			var pos = get_global_mouse_position()
			for u in selected_units:
				if is_instance_valid(u) and u.alive: u.move_to(pos)
			get_viewport().set_input_as_handled()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _spawn_player_unit("warrior")
			KEY_2: _spawn_player_unit("archer")
			KEY_3: _spawn_player_unit("cavalry")
			KEY_Q: _use_hero_skill()
			KEY_SPACE:
				paused = !paused
				status_label.text = "⏸ PAUSA" if paused else ("⚔️ BATALLA")

func _update_ui():
	gold_label.text = "🪙 " + str(gold)
	food_label.text = "🌾 " + str(food)
	if is_instance_valid(hero_node) and hero_node.alive:
		hero_hp = hero_node.hp
		hero_hp_label.text = "HP: " + str(hero_hp) + "/" + str(hero_max_hp)
