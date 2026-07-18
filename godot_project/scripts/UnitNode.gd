extends Node2D

signal unit_clicked(unit)

var unit_name = ""
var unit_type = ""
var team = "player"
var unit_class = "infantry"
var hp = 100
var max_hp = 100
var attack = 10
var defense = 5
var attack_speed = 1.0
var attack_range = 40.0
var is_hero = false

var alive = true
var selected = false
var moving = false
var target_pos = Vector2()
var cooldown_timer = 0.0
var move_speed = 100.0
var flash_timer = 0.0
var idle_bob = 0.0
var base_y = 0.0
var attack_anim = 0.0
var original_scale = Vector2(1, 1)
var original_body_color = Color.WHITE

@onready var body = $Body
@onready var outline = $Outline
@onready var hp_bar = $HPBar
@onready var hp_bar_bg = $HPBarBg
@onready var class_icon = $ClassIcon
@onready var area = $CollisionArea

func _ready():
	area.input_event.connect(_on_input)
	_update_appearance()
	base_y = position.y
	original_scale = scale

func setup(name_val, type_val, team_val, color_val, w, h):
	unit_name = name_val
	unit_type = type_val
	team = team_val
	
	body.size = Vector2(w, h)
	body.position = Vector2(-w/2, -h/2)
	var col = color_val if team == "player" else Color(color_val.r * 0.5, color_val.g * 0.2, color_val.b * 0.2)
	body.color = col
	original_body_color = col
	
	# Shadow
	if not has_node("Shadow"):
		var shadow = ColorRect.new()
		shadow.name = "Shadow"
		shadow.size = Vector2(w * 0.7, h * 0.2)
		shadow.position = Vector2(-w * 0.35, 1)
		shadow.color = Color(0, 0, 0, 0.3)
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shadow)
		move_child(shadow, 0)
	
	var shape = RectangleShape2D.new()
	shape.size = Vector2(w + 6, h + 6)
	$CollisionArea/CollisionShape.shape = shape
	
	outline.size = Vector2(w + 6, h + 6)
	outline.position = Vector2(-(w+6)/2, -(h+6)/2)
	
	hp_bar.size.x = w
	hp_bar.position.x = -w/2
	hp_bar.position.y = -h/2 - 6
	hp_bar_bg.size.x = w
	hp_bar_bg.position.x = -w/2
	hp_bar_bg.position.y = -h/2 - 6
	
	var icons = {"infantry": "🛡", "archer": "🏹", "cavalry": "🐎", "hero": "⚔"}
	class_icon.text = icons.get(unit_class, "")
	if team == "enemy":
		class_icon.text = "⚔"
	class_icon.position = Vector2(-8, -6)

func _process(delta):
	if not alive: return
	
	# Idle bob when not moving
	if not moving:
		idle_bob += delta * 2.0
		position.y = base_y + sin(idle_bob) * 1.5
	else:
		idle_bob = 0
	
	# Attack animation
	if attack_anim > 0:
		attack_anim -= delta * 4
		scale = original_scale * (1.0 + attack_anim * 0.2)
	else:
		scale = original_scale
	
	# Movement
	if moving:
		var dir = target_pos - global_position
		var dist = dir.length()
		if dist < 8:
			moving = false
		else:
			dir = dir.normalized()
			global_position += dir * move_speed * delta
			# Tilt in movement direction
			rotation = lerp(rotation, dir.x * 0.1, delta * 5)
	else:
		rotation = lerp(rotation, 0.0, delta * 3)

func _on_input(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if team == "player":
			emit_signal("unit_clicked", self)
			get_viewport().set_input_as_handled()

func select():
	selected = true
	outline.color = Color(1, 1, 0, 0.6)
	var tween = create_tween()
	tween.tween_property(outline, "color:a", 0.3, 0.5).set_loops()

func deselect():
	selected = false
	outline.color = Color(0, 0, 0, 0)

func move_to(pos):
	if not alive or team != "player": return
	target_pos = pos
	moving = true

func take_damage(dmg, crit = false):
	if not alive: return
	hp -= dmg
	
	body.color = Color(1, 0.3, 0.3)
	flash_timer = 0.15
	
	# Scale punch on hit
	attack_anim = 0.5
	
	var pct = float(max(0, hp)) / max_hp
	hp_bar.size.x = body.size.x * pct
	if pct > 0.5:
		hp_bar.color = Color(0.2, 0.9, 0.2, 0.9)
	elif pct > 0.25:
		hp_bar.color = Color(0.9, 0.8, 0.1, 0.9)
	else:
		hp_bar.color = Color(0.9, 0.2, 0.1, 0.9)
	
	if crit:
		outline.color = Color(1, 0.5, 0, 0.9)
		await get_tree().create_timer(0.15).timeout
		outline.color = Color(1, 1, 0, 0.6) if selected else Color(0, 0, 0, 0)
	
	# Recover color
	await get_tree().create_timer(0.15).timeout
	if alive:
		body.color = get_original_color()
	
	if hp <= 0: die()

func get_original_color():
	return original_body_color

func heal(amount):
	if not alive: return
	hp = min(max_hp, hp + amount)
	var pct = float(hp) / max_hp
	hp_bar.size.x = body.size.x * pct
	body.color = Color(0.3, 1, 0.3)
	attack_anim = 0.3
	await get_tree().create_timer(0.2).timeout
	if alive: body.color = Color(1, 1, 1)

func die():
	alive = false
	
	# Death particles (simple)
	for i in range(6):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = body.color
		particle.position = Vector2(randf() * 20 - 10, randf() * 20 - 10)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(particle)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", Vector2(randf() * 60 - 30, -randf() * 40 - 10), 0.5)
		tween.tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particle.queue_free)
	
	hp_bar.visible = false
	hp_bar_bg.visible = false
	body.visible = false
	class_icon.visible = false
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.4)
	tween.tween_callback(queue_free)

func _update_appearance():
	pass
