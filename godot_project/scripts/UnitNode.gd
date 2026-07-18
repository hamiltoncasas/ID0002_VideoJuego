extends Node2D

signal unit_clicked(unit)

# Stats
var unit_name = ""
var unit_type = ""
var team = "player"
var unit_class = "infantry"
var hp = 100; var max_hp = 100
var attack = 10; var defense = 5
var attack_speed = 1.0; var attack_range = 40.0
var is_hero = false

# State
var alive = true; var selected = false
var moving = false; var target_pos = Vector2()
var cooldown_timer = 0.0; var move_speed = 100.0
var flash_timer = 0.0; var idle_bob = 0.0
var base_y = 0.0; var attack_anim = 0.0
var original_scale = Vector2(1, 1)
var original_body_color = Color.WHITE
var facing_right = true

# Character parts
var head: ColorRect; var body: ColorRect
var weapon: ColorRect; var legs: Array = []
var shadow: ColorRect
var hp_bar: ColorRect; var hp_bar_bg: ColorRect
var selection_ring: ColorRect
var collision_area: Area2D
var col_shape: CollisionShape2D

func _ready():
	_build_character()
	_update_appearance()
	base_y = position.y
	original_scale = scale

func _build_character():
	# Shadow
	shadow = ColorRect.new()
	shadow.size = Vector2(30, 6)
	shadow.position = Vector2(-15, 14)
	shadow.color = Color(0, 0, 0, 0.25)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.name = "Shadow"
	add_child(shadow)
	
	# Legs
	for i in 2:
		var leg = ColorRect.new()
		leg.size = Vector2(6, 10)
		leg.position = Vector2(-5 + i * 10, 4)
		leg.color = Color(0.3, 0.2, 0.15)
		leg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		leg.name = "Leg" + str(i)
		add_child(leg)
		legs.append(leg)
	
	# Body
	body = ColorRect.new()
	body.size = Vector2(20, 18)
	body.position = Vector2(-10, -8)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.name = "Body"
	add_child(body)
	
	# Weapon
	weapon = ColorRect.new()
	weapon.size = Vector2(12, 4)
	weapon.position = Vector2(10, 0)
	weapon.color = Color(0.6, 0.6, 0.6)
	weapon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon.name = "Weapon"
	add_child(weapon)
	
	# Head
	head = ColorRect.new()
	head.size = Vector2(12, 12)
	head.position = Vector2(-6, -18)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.name = "Head"
	add_child(head)
	
	# HP Bar BG
	hp_bar_bg = ColorRect.new()
	hp_bar_bg.size = Vector2(28, 4)
	hp_bar_bg.position = Vector2(-14, -24)
	hp_bar_bg.color = Color(0.2, 0.05, 0.05, 0.7)
	hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar_bg.name = "HPBarBg"
	add_child(hp_bar_bg)
	
	# HP Bar
	hp_bar = ColorRect.new()
	hp_bar.size = Vector2(28, 4)
	hp_bar.position = Vector2(-14, -24)
	hp_bar.color = Color(0.2, 0.8, 0.2, 0.9)
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar.name = "HPBar"
	add_child(hp_bar)
	
	# Selection ring
	selection_ring = ColorRect.new()
	selection_ring.size = Vector2(34, 34)
	selection_ring.position = Vector2(-17, -19)
	selection_ring.color = Color(0, 0, 0, 0)
	selection_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_ring.name = "SelectionRing"
	add_child(selection_ring)
	
	# Collision area
	collision_area = Area2D.new()
	collision_area.name = "CollisionArea"
	col_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(34, 34)
	col_shape.shape = shape
	collision_area.add_child(col_shape)
	collision_area.input_event.connect(_on_input)
	add_child(collision_area)

func setup(name_val, type_val, team_val, color_val, w, h):
	unit_name = name_val; unit_type = type_val; team = team_val
	
	var c = color_val if team == "player" else Color(color_val.r * 0.5, color_val.g * 0.2, color_val.b * 0.2)
	original_body_color = c
	body.color = c
	head.color = c * 0.85
	head.color.a = 1.0
	
	# Class-specific visuals
	match unit_type:
		"hero":
			weapon.color = Color(1, 0.8, 0)
			weapon.size = Vector2(16, 5)
			head.color = c * 0.9
		"warrior":
			weapon.color = Color(0.6, 0.6, 0.7)
			body.size = Vector2(22, 20)
		"archer":
			weapon.color = Color(0.5, 0.3, 0.1)
			weapon.size = Vector2(16, 3)
			body.size = Vector2(16, 16)
		"cavalry":
			weapon.color = Color(0.7, 0.7, 0.8)
			body.size = Vector2(24, 18)
	
	if team == "enemy":
		head.color = Color(0.6, 0.15, 0.15)
		weapon.color = Color(0.5, 0.1, 0.1)
	
	_update_hp_positions()
	_update_collision()

func _update_hp_positions():
	hp_bar.position.y = -body.size.y / 2 - 10
	hp_bar.size.x = 28
	hp_bar_bg.position.y = -body.size.y / 2 - 10
	hp_bar_bg.size.x = 28

func _update_collision():
	var s = max(body.size.x, 34)
	col_shape.shape.size = Vector2(s, s + 10)
	selection_ring.size = Vector2(s + 6, s + 10)

func _process(delta):
	if not alive: return
	
	# Idle bob
	if not moving:
		idle_bob += delta * 2.5
		position.y = base_y + sin(idle_bob) * 1.2
		legs[0].position.x = -5 + sin(idle_bob * 2) * 1
		legs[1].position.x = 5 + cos(idle_bob * 2) * 1
	else:
		idle_bob += delta * 6
		# Walking animation
		legs[0].position.y = 4 + sin(idle_bob) * 2
		legs[1].position.y = 4 + cos(idle_bob) * 2
	
	# Attack animation
	if attack_anim > 0:
		attack_anim -= delta * 5
		var pct = attack_anim
		weapon.position.x = 10 + sin(pct * 10) * 6
		weapon.rotation = sin(pct * 10) * 0.5
		scale = original_scale * (1.0 + pct * 0.15)
	else:
		weapon.position.x = 10
		weapon.rotation = 0
		scale = original_scale
	
	# Flash recovery
	if flash_timer > 0:
		flash_timer -= delta
	
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
			_update_facing()

func _update_facing():
	var s = 1 if facing_right else -1
	body.scale.x = s
	head.scale.x = s
	weapon.scale.x = s
	weapon.position.x = 10 if s > 0 else -22

func _on_input(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if team == "player":
			emit_signal("unit_clicked", self)
			get_viewport().set_input_as_handled()

func select():
	selected = true
	selection_ring.color = Color(1, 1, 0, 0.25)
	create_tween().tween_property(selection_ring, "color:a", 0.1, 0.5).set_loops()

func deselect():
	selected = false
	selection_ring.color = Color(0, 0, 0, 0)

func move_to(pos):
	if not alive or team != "player": return
	target_pos = pos; moving = true

func take_damage(dmg, crit = false):
	if not alive: return
	hp -= dmg
	
	body.color = Color(1, 0.4, 0.4)
	head.color = Color(1, 0.3, 0.3)
	attack_anim = 0.4
	flash_timer = 0.15
	
	_update_hp_bar()
	
	if crit:
		selection_ring.color = Color(1, 0.5, 0, 0.8)
		await get_tree().create_timer(0.12).timeout
		selection_ring.color = Color(1, 1, 0, 0.25) if selected else Color(0, 0, 0, 0)
	
	await get_tree().create_timer(0.12).timeout
	if alive:
		body.color = original_body_color
		head.color = original_body_color * 0.85
		head.color.a = 1.0
	
	if hp <= 0: die()

func _update_hp_bar():
	var pct = float(max(0, hp)) / max_hp
	hp_bar.size.x = 28 * pct
	if pct > 0.5: hp_bar.color = Color(0.2, 0.85, 0.2, 0.9)
	elif pct > 0.25: hp_bar.color = Color(0.85, 0.75, 0.1, 0.9)
	else: hp_bar.color = Color(0.85, 0.15, 0.1, 0.9)

func heal(amount):
	if not alive: return
	hp = min(max_hp, hp + amount)
	_update_hp_bar()
	body.color = Color(0.3, 1, 0.3)
	head.color = Color(0.3, 1, 0.3)
	attack_anim = 0.2
	await get_tree().create_timer(0.2).timeout
	if alive:
		body.color = original_body_color
		head.color = original_body_color * 0.85

func die():
	alive = false
	# Death particles from body
	for i in range(8):
		var p = ColorRect.new()
		p.size = Vector2(4, 4)
		p.color = original_body_color
		p.position = Vector2(randf() * 20 - 10, randf() * 20 - 10) + position
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		get_parent().add_child(p)
		var t = create_tween(); t.set_parallel(true)
		t.tween_property(p, "position", position + Vector2(randf() * 60 - 30, -randf() * 50 - 10), 0.5)
		t.tween_property(p, "modulate:a", 0.0, 0.5)
		t.tween_callback(p.queue_free)
	
	hp_bar.visible = false; hp_bar_bg.visible = false
	body.visible = false; head.visible = false; weapon.visible = false
	for l in legs: l.visible = false
	shadow.visible = false
	selection_ring.visible = false
	
	create_tween().tween_property(self, "modulate", Color(1, 1, 1, 0), 0.4)
	create_tween().tween_callback(queue_free)

func _update_appearance():
	pass
