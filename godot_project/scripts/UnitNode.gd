extends Node2D

signal unit_clicked(unit)

# Stats
var unit_name = ""
var unit_type = ""  # warrior, archer, cavalry, hero
var team = "player"
var unit_class = "infantry"
var hp = 100
var max_hp = 100
var attack = 10
var defense = 5
var attack_speed = 1.0
var attack_range = 40.0
var is_hero = false

# State
var alive = true
var selected = false
var moving = false
var target_pos = Vector2()
var cooldown_timer = 0.0
var move_speed = 100.0
var flash_timer = 0.0

# References
@onready var body = $Body
@onready var outline = $Outline
@onready var hp_bar = $HPBar
@onready var hp_bar_bg = $HPBarBg
@onready var class_icon = $ClassIcon
@onready var area = $CollisionArea

func _ready():
	area.input_event.connect(_on_input)
	_update_appearance()

func setup(name_val, type_val, team_val, color_val, w, h):
	unit_name = name_val
	unit_type = type_val
	team = team_val
	
	# Set body
	body.size = Vector2(w, h)
	body.position = Vector2(-w/2, -h/2)
	var base_color = color_val if team == "player" else Color(color_val.r * 0.6, color_val.g * 0.3, color_val.b * 0.3)
	body.color = base_color
	
	# Set collision
	var shape = RectangleShape2D.new()
	shape.size = Vector2(w + 4, h + 4)
	$CollisionArea/CollisionShape.shape = shape
	
	# Outline
	outline.size = Vector2(w + 4, h + 4)
	outline.position = Vector2(-(w+4)/2, -(h+4)/2)
	
	# HP bars
	hp_bar.size.x = w
	hp_bar.position.x = -w/2
	hp_bar.position.y = -h/2 - 5
	hp_bar_bg.size.x = w
	hp_bar_bg.position.x = -w/2
	hp_bar_bg.position.y = -h/2 - 5
	
	# Class icon
	var icons = {"infantry": "🛡", "archer": "🏹", "cavalry": "🐎"}
	class_icon.text = icons.get(unit_class, "")
	var icon_pos = Vector2(-8, -6)
	if team == "enemy":
		class_icon.text = "⚔"
	class_icon.position = icon_pos

func _process(delta):
	if not alive:
		return
	
	# Movement
	if moving:
		var dir = target_pos - global_position
		var dist = dir.length()
		if dist < 5:
			moving = false
		else:
			dir = dir.normalized()
			global_position += dir * move_speed * delta
	
	# Flash effect
	if flash_timer > 0:
		flash_timer -= delta
		if flash_timer <= 0:
			body.color = body.color * 1.5
			body.color.a = 1.0

func _on_input(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if team == "player":
			emit_signal("unit_clicked", self)
			get_viewport().set_input_as_handled()

func select():
	selected = true
	outline.color = Color(1, 1, 0, 0.6)

func deselect():
	selected = false
	outline.color = Color(0, 0, 0, 0)

func move_to(pos):
	if not alive or team != "player":
		return
	target_pos = pos
	moving = true

func take_damage(dmg, crit = false):
	if not alive:
		return
	
	hp -= dmg
	
	# Flash red
	body.color = Color(1, 0.3, 0.3)
	flash_timer = 0.15
	
	# Update HP bar
	var pct = float(max(0, hp)) / max_hp
	hp_bar.size.x = body.size.x * pct
	if pct > 0.5:
		hp_bar.color = Color(0, 0.8, 0, 0.8)
	elif pct > 0.25:
		hp_bar.color = Color(0.8, 0.8, 0, 0.8)
	else:
		hp_bar.color = Color(0.8, 0.2, 0, 0.8)
	
	if crit:
		# Extra visual feedback
		outline.color = Color(1, 0.5, 0, 0.8)
		await get_tree().create_timer(0.2).timeout
		outline.color = Color(1, 1, 0, 0.6) if selected else Color(0, 0, 0, 0)
	
	if hp <= 0:
		die()

func heal(amount):
	if not alive:
		return
	hp = min(max_hp, hp + amount)
	var pct = float(hp) / max_hp
	hp_bar.size.x = body.size.x * pct
	body.color = Color(0.3, 1, 0.3)
	flash_timer = 0.2

func die():
	alive = false
	body.color = Color(0.3, 0.1, 0.1, 0.5)
	hp_bar.visible = false
	hp_bar_bg.visible = false
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.6)
	tween.tween_callback(queue_free)

func _update_appearance():
	pass
