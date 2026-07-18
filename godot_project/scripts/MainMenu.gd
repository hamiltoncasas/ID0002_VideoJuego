extends Control

var hero_cards = []
var selected_idx = 0
var battle_btn: Button

func _ready():
	# Create UI elements programmatically to avoid TSCN issues
	
	# Title
	var title = Label.new()
	title.text = "LEGADO MUISCA"
	title.add_theme_font_size_override("font_size", 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.position = Vector2(200, 35)
	title.size = Vector2(880, 80)
	title.modulate = Color(1, 0.85, 0.3)
	add_child(title)
	
	# Subtitle
	var sub = Label.new()
	sub.text = "Estrategia y magia en la era Muisca"
	sub.add_theme_font_size_override("font_size", 14)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(300, 115)
	sub.size = Vector2(680, 30)
	sub.modulate = Color(0.7, 0.6, 0.4, 0.8)
	add_child(sub)
	
	# Bottom bar
	var bar = ColorRect.new()
	bar.size = Vector2(1280, 35)
	bar.position = Vector2(0, 685)
	bar.color = Color(0, 0, 0, 0.6)
	add_child(bar)
	
	# Resources
	var gold_label = Label.new()
	gold_label.text = "Oro: " + str(Globals.gold)
	gold_label.add_theme_font_size_override("font_size", 14)
	gold_label.position = Vector2(30, 690)
	gold_label.size = Vector2(200, 25)
	add_child(gold_label)
	
	var food_label = Label.new()
	food_label.text = "Comida: " + str(Globals.food)
	food_label.add_theme_font_size_override("font_size", 14)
	food_label.position = Vector2(200, 690)
	food_label.size = Vector2(200, 25)
	add_child(food_label)
	
	# Hero container label
	var hl = Label.new()
	hl.text = "SELECCIONA TU HEROE PRINCIPAL"
	hl.add_theme_font_size_override("font_size", 12)
	hl.position = Vector2(40, 168)
	hl.size = Vector2(400, 20)
	hl.modulate = Color(0.6, 0.6, 0.8, 0.7)
	add_child(hl)
	
	# Hero container
	var hc = Node.new()
	hc.name = "HeroContainer"
	add_child(hc)
	
	# Battle button
	battle_btn = Button.new()
	battle_btn.text = "INICIAR BATALLA"
	battle_btn.position = Vector2(490, 530)
	battle_btn.size = Vector2(300, 50)
	add_child(battle_btn)
	battle_btn.pressed.connect(_on_battle)
	
	# Controls help
	var ctrl = Label.new()
	ctrl.text = "[1-3] Invocar   [Click] Seleccionar   [Der] Mover   [Q] Habilidad   [Espacio] Pausa"
	ctrl.add_theme_font_size_override("font_size", 10)
	ctrl.position = Vector2(40, 600)
	ctrl.size = Vector2(800, 20)
	ctrl.modulate = Color(0.5, 0.5, 0.5, 0.6)
	add_child(ctrl)
	
	create_hero_cards()

func create_hero_cards():
	var heroes = Globals.heroes
	var hero_container = $HeroContainer
	var cw = 215; var ch = 320; var gap = 18
	var tw = heroes.size() * cw + (heroes.size() - 1) * gap
	var sx = (1280 - tw) / 2
	
	for i in range(heroes.size()):
		var h = heroes[i]
		var card = ColorRect.new()
		card.size = Vector2(cw, ch)
		card.position = Vector2(sx + i * (cw + gap), 5)
		card.color = Color(0.1, 0.07, 0.15, 0.95)
		hero_container.add_child(card)
		
		# Rarity bar
		var rbar = ColorRect.new()
		rbar.size = Vector2(cw, 4)
		rbar.color = _rarity_color(h["rarity"])
		rbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(rbar)
		
		# Avatar circle
		var avatar = ColorRect.new()
		avatar.size = Vector2(70, 70)
		avatar.position = Vector2((cw - 70) / 2, 12)
		avatar.color = h["color"]
		card.add_child(avatar)
		
		# Name
		var nl = Label.new()
		nl.text = h["name"]; nl.add_theme_font_size_override("font_size", 14)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.position = Vector2(0, 88); nl.size = Vector2(cw, 24)
		card.add_child(nl)
		
		# Rarity text
		var rl = Label.new()
		rl.text = "[" + h["rarity"] + "]"; rl.add_theme_font_size_override("font_size", 10)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rl.position = Vector2(0, 108); rl.size = Vector2(cw, 18)
		rl.modulate = _rarity_color(h["rarity"])
		card.add_child(rl)
		
		# Desc
		var dl = Label.new()
		dl.text = h["desc"]; dl.add_theme_font_size_override("font_size", 10)
		dl.position = Vector2(8, 130); dl.size = Vector2(cw - 16, 20)
		dl.modulate = Color(0.7, 0.7, 0.7)
		card.add_child(dl)
		
		# Stats
		var sl = Label.new()
		sl.text = "HP: " + str(h["hp"]) + "  ATK: " + str(h["atk"]) + "  DEF: " + str(h["def"])
		sl.add_theme_font_size_override("font_size", 9)
		sl.position = Vector2(8, 152); sl.size = Vector2(cw - 16, 18)
		sl.modulate = Color(0.5, 0.8, 0.5)
		card.add_child(sl)
		
		# Speed
		var srl = Label.new()
		srl.text = "Vel: " + str(h["speed"]) + "/s  Alc: " + str(h["range"])
		srl.add_theme_font_size_override("font_size", 9)
		srl.position = Vector2(8, 168); srl.size = Vector2(cw - 16, 18)
		srl.modulate = Color(0.6, 0.6, 0.8)
		card.add_child(srl)
		
		# Skill
		var skl = Label.new()
		skl.text = h["skill_name"]; skl.add_theme_font_size_override("font_size", 9)
		skl.position = Vector2(8, 190); skl.size = Vector2(cw - 16, 16)
		skl.modulate = Color(0.9, 0.8, 0.3)
		card.add_child(skl)
		
		var skd = Label.new()
		skd.text = h["skill_desc"]; skd.add_theme_font_size_override("font_size", 8)
		skd.position = Vector2(8, 205); skd.size = Vector2(cw - 16, 30)
		skd.modulate = Color(0.7, 0.7, 0.5)
		skd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(skd)
		
		# Passive
		var psl = Label.new()
		psl.text = h["passive_name"]; psl.add_theme_font_size_override("font_size", 9)
		psl.position = Vector2(8, 238); psl.size = Vector2(cw - 16, 16)
		psl.modulate = Color(0.5, 0.8, 0.8)
		card.add_child(psl)
		
		var psd = Label.new()
		psd.text = h["passive_desc"]; psd.add_theme_font_size_override("font_size", 8)
		psd.position = Vector2(8, 253); psd.size = Vector2(cw - 16, 30)
		psd.modulate = Color(0.6, 0.7, 0.7)
		psd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(psd)
		
		# Border
		var border = ColorRect.new()
		border.name = "Border"
		border.size = Vector2(cw, ch)
		border.color = Color(0.3, 0.3, 0.3, 0.5)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(border)
		
		var idx = i
		card.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				select_hero(idx))
		card.mouse_entered.connect(func():
			if selected_idx != idx: card.modulate = Color(1.05, 1.05, 1.05))
		card.mouse_exited.connect(func():
			if selected_idx != idx: card.modulate = Color(1, 1, 1))
		
		hero_cards.append(card)
	
	select_hero(0)

func _rarity_color(rarity):
	match rarity:
		"Comun": return Color(0.7, 0.7, 0.7)
		"Raro": return Color(0.3, 0.5, 1.0)
		"Epico": return Color(0.8, 0.2, 1.0)
	return Color.WHITE

func select_hero(idx):
	selected_idx = idx
	Globals.selected_hero_id = idx
	for i in range(hero_cards.size()):
		var card = hero_cards[i]
		var border = card.get_node("Border")
		if i == idx:
			border.color = Color(1, 0.8, 0, 0.8)
			card.modulate = Color(1.05, 1.05, 1.05)
		else:
			border.color = Color(0.3, 0.3, 0.3, 0.5)
			card.modulate = Color(0.85, 0.85, 0.85)

func _on_battle():
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")
