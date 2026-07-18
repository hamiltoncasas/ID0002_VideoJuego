extends Control

var prep_time = 3.0; var wave = 1; var phase = "preparation"
var paused = false; var elapsed = 0.0; var prep_timer = 0.0
var gold: int; var food: int

var hero_data: Dictionary; var hero_node: Node2D
var hero_hp: int; var hero_max_hp: int; var hero_atk: int; var hero_def: int
var hero_speed: float; var hero_range: float
var hero_skill_cooldown = 0.0; var hero_skill_max_cooldown = 8.0

var player_units = []; var enemy_units = []; var selected_units = []
var screen_shake = 0.0

@onready var gold_label = $HUD/GoldLabel; @onready var food_label = $HUD/FoodLabel
@onready var wave_label = $HUD/WaveLabel; @onready var status_label = $HUD/StatusLabel
@onready var hero_name_label = $HeroPanel/HeroNameLabel
@onready var hero_hp_label = $HeroPanel/HeroHPLabel
@onready var skill_label = $HeroPanel/SkillLabel
@onready var top_units = $Lanes/Top/TopUnits; @onready var mid_units = $Lanes/Mid/MidUnits
@onready var bot_units = $Lanes/Bot/BotUnits
@onready var player_castle = $PlayerCastle; @onready var enemy_castle = $EnemyCastle
@onready var effects_layer = $Effects

var unit_scene = preload("res://scenes/UnitNode.tscn")

func _ready():
	gold = Globals.gold; food = Globals.food
	hero_data = Globals.get_hero(Globals.selected_hero_id)
	hero_max_hp = hero_data["hp"]; hero_hp = hero_max_hp
	hero_atk = hero_data["atk"]; hero_def = hero_data["def"]
	hero_speed = hero_data["speed"]; hero_range = hero_data["range"]
	
	hero_name_label.text = "🦸 " + hero_data["name"] + " [" + hero_data["rarity"] + "]"
	skill_label.text = "⚡ [Q] " + hero_data["skill_name"]
	
	_decorate_terrain()
	_create_hero()
	_spawn_enemy_wave(1)
	_update_ui()
	phase = "preparation"; prep_timer = prep_time
	status_label.text = "⏳ PREPARACIÓN..."

func _decorate_terrain():
	# Lane background colors with subtle terrain
	var bgs = [$Lanes/Top/TopBg, $Lanes/Mid/MidBg, $Lanes/Bot/BotBg]
	var cs = [
		Color(0.18, 0.32, 0.1, 0.35),  # Grass
		Color(0.28, 0.22, 0.08, 0.35), # Dirt road
		Color(0.1, 0.18, 0.28, 0.35)   # Stone/water
	]
	for i in range(3): bgs[i].color = cs[i]
	
	# Decorative elements on lanes
	var lane_nodes = [$Lanes/Top, $Lanes/Mid, $Lanes/Bot]
	var decorations = ["🌿", "🪨", "🌾"]
	for i in range(3):
		for j in range(4):
			var dec = Label.new()
			dec.text = decorations[i]
			dec.position = Vector2(100 + j * 250 + randi() % 60, 20 + randi() % 150)
			dec.modulate = Color(1, 1, 1, 0.15 + randf() * 0.1)
			dec.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lane_nodes[i].add_child(dec)

func _create_hero():
	var u = unit_scene.instantiate()
	mid_units.add_child(u)
	u.setup(hero_data["name"], "hero", "player", hero_data["color"], 42, 32)
	u.hp = hero_hp; u.max_hp = hero_max_hp; u.attack = hero_atk; u.defense = hero_def
	u.attack_speed = hero_speed; u.attack_range = hero_range
	u.position = Vector2(80, 95); u.is_hero = true
	u.unit_clicked.connect(_on_unit_clicked)
	hero_node = u; player_units.append(u)

func _spawn_enemy_wave(wave_num):
	var count = 2 + wave_num
	var types = ["warrior", "archer", "cavalry"]
	var lanes = [top_units, mid_units, bot_units]
	for li in range(3):
		for i in range(count):
			var t = i % types.size(); var d = Globals.unit_defs[types[t]]
			var u = unit_scene.instantiate()
			lanes[li].add_child(u)
			u.setup("E_" + d["name"], types[t], "enemy", d["color"], 28, 22)
			u.hp = d["hp"]; u.max_hp = d["hp"]; u.attack = d["atk"]; u.defense = d["def"]
			u.attack_speed = d["speed"]; u.attack_range = d["range"]; u.unit_class = d["class"]
			u.position = Vector2(1020 - i * 35, 40 + i * 30)
			enemy_units.append(u)
	wave_label.text = "⚔️ OLEADA " + str(wave_num)

func _process(delta):
	if paused or phase in ["victory", "defeat"]: return
	elapsed += delta
	
	# Screen shake
	if screen_shake > 0:
		screen_shake -= delta * 10
		var amt = screen_shake * 3
		position = Vector2(randf() * amt - amt/2, randf() * amt - amt/2)
	else:
		position = Vector2(0, 0)
	
	if phase == "preparation":
		prep_timer -= delta
		if prep_timer <= 0: phase = "battle"; status_label.text = "⚔️ BATALLA"
		else: status_label.text = "⚔️ EN " + str(ceil(prep_timer)) + "s"
		return
	
	if phase != "battle": return
	
	if int(elapsed) != int(elapsed - delta): gold += 3; _update_ui()
	if hero_skill_cooldown > 0: hero_skill_cooldown -= delta
	
	for lane in [top_units, mid_units, bot_units]:
		var pl = []; var el = []
		for u in player_units:
			if is_instance_valid(u) and u.alive and u.get_parent() == lane: pl.append(u)
		for u in enemy_units:
			if is_instance_valid(u) and u.alive and u.get_parent() == lane: el.append(u)
		
		for u in pl:
			if el.size() > 0: _auto_fight(u, _nearest(u, el), delta)
			else: _advance(u, delta, 1)
		for u in el:
			if pl.size() > 0: _auto_fight(u, _nearest(u, pl), delta)
			else: _advance(u, delta, -1)
	
	_check_victory(); _cleanup()

func _nearest(u, list):
	var n = null; var md = 99999.0
	for t in list:
		if is_instance_valid(t) and t.alive:
			var d = u.global_position.distance_to(t.global_position)
			if d < md: md = d; n = t
	return n

func _auto_fight(u, target, delta):
	var dist = u.global_position.distance_to(target.global_position)
	if dist > u.attack_range:
		var dir = (target.global_position - u.global_position).normalized()
		u.position += dir * (70.0 if u.is_hero else 90.0) * delta
	else:
		u.cooldown_timer -= delta
		if u.cooldown_timer <= 0:
			u.cooldown_timer = 1.0 / max(u.attack_speed, 0.1)
			_spawn_projectile(u, target)
			_do_damage(u, target)

func _spawn_projectile(from, to):
	# Simple projectile visual
	var proj = ColorRect.new()
	proj.size = Vector2(6, 4)
	proj.color = Color(1, 0.8, 0.2, 0.9) if from.team == "player" else Color(1, 0.3, 0.2, 0.9)
	proj.position = from.global_position
	proj.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects_layer.add_child(proj)
	
	var tween = create_tween(); tween.set_parallel(true)
	tween.tween_property(proj, "position", to.global_position, 0.15)
	tween.tween_property(proj, "modulate:a", 0.0, 0.15)
	tween.tween_callback(proj.queue_free)

func _advance(u, delta, dir):
	u.position.x += 40.0 * delta * dir

func _do_damage(atk, target):
	var raw = atk.attack
	var def_red = 100.0 / (100.0 + max(1, target.defense))
	var dmg = max(1, int(raw * def_red))
	var crit = randf() < 0.1
	if crit: dmg = int(dmg * 1.8); screen_shake = 1.0
	
	target.take_damage(dmg, crit)
	
	if not target.alive:
		if target in player_units: player_units.erase(target)
		if target in enemy_units:
			enemy_units.erase(target); gold += 5
			_floating_text(target.global_position + Vector2(0, -25), "+5🪙", Color(1, 0.85, 0))
			_update_ui()
	
	if target == hero_node or atk == hero_node:
		if is_instance_valid(hero_node) and hero_node.alive:
			hero_hp = hero_node.hp
			hero_hp_label.text = "❤️ " + str(hero_hp) + "/" + str(hero_max_hp)

func _floating_text(pos, txt, col):
	var lbl = Label.new()
	lbl.text = txt; lbl.modulate = col
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.position = pos - Vector2(25, 0)
	lbl.size = Vector2(50, 16)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(lbl)
	var t = create_tween(); t.set_parallel(true)
	t.tween_property(lbl, "position", pos + Vector2(0, -35), 0.8)
	t.tween_property(lbl, "modulate:a", 0.0, 0.8)
	t.tween_callback(lbl.queue_free)

func _check_victory():
	var ae = 0; var ap = 0
	for u in enemy_units:
		if is_instance_valid(u) and u.alive: ae += 1
	for u in player_units:
		if is_instance_valid(u) and u.alive: ap += 1
	
	for u in enemy_units:
		if is_instance_valid(u) and u.alive and u.position.x < 50:
			phase = "defeat"; status_label.text = "💀 DERROTA"
			status_label.modulate = Color(1, 0.3, 0.3)
			_effect_explosion(Vector2(640, 360), Color(1, 0.3, 0.2))
			return
	
	if ae == 0:
		phase = "victory"; status_label.text = "🏆 ¡VICTORIA! 🏆"
		status_label.modulate = Color(0.3, 1, 0.3)
		_effect_explosion(Vector2(640, 360), Color(1, 0.8, 0))
		await get_tree().create_timer(2.0).timeout
		wave += 1
		if wave <= 10:
			_spawn_enemy_wave(wave)
			phase = "battle"; status_label.text = "⚔️ BATALLA"
			status_label.modulate = Color(1, 1, 1)
	elif ap == 0:
		phase = "defeat"; status_label.text = "💀 DERROTA"
		status_label.modulate = Color(1, 0.3, 0.3)
		_effect_explosion(Vector2(640, 360), Color(1, 0.3, 0.2))

func _effect_explosion(pos, color):
	for i in range(12):
		var p = ColorRect.new()
		p.size = Vector2(5, 5)
		p.color = color
		p.position = pos; p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		effects_layer.add_child(p)
		var t = create_tween(); t.set_parallel(true)
		t.tween_property(p, "position", pos + Vector2(randf() * 200 - 100, randf() * 200 - 100), 0.6)
		t.tween_property(p, "modulate:a", 0.0, 0.6)
		t.tween_property(p, "size", Vector2(2, 2), 0.6)
		t.tween_callback(p.queue_free)

func _hero_skill_effect():
	# Big flash for hero skill
	var flash = ColorRect.new()
	flash.size = Vector2(1280, 720)
	flash.color = Color(1, 1, 0.5, 0.15)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects_layer.add_child(flash)
	var t = create_tween()
	t.tween_property(flash, "modulate:a", 0.0, 0.4)
	t.tween_callback(flash.queue_free)
	screen_shake = 2.0

func _cleanup():
	player_units = player_units.filter(func(u): return is_instance_valid(u) and u.alive)
	enemy_units = enemy_units.filter(func(u): return is_instance_valid(u) and u.alive)

func _spawn_player_unit(type_name):
	if phase != "battle": return
	var d = Globals.unit_defs.get(type_name)
	if not d: return
	if gold < d["gold"] or food < d["food"]: return
	gold -= d["gold"]; food -= d["food"]
	
	var tl = mid_units
	if selected_units.size() > 0:
		var u = selected_units[0]
		if is_instance_valid(u) and u.alive:
			var p = u.get_parent()
			tl = p if p in [top_units, mid_units, bot_units] else mid_units
	
	var u = unit_scene.instantiate(); tl.add_child(u)
	u.setup(d["name"], type_name, "player", d["color"], 28, 22)
	u.hp = d["hp"]; u.max_hp = d["hp"]; u.attack = d["atk"]; u.defense = d["def"]
	u.attack_speed = d["speed"]; u.attack_range = d["range"]; u.unit_class = d["class"]
	u.position = Vector2(80, 40 + player_units.size() * 25)
	u.unit_clicked.connect(_on_unit_clicked)
	player_units.append(u); _update_ui()

func _hero_skill():
	if phase != "battle" or not is_instance_valid(hero_node) or not hero_node.alive: return
	if hero_skill_cooldown > 0: return
	hero_skill_cooldown = hero_skill_max_cooldown
	var sd = hero_data["skill_dmg"]
	_hero_skill_effect()
	if sd > 0:
		for e in enemy_units:
			if is_instance_valid(e) and e.alive: e.take_damage(int(hero_atk * sd), true)
			if is_instance_valid(e) and not e.alive: enemy_units.erase(e); gold += 5
	else:
		for p in player_units:
			if is_instance_valid(p) and p.alive: p.heal(int(p.max_hp * 0.25))
		if is_instance_valid(hero_node) and hero_node.alive:
			hero_node.heal(int(hero_max_hp * 0.25)); hero_hp = hero_node.hp
	status_label.text = "⚡ " + hero_data["skill_name"] + "!"
	_update_ui()

func _on_unit_clicked(u):
	if u.team != "player" or not u.alive: return
	_deselect_all(); u.select(); selected_units.append(u)

func _deselect_all():
	for u in selected_units:
		if is_instance_valid(u): u.deselect()
	selected_units.clear()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT: _deselect_all()
		elif event.button_index == MOUSE_BUTTON_RIGHT and selected_units.size() > 0:
			var pos = get_global_mouse_position()
			for u in selected_units:
				if is_instance_valid(u) and u.alive: u.move_to(pos)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _spawn_player_unit("warrior")
			KEY_2: _spawn_player_unit("archer")
			KEY_3: _spawn_player_unit("cavalry")
			KEY_Q: _hero_skill()
			KEY_SPACE: paused = !paused; status_label.text = "⏸ PAUSA"

func _update_ui():
	gold_label.text = "🪙 " + str(gold); food_label.text = "🌾 " + str(food)
	if is_instance_valid(hero_node) and hero_node.alive:
		hero_hp = hero_node.hp; hero_hp_label.text = "❤️ " + str(hero_hp) + "/" + str(hero_max_hp)
