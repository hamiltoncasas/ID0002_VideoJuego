extends Control

func _ready():
	# Background
	var bg = ColorRect.new()
	bg.name = "Bg"
	bg.size = Vector2(1280, 720)
	bg.color = Color(0.06, 0.03, 0.1, 1)
	add_child(bg)
	
	var title = Label.new()
	title.text = "SELECCIONA TU HEROE"
	title.add_theme_font_size_override("font_size", 28)
	title.position = Vector2(200, 30); title.size = Vector2(880, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1, 0.85, 0.3)
	add_child(title)
	
	var heroes = Globals.heroes
	var cw = 220; var ch = 340; var gap = 20
	var tw = heroes.size() * cw + (heroes.size() - 1) * gap
	var sx = (1280 - tw) / 2
	
	for i in range(heroes.size()):
		var h = heroes[i]
		var card = ColorRect.new()
		card.size = Vector2(cw, ch)
		card.position = Vector2(sx + i * (cw + gap), 100)
		card.color = Color(0.12, 0.08, 0.2, 0.9)
		add_child(card)
		
		var bar = ColorRect.new()
		bar.size = Vector2(cw, 4); bar.color = _rc(h["rarity"])
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE; card.add_child(bar)
		
		var av = ColorRect.new()
		av.size = Vector2(60, 60); av.position = Vector2((cw-60)/2, 15)
		av.color = h["color"]; card.add_child(av)
		
		var nl = Label.new()
		nl.text = h["name"]; nl.add_theme_font_size_override("font_size", 16)
		nl.position = Vector2(0, 82); nl.size = Vector2(cw, 25)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; card.add_child(nl)
		
		var rl = Label.new()
		rl.text = "[" + h["rarity"] + "]"; rl.add_theme_font_size_override("font_size", 11)
		rl.position = Vector2(0, 105); rl.size = Vector2(cw, 20)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; rl.modulate = _rc(h["rarity"])
		card.add_child(rl)
		
		var st = "HP:" + str(h["hp"]) + " ATK:" + str(h["atk"]) + " DEF:" + str(h["def"])
		var sl = Label.new()
		sl.text = st; sl.add_theme_font_size_override("font_size", 10)
		sl.position = Vector2(10, 130); sl.size = Vector2(cw-20, 20)
		sl.modulate = Color(0.5, 0.8, 0.5); card.add_child(sl)
		
		var sk = "⚡ " + h["skill_name"] + ": " + h["skill_desc"]
		var skl = Label.new()
		skl.text = sk; skl.add_theme_font_size_override("font_size", 9)
		skl.position = Vector2(10, 155); skl.size = Vector2(cw-20, 40)
		skl.modulate = Color(0.8, 0.8, 0.5); skl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(skl)
		
		var ps = "✨ " + h["passive_name"] + ": " + h["passive_desc"]
		var psl = Label.new()
		psl.text = ps; psl.add_theme_font_size_override("font_size", 9)
		psl.position = Vector2(10, 200); psl.size = Vector2(cw-20, 40)
		psl.modulate = Color(0.5, 0.8, 0.8); psl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(psl)
		
		var border = ColorRect.new()
		border.name = "Border" + str(i)
		border.size = Vector2(cw, ch); border.color = Color(0.3, 0.3, 0.3, 0.5)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE; card.add_child(border)
		
		var idx = i
		card.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_select(idx))
	
	_select(0)
	
	# Bottom bar
	var bb = ColorRect.new()
	bb.size = Vector2(1280, 50); bb.position = Vector2(0, 670)
	bb.color = Color(0, 0, 0, 0.6); add_child(bb)
	
	var play = Button.new()
	play.name = "PlayBtn"; play.text = "⚔ INICIAR PARTIDA"
	play.position = Vector2(490, 520); play.size = Vector2(300, 50)
	add_child(play); play.pressed.connect(_start)

func _rc(r):
	match r:
		"Comun": return Color(0.7, 0.7, 0.7)
		"Raro": return Color(0.3, 0.5, 1.0)
		"Epico": return Color(0.8, 0.2, 1.0)
	return Color.WHITE

func _select(idx):
	Globals.selected_hero_id = idx
	for i in range(Globals.heroes.size()):
		var b = get_child(2 + i)
		if b is ColorRect:
			var border = b.get_node("Border" + str(i))
			if border:
				border.color = Color(1, 0.8, 0, 0.8) if i == idx else Color(0.3, 0.3, 0.3, 0.5)

func _start():
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
