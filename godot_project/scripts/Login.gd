extends Control

func _ready():
	# Background
	var bg = ColorRect.new()
	bg.size = Vector2(1280, 720)
	bg.color = Color(0.06, 0.03, 0.1, 1)
	add_child(bg)
	
	# Panel
	var panel = ColorRect.new()
	panel.size = Vector2(400, 300)
	panel.position = Vector2(440, 200)
	panel.color = Color(0.12, 0.08, 0.2, 0.9)
	add_child(panel)
	
	# Title
	var title = Label.new()
	title.text = "LEGADO MUISCA"
	title.add_theme_font_size_override("font_size", 28)
	title.position = Vector2(440, 130)
	title.size = Vector2(400, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1, 0.85, 0.3)
	add_child(title)
	
	# Name input label
	var nl = Label.new()
	nl.text = "NOMBRE DEL ARQUEOLOGO:"
	nl.add_theme_font_size_override("font_size", 12)
	nl.position = Vector2(460, 230)
	nl.size = Vector2(360, 20)
	nl.modulate = Color(0.7, 0.7, 0.8)
	add_child(nl)
	
	# Name input
	var input = LineEdit.new()
	input.name = "NameInput"
	input.position = Vector2(480, 260)
	input.size = Vector2(320, 30)
	input.placeholder_text = "Ingresa tu nombre..."
	add_child(input)
	
	# Enter button
	var btn = Button.new()
	btn.name = "EnterBtn"
	btn.text = "COMENZAR AVENTURA"
	btn.position = Vector2(520, 320)
	btn.size = Vector2(240, 40)
	add_child(btn)
	btn.pressed.connect(_on_enter)
	
	# Also connect enter key
	input.text_submitted.connect(func(t): _on_enter())

func _on_enter():
	var input = $NameInput
	var name_text = input.text.strip_edges()
	if name_text == "":
		name_text = "Arqueologo"
	Globals.player_name = name_text
	Globals.logged_in = true
	get_tree().change_scene_to_file("res://scenes/ModeSelect.tscn")
