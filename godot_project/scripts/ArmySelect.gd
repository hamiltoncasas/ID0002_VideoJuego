extends Control

var max_units = 6
var counts = {"warrior": 0, "archer": 0, "cavalry": 0}
var _cards = []

func _ready():
	_create_cards()
	_update_display()
	$DeployBtn.pressed.connect(_on_deploy)
	$Back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))

func _create_cards():
	var types = ["warrior", "archer", "cavalry"]
	var names = ["Guerrero", "Arquero", "Jinete"]
	var icons_text = ["🛡️", "🏹", "🐎"]
	var costs = [50, 80, 120]
	
	for i in range(3):
		var d = Globals.unit_defs[types[i]]
		var food = d["food"]
		
		var card = ColorRect.new()
		card.size = Vector2(240, 300)
		card.position = Vector2(100 + i * 300, 100)
		card.color = Color(0.12, 0.08, 0.18, 0.9)
		add_child(card)
		
		var icon = Label.new()
		icon.text = icons_text[i]
		icon.add_theme_font_size_override("font_size", 48)
		icon.position = Vector2(70, 10)
		icon.size = Vector2(100, 70)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(icon)
		
		var nl = Label.new()
		nl.text = names[i]
		nl.add_theme_font_size_override("font_size", 18)
		nl.position = Vector2(20, 85)
		nl.size = Vector2(200, 25)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(nl)
		
		var cl = Label.new()
		cl.text = "Oro: " + str(costs[i]) + "  Comida: " + str(food)
		cl.add_theme_font_size_override("font_size", 12)
		cl.position = Vector2(20, 110)
		cl.size = Vector2(200, 20)
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cl.modulate = Color(0.8, 0.8, 0.5)
		card.add_child(cl)
		
		var stats = Label.new()
		stats.text = "HP:" + str(d["hp"]) + " ATK:" + str(d["atk"]) + " DEF:" + str(d["def"])
		stats.add_theme_font_size_override("font_size", 10)
		stats.position = Vector2(20, 132)
		stats.size = Vector2(200, 18)
		stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats.modulate = Color(0.6, 0.8, 0.6)
		card.add_child(stats)
		
		var count_label = Label.new()
		count_label.name = "CountLabel"
		count_label.text = "0"
		count_label.add_theme_font_size_override("font_size", 28)
		count_label.position = Vector2(90, 170)
		count_label.size = Vector2(60, 40)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(count_label)
		
		var plus = Button.new()
		plus.text = "+"
		plus.position = Vector2(155, 190)
		plus.size = Vector2(40, 30)
		card.add_child(plus)
		plus.pressed.connect(_add_unit.bind(types[i], costs[i]))
		
		var minus = Button.new()
		minus.text = "-"
		minus.position = Vector2(45, 190)
		minus.size = Vector2(40, 30)
		card.add_child(minus)
		minus.pressed.connect(_remove_unit.bind(types[i], costs[i]))
		
		_cards.append({"card": card, "type": types[i], "count": count_label})

func _add_unit(type, cost):
	if _total() >= max_units: return
	if Globals.gold < cost: return
	var food = Globals.unit_defs[type]["food"]
	if Globals.food < food: return
	
	counts[type] += 1
	Globals.gold -= cost
	Globals.food -= food
	_update_display()

func _remove_unit(type, cost):
	if counts[type] <= 0: return
	var food = Globals.unit_defs[type]["food"]
	counts[type] -= 1
	Globals.gold += cost
	Globals.food += food
	_update_display()

func _total():
	return counts["warrior"] + counts["archer"] + counts["cavalry"]

func _update_display():
	$GoldLabel.text = "Oro: " + str(Globals.gold) + "  Comida: " + str(Globals.food)
	$DeployBtn.text = "INICIAR BATALLA (" + str(_total()) + "/" + str(max_units) + ")"
	
	for c in _cards:
		c["count"].text = str(counts[c["type"]])
	
	# Update army preview
	var prev = $ArmyDisplay
	for c in prev.get_children():
		c.queue_free()
	
	var icons = {"warrior": "🛡️", "archer": "🏹", "cavalry": "🐎"}
	var x = 10
	for type in ["warrior", "archer", "cavalry"]:
		for i in range(counts[type]):
			var lbl = Label.new()
			lbl.text = icons[type]
			lbl.add_theme_font_size_override("font_size", 22)
			lbl.position = Vector2(x, 5)
			lbl.size = Vector2(28, 28)
			prev.add_child(lbl)
			x += 32

func _on_deploy():
	if _total() == 0: return
	Globals.army_counts = counts.duplicate()
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")
