extends Control

const SCREEN_W = 1280
const SCREEN_H = 720

var time = 0.0
var bg_layers = []
var particles = []

func _ready():
	_build_background()
	_build_particles()
	_build_decorations()
	_build_login_ui()

func _build_background():
	for i in 6:
		var r = ColorRect.new()
		r.size = Vector2(SCREEN_W, SCREEN_H)
		var t = i * 0.04
		r.color = Color(0.03 + t, 0.01 + t * 0.3, 0.07 + t * 0.5, 0.5 + i * 0.08)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.name = "BgLayer" + str(i)
		add_child(r)
		bg_layers.append(r)

	var warm_glow = ColorRect.new()
	warm_glow.size = Vector2(SCREEN_W, 220)
	warm_glow.position = Vector2(0, SCREEN_H - 220)
	warm_glow.color = Color(0.35, 0.12, 0.06, 0.12)
	warm_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(warm_glow)

	var top_glow = ColorRect.new()
	top_glow.size = Vector2(SCREEN_W, 160)
	top_glow.position = Vector2(0, 0)
	top_glow.color = Color(0.15, 0.05, 0.25, 0.08)
	top_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_glow)

func _build_particles():
	for i in 35:
		var p = ColorRect.new()
		var sz = 1.5 + randi() % 4
		p.size = Vector2(sz, sz)
		p.position = Vector2(randi() % SCREEN_W, randi() % SCREEN_H)
		var alpha = 0.06 + randf() * 0.3
		var hue = 0.72 + randf() * 0.18
		p.color = Color.from_hsv(hue, 0.55, 0.7, alpha)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.name = "Particle" + str(i)
		add_child(p)
		particles.append({
			rect = p,
			speed = 6 + randf() * 28,
			drift = (randf() - 0.5) * 14,
			phase = randf() * TAU,
			flicker_speed = 1.5 + randf() * 3.0,
			is_sparkle = false
		})

	for i in 10:
		var s = ColorRect.new()
		s.size = Vector2(1, 5 + randi() % 4)
		s.position = Vector2(randi() % SCREEN_W, randi() % 600)
		s.color = Color(1, 0.85, 0.3, 0.04 + randf() * 0.08)
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.name = "Sparkle" + str(i)
		add_child(s)
		particles.append({
			rect = s,
			speed = 4 + randf() * 12,
			drift = (randf() - 0.5) * 6,
			phase = randf() * TAU,
			flicker_speed = 2.0 + randf() * 4.0,
			is_sparkle = true
		})

func _build_decorations():
	var top_bar = ColorRect.new()
	top_bar.name = "TopBar"
	top_bar.size = Vector2(SCREEN_W, 3)
	top_bar.color = Color(0.9, 0.65, 0.1, 0.45)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_bar)

	var bot_bar = ColorRect.new()
	bot_bar.size = Vector2(SCREEN_W, 3)
	bot_bar.position = Vector2(0, SCREEN_H - 3)
	bot_bar.color = Color(0.9, 0.65, 0.1, 0.25)
	bot_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bot_bar)

	for side in [0, 1]:
		var line = ColorRect.new()
		line.size = Vector2(1, SCREEN_H)
		line.position = Vector2(side * (SCREEN_W - 1), 0)
		line.color = Color(0.5, 0.3, 0.1, 0.06)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(line)

	var corners = [Vector2(30, 30), Vector2(SCREEN_W - 90, 30)]
	for c in corners:
		var h = ColorRect.new()
		h.size = Vector2(60, 2)
		h.position = c
		h.color = Color(1, 0.7, 0.1, 0.2)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(h)
		var v = ColorRect.new()
		v.size = Vector2(2, 60)
		v.position = c
		v.color = Color(1, 0.7, 0.1, 0.2)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(v)

func _build_login_ui():
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "LEGADO MUISCA"
	title.add_theme_font_size_override("font_size", 58)
	title.position = Vector2(140, 55)
	title.size = Vector2(1000, 85)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1, 0.85, 0.3)
	add_child(title)

	var glow = ColorRect.new()
	glow.name = "TitleGlow"
	glow.size = Vector2(500, 20)
	glow.position = Vector2(390, 85)
	glow.color = Color(1, 0.7, 0.1, 0.06)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var sub = Label.new()
	sub.text = "ESTRATEGIA Y MAGIA EN LA ERA MUISCA"
	sub.add_theme_font_size_override("font_size", 12)
	sub.position = Vector2(240, 130)
	sub.size = Vector2(800, 25)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(0.7, 0.6, 0.4, 0.55)
	add_child(sub)

	var div = ColorRect.new()
	div.size = Vector2(480, 1)
	div.position = Vector2(400, 150)
	div.color = Color(1, 0.65, 0.1, 0.08)
	add_child(div)

	var outer_frame = ColorRect.new()
	outer_frame.size = Vector2(420, 250)
	outer_frame.position = Vector2(430, 195)
	outer_frame.color = Color(0.5, 0.3, 0.1, 0.12)
	add_child(outer_frame)

	var panel = ColorRect.new()
	panel.size = Vector2(408, 238)
	panel.position = Vector2(436, 201)
	panel.color = Color(0.05, 0.035, 0.1, 0.92)
	add_child(panel)

	var accent = ColorRect.new()
	accent.size = Vector2(408, 3)
	accent.position = Vector2(436, 201)
	accent.color = Color(1, 0.7, 0.1, 0.35)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent)

	var corner_positions = [Vector2(436, 201), Vector2(844, 201), Vector2(436, 439), Vector2(844, 439)]
	for cp in corner_positions:
		var dot = ColorRect.new()
		dot.size = Vector2(4, 4)
		dot.position = cp - Vector2(2, 2)
		dot.color = Color(1, 0.7, 0.1, 0.3)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dot)

	var pl = Label.new()
	pl.text = "NOMBRE DEL ARQUEOLOGO"
	pl.add_theme_font_size_override("font_size", 10)
	pl.position = Vector2(470, 245)
	pl.size = Vector2(340, 16)
	pl.modulate = Color(0.65, 0.65, 0.8)
	add_child(pl)

	var input = LineEdit.new()
	input.name = "NameInput"
	input.placeholder_text = "Ingresa tu nombre..."
	input.position = Vector2(485, 272)
	input.size = Vector2(310, 38)
	input.add_theme_color_override("font_color", Color(1, 0.9, 0.7))
	input.add_theme_color_override("background_color", Color(0.08, 0.05, 0.15, 0.88))
	input.add_theme_color_override("placeholder_color", Color(0.4, 0.35, 0.5, 0.5))
	add_child(input)

	var btn = Button.new()
	btn.name = "EnterBtn"
	btn.text = "COMENZAR AVENTURA"
	btn.position = Vector2(510, 335)
	btn.size = Vector2(260, 48)
	btn.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	btn.add_theme_color_override("button_normal", Color(0.1, 0.07, 0.18, 0.9))
	btn.add_theme_color_override("button_hover", Color(0.16, 0.1, 0.26, 0.95))
	btn.add_theme_color_override("button_pressed", Color(0.08, 0.05, 0.14, 0.95))
	add_child(btn)
	btn.pressed.connect(_on_enter)

	input.text_submitted.connect(func(t): _on_enter())

	var panel_div = ColorRect.new()
	panel_div.size = Vector2(280, 1)
	panel_div.position = Vector2(500, 400)
	panel_div.color = Color(1, 0.65, 0.1, 0.05)
	panel_div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel_div)

	var ver = Label.new()
	ver.text = "v0.1 - Godot Engine 4.3"
	ver.add_theme_font_size_override("font_size", 8)
	ver.position = Vector2(1100, 700)
	ver.size = Vector2(150, 15)
	ver.modulate = Color(0.4, 0.4, 0.4)
	add_child(ver)

func _process(delta):
	time += delta

	for i in range(bg_layers.size()):
		var r = bg_layers[i]
		var t = i * 0.04
		var pulse = sin(time * 0.12 + i * 0.7) * 0.007
		r.color = Color(
			0.03 + t + pulse,
			0.01 + t * 0.3 + pulse * 0.5,
			0.07 + t * 0.5 + pulse * 0.3,
			0.5 + i * 0.08
		)

	for p in particles:
		var rect = p.rect
		var pos = rect.position
		pos.y -= p.speed * delta
		pos.x += sin(time * 0.4 + p.phase) * p.drift * delta
		if pos.y < -10:
			pos.y = SCREEN_H + 5 + randi() % 40
			pos.x = randi() % SCREEN_W
		rect.position = pos

		var flicker = 0.5 + sin(time * p.flicker_speed + p.phase) * 0.5
		var c = rect.color
		rect.color = Color(c.r, c.g, c.b, c.a * (0.3 + flicker * 0.7))

	var glow = get_node_or_null("TitleGlow")
	if glow:
		var gs = 480 + sin(time * 1.3) * 60
		glow.size = Vector2(gs, 20)
		glow.position = Vector2(640 - gs / 2, 85)
		glow.color = Color(1, 0.7, 0.1, 0.05 + sin(time * 1.1) * 0.03)

	var title = get_node_or_null("TitleLabel")
	if title:
		var b = 1.0 + sin(time * 0.7) * 0.012
		title.modulate = Color(1 * b, 0.85 * b, 0.3 * b)

	var top_bar = get_node_or_null("TopBar")
	if top_bar:
		top_bar.color = Color(0.9, 0.65, 0.1, 0.35 + sin(time * 0.6) * 0.15)

func _on_enter():
	var input = $NameInput
	var name_text = input.text.strip_edges()
	if name_text == "":
		name_text = "Arqueologo"
	Globals.player_name = name_text
	Globals.logged_in = true
	get_tree().change_scene_to_file("res://scenes/ModeSelect.tscn")
