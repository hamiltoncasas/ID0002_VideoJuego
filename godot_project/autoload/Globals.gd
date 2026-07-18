extends Node

# Game state persistent across scenes
var gold = 300
var food = 100
var gems = 0
var current_wave = 1
var max_wave = 20

# Selected hero data
var selected_hero_id = 0
var heroes = [
	{
		"id": "hero_sol",
		"name": "Guerrero Sol",
		"desc": "Tanque frontal con alta defensa",
		"hp": 1500, "atk": 70, "def": 55,
		"speed": 1.0, "range": 30,
		"rarity": "Común",
		"color": Color(1, 0.7, 0.1),
		"skill_name": "Golpe Solar",
		"skill_desc": "Golpe devastador que causa 180% de daño",
		"skill_dmg": 1.8,
		"passive_name": "Escudo de Sol",
		"passive_desc": "20% de reducción de daño"
	},
	{
		"id": "hero_chaman",
		"name": "Chamán del Sol",
		"desc": "Mago de apoyo con daño mágico",
		"hp": 900, "atk": 85, "def": 25,
		"speed": 0.8, "range": 120,
		"rarity": "Raro",
		"color": Color(0.3, 0.5, 1.0),
		"skill_name": "Rayo Solar",
		"skill_desc": "Ataca a TODOS los enemigos con 120% de daño mágico",
		"skill_dmg": 1.2,
		"passive_name": "Sabiduría",
		"passive_desc": "Aumenta el ataque de aliados en 10%"
	},
	{
		"id": "hero_guardiana",
		"name": "Guardiana Dorada",
		"desc": "Defensora con protección de equipo",
		"hp": 2000, "atk": 45, "def": 75,
		"speed": 0.7, "range": 25,
		"rarity": "Común",
		"color": Color(0.9, 0.8, 0.2),
		"skill_name": "Muro Dorado",
		"skill_desc": "Escudo que protege a todos por 3s",
		"skill_dmg": 0.0,
		"passive_name": "Fortaleza",
		"passive_desc": "+15% HP para todo el equipo"
	},
	{
		"id": "hero_aguila",
		"name": "Águila Guerrera",
		"desc": "Asesino rápido con críticos letales",
		"hp": 1100, "atk": 110, "def": 30,
		"speed": 1.8, "range": 40,
		"rarity": "Épico",
		"color": Color(0.2, 0.9, 0.6),
		"skill_name": "Ráfaga de Plumas",
		"skill_desc": "Ráfaga que golpea 3 veces al azar",
		"skill_dmg": 1.5,
		"passive_name": "Garra Veloz",
		"passive_desc": "20% de chance de atacar dos veces"
	},
	{
		"id": "hero_luna",
		"name": "Sacerdotisa Lunar",
		"desc": "Sanadora que mantiene vivo al equipo",
		"hp": 750, "atk": 35, "def": 18,
		"speed": 0.6, "range": 130,
		"rarity": "Raro",
		"color": Color(0.8, 0.4, 1.0),
		"skill_name": "Plegaria Lunar",
		"skill_desc": "Cura 25% del HP a todos los aliados",
		"skill_dmg": 0.0,
		"passive_name": "Luz Sanadora",
		"passive_desc": "Cura 5% HP a aliados cada 5s"
	}
]

# Unit definitions
var unit_defs = {
	"warrior": {"name": "Guerrero", "hp": 250, "atk": 30, "def": 18, "speed": 1.0, "range": 30, "gold": 50, "food": 25, "class": "infantry", "color": Color(0.7, 0.4, 0.2)},
	"archer": {"name": "Arquero", "hp": 140, "atk": 38, "def": 6, "speed": 1.4, "range": 110, "gold": 80, "food": 15, "class": "archer", "color": Color(0.3, 0.6, 0.3)},
	"cavalry": {"name": "Jinete", "hp": 350, "atk": 42, "def": 22, "speed": 0.9, "range": 25, "gold": 120, "food": 40, "class": "cavalry", "color": Color(0.8, 0.5, 0.2)},
}

var unit_classes = {
	"infantry": {"strong": "cavalry", "weak": "archer", "icon": "🛡️", "mult": 1.5},
	"archer": {"strong": "infantry", "weak": "cavalry", "icon": "🏹", "mult": 1.5},
	"cavalry": {"strong": "archer", "weak": "infantry", "icon": "🐎", "mult": 1.5},
}

func get_hero(id):
	if id >= 0 and id < heroes.size():
		return heroes[id]
	return heroes[0]

func get_unit_def(type_name):
	return unit_defs.get(type_name, unit_defs["warrior"])
