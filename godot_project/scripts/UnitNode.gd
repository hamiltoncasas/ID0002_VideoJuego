extends Node2D

signal unit_clicked(unit)

# Stats
var unit_name = ""; var unit_type = ""
var team = "player"; var unit_class = "infantry"
var hp = 100; var max_hp = 100
var attack = 10; var defense = 5
var attack_speed = 1.0; var attack_range = 40.0
var is_hero = false

# State
var alive = true; var selected = false
var moving = false; var target_pos = Vector2()
var cooldown_timer = 0.0; var move_speed = 100.0
var flash_timer = 0.0; var idle_bob = 0.0
var base_y = 0.0; var anim_time = 0.0
var facing_right = true
var flash_color = Color(1, 1, 1)
var body_color = Color(0.5, 0.5, 0.5)
var glow_intensity = 0.0
var attack_swing = 0.0

@onready var hp_bar = $HPBar
@onready var hp_bar_bg = $HPBarBg
@onready var selection = $Selection

func _ready():
	base_y = position.y
	_create_hp_bar()
	_create_selection()
	queue_redraw()

func _create_hp_bar():
	hp_bar_bg = ColorRect.new()
	hp_bar_bg.size = Vector2(30, 4)
	hp_bar_bg.position = Vector2(-15, -28)
	hp_bar_bg.color = Color(0.15, 0.05, 0.05, 0.7)
	hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar_bg.name = "HPBarBg"
	add_child(hp_bar_bg)
	
	hp_bar = ColorRect.new()
	hp_bar.size = Vector2(30, 4)
	hp_bar.position = Vector2(-15, -28)
	hp_bar.color = Color(0.2, 0.85, 0.2, 0.9)
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar.name = "HPBar"
	add_child(hp_bar)

func _create_selection():
	selection = ColorRect.new()
	selection.size = Vector2(40, 44)
	selection.position = Vector2(-20, -24)
	selection.color = Color(0, 0, 0, 0)
	selection.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection.name = "Selection"
	add_child(selection)

func setup(name_val, type_val, team_val, color_val, w, h):
	unit_name = name_val; unit_type = type_val; team = team_val
	body_color = color_val if team == "player" else Color(color_val.r * 0.45, color_val.g * 0.2, color_val.b * 0.2)
	queue_redraw()

func _draw():
	if not alive: return
	
	var w = 20; var h = 24
	var cx = 0; var cy = 0
	var col = body_color
	
	# Shadow
	draw_ellipse(Vector2(2, 14), Vector2(14, 4), Color(0, 0, 0, 0.2))
	
	# Legs
	var leg_color = col * 0.7; leg_color.a = 1
	var leg_offset = sin(idle_bob * 4) * 2 if not moving else sin(idle_bob * 8) * 3
	draw_rect(Rect2(-7, 8, 5, 8), leg_color)
	draw_rect(Rect2(2, 8 + leg_offset, 5, 8), leg_color)
	
	# Body (rounded rect approximation)
	var body_col = col * (1.2 if is_hero else 1.0); body_col.a = 1
	draw_rect(Rect2(-10, -6, 20, 16), body_col)
	
	# Armor detail (chest)
	var armor = Color(0.7, 0.7, 0.6, 0.4) if team == "player" else Color(0.4, 0.2, 0.2, 0.4)
	draw_rect(Rect2(-6, -2, 12, 8), armor)
	
	# Hero glow
	if is_hero:
		var glow = Color(1, 0.9, 0.3, 0.1 + sin(idle_bob * 2) * 0.05)
		draw_rect(Rect2(-12, -8, 24, 20), glow)
	
	# Arms
	var arm_col = col * 0.8; arm_col.a = 1
	if facing_right:
		draw_rect(Rect2(8, -2 + attack_swing, 8, 4), arm_col)
		# Weapon
		var wpn = Color(0.7, 0.7, 0.8, 1) if unit_type != "archer" else Color(0.5, 0.3, 0.1, 1)
		draw_rect(Rect2(14, -3 + attack_swing, 10, 3), wpn)
	else:
		draw_rect(Rect2(-16, -2 + attack_swing, 8, 4), arm_col)
		var wpn = Color(0.7, 0.7, 0.8, 1)
		draw_rect(Rect2(-24, -3 + attack_swing, 10, 3), wpn)
	
	# Head
	var head_col = col * 0.85; head_col.a = 1
	draw_circle(Vector2(0, -11), 7, head_col)
	
	# Eyes
	var eye_col = Color(0, 0, 0, 0.8)
	if facing_right:
		draw_circle(Vector2(2, -12), 1.5, eye_col)
		draw_circle(Vector2(-3, -12), 1.5, eye_col)
	else:
		draw_circle(Vector2(-2, -12), 1.5, eye_col)
		draw_circle(Vector2(3, -12), 1.5, eye_col)
	
	# Helmet/headband
	var band = Color(0.8, 0.2, 0.2, 0.6) if team == "player" else Color(0.6, 0.1, 0.1, 0.6)
	draw_rect(Rect2(-6, -16, 12, 3), band)
	
	# Flash overlay
	if flash_timer > 0:
		var f = Color(1, 1, 1, 0.3 * flash_timer)
		draw_rect(Rect2(-10, -18, 20, 30), f)
	
	# Selection glow
	if selected:
		var s = Color(1, 1, 0, 0.15 + sin(idle_bob * 3) * 0.1)
		draw_rect(Rect2(-14, -20, 28, 36), s)

func draw_ellipse(pos, size, color):
	var steps = 20
	var points = []
	for i in range(steps):
		var a = i * 2 * PI / steps
		points.append(pos + Vector2(cos(a) * size.x, sin(a) * size.y))
	draw_colored_polygon(points, color)

func _process(delta):
	if not alive: return
	anim_time += delta
	idle_bob += delta * 2.5
	
	# Attack swing decay
	if attack_swing > 0:
		attack_swing -= delta * 6
	else:
		attack_swing = 0
	
	# Flash decay
	if flash_timer > 0: flash_timer -= delta
	
	# Movement
	if moving:
		var dir = target_pos - global_position
		var dist = dir.length()
		if dist < 10:
			moving = false
		else:
			dir = dir.normalized()
			global_position += dir * move_speed * delta
			facing_right = dir.x > 0
	
	# Redraw
	queue_redraw()

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if team == "player":
			emit_signal("unit_clicked", self)
			get_viewport().set_input_as_handled()

func select():
	selected = true; queue_redraw()

func deselect():
	selected = false; queue_redraw()

func move_to(pos):
	if not alive or team != "player": return
	target_pos = pos; moving = true

func take_damage(dmg, crit = false):
	if not alive: return
	hp -= dmg
	flash_timer = 0.3
	attack_swing = 0.3
	
	var pct = float(max(0, hp)) / max_hp
	hp_bar.size.x = 30 * pct
	if pct > 0.5: hp_bar.color = Color(0.2, 0.85, 0.2, 0.9)
	elif pct > 0.25: hp_bar.color = Color(0.85, 0.7, 0.1, 0.9)
	else: hp_bar.color = Color(0.85, 0.15, 0.1, 0.9)
	
	if crit:
		flash_timer = 0.5
		selection.color = Color(1, 0.5, 0, 0.6)
		await get_tree().create_timer(0.15).timeout
		selection.color = Color(0, 0, 0, 0)
	
	if hp <= 0: die()

func heal(amount):
	if not alive: return
	hp = min(max_hp, hp + amount)
	var pct = float(hp) / max_hp
	hp_bar.size.x = 30 * pct
	flash_timer = -0.2
	if hp <= 0: die()

func die():
	alive = false
	# Spawn death particles in parent
	for i in range(10):
		var p = ColorRect.new()
		p.size = Vector2(4, 4)
		p.color = body_color
		p.position = global_position + Vector2(randf() * 20 - 10, randf() * 20 - 10)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		get_parent().add_child(p)
		var t = create_tween(); t.set_parallel(true)
		t.tween_property(p, "position", global_position + Vector2(randf() * 80 - 40, -randf() * 60 - 10), 0.5)
		t.tween_property(p, "modulate:a", 0.0, 0.5)
		t.tween_property(p, "size", Vector2(2, 2), 0.5)
		t.tween_callback(p.queue_free)
	
	hp_bar.visible = false; hp_bar_bg.visible = false
	create_tween().tween_property(self, "modulate", Color(1, 1, 1, 0), 0.4)
	create_tween().tween_callback(queue_free)

func get_class_icon():
	match unit_class:
		"infantry": return "🛡"
		"archer": return "🏹"
		"cavalry": return "🐎"
	return ""
