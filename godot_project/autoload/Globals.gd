extends Node

# Player
var player_name = "Arqueologo"
var logged_in = false

# Game mode
var game_mode = "offline"  # offline, online_1v1, online_3v3

# Resources
var resources = {
	"gold": 200, "stone": 100, "food": 150,
	"wood": 150, "copper": 0, "bronze": 0,
	"diamond": 0, "leather": 0
}

# Hero
var selected_hero_id = 0
var heroes = [
	{"id": "hero_sol", "name": "Guerrero Sol", "hp": 1500, "atk": 70, "def": 55,
	 "speed": 1.0, "range": 30, "rarity": "Comun", "color": Color(1, 0.7, 0.1),
	 "skill_name": "Golpe Solar", "skill_desc": "Golpe devastador 180%", "skill_dmg": 1.8,
	 "passive_name": "Escudo de Sol", "passive_desc": "20% reduccion de dano"},
	{"id": "hero_chaman", "name": "Chaman del Sol", "hp": 900, "atk": 85, "def": 25,
	 "speed": 0.8, "range": 120, "rarity": "Raro", "color": Color(0.3, 0.5, 1.0),
	 "skill_name": "Rayo Solar", "skill_desc": "Ataca TODOS los enemigos 120%", "skill_dmg": 1.2,
	 "passive_name": "Sabiduria", "passive_desc": "+10% ataque aliados"},
	{"id": "hero_guardiana", "name": "Guardiana Dorada", "hp": 2000, "atk": 45, "def": 75,
	 "speed": 0.7, "range": 25, "rarity": "Comun", "color": Color(0.9, 0.8, 0.2),
	 "skill_name": "Muro Dorado", "skill_desc": "Escudo protege a todos 3s", "skill_dmg": 0.0,
	 "passive_name": "Fortaleza", "passive_desc": "+15% HP equipo"},
	{"id": "hero_aguila", "name": "Aguila Guerrera", "hp": 1100, "atk": 110, "def": 30,
	 "speed": 1.8, "range": 40, "rarity": "Epico", "color": Color(0.2, 0.9, 0.6),
	 "skill_name": "Rafaga de Plumas", "skill_desc": "3 golpes al azar 150%", "skill_dmg": 1.5,
	 "passive_name": "Garra Veloz", "passive_desc": "20% doble ataque"},
	{"id": "hero_luna", "name": "Sacerdotisa Lunar", "hp": 750, "atk": 35, "def": 18,
	 "speed": 0.6, "range": 130, "rarity": "Raro", "color": Color(0.8, 0.4, 1.0),
	 "skill_name": "Plegaria Lunar", "skill_desc": "Cura 25% HP a todos", "skill_dmg": 0.0,
	 "passive_name": "Luz Sanadora", "passive_desc": "Cura 5% HP cada 5s"},
]

# Unit definitions
var unit_defs = {
	"warrior": {"name": "Guerrero", "hp": 300, "atk": 35, "def": 20, "speed": 1.0, "range": 30, "gold": 50, "food": 25, "wood": 10, "class": "infantry", "color": Color(0.7, 0.4, 0.2)},
	"archer": {"name": "Arquero", "hp": 150, "atk": 42, "def": 8, "speed": 1.4, "range": 120, "gold": 80, "food": 15, "wood": 30, "class": "archer", "color": Color(0.3, 0.6, 0.3)},
	"cavalry": {"name": "Jinete", "hp": 400, "atk": 48, "def": 25, "speed": 0.9, "range": 25, "gold": 120, "food": 40, "wood": 15, "class": "cavalry", "color": Color(0.8, 0.5, 0.2)},
	"villager": {"name": "Aldeano", "hp": 100, "atk": 8, "def": 3, "speed": 1.2, "range": 20, "gold": 0, "food": 50, "wood": 0, "class": "villager", "color": Color(0.6, 0.4, 0.3)},
	"artisan": {"name": "Artesano", "hp": 80, "atk": 5, "def": 2, "speed": 0.8, "range": 15, "gold": 100, "food": 20, "wood": 20, "class": "artisan", "color": Color(0.7, 0.6, 0.2)},
}

# Building definitions
var building_defs = {
	"castle": {"name": "Castillo", "hp": 5000, "cost": {"gold": 300, "stone": 200, "wood": 100}, "desc": "Edificio central. Produce aldeanos.", "size": Vector2(80, 80)},
	"barracks": {"name": "Cuartel", "hp": 1500, "cost": {"gold": 100, "wood": 100}, "desc": "Entrena infanteria. Max 5 unidades.", "size": Vector2(60, 50)},
	"archery": {"name": "Torre de Arqueros", "hp": 1200, "cost": {"gold": 120, "wood": 80, "stone": 50}, "desc": "Entrena arqueros. Max 5 unidades.", "size": Vector2(50, 50)},
	"stable": {"name": "Caballeriza", "hp": 1800, "cost": {"gold": 150, "wood": 60, "stone": 30}, "desc": "Entrena jinetes. Max 5 unidades.", "size": Vector2(70, 50)},
	"wall": {"name": "Muralla", "hp": 2000, "cost": {"stone": 50}, "desc": "Defensa pasiva. Bloquea el paso.", "size": Vector2(40, 16)},
	"tower_arrow": {"name": "Torre Lanzaflechas", "hp": 2500, "cost": {"gold": 80, "stone": 100, "wood": 40}, "desc": "Torre defensiva. Ataca automatico.", "size": Vector2(40, 40)},
	"tower_stone": {"name": "Torre Lanzapiedras", "hp": 3500, "cost": {"gold": 150, "stone": 200, "wood": 60}, "desc": "Torre pesada. Alto dano a edificios.", "size": Vector2(50, 50)},
	"gate": {"name": "Puerta", "hp": 1000, "cost": {"stone": 30, "wood": 30}, "desc": "Paso controlado en murallas.", "size": Vector2(40, 16)},
	"workshop": {"name": "Taller", "hp": 1000, "cost": {"gold": 80, "wood": 100}, "desc": "Mejora armas y armaduras.", "size": Vector2(50, 40)},
	"market": {"name": "Mercado", "hp": 800, "cost": {"gold": 100, "wood": 50}, "desc": "Comercio de recursos.", "size": Vector2(50, 40)},
}

# Tech upgrades
var techs = {
	"forge": {"name": "Forja", "desc": "Ataque unidades +10%", "cost": {"gold": 100, "stone": 50}, "max": 5, "effect": "attack"},
	"armor": {"name": "Armadura", "desc": "Defensa unidades +10%", "cost": {"gold": 80, "stone": 80}, "max": 5, "effect": "defense"},
	"range": {"name": "Punteria", "desc": "Rango arqueros +10%", "cost": {"gold": 120, "wood": 60}, "max": 3, "effect": "range"},
}

# Save slots
var save_slots = {}

# Game state for current match
var game_data = {}

func get_hero(id):
	if id >= 0 and id < heroes.size(): return heroes[id]
	return heroes[0]

func can_afford(cost_dict):
	for r in cost_dict.keys():
		if resources.get(r, 0) < cost_dict[r]: return false
	return true

func spend(cost_dict):
	if not can_afford(cost_dict): return false
	for r in cost_dict.keys():
		resources[r] -= cost_dict[r]
	return true
