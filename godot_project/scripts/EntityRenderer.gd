extends Node2D

var entity_type = "villager"
var entity_team = "player"
var entity_color = Color(0.6, 0.4, 0.3)
var hp = 100; var max_hp = 100
var selected = false; var is_moving = false
var anim_time = 0.0; var is_hero = false

var _body_color = Color(0.6, 0.4, 0.3)

func _ready():
	_body_color = entity_color
	queue_redraw()

func _draw():
	var cx = 0; var cy = 0
	var bob = sin(anim_time * 8) * 1.5 if is_moving else sin(anim_time * 2) * 0.5
	var walk = sin(anim_time * 8) * 2 if is_moving else 0
	var h = _body_color
	
	# ── Shadow ──
	draw_circle(Vector2(cx, cy + 18), 10, Color(0, 0, 0, 0.12))
	
	# ── Legs ──
	var leg = h * 0.7; leg.a = 1
	draw_circle(Vector2(cx - 4 + sin(anim_time * 4) * (2 if is_moving else 0), cy + 12 + bob), 3.5, leg)
	draw_circle(Vector2(cx + 4 + cos(anim_time * 4) * (2 if is_moving else 0), cy + 12 + bob), 3.5, leg)
	
	# ── Body (gradient using stacked circles) ──
	var body_c = h; body_c.a = 1
	# Main body
	draw_circle(Vector2(cx, cy + 2 + bob), 9, body_c)
	draw_circle(Vector2(cx, cy - 3 + bob), 8, body_c)
	
	# Body highlight (top)
	var hl = body_c * 1.2; hl.a = 0.25
	draw_circle(Vector2(cx, cy - 3 + bob), 6, hl)
	
	# ── Armor/chest plate ──
	var ac = Color(0.5, 0.45, 0.4, 0.3)
	if entity_type in ["warrior", "hero"]: ac = Color(0.5, 0.5, 0.5, 0.4)
	draw_rect(Rect2(cx - 6, cy - 2 + bob, 12, 6), ac)
	
	# ── Arms ──
	var arm = h * 0.85; arm.a = 1
	# Left arm
	draw_rect(Rect2(cx - 11, cy - 2 + walk * 0.5 + bob, 4, 3), arm)
	# Right arm (weapon arm)
	draw_rect(Rect2(cx + 7, cy - 2 - walk * 0.5 + bob, 4, 3), arm)
	
	# ── Weapon ──
	match entity_type:
		"warrior": draw_rect(Rect2(cx + 10, cy - 1 + walk * 0.5 + bob, 10, 3), Color(0.7, 0.7, 0.8))
		"hero": draw_rect(Rect2(cx + 10, cy - 1 + walk * 0.5 + bob, 12, 4), Color(1, 0.8, 0.2))
		"archer": draw_line(Vector2(cx + 10, cy - 1 + bob), Vector2(cx + 18, cy - 7 + bob), Color(0.5, 0.3, 0.1), 2)
		"cavalry": 
			draw_circle(Vector2(cx + 6, cy + 4 + bob), 8, h * 0.8)
			draw_rect(Rect2(cx + 14, cy - 1 + walk * 0.5 + bob, 11, 3), Color(0.6, 0.6, 0.7))
		"villager": draw_rect(Rect2(cx + 9, cy + 3 + bob, 7, 3), Color(0.5, 0.4, 0.2))
		"artisan": draw_rect(Rect2(cx + 9, cy + 2 + bob, 6, 3), Color(0.7, 0.7, 0.2))
	
	# ── Head ──
	var head = h * 0.85; head.a = 1
	draw_circle(Vector2(cx, cy - 11 + bob), 7, head)
	# Head highlight
	var head_hl = head * 1.15; head_hl.a = 0.2
	draw_circle(Vector2(cx - 1, cy - 13 + bob), 5, head_hl)
	
	# ── Eyes ──
	var eye_w = Color(0.9, 0.9, 0.9, 0.9)
	var eye_p = Color(0.05, 0.05, 0.2, 0.95)
	# White
	draw_circle(Vector2(cx - 2.5, cy - 12 + bob), 2.5, eye_w)
	draw_circle(Vector2(cx + 2.5, cy - 12 + bob), 2.5, eye_w)
	# Pupil
	draw_circle(Vector2(cx - 2.5, cy - 12 + bob), 1.2, eye_p)
	draw_circle(Vector2(cx + 2.5, cy - 12 + bob), 1.2, eye_p)
	# Catchlight
	var cl = Color(1, 1, 1, 0.8)
	draw_circle(Vector2(cx - 1.8, cy - 12.8 + bob), 0.6, cl)
	draw_circle(Vector2(cx + 3.2, cy - 12.8 + bob), 0.6, cl)
	
	# ── Helmet / headband ──
	var band = Color(0.7, 0.15, 0.15, 0.5)
	if is_hero: band = Color(1, 0.8, 0, 0.6)
	draw_rect(Rect2(cx - 6, cy - 16.5 + bob, 12, 3), band)
	# Helmet top
	if is_hero or entity_type == "warrior":
		draw_rect(Rect2(cx - 4, cy - 19 + bob, 8, 3), Color(0.4, 0.4, 0.4, 0.3))
	
	# ── Hero aura ──
	if is_hero:
		var aura = Color(1, 0.9, 0.3, 0.05 + sin(anim_time * 2) * 0.03)
		draw_circle(Vector2(cx, cy + bob), 18, aura)
	
	# ── HP Bar ──
	var hp_pct = float(hp) / max(1, max_hp)
	var bw = 24.0; var bh = 3.0
	var bx = cx - bw / 2; var by = cy - 21 + bob
	
	# Background
	draw_rect(Rect2(bx, by, bw, bh), Color(0.1, 0.02, 0.02, 0.65))
	# Fill
	var fc = Color(0.2, 0.75, 0.2, 0.9)
	if hp_pct < 0.5: fc = Color(0.8, 0.65, 0.1, 0.9)
	if hp_pct < 0.25: fc = Color(0.8, 0.15, 0.1, 0.9)
	draw_rect(Rect2(bx + 1, by + 0.5, (bw - 2) * hp_pct, bh - 1), fc)
	# HP border
	draw_rect(Rect2(bx, by, bw, bh), Color(0.8, 0.8, 0.8, 0.15), false, 0.5)
	
	# ── Selection glow ──
	if selected:
		var pulse = 0.12 + sin(anim_time * 3) * 0.08
		draw_circle(Vector2(cx, cy + bob), 16, Color(1, 1, 0, pulse))
		# Corner marks
		var cm = Color(1, 1, 0, 0.35 + sin(anim_time * 3) * 0.15)
		var s = 16
		draw_rect(Rect2(cx - s, cy - s + bob, 5, 2), cm)
		draw_rect(Rect2(cx + s - 5, cy - s + bob, 5, 2), cm)
		draw_rect(Rect2(cx - s, cy + s + bob, 5, 2), cm)
		draw_rect(Rect2(cx + s - 5, cy + s + bob, 5, 2), cm)

func _process(delta):
	anim_time += delta
	queue_redraw()
