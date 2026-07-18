extends Node2D

var entity_type = "villager"
var entity_team = "player"
var entity_color = Color(0.6, 0.4, 0.3)
var hp = 100; var max_hp = 100
var selected = false; var is_moving = false
var anim_time = 0.0; var is_hero = false
var _sprite_loaded = false

static var _tex_cache = {}

func _ready():
	_try_load_sprite()

func _try_load_sprite():
	var prefix = "enemy_" if entity_team == "enemy" else ""
	var key = prefix + entity_type
	if entity_type == "hero":
		key = "enemy_hero" if entity_team == "enemy" else "hero"
	
	var path = "res://assets/sprites/" + key + ".png"
	
	var tex = null
	if _tex_cache.has(path):
		tex = _tex_cache[path]
	else:
		if ResourceLoader.exists(path):
			tex = load(path)
		if tex:
			_tex_cache[path] = tex
	
	if tex:
		var spr = Sprite2D.new()
		spr.texture = tex; spr.centered = true
		spr.scale = Vector2(2, 2)
		add_child(spr)
		_sprite_loaded = true
	
	# HP Bar BG
	var hb = ColorRect.new()
	hb.name = "hp_bg"
	hb.size = Vector2(30, 4); hb.position = Vector2(-15, -30)
	hb.color = Color(0.1, 0.02, 0.02, 0.65)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(hb)
	
	var hf = ColorRect.new()
	hf.name = "hp_fill"
	hf.size = Vector2(30, 4); hf.position = Vector2(-15, -30)
	hf.color = Color(0.2, 0.75, 0.2, 0.9)
	hf.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(hf)

func _draw():
	if _sprite_loaded: return  # Skip draw if sprite loaded
	
	# Fallback procedural character
	var cx = 0; var cy = 0
	var bob = sin(anim_time * 2) * 0.5
	var body_c = entity_color; body_c.a = 1
	
	# Shadow
	draw_ellipse(Vector2(cx, cy + 16), Vector2(10, 3), Color(0, 0, 0, 0.15))
	
	# Body
	draw_rect(Rect2(cx - 8, cy - 6 + bob, 16, 14), body_c)
	draw_rect(Rect2(cx - 6, cy - 4 + bob, 12, 8), Color(0.5, 0.45, 0.4, 0.3))
	
	# Head
	draw_circle(Vector2(cx, cy - 10 + bob), 6, body_c * 0.85)
	# Eyes
	draw_circle(Vector2(cx - 2, cy - 11 + bob), 1.5, Color(0, 0, 0, 0.8))
	draw_circle(Vector2(cx + 2, cy - 11 + bob), 1.5, Color(0, 0, 0, 0.8))
	
	# Selection glow
	if selected:
		var pulse = 0.1 + sin(anim_time * 3) * 0.08
		draw_rect(Rect2(cx - 14, cy - 14 + bob, 28, 28), Color(1, 1, 0, pulse))

func draw_ellipse(pos, size, color):
	var pts = []
	for i in range(12):
		var a = i * 2 * PI / 12
		pts.append(pos + Vector2(cos(a) * size.x, sin(a) * size.y))
	draw_colored_polygon(pts, color)

func _process(delta):
	anim_time += delta
	
	# HP bar
	var hp_pct = float(hp) / max(1, max_hp)
	var hf = get_node_or_null("hp_fill")
	if hf:
		hf.size.x = 30 * hp_pct
		if hp_pct > 0.5: hf.color = Color(0.2, 0.75, 0.2, 0.9)
		elif hp_pct > 0.25: hf.color = Color(0.8, 0.65, 0.1, 0.9)
		else: hf.color = Color(0.8, 0.15, 0.1, 0.9)
	
	queue_redraw()
