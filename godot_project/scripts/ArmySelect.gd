extends Control

var selected_units = []
var max_units = 6
var unit_types = ["warrior", "archer", "cavalry"]
var counts = {"warrior": 0, "archer": 0, "cavalry": 0}
var total_cost = 0

@onready var deploy_btn = $DeployBtn
@onready var gold_label = $GoldLabel
@onready var army_display = $ArmyDisplay

func _ready():
	_update_ui()
	
	deploy_btn.pressed.connect(_on_deploy)
	$Back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	
	# Create unit selection cards
	var types = ["warrior", "archer", "cavalry"]
	var names = ["Guerrero", "Arquero", "Jinete"]
	var icons = ["🛡️", "🏹", "🐎"]
	var costs = [50, 80, 120]
	
	for i in range(3):
		var card = get_node("UnitCard" + str(i + 1))
		card.get_node("Name").text = names[i]
		card.get_node("Icon").text = icons[i]
		card.get_node("Cost").text = "🪙" + str(costs[i]) + " 🌾" + str(Globals.unit_defs[types[i]]["food"])
		card.get_node("Plus").pressed.connect(_add_unit.bind(types[i], costs[i]))
		card.get_node("Minus").pressed.connect(_remove_unit.bind(types[i], costs[i]))
	
	# Preview
	_refresh_army_preview()

func _add_unit(type, cost):
	if _total_units() >= max_units: return
	if Globals.gold < cost: return
	var food = Globals.unit_defs[type]["food"]
	if Globals.food < food: return
	
	counts[type] += 1
	Globals.gold -= cost
	Globals.food -= food
	_update_counts()
	_update_ui()
	_refresh_army_preview()

func _remove_unit(type, cost):
	if counts[type] <= 0: return
	var food = Globals.unit_defs[type]["food"]
	counts[type] -= 1
	Globals.gold += cost
	Globals.food += food
	_update_counts()
	_update_ui()
	_refresh_army_preview()

func _update_counts():
	var types = ["warrior", "archer", "cavalry"]
	for i in range(3):
		var card = get_node("UnitCard" + str(i + 1))
		card.get_node("Count").text = str(counts[types[i]])

func _total_units():
	return counts["warrior"] + counts["archer"] + counts["cavalry"]

func _update_ui():
	gold_label.text = "🪙 Oro: " + str(Globals.gold) + "  🌾 Comida: " + str(Globals.food)
	deploy_btn.text = "⚔️  INICIAR BATALLA (" + str(_total_units()) + "/" + str(max_units) + ")"

func _refresh_army_preview():
	# Clear old
	for c in army_display.get_children():
		c.queue_free()
	
	var x = 10
	var types = ["warrior", "archer", "cavalry"]
	var names = ["Guerrero", "Arquero", "Jinete"]
	var icons = {"warrior": "🛡️", "archer": "🏹", "cavalry": "🐎"}
	
	for type in types:
		for i in range(counts[type]):
			var u = Label.new()
			u.text = icons[type]
			u.add_theme_font_size_override("font_size", 24)
			u.position = Vector2(x, 5)
			u.size = Vector2(30, 30)
			army_display.add_child(u)
			x += 35

func _on_deploy():
	if _total_units() == 0: return
	Globals.army_counts = counts.duplicate()
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")
