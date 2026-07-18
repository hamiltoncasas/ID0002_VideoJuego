extends Control

var cards = []
var selected_idx = 0

func _ready():
	# Animated background layers
	for i in 5:
		var bg = ColorRect.new()
		bg.size = Vector2(1280, 720)
		bg.color = Color(0.04 + i * 0.015, 0.02, 0.05 + i * 0.01, 0.4)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
	
	# Top decorative bar
	var topbar = ColorRect.new()
	topbar.size = Vector2(1280, 4)
	topbar.color = Color(1, 0.7, 0.1, 0.4)
	topbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(topbar)
	
	# Ambient particles
	for i in 30:
		var p = ColorRect.new()
		p.size = Vector2(2 + randi() % 3, 2 + randi() % 3)
		p.position = Vector2(randi() % 1280, randi() % 720)
		p.color = Color(1, 0.8, 0.5, 0.03 + randf() * 0.05)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.name = "particle"
		add_child(p)
	
	# Title with glow effect
	var title_bg = ColorRect.new()
	title_bg.size = Vector2(600, 60)
	title_bg.position = Vector2(340, 20)
	title_bg.color = Color(0, 0, 0, 0.3)
	title_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_bg)
	
	var title = Label.new()
	title.text = "SELECCIONA TU HEROE"
	title.add_theme_font_size_override("font_size", 28)
	title.position = Vector2(200, 25)
	title.size = Vector2(880, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1, 0.85, 0.3)
	add_child(title)
	
	# Subtitle
	var sub = Label.new()
	sub.text = "Cada heroe tiene habilidades y pasivas unicas"
	sub.add_theme_font_size_override("font_size", 12)
	sub.position = Vector2(200, 75)
	sub.size = Vector2(880, 20)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(0.6, 0.6, 0.7, 0.7)
	add_child(sub)
	
	# Hero cards
	var heroes = Globals.heroes
	var cw = 210; var ch = 370; var gap = 18
	var tw = heroes.size() * cw + (heroes.size() - 1) * gap
	var sx = max(20, (1280 - tw) / 2)
	
	for i in range(heroes.size()):
		var h = heroes[i]
		var card = ColorRect.new()
		card.name = "Card" + str(i)
		card.size = Vector2(cw, ch)
		card.position = Vector2(sx + i * (cw + gap), 105)
		card.color = Color(0.08, 0.05, 0.13, 0.92)
		add_child(card)
		
		# Rarity top glow bar
		var rbar = ColorRect.new()
		rbar.size = Vector2(cw, 4)
		rbar.color = _rc(h["rarity"])
		rbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(rbar)
		
		# Avatar circle with border
		var av_border = ColorRect.new()
		av_border.size = Vector2(66, 66)
		av_border.position = Vector2((cw-66)/2, 14)
		av_border.color = _rc(h["rarity"])
		av_border.color.a = 0.3
		av_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(av_border)
		
		var av = ColorRect.new()
		av.size = Vector2(58, 58)
		av.position = Vector2((cw-58)/2, 18)
		av.color = h["color"]
		card.add_child(av)
		
		# Hero name
		var nl = Label.new()
		nl.text = h["name"]
		nl.add_theme_font_size_override("font_size", 15)
		nl.position = Vector2(0, 86)
		nl.size = Vector2(cw, 22)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(nl)
		
		# Rarity text
		var rl = Label.new()
		rl.text = "[" + h["rarity"] + "]"
		rl.add_theme_font_size_override("font_size", 10)
		rl.position = Vector2(0, 106)
		rl.size = Vector2(cw, 16)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rl.modulate = _rc(h["rarity"])
		card.add_child(rl)
		
		# Stats line
		var stats_text = "HP: " + str(h["hp"]) + "  ATK: " + str(h["atk"]) + "  DEF: " + str(h["def"])
		var sl = Label.new()
		sl.text = stats_text
		sl.add_theme_font_size_override("font_size", 10)
		sl.position = Vector2(10, 128)
		sl.size = Vector2(cw - 20, 18)
		sl.modulate = Color(0.6, 0.9, 0.6)
		card.add_child(sl)
		
		# Divider line
		var divider = ColorRect.new()
		divider.size = Vector2(cw - 30, 1)
		divider.position = Vector2(15, 150)
		divider.color = Color(1, 1, 1, 0.08)
		divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(divider)
		
		# Skill section
		var sk_head = Label.new()
		sk_head.text = "⚡ HABILIDAD"
		sk_head.add_theme_font_size_override("font_size", 9)
		sk_head.position = Vector2(10, 158)
		sk_head.size = Vector2(cw - 20, 14)
		sk_head.modulate = Color(0.9, 0.8, 0.3)
		card.add_child(sk_head)
		
		var sk_desc = h["skill_name"] + ": " + h["skill_desc"]
		var skl = Label.new()
		skl.text = sk_desc
		skl.add_theme_font_size_override("font_size", 8)
		skl.position = Vector2(10, 172)
		skl.size = Vector2(cw - 20, 36)
		skl.modulate = Color(0.7, 0.7, 0.5)
		skl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(skl)
		
		# Passive section
		var ps_head = Label.new()
		ps_head.text = "✨ PASIVA"
		ps_head.add_theme_font_size_override("font_size", 9)
		ps_head.position = Vector2(10, 212)
		ps_head.size = Vector2(cw - 20, 14)
		ps_head.modulate = Color(0.5, 0.8, 0.8)
		card.add_child(ps_head)
		
		var ps_desc = h["passive_name"] + ": " + h["passive_desc"]
		var psl = Label.new()
		psl.text = ps_desc
		psl.add_theme_font_size_override("font_size", 8)
		psl.position = Vector2(10, 226)
		psl.size = Vector2(cw - 20, 36)
		psl.modulate = Color(0.6, 0.7, 0.7)
		psl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(psl)
		
		# Speed and range
		var extra = "Vel: " + str(h["speed"]) + "/s  Alc: " + str(h["range"])
		var el = Label.new()
		el.text = extra
		el.add_theme_font_size_override("font_size", 9)
		el.position = Vector2(10, 270)
		el.size = Vector2(cw - 20, 16)
		el.modulate = Color(0.6, 0.6, 0.8)
		card.add_child(el)
		
		# Selection border (highlighted when selected)
		var border = ColorRect.new()
		border.name = "Border"
		border.size = Vector2(cw, ch)
		border.color = Color(0.3, 0.3, 0.3, 0.5)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(border)
		
		# Selection glow (inner)
		var sel_glow = ColorRect.new()
		sel_glow.name = "SelGlow"
		sel_glow.size = Vector2(cw - 4, ch - 4)
		sel_glow.position = Vector2(2, 2)
		sel_glow.color = Color(0, 0, 0, 0)
		sel_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(sel_glow)
		
		# Hover and click handling
		var idx = i
		card.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_select(idx))
		card.mouse_entered.connect(func():
			if selected_idx != idx:
				card.modulate = Color(1.04, 1.04, 1.04)
				card.position.y -= 3)
		card.mouse_exited.connect(func():
			if selected_idx != idx:
				card.modulate = Color(1, 1, 1)
				card.position.y += 3)
		
		cards.append(card)
	
	_select(0)
	
	# Bottom bar
	var bb = ColorRect.new()
	bb.size = Vector2(1280, 55)
	bb.position = Vector2(0, 665)
	bb.color = Color(0, 0, 0, 0.5)
	add_child(bb)
	
	# Play button
	var play = Button.new()
	play.name = "PlayBtn"
	play.text = "⚔  INICIAR PARTIDA"
	play.position = Vector2(490, 510)
	play.size = Vector2(300, 50)
	play.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	play.add_theme_color_override("button_normal", Color(0.2, 0.45, 0.2, 0.9))
	play.add_theme_color_override("button_hover", Color(0.3, 0.55, 0.3, 1.0))
	add_child(play)
	play.pressed.connect(_start)
	
	# Animate particles
	_animate_particles()

func _animate_particles():
	while true:
		for p in get_children():
			if p.name == "particle":
				p.position.y += 0.3
				p.position.x += sin(Time.get_ticks_msec() * 0.001 + p.position.y * 0.01) * 0.2
				if p.position.y > 740:
					p.position.y = -10
					p.position.x = randi() % 1280
		await get_tree().create_timer(0.05).timeout

func _rc(r):
	match r:
		"Comun": return Color(0.7, 0.7, 0.7)
		"Raro": return Color(0.3, 0.5, 1.0)
		"Epico": return Color(0.8, 0.2, 1.0)
		"Mítico": return Color(1, 0.5, 0, 1)
	return Color.WHITE

func _select(idx):
	selected_idx = idx
	Globals.selected_hero_id = idx
	for i in range(cards.size()):
		var card = cards[i]
		var border = card.get_node("Border")
		var glow = card.get_node("SelGlow")
		if i == idx:
			border.color = _rc(Globals.heroes[i]["rarity"])
			border.color.a = 0.8
			glow.color = Color(1, 1, 0, 0.04)
			card.modulate = Color(1.05, 1.05, 1.05)
		else:
			border.color = Color(0.3, 0.3, 0.3, 0.4)
			glow.color = Color(0, 0, 0, 0)
			card.modulate = Color(0.85, 0.85, 0.85)

func _start():
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
