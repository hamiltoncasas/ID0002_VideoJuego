extends Control

# Game state
var gold = 200
var food = 100
var wave = 1
var hero_hp = 900
var hero_max_hp = 900
var hero_atk = 100
var enemy_count = 3
var phase = "preparation"  # preparation, battle, victory, defeat
var paused = false
var elapsed = 0.0
var prep_timer = 3.0

# Enemy HP per lane (simplified)
var enemy_hp = {
	"top": [80, 80, 80],
	"mid": [80, 80, 80],
	"bot": [80, 80]
}

# UI references
@onready var gold_label = $HUD/GoldLabel
@onready var wave_label = $HUD/WaveLabel
@onready var food_label = $HUD/FoodLabel
@onready var status_label = $HUD/StatusLabel
@onready var hero_hp_label = $HeroHP
@onready var hero_label = $HeroLabel

func _ready():
	update_ui()
	status_label.text = "PREPARACIÓN..."
	# Take screenshots at key moments
	await get_tree().create_timer(1.5).timeout
	take_screenshot("screenshot_battle")

func _process(delta):
	if paused or phase == "victory" or phase == "defeat":
		return
	
	elapsed += delta
	
	if phase == "preparation":
		prep_timer -= delta
		if prep_timer <= 0:
			phase = "battle"
			status_label.text = "⚔️ BATALLA"
			wave_label.text = "⚔️ OLEADA " + str(wave)
		return
	
	# Battle phase - auto combat
	if phase == "battle":
		# Hero attacks every 0.8s
		if int(elapsed * 10) % 8 == 0 and int((elapsed - delta) * 10) % 8 != 0:
			hero_attack()
		
		# Enemies attack back
		if int(elapsed * 10) % 12 == 0 and int((elapsed - delta) * 10) % 12 != 0:
			enemy_attack()
		
		# Gold generation
		if int(elapsed) != int(elapsed - delta):
			gold += 2
			food += 1
			update_ui()
		
		check_victory()

func hero_attack():
	if hero_hp <= 0:
		return
	
	# Find alive enemies on mid lane
	var mid_enemies = enemy_hp["mid"]
	var alive = []
	for i in range(mid_enemies.size()):
		if mid_enemies[i] > 0:
			alive.append(i)
	
	if alive.size() > 0:
		var target = alive[0]
		var damage = hero_atk
		var is_crit = randf() < 0.2
		if is_crit:
			damage = int(damage * 2.0)
		
		mid_enemies[target] -= damage
		if mid_enemies[target] <= 0:
			mid_enemies[target] = 0
			gold += 5
			enemy_count -= 1
			print("Enemy killed! Remaining: ", enemy_count)
		
		var crit_text = " 💥 CRIT!" if is_crit else ""
		print("Hero attacks! -", damage, " HP", crit_text)
		update_ui()

func enemy_attack():
	if hero_hp <= 0:
		return
	
	var damage = 8 + randi() % 5
	var is_crit = randf() < 0.05
	if is_crit:
		damage = int(damage * 1.5)
	
	hero_hp -= damage
	if hero_hp <= 0:
		hero_hp = 0
		phase = "defeat"
		status_label.text = "💀 DERROTA"
		print("Hero defeated!")
	
	update_ui()

func check_victory():
	# Check if all enemies are dead
	var total_alive = 0
	for lane in enemy_hp.keys():
		for hp in enemy_hp[lane]:
			if hp > 0:
				total_alive += 1
	
	if total_alive == 0:
		phase = "victory"
		status_label.text = "🏆 VICTORIA!"
		print("Victory!")
		take_screenshot()
	elif hero_hp <= 0:
		phase = "defeat"
		status_label.text = "💀 DERROTA"
		print("Defeat!")
		take_screenshot()

func update_ui():
	gold_label.text = "🪙 Oro: " + str(gold)
	food_label.text = "🌾 Comida: " + str(food)
	hero_hp_label.text = "HP: " + str(hero_hp) + "/" + str(hero_max_hp)

func take_screenshot(name = "screenshot"):
	var image = get_viewport().get_texture().get_image()
	if image:
		var path = "user://" + name + ".png"
		image.save_png(path)
		print("✅ Screenshot saved: ", path)

func _input(event):
	if event is InputEventKey:
		if event.pressed and not event.echo:
			match event.keycode:
				KEY_SPACE:
					paused = !paused
					status_label.text = "⏸️ PAUSA" if paused else ("⚔️ BATALLA" if phase == "battle" else phase)
				KEY_1:
					spawn_unit("warrior")
				KEY_2:
					spawn_unit("archer")
				KEY_3:
					spawn_unit("cavalry")
				KEY_4:
					hero_skill()

func spawn_unit(type):
	if phase != "battle":
		return
	
	var cost = {"warrior": 50, "archer": 80, "cavalry": 120}
	var food_cost = {"warrior": 25, "archer": 15, "cavalry": 40}
	
	if gold >= cost[type] and food >= food_cost[type]:
		gold -= cost[type]
		food -= food_cost[type]
		var names = {"warrior": "🔰 Guerrero", "archer": "🏹 Arquero", "cavalry": "🐎 Jinete"}
		print(names[type], " desplegado!")
		update_ui()

func hero_skill():
	if phase != "battle" or hero_hp <= 0:
		return
	print("⚡ Ráfaga de Plumas! Hero attacks all enemies!")
	
	# Damage all enemies
	for lane in enemy_hp.keys():
		for i in range(enemy_hp[lane].size()):
			if enemy_hp[lane][i] > 0:
				enemy_hp[lane][i] -= int(hero_atk * 1.2)
				if enemy_hp[lane][i] <= 0:
					enemy_hp[lane][i] = 0
					enemy_count -= 1
					gold += 5
	
	update_ui()
	check_victory()
