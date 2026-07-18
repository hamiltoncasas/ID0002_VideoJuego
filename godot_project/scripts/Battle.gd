extends Control

# ─── CONFIG ───
var wave = 1; var phase = "preparation"
var paused = false; var elapsed = 0.0; var prep_timer = 3.0
var gold: int; var food: int
var screen_shake = 0.0

var hero_data: Dictionary; var hero_node: Node2D
var hero_hp: int; var hero_max_hp: int; var hero_atk: int; var hero_def: int
var hero_speed: float; var hero_range: float
var hero_skill_cd = 0.0; var hero_skill_max_cd = 8.0

var player_units = []; var enemy_units = []; var selected_units = []

@onready var gold_label = $HUD/GoldLabel
@onready var food_label = $HUD/FoodLabel
@onready var wave_label = $HUD/WaveLabel
@onready var status_label = $HUD/StatusLabel
@onready var hero_name_label = $HeroPanel/HeroNameLabel
@onready var hero_hp_label = $HeroPanel/HeroHPLabel
@onready var skill_label = $HeroPanel/SkillLabel
@onready var effects = $Effects
@onready var battlefield = $Battlefield

var unit_scene = preload("res://scenes/UnitNode.tscn")

func _ready():
	gold = Globals.gold; food = Globals.food
	hero_data = Globals.get_hero(Globals.selected_hero_id)
	hero_max_hp = hero_data["hp"]; hero_hp = hero_max_hp
	hero_atk = hero_data["atk"]; hero_def = hero_data["def"]
	hero_speed = hero_data["speed"]; hero_range = hero_data["range"]
	
	hero_name_label.text = "🦸 " + hero_data["name"]
	skill_label.text = "⚡ [Q] " + hero_data["skill_name"]
	
	_generate_terrain()
	_spawn_hero()
	_spawn_player_army()
	_spawn_enemy_wave(1)
	_update_ui()
	phase = "preparation"; prep_timer = 3.0
	status_label.text = "⏳ PREPARACION..."

func _generate_terrain():
	# Create a nice 2D battlefield background
	# Grass field
	var grass = ColorRect.new()
	grass.size = Vector2(1260, 640)
	grass.position = Vector2(10, 55)
	grass.color = Color(0.15, 0.35, 0.1, 0.4)
	battlefield.add_child(grass)
	
	# Decorative elements
	for i in range(20):
		var d = Label.new()
		var items = ["🌿", "🌱", "🪨", "🌾", "🍃"]
		d.text = items[i % items.size()]
		d.position = Vector2(30 + randi() % 1200, 65 + randi() % 600)
		d.modulate = Color(1, 1, 1, 0.1 + randf() * 0.15)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		battlefield.add_child(d)

func _spawn_hero():
	var u = unit_scene.instantiate()
	battlefield.add_child(u)
	u.setup(hero_data["name"], "hero", "player", hero_data["color"], 42, 32)
	u.hp = hero_max_hp; u.max_hp = hero_max_hp
	u.attack = hero_atk; u.defense = hero_def
	u.attack_speed = hero_speed; u.attack_range = hero_range + 20
	u.position = Vector2(120, 360); u.is_hero = true
	u.unit_clicked.connect(_on_unit_clicked)
	hero_node = u; player_units.append(u)

func _spawn_player_army():
	var types = ["warrior", "archer", "cavalry"]
	var y = 200
	for type in types:
		var count = Globals.army_counts.get(type, 0)
		for i in range(count):
			var d = Globals.unit_defs[type]
			var u = unit_scene.instantiate()
			battlefield.add_child(u)
			u.setup(d["name"], type, "player", d["color"], 28, 22)
			u.hp = d["hp"]; u.max_hp = d["hp"]
			u.attack = d["atk"]; u.defense = d["def"]
			u.attack_speed = d["speed"]; u.attack_range = d["range"]
			u.unit_class = d["class"]
			u.position = Vector2(60 + i * 30, y)
			u.unit_clicked.connect(_on_unit_clicked)
			player_units.append(u)
			y += 25

func _spawn_enemy_wave(wave_num):
	var count = 3 + wave_num * 2
	var types = ["warrior", "archer", "cavalry"]
	var names = ["Guerrero", "Arquero", "Jinete"]
	
	for i in range(count):
		var t = i % types.size()
		var d = Globals.unit_defs[types[t]]
		var u = unit_scene.instantiate()
		battlefield.add_child(u)
		u.setup("E_" + d["name"], types[t], "enemy", d["color"], 28, 22)
		u.hp = d["hp"] * (1 + wave_num * 0.1); u.max_hp = u.hp
		u.attack = d["atk"] * (1 + wave_num * 0.05); u.defense = d["def"]
		u.attack_speed = d["speed"]; u.attack_range = d["range"]
		u.unit_class = d["class"]
		u.position = Vector2(1100 + randi() % 100, 100 + randi() % 500)
		enemy_units.append(u)
	
	wave_label.text = "⚔️ OLEADA " + str(wave_num)

func _process(delta):
	if paused or phase in ["victory", "defeat"]: return
	elapsed += delta
	
	if screen_shake > 0:
		screen_shake -= delta * 8
		var a = screen_shake * 3
		position = Vector2(randf() * a - a/2, randf() * a - a/2)
	else:
		position = Vector2(0, 0)
	
	if phase == "preparation":
		prep_timer -= delta
		if prep_timer <= 0: phase = "battle"; status_label.text = "⚔️ BATALLA"
		else: status_label.text = "⏳ " + str(ceil(prep_timer)) + "s"
		return
	
	if phase != "battle": return
	
	if int(elapsed) != int(elapsed - delta): gold += 5; _update_ui()
	if hero_skill_cd > 0: hero_skill_cd -= delta
	
	# Auto-combat: check each player unit vs nearest enemy
	for u in player_units:
		if not is_instance_valid(u) or not u.alive: continue
		var target = _nearest(u, enemy_units)
		if target: _auto_fight(u, target, delta)
		else: _advance_to_enemy_side(u, delta)
	
	# Enemy AI: attack nearest player or advance
	for u in enemy_units:
		if not is_instance_valid(u) or not u.alive: continue
		var target = _nearest(u, player_units)
		if target: _auto_fight(u, target, delta)
		else: _advance_to_player_side(u, delta)
	
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
		u.position += dir * (70 if u.is_hero else 90) * delta
	else:
		u.cooldown_timer -= delta
		if u.cooldown_timer <= 0:
			u.cooldown_timer = 1.0 / max(u.attack_speed, 0.1)
			_spawn_projectile(u, target)
			_do_damage(u, target)

func _spawn_projectile(from, to):
	var p = ColorRect.new()
	p.size = Vector2(6, 4)
	p.color = Color(1, 0.8, 0.2) if from.team == "player" else Color(1, 0.3, 0.2)
	p.position = from.global_position; p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects.add_child(p)
	var t = create_tween(); t.set_parallel(true)
	t.tween_property(p, "position", to.global_position, 0.12)
	t.tween_property(p, "modulate:a", 0.0, 0.12)
	t.tween_callback(p.queue_free)

func _advance_to_enemy_side(u, delta):
	u.position.x += 50 * delta

func _advance_to_player_side(u, delta):
	u.position.x -= 40 * delta

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
			enemy_units.erase(target); gold += 8
			_floating_text(target.global_position + Vector2(0, -25), "+8🪙", Color(1, 0.85, 0))
			_update_ui()
	
	if target == hero_node or atk == hero_node:
		if is_instance_valid(hero_node) and hero_node.alive: hero_hp = hero_node.hp
		hero_hp_label.text = "❤️ " + str(hero_hp) + "/" + str(hero_max_hp)

func _floating_text(pos, txt, col):
	var l = Label.new()
	l.text = txt; l.modulate = col
	l.add_theme_font_size_override("font_size", 12)
	l.position = pos - Vector2(25, 0); l.size = Vector2(50, 16)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(l)
	var t = create_tween(); t.set_parallel(true)
	t.tween_property(l, "position", pos + Vector2(0, -35), 0.7)
	t.tween_property(l, "modulate:a", 0.0, 0.7)
	t.tween_callback(l.queue_free)

func _check_victory():
	var ae = 0; var ap = 0
	for u in enemy_units:
		if is_instance_valid(u) and u.alive: ae += 1
	for u in player_units:
		if is_instance_valid(u) and u.alive: ap += 1
	
	# Enemies reaching left side = defeat
	for u in enemy_units:
		if is_instance_valid(u) and u.alive and u.position.x < 40:
			phase = "defeat"; status_label.text = "💀 DERROTA"
			status_label.modulate = Color(1, 0.3, 0.3)
			_explosion(Vector2(640, 360), Color(1, 0.3, 0.2))
			return
	
	if ae == 0:
		phase = "victory"; status_label.text = "🏆 VICTORIA!"
		status_label.modulate = Color(0.3, 1, 0.3)
		_explosion(Vector2(640, 360), Color(1, 0.8, 0))
		gold += 50 + wave * 25
		_update_ui()
		await get_tree().create_timer(2.0).timeout
		wave += 1
		if wave <= 100:
			_spawn_enemy_wave(wave)
			phase = "battle"; status_label.text = "⚔️ BATALLA"
			status_label.modulate = Color(1, 1, 1)
	elif ap == 0:
		phase = "defeat"; status_label.text = "💀 DERROTA"
		status_label.modulate = Color(1, 0.3, 0.3)
		_explosion(Vector2(640, 360), Color(1, 0.3, 0.2))

func _explosion(pos, color):
	for i in range(16):
		var p = ColorRect.new()
		p.size = Vector2(5, 5); p.color = color
		p.position = pos; p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		effects.add_child(p)
		var t = create_tween(); t.set_parallel(true)
		t.tween_property(p, "position", pos + Vector2(randf() * 250 - 125, randf() * 250 - 125), 0.7)
		t.tween_property(p, "modulate:a", 0.0, 0.7)
		t.tween_property(p, "size", Vector2(2, 2), 0.7)
		t.tween_callback(p.queue_free)

func _hero_skill_effect():
	var flash = ColorRect.new()
	flash.size = Vector2(1280, 720)
	flash.color = Color(1, 1, 0.5, 0.12)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects.add_child(flash)
	var t = create_tween()
	t.tween_property(flash, "modulate:a", 0.0, 0.4)
	t.tween_callback(flash.queue_free)
	screen_shake = 2.0

func _cleanup():
	player_units = player_units.filter(func(u): return is_instance_valid(u) and u.alive)
	enemy_units = enemy_units.filter(func(u): return is_instance_valid(u) and u.alive)

func _hero_skill():
	if phase != "battle": return
	if not is_instance_valid(hero_node) or not hero_node.alive: return
	if hero_skill_cd > 0: return
	hero_skill_cd = hero_skill_max_cd
	var sd = hero_data["skill_dmg"]
	_hero_skill_effect()
	if sd > 0:
		for e in enemy_units:
			if is_instance_valid(e) and e.alive:
				e.take_damage(int(hero_atk * sd), true)
				if not e.alive: enemy_units.erase(e); gold += 8
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
			KEY_Q: _hero_skill()
			KEY_SPACE: paused = !paused; status_label.text = "⏸ PAUSA"

func _update_ui():
	gold_label.text = "🪙 " + str(gold); food_label.text = "🌾 " + str(food)
	if is_instance_valid(hero_node) and hero_node.alive:
		hero_hp = hero_node.hp; hero_hp_label.text = "❤️ " + str(hero_hp) + "/" + str(hero_max_hp)
