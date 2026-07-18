extends Node2D

# High-quality procedural entity renderer
# Creates detailed characters with gradients, shadows, and armor

var entity_type = "villager"
var entity_team = "player"
var entity_color = Color(0.6, 0.4, 0.3)
var hp = 100
var max_hp = 100
var selected = false
var is_moving = false
var anim_time = 0.0
var is_hero = false
var hp_pct_text = "100%"

func _ready():
	queue_redraw()

func _draw():
	var cx = 0; var cy = 0
	var colors = _get_palette(entity_type, entity_color)
	
	# Shadow
	draw_ellipse(Vector2(cx, cy + 14), Vector2(10, 3), Color(0, 0, 0, 0.2))
	
	var bob = sin(anim_time * 8) * 1.5 if is_moving else sin(anim_time * 2) * 0.5
	
	# Legs
	var leg_color = colors["body"] * 0.6; leg_color.a = 1
	_draw_rounded_rect(Vector2(cx - 5, cy + 4 + bob), Vector2(4, 8), leg_color)
	_draw_rounded_rect(Vector2(cx + 1, cy + 4 + bob), Vector2(4, 8), leg_color)
	
	# Body
	var body_col = colors["body"]; body_col.a = 1
	_draw_rounded_rect(Vector2(cx - 8, cy - 7 + bob), Vector2(16, 14), body_col)
	
	# Armor/chest detail
	var armor_col = colors.get("armor", Color(0.7, 0.7, 0.6, 0.5))
	_draw_rounded_rect(Vector2(cx - 5, cy - 3 + bob), Vector2(10, 7), armor_col)
	
	# Hero glow
	if is_hero:
		var glow = Color(1, 0.9, 0.3, 0.08 + sin(anim_time * 2) * 0.04)
		_draw_rounded_rect(Vector2(cx - 10, cy - 9 + bob), Vector2(20, 18), glow)
	
	# Head
	var head_col = colors["head"]; head_col.a = 1
	draw_circle(Vector2(cx, cy - 11 + bob), 6, head_col)
	
	# Eyes
	var eye_col = Color(0, 0, 0, 0.8)
	draw_circle(Vector2(cx - 2, cy - 12 + bob), 1.2, eye_col)
	draw_circle(Vector2(cx + 2, cy - 12 + bob), 1.2, eye_col)
	
	# Helmet/headband
	var band = colors.get("band", Color(0.7, 0.15, 0.15, 0.5))
	_draw_rounded_rect(Vector2(cx - 5, cy - 15 + bob), Vector2(10, 2.5), band)
	
	# Class-specific weapon
	match entity_type:
		"warrior", "hero":
			var wpn = Color(0.7, 0.7, 0.8, 1)
			var swing = sin(anim_time * 10) * 3 if is_moving else 0
			_draw_rounded_rect(Vector2(cx + 8, cy - 2 + swing + bob), Vector2(8, 3), wpn)
		"archer":
			var bow = Color(0.5, 0.3, 0.1, 1)
			_draw_rounded_rect(Vector2(cx + 8, cy - 3 + bob), Vector2(10, 2), bow)
		"cavalry":
			var spear = Color(0.6, 0.6, 0.7, 1)
			_draw_rounded_rect(Vector2(cx + 8, cy - 1 + bob), Vector2(12, 2.5), spear)
			# Horse body (larger)
			_draw_rounded_rect(Vector2(cx - 4, cy + 1 + bob), Vector2(20, 12), body_col * 0.8)
		"villager":
			var tool = Color(0.5, 0.4, 0.2, 1)
			_draw_rounded_rect(Vector2(cx + 8, cy + 2 + bob), Vector2(6, 3), tool)
	
	# HP Bar
	var hp_pct = float(hp) / max(1, max_hp)
	var bar_w = 24.0; var bar_h = 3.0
	var bar_x = cx - bar_w / 2; var bar_y = cy - 19 + bob
	
	# BG
	var bg_col = Color(0.15, 0.04, 0.04, 0.6)
	_draw_rounded_rect(Vector2(bar_x, bar_y), Vector2(bar_w, bar_h), bg_col)
	
	# Fill
	var fill_col = Color(0.2, 0.85, 0.2, 0.9)
	if hp_pct < 0.5: fill_col = Color(0.85, 0.75, 0.1, 0.9)
	if hp_pct < 0.25: fill_col = Color(0.85, 0.15, 0.1, 0.9)
	_draw_rounded_rect(Vector2(bar_x, bar_y), Vector2(bar_w * hp_pct, bar_h), fill_col)
	
	# Selection glow
	if selected:
		var pulse = 0.12 + sin(anim_time * 3) * 0.08
		_draw_rounded_rect(Vector2(cx - 13, cy - 15 + bob), Vector2(26, 30), Color(1, 1, 0, pulse))

func draw_ellipse(pos, size, color):
	var steps = 16; var pts = []
	for i in range(steps):
		var a = i * 2 * PI / steps
		pts.append(pos + Vector2(cos(a) * size.x, sin(a) * size.y))
	draw_colored_polygon(pts, color)

func _draw_rounded_rect(pos, size, color):
	draw_rect(Rect2(pos, size), color)

func _get_palette(type, color):
	var base = {}
	base["body"] = color
	base["head"] = color * 0.85
	base["armor"] = Color(0.7, 0.7, 0.6, 0.3)
	base["band"] = Color(0.7, 0.15, 0.15, 0.4)
	return base

func update_visuals():
	queue_redraw()
