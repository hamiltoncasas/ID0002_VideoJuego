extends Control

func _ready():
	# Animated background
	var anim_timer = 0.0
	var bg_panels = []
	for i in 3:
		var p = ColorRect.new()
		p.size = Vector2(1280, 720)
		p.color = Color(0.04 + i * 0.02, 0.02, 0.06 + i * 0.02, 1)
		add_child(p)
		bg_panels.append(p)
	
	# Decorative top bar
	var top = ColorRect.new()
	top.size = Vector2(1280, 6)
	top.color = Color(0.8, 0.5, 0.1, 0.6)
	add_child(top)
	
	# Title with glow effect
	var title = Label.new()
	title.text = "LEGADO MUISCA"
	title.add_theme_font_size_override("font_size", 52)
	title.position = Vector2(140, 80)
	title.size = Vector2(1000, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1, 0.85, 0.3)
	add_child(title)
	
	# Subtitle
	var sub = Label.new()
	sub.text = "⚔  ESTRATEGIA Y MAGIA EN LA ERA MUISCA  ⚔"
	sub.add_theme_font_size_override("font_size", 14)
	sub.position = Vector2(240, 155)
	sub.size = Vector2(800, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(0.7, 0.6, 0.4, 0.7)
	add_child(sub)
	
	# Decorative line
	var line = ColorRect.new()
	line.size = Vector2(600, 1)
	line.position = Vector2(340, 175)
	line.color = Color(1, 0.7, 0.1, 0.15)
	add_child(line)
	
	# Login panel
	var panel = ColorRect.new()
	panel.size = Vector2(380, 200)
	panel.position = Vector2(450, 240)
	panel.color = Color(0.08, 0.05, 0.15, 0.85)
	add_child(panel)
	
	var border = ColorRect.new()
	border.size = Vector2(384, 204)
	border.position = Vector2(448, 238)
	border.color = Color(0.5, 0.3, 0.1, 0.3)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)
	
	var pl = Label.new()
	pl.text = "NOMBRE DEL ARQUEOLOGO"
	pl.add_theme_font_size_override("font_size", 11)
	pl.position = Vector2(470, 270)
	pl.size = Vector2(340, 20)
	pl.modulate = Color(0.7, 0.7, 0.8)
	add_child(pl)
	
	var input = LineEdit.new()
	input.name = "NameInput"
	input.placeholder_text = "Ingresa tu nombre..."
	input.position = Vector2(490, 300)
	input.size = Vector2(300, 35)
	input.add_theme_color_override("font_color", Color.WHITE)
	input.add_theme_color_override("background_color", Color(0.15, 0.1, 0.2, 0.8))
	add_child(input)
	
	var btn = Button.new()
	btn.name = "EnterBtn"
	btn.text = "COMENZAR AVENTURA"
	btn.position = Vector2(510, 360)
	btn.size = Vector2(260, 45)
	btn.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	btn.add_theme_color_override("button_normal", Color(0.2, 0.4, 0.2, 0.8))
	btn.add_theme_color_override("button_hover", Color(0.3, 0.5, 0.3, 0.9))
	add_child(btn)
	btn.pressed.connect(_on_enter)
	
	input.text_submitted.connect(func(t): _on_enter())
	
	# Decorative elements
	var deco_items = ["🌿", "🌱", "🌾", "🍃", "🪨", "🌻"]
	for i in 15:
		var d = Label.new()
		d.text = deco_items[i % deco_items.size()]
		d.add_theme_font_size_override("font_size", 12 + (i % 3) * 6)
		d.position = Vector2(50 + randi() % 1180, 450 + randi() % 250)
		d.modulate = Color(1, 1, 1, 0.06 + randf() * 0.06)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(d)
	
	# Version text
	var ver = Label.new()
	ver.text = "v0.1 - Godot Engine 4.3"
	ver.add_theme_font_size_override("font_size", 8)
	ver.position = Vector2(1100, 700)
	ver.size = Vector2(150, 15)
	ver.modulate = Color(0.4, 0.4, 0.4)
	add_child(ver)

func _on_enter():
	var input = $NameInput
	var name_text = input.text.strip_edges()
	if name_text == "":
		name_text = "Arqueologo"
	Globals.player_name = name_text
	Globals.logged_in = true
	get_tree().change_scene_to_file("res://scenes/ModeSelect.tscn")
