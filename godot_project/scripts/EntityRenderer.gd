extends Node2D

var entity_type = "villager"
var entity_team = "player"
var entity_color = Color(0.6, 0.4, 0.3)
var hp = 100; var max_hp = 100
var selected = false; var is_moving = false
var anim_time = 0.0; var is_hero = false

var _sprite_node: Sprite2D
var _hp_fill: ColorRect
var _hp_bg: ColorRect

func _ready():
	# HP Bar - always created
	_hp_bg = ColorRect.new()
	_hp_bg.size = Vector2(30, 4); _hp_bg.position = Vector2(-15, -28)
	_hp_bg.color = Color(0.1, 0.02, 0.02, 0.6)
	_hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_bg)
	
	_hp_fill = ColorRect.new()
	_hp_fill.size = Vector2(30, 4); _hp_fill.position = Vector2(-15, -28)
	_hp_fill.color = Color(0.2, 0.75, 0.2, 0.9)
	_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_fill)
	
	# Try to load sprite texture
	_load_texture()
	
	# Always redraw for the fallback
	queue_redraw()

func _load_texture():
	var prefix = "enemy_" if entity_team == "enemy" else ""
	var key = prefix + entity_type
	if entity_type == "hero":
		key = "enemy_hero" if entity_team == "enemy" else "hero"
	
	var path = "res://assets/sprites/" + key + ".png"
	var tex = load(path)
	if tex and tex is Texture2D:
		_sprite_node = Sprite2D.new()
		_sprite_node.texture = tex
		_sprite_node.centered = true
		_sprite_node.scale = Vector2(1.5, 1.5)
		add_child(_sprite_node)

func _draw():
	# Always draw fallback (visible behind sprite if loaded)
	var cx = 0; var cy = 0
	var bob = sin(anim_time * 2) * 0.8
	var body_c = entity_color; body_c.a = 1
	
	# Soft shadow
	draw_circle(Vector2(cx, cy + 18), 14, Color(0, 0, 0, 0.1))
	
	# Simple character body
	draw_circle(Vector2(cx, cy + bob), 8, body_c)
	draw_circle(Vector2(cx, cy - 6 + bob), 6, body_c * 0.85)
	
	# Eyes
	draw_circle(Vector2(cx - 2, cy - 7 + bob), 1.5, Color(0, 0, 0, 0.8))
	draw_circle(Vector2(cx + 2, cy - 7 + bob), 1.5, Color(0, 0, 0, 0.8))
	
	# Selection glow
	if selected:
		var pulse = 0.1 + sin(anim_time * 3) * 0.08
		draw_circle(Vector2(cx, cy + bob), 16, Color(1, 1, 0, pulse))

func _process(delta):
	anim_time += delta
	
	# Update HP bar
	var hp_pct = float(hp) / max(1, max_hp)
	if _hp_fill:
		_hp_fill.size.x = 30 * hp_pct
		if hp_pct > 0.5: _hp_fill.color = Color(0.2, 0.75, 0.2, 0.9)
		elif hp_pct > 0.25: _hp_fill.color = Color(0.8, 0.65, 0.1, 0.9)
		else: _hp_fill.color = Color(0.8, 0.15, 0.1, 0.9)
	
	queue_redraw()
