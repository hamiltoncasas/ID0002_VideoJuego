extends Node2D

var entity_type = "villager"
var entity_team = "player"
var entity_color = Color(0.6, 0.4, 0.3)
var hp = 100; var max_hp = 100
var selected = false; var is_moving = false
var anim_time = 0.0; var is_hero = false

var hp_pct = 1.0
var body_color = Color(0.6, 0.4, 0.3)

func _ready():
	body_color = entity_color
	queue_redraw()

func _draw():
	var cx = 0; var cy = 0
	var bob = sin(anim_time * 8) * 1.5 if is_moving else sin(anim_time * 2) * 0.6
	var walk = sin(anim_time * 8) if is_moving else 0
	
	# Shadow
	draw_ellipse(Vector2(cx, cy + 16), Vector2(12, 3), Color(0, 0, 0, 0.2))
	
	# Legs
	var lc = body_color * 0.65; lc.a = 1
	var leg_offs = walk * 2
	draw_rect(Rect2(cx - 6, cy + 4 + leg_offs + bob, 5, 10), lc)
	draw_rect(Rect2(cx + 1, cy + 4 - leg_offs + bob, 5, 10), lc)
	
	# Body (gradient effect with multiple rects)
	var bc = body_color; bc.a = 1
	draw_rect(Rect2(cx - 9, cy - 8 + bob, 18, 14), bc)
	
	# Body highlight
	var hl = bc * 1.15; hl.a = 0.3
	draw_rect(Rect2(cx - 7, cy - 7 + bob, 6, 12), hl)
	
	# Armor/chest
	var ac = Color(0.6, 0.5, 0.4, 0.4)
	if entity_type in ["warrior", "hero"]: ac = Color(0.5, 0.5, 0.5, 0.5)
	draw_rect(Rect2(cx - 6, cy - 4 + bob, 12, 8), ac)
	
	# Arms
	var arm_c = body_color * 0.8; arm_c.a = 1
	draw_rect(Rect2(cx - 12, cy - 4 + walk + bob, 4, 3), arm_c)
	draw_rect(Rect2(cx + 8, cy - 4 - walk + bob, 4, 3), arm_c)
	
	# Weapon based on type
	match entity_type:
		"warrior":
			draw_rect(Rect2(cx + 10, cy - 3 + walk + bob, 10, 3), Color(0.7, 0.7, 0.8))
			draw_rect(Rect2(cx + 14, cy - 6 + walk + bob, 3, 3), Color(0.5, 0.3, 0.1))
		"hero":
			draw_rect(Rect2(cx + 10, cy - 2 + walk + bob, 12, 4), Color(1, 0.8, 0.2))
			draw_rect(Rect2(cx + 16, cy - 5 + walk + bob, 3, 3), Color(0.5, 0.3, 0.1))
		"archer":
			draw_rect(Rect2(cx + 9, cy - 2 + bob, 10, 2), Color(0.5, 0.3, 0.1))
			draw_line(Vector2(cx + 9, cy - 2 + bob), Vector2(cx + 9, cy - 8 + bob), Color(0.5, 0.3, 0.1), 1.5)
		"cavalry":
			draw_rect(Rect2(cx - 4, cy + 2 + bob, 22, 12), body_color * 0.85)
			draw_rect(Rect2(cx + 14, cy - 2 + walk + bob, 12, 3), Color(0.6, 0.6, 0.7))
		"villager":
			draw_rect(Rect2(cx + 9, cy + 2 + bob, 7, 3), Color(0.5, 0.4, 0.2))
		"artisan":
			draw_rect(Rect2(cx + 9, cy + 1 + bob, 6, 3), Color(0.7, 0.7, 0.2))
	
	# Head
	var hc = body_color * 0.85; hc.a = 1
	draw_circle(Vector2(cx, cy - 12 + bob), 6.5, hc)
	
	# Eyes
	var ec = Color(0, 0, 0, 0.85)
	draw_circle(Vector2(cx - 2.5, cy - 13 + bob), 1.5, ec)
	draw_circle(Vector2(cx + 2.5, cy - 13 + bob), 1.5, ec)
	
	# Headband/helmet
	var band_color = Color(0.7, 0.15, 0.15, 0.5)
	if is_hero: band_color = Color(1, 0.8, 0, 0.6)
	draw_rect(Rect2(cx - 6, cy - 16.5 + bob, 12, 3), band_color)
	
	# Hero glow
	if is_hero:
		var glow = Color(1, 0.9, 0.3, 0.06 + sin(anim_time * 2) * 0.04)
		draw_rect(Rect2(cx - 11, cy - 10 + bob, 22, 20), glow)
	
	# HP Bar
	hp_pct = float(hp) / max(1, max_hp)
	var bw = 26.0; var bh = 3.5
	var bx = cx - bw / 2; var by = cy - 20 + bob
	
	draw_rect(Rect2(bx, by, bw, bh), Color(0.12, 0.03, 0.03, 0.7))
	
	var fc = Color(0.2, 0.85, 0.2, 0.9)
	if hp_pct < 0.5: fc = Color(0.85, 0.7, 0.1, 0.9)
	if hp_pct < 0.25: fc = Color(0.85, 0.15, 0.1, 0.9)
	draw_rect(Rect2(bx + 1, by + 0.5, (bw - 2) * hp_pct, bh - 1), fc)
	
	# Selection glow
	if selected:
		var pulse = 0.1 + sin(anim_time * 3) * 0.08
		draw_rect(Rect2(cx - 15, cy - 16 + bob, 30, 32), Color(1, 1, 0, pulse))
		
		# Corner marks
		var cm = Color(1, 1, 0, 0.4 + sin(anim_time * 3) * 0.2)
		draw_rect(Rect2(cx - 15, cy - 16 + bob, 5, 2), cm)
		draw_rect(Rect2(cx + 10, cy - 16 + bob, 5, 2), cm)
		draw_rect(Rect2(cx - 15, cy + 14 + bob, 5, 2), cm)
		draw_rect(Rect2(cx + 10, cy + 14 + bob, 5, 2), cm)

func draw_ellipse(pos, size, color):
	var pts = []
	for i in range(12):
		var a = i * 2 * PI / 12
		pts.append(pos + Vector2(cos(a) * size.x, sin(a) * size.y))
	draw_colored_polygon(pts, color)

func update_stats(hp_val, max_hp_val):
	hp = hp_val; max_hp = max_hp_val
	queue_redraw()

func _process(delta):
	anim_time += delta
	queue_redraw()
