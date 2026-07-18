extends Control

var hero_cards = []
var selected_idx = 0

@onready var hero_container = $HeroContainer
@onready var battle_btn = $BattleBtn
@onready var gold_label = $Resources/GoldLabel
@onready var food_label = $Resources/FoodLabel

func _ready():
	update_resources()
	create_hero_cards()
	battle_btn.connect("pressed", Callable(self, "_on_battle"))

func update_resources():
	gold_label.text = "Oro: " + str(Globals.gold)
	food_label.text = "Comida: " + str(Globals.food)

func create_hero_cards():
	var heroes = Globals.heroes
	var card_w = 200
	var card_h = 280
	var gap = 20
	var total_w = heroes.size() * card_w + (heroes.size() - 1) * gap
	var start_x = (1280 - total_w) / 2
	
	for i in range(heroes.size()):
		var h = heroes[i]
		var card = ColorRect.new()
		card.size = Vector2(card_w, card_h)
		card.position = Vector2(start_x + i * (card_w + gap), 10)
		card.color = Color(0.12, 0.08, 0.18, 0.9)
		
		# Name
		var name_label = Label.new()
		name_label.size = Vector2(card_w, 30)
		name_label.position = Vector2(0, 10)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.text = h["name"]
		card.add_child(name_label)
		
		# Rarity
		var rarity_label = Label.new()
		rarity_label.size = Vector2(card_w, 20)
		rarity_label.position = Vector2(0, 35)
		rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rarity_label.add_theme_font_size_override("font_size", 10)
		var rarity_colors = {"Común": Color(0.8, 0.8, 0.8), "Raro": Color(0.3, 0.5, 1.0), "Épico": Color(0.8, 0.2, 1.0)}
		rarity_label.modulate = rarity_colors.get(h["rarity"], Color.WHITE)
		rarity_label.text = "[" + h["rarity"] + "]"
		card.add_child(rarity_label)
		
		# Hero avatar (colored circle)
		var avatar = ColorRect.new()
		avatar.size = Vector2(80, 80)
		avatar.position = Vector2((card_w - 80) / 2, 55)
		avatar.color = h["color"]
		card.add_child(avatar)
		
		# Description
		var desc_label = Label.new()
		desc_label.size = Vector2(card_w - 20, 25)
		desc_label.position = Vector2(10, 142)
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.modulate = Color(0.7, 0.7, 0.7)
		desc_label.text = h["desc"]
		card.add_child(desc_label)
		
		# Stats
		var stats_text = "HP: " + str(h["hp"]) + "  ATK: " + str(h["atk"]) + "  DEF: " + str(h["def"])
		var stats_label = Label.new()
		stats_label.size = Vector2(card_w - 20, 20)
		stats_label.position = Vector2(10, 165)
		stats_label.add_theme_font_size_override("font_size", 9)
		stats_label.modulate = Color(0.6, 0.8, 0.6)
		stats_label.text = stats_text
		card.add_child(stats_label)
		
		# Skill
		var skill_text = "⚡ " + h["skill_name"] + ": " + h["skill_desc"]
		var skill_label = Label.new()
		skill_label.size = Vector2(card_w - 20, 40)
		skill_label.position = Vector2(10, 185)
		skill_label.add_theme_font_size_override("font_size", 8)
		skill_label.modulate = Color(0.8, 0.8, 0.5)
		skill_label.text = skill_text
		skill_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(skill_label)
		
		# Passive
		var pass_text = "✨ " + h["passive_name"] + ": " + h["passive_desc"]
		var pass_label = Label.new()
		pass_label.size = Vector2(card_w - 20, 40)
		pass_label.position = Vector2(10, 225)
		pass_label.add_theme_font_size_override("font_size", 8)
		pass_label.modulate = Color(0.5, 0.8, 0.8)
		pass_label.text = pass_text
		pass_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(pass_label)
		
		# Selection highlight
		var highlight = ColorRect.new()
		highlight.name = "Highlight"
		highlight.size = Vector2(card_w, card_h)
		highlight.position = Vector2(0, 0)
		highlight.color = Color(1, 1, 0, 0)
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(highlight)
		
		# Border
		var border = ColorRect.new()
		border.name = "Border"
		border.size = Vector2(card_w, card_h)
		border.position = Vector2(0, 0)
		border.color = Color(0.3, 0.3, 0.3, 0.5)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(border)
		
		# Click handling
		var idx = i
		var click_area = Area2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(card_w, card_h)
		var col = CollisionShape2D.new()
		col.shape = shape
		click_area.add_child(col)
		click_area.position = Vector2(card_w/2, card_h/2)
		card.add_child(click_area)
		var input = InputEventMouseButton.new()
		
		card.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				select_hero(idx)
		)
		
		card.mouse_entered.connect(func():
			if selected_idx != idx:
				card.modulate = Color(1.05, 1.05, 1.05)
		)
		card.mouse_exited.connect(func():
			if selected_idx != idx:
				card.modulate = Color(1, 1, 1)
		)
		
		hero_container.add_child(card)
		hero_cards.append(card)
	
	# Select first
	select_hero(0)

func select_hero(idx):
	selected_idx = idx
	Globals.selected_hero_id = idx
	
	for i in range(hero_cards.size()):
		var card = hero_cards[i]
		var border = card.get_node("Border")
		var highlight = card.get_node("Highlight")
		
		if i == idx:
			border.color = Color(1, 0.8, 0, 0.8)
			highlight.color = Color(1, 1, 0, 0.05)
			card.modulate = Color(1.05, 1.05, 1.05)
		else:
			border.color = Color(0.3, 0.3, 0.3, 0.5)
			highlight.color = Color(1, 1, 0, 0)
			card.modulate = Color(0.85, 0.85, 0.85)

func _on_battle():
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")
