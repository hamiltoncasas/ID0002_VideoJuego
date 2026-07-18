extends Control

var _slot_labels = []

func _ready():
	# Background
	var bg = ColorRect.new()
	bg.size = Vector2(1280, 720)
	bg.color = Color(0.06, 0.03, 0.1, 1)
	add_child(bg)
	
	# Title
	var title = Label.new()
	title.text = "SELECCIONA MODO DE JUEGO"
	title.add_theme_font_size_override("font_size", 24)
	title.position = Vector2(140, 40)
	title.size = Vector2(1000, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1, 0.85, 0.3)
	add_child(title)
	
	# Player name
	var pnl = Label.new()
	pnl.text = "Arqueologo: " + Globals.player_name
	pnl.add_theme_font_size_override("font_size", 14)
	pnl.position = Vector2(140, 90)
	pnl.size = Vector2(1000, 25)
	pnl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pnl.modulate = Color(0.6, 0.6, 0.8)
	add_child(pnl)
	
	# Mode cards
	_create_card(Vector2(80, 150), "🏰 OFFLINE", "Aventura individual\nMapa completo con recursos\nConstruye y conquista", Color(0.2, 0.5, 0.2), "_on_offline")
	_create_card(Vector2(460, 150), "⚔️ ONLINE 1v1", "Disponible en el futuro\nCombate contra otro jugador", Color(0.5, 0.2, 0.2), "_on_online1v1")
	_create_card(Vector2(840, 150), "🔥 ONLINE 3v3", "Disponible en el futuro\nBatalla por equipos", Color(0.5, 0.2, 0.5), "_on_online3v3")
	
	# Save slots
	var sv = Label.new()
	sv.text = "PARTIDAS GUARDADAS:"
	sv.add_theme_font_size_override("font_size", 14)
	sv.position = Vector2(80, 430)
	sv.size = Vector2(500, 25)
	sv.modulate = Color(0.7, 0.7, 0.5)
	add_child(sv)
	
	for i in range(5):
		var slot = ColorRect.new()
		slot.name = "Slot" + str(i)
		slot.size = Vector2(220, 60)
		slot.position = Vector2(80 + i * 230, 460)
		slot.color = Color(0.1, 0.08, 0.15, 0.8)
		add_child(slot)
		
		var sl = Label.new()
		sl.text = "Slot " + str(i + 1) + "\n(Vacio)"
		sl.add_theme_font_size_override("font_size", 10)
		sl.position = Vector2(5, 5)
		sl.size = Vector2(210, 50)
		slot.add_child(sl)
		_slot_labels.append(sl)
		
		# Load button
		if FileAccess.file_exists("user://save_" + str(i) + ".json"):
			var data = JSON.parse_string(FileAccess.get_file_as_string("user://save_" + str(i) + ".json"))
			if data and data.has("timestamp"):
				sl.text = "Slot " + str(i + 1) + "\n" + str(data["timestamp"])

func _create_card(pos, title, desc, color, callback):
	var card = ColorRect.new()
	card.size = Vector2(340, 250)
	card.position = pos
	card.color = Color(0.12, 0.08, 0.18, 0.9)
	add_child(card)
	
	var bar = ColorRect.new()
	bar.size = Vector2(340, 6); bar.color = color
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE; card.add_child(bar)
	
	var tl = Label.new()
	tl.text = title; tl.add_theme_font_size_override("font_size", 20)
	tl.position = Vector2(20, 20); tl.size = Vector2(300, 35)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; card.add_child(tl)
	
	var dl = Label.new()
	dl.text = desc; dl.add_theme_font_size_override("font_size", 12)
	dl.position = Vector2(30, 70); dl.size = Vector2(280, 90)
	dl.modulate = Color(0.7, 0.7, 0.7); dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(dl)
	
	var btn = Button.new()
	btn.text = "JUGAR"; btn.position = Vector2(100, 180); btn.size = Vector2(140, 40)
	card.add_child(btn)
	btn.pressed.connect(Callable(self, callback))

func _on_offline():
	Globals.game_mode = "offline"
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_online1v1(): _show_coming_soon()
func _on_online3v3(): _show_coming_soon()

func _show_coming_soon():
	var popup = ColorRect.new()
	popup.name = "Popup"; popup.size = Vector2(1280, 720)
	popup.color = Color(0, 0, 0, 0.7)
	add_child(popup)
	
	var msg = Label.new()
	msg.text = "MODO DISPONIBLE EN EL FUTURO\n\nEstamos trabajando en esta funcionalidad."
	msg.add_theme_font_size_override("font_size", 18)
	msg.position = Vector2(340, 250); msg.size = Vector2(600, 150)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; msg.modulate = Color(1, 0.8, 0.3)
	popup.add_child(msg)
	
	var close = Button.new()
	close.text = "CERRAR"; close.position = Vector2(540, 420); close.size = Vector2(200, 40)
	popup.add_child(close)
	close.pressed.connect(func(): popup.queue_free())
