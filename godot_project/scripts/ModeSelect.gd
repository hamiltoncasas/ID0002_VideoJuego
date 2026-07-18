extends Control

func _ready():
	# Background gradient (simulated with multiple rects)
	for i in 4:
		var r = ColorRect.new()
		r.size = Vector2(1280, 720)
		r.color = Color(0.04 + i * 0.015, 0.02, 0.06 + i * 0.01, 0.3)
		add_child(r)
	
	# Decorative top bar
	var bar = ColorRect.new()
	bar.size = Vector2(1280, 4); bar.color = Color(1, 0.7, 0.1, 0.4)
	add_child(bar)
	
	# Title
	var title = Label.new()
	title.text = "SELECCIONA MODO DE JUEGO"
	title.add_theme_font_size_override("font_size", 28)
	title.position = Vector2(140, 40)
	title.size = Vector2(1000, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1, 0.85, 0.3)
	add_child(title)
	
	# Player info
	var pinfo = Label.new()
	pinfo.text = "🏛 Arqueologo: " + Globals.player_name
	pinfo.add_theme_font_size_override("font_size", 13)
	pinfo.position = Vector2(140, 85)
	pinfo.size = Vector2(1000, 25)
	pinfo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pinfo.modulate = Color(0.6, 0.6, 0.8)
	add_child(pinfo)
	
	# Mode cards
	_create_card(Vector2(100, 140), 320, 280, "🏰 MODO OFFLINE",
		"Aventura individual\nMapa completo 4000x4000\nRecursos, construccion\nIA de unidades",
		Color(0.2, 0.5, 0.2, 0.8), "_on_offline")
	
	_create_card(Vector2(480, 140), 320, 280, "⚔ ONLINE 1v1",
		"Disponible en el futuro\nCombate contra otro\njugador en tiempo real",
		Color(0.5, 0.2, 0.2, 0.8), "_on_online1v1")
	
	_create_card(Vector2(860, 140), 320, 280, "🔥 ONLINE 3v3",
		"Disponible en el futuro\nBatallas por equipos\nEstrategia cooperativa",
		Color(0.5, 0.2, 0.5, 0.8), "_on_online3v3")
	
	# Saved games section
	var sl = Label.new()
	sl.text = "📂 PARTIDAS GUARDADAS"
	sl.add_theme_font_size_override("font_size", 14)
	sl.position = Vector2(80, 460)
	sl.size = Vector2(400, 25)
	sl.modulate = Color(0.7, 0.7, 0.5)
	add_child(sl)
	
	for i in range(5):
		var slot = ColorRect.new()
		slot.size = Vector2(220, 65)
		slot.position = Vector2(80 + i * 230, 490)
		slot.color = Color(0.08, 0.05, 0.12, 0.85)
		add_child(slot)
		
		var sborder = ColorRect.new()
		sborder.size = Vector2(224, 69)
		sborder.position = Vector2(78 + i * 230, 488)
		sborder.color = Color(0.3, 0.2, 0.1, 0.2)
		sborder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sborder)
		
		var slbl = Label.new()
		slbl.text = "Slot " + str(i + 1) + "\n(Vacio)"
		slbl.add_theme_font_size_override("font_size", 10)
		slbl.position = Vector2(88 + i * 230, 497)
		slbl.size = Vector2(200, 50)
		add_child(slbl)
		
		# Check for save data
		if FileAccess.file_exists("user://save_" + str(i) + ".json"):
			var data = JSON.parse_string(FileAccess.get_file_as_string("user://save_" + str(i) + ".json"))
			if data and data.has("timestamp"):
				slbl.text = "Slot " + str(i + 1) + "\n" + str(data["timestamp"])

func _create_card(pos, w, h, title, desc, color, callback):
	var card = ColorRect.new()
	card.size = Vector2(w, h)
	card.position = pos
	card.color = Color(0.1, 0.07, 0.16, 0.9)
	add_child(card)
	
	# Top accent bar
	var bar = ColorRect.new()
	bar.size = Vector2(w, 5)
	bar.color = color
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(bar)
	
	# Title
	var tl = Label.new()
	tl.text = title
	tl.add_theme_font_size_override("font_size", 20)
	tl.position = Vector2(20, 20)
	tl.size = Vector2(w - 40, 35)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(tl)
	
	# Description
	var dl = Label.new()
	dl.text = desc
	dl.add_theme_font_size_override("font_size", 12)
	dl.position = Vector2(25, 65)
	dl.size = Vector2(w - 50, 100)
	dl.modulate = Color(0.7, 0.7, 0.7)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(dl)
	
	# Play button
	var btn = Button.new()
	btn.text = "▶ JUGAR"
	btn.position = Vector2(w/2 - 70, 200)
	btn.size = Vector2(140, 45)
	btn.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	btn.add_theme_color_override("button_normal", Color(0.2, 0.4, 0.2, 0.8))
	btn.add_theme_color_override("button_hover", Color(0.3, 0.5, 0.3, 0.9))
	card.add_child(btn)
	btn.pressed.connect(Callable(self, callback))

func _on_offline():
	Globals.game_mode = "offline"
	get_tree().change_scene_to_file("res://scenes/HeroSelect.tscn")

func _on_online1v1(): _show_coming_soon()
func _on_online3v3(): _show_coming_soon()

func _show_coming_soon():
	var overlay = ColorRect.new()
	overlay.name = "Popup"
	overlay.size = Vector2(1280, 720)
	overlay.color = Color(0, 0, 0, 0.75)
	add_child(overlay)
	
	var msg = Label.new()
	msg.text = "🔧 MODO DISPONIBLE EN EL FUTURO\n\nEstamos trabajando en esta funcionalidad.\nVuelve pronto, Arqueologo."
	msg.add_theme_font_size_override("font_size", 18)
	msg.position = Vector2(340, 250)
	msg.size = Vector2(600, 150)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg.modulate = Color(1, 0.8, 0.3)
	overlay.add_child(msg)
	
	var close = Button.new()
	close.text = "CERRAR"
	close.position = Vector2(540, 420)
	close.size = Vector2(200, 40)
	close.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	overlay.add_child(close)
	close.pressed.connect(func(): overlay.queue_free())
