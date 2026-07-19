extends Node

var player_name = "Arqueologo"
var logged_in = false
var game_mode = "offline"
var selected_hero_id = 0
var difficulty = 1  # 1=Facil, 2=Normal, 3=Dificil
var enemy_kingdoms = 2  # 1-4 reinos enemigos

var resources = {"gold":300,"stone":200,"food":200,"wood":200,"copper":50,"bronze":0,"diamond":0,"leather":0}

var heroes = [
	{"id":"hero_sol","name":"Guerrero Sol","hp":1500,"atk":70,"def":55,"speed":1.0,"range":30,"rarity":"Comun","color":Color(1,0.7,0.1),"skill_name":"Golpe Solar","skill_desc":"Golpe devastador 180%","skill_dmg":1.8,"passive_name":"Escudo de Sol","passive_desc":"20% reduccion de dano"},
	{"id":"hero_chaman","name":"Chaman del Sol","hp":900,"atk":85,"def":25,"speed":0.8,"range":120,"rarity":"Raro","color":Color(0.3,0.5,1.0),"skill_name":"Rayo Solar","skill_desc":"Ataca TODOS los enemigos 120%","skill_dmg":1.2,"passive_name":"Sabiduria","passive_desc":"+10% ataque aliados"},
	{"id":"hero_guardiana","name":"Guardiana Dorada","hp":2000,"atk":45,"def":75,"speed":0.7,"range":25,"rarity":"Comun","color":Color(0.9,0.8,0.2),"skill_name":"Muro Dorado","skill_desc":"Escudo protege a todos 3s","skill_dmg":0.0,"passive_name":"Fortaleza","passive_desc":"+15% HP equipo"},
	{"id":"hero_aguila","name":"Aguila Guerrera","hp":1100,"atk":110,"def":30,"speed":1.8,"range":40,"rarity":"Epico","color":Color(0.2,0.9,0.6),"skill_name":"Rafaga de Plumas","skill_desc":"3 golpes al azar 150%","skill_dmg":1.5,"passive_name":"Garra Veloz","passive_desc":"20% doble ataque"},
	{"id":"hero_luna","name":"Sacerdotisa Lunar","hp":750,"atk":35,"def":18,"speed":0.6,"range":130,"rarity":"Raro","color":Color(0.8,0.4,1.0),"skill_name":"Plegaria Lunar","skill_desc":"Cura 25% HP a todos","skill_dmg":0.0,"passive_name":"Luz Sanadora","passive_desc":"Cura 5% HP cada 5s"},
]

var unit_defs = {
	"warrior":{"name":"Guerrero","hp":300,"atk":35,"def":20,"speed":1.0,"range":30,"cost":{"gold":50,"food":25},"class":"infantry","color":Color(0.7,0.4,0.2)},
	"archer":{"name":"Arquero","hp":150,"atk":42,"def":8,"speed":1.4,"range":120,"cost":{"gold":80,"food":15,"wood":30},"class":"archer","color":Color(0.3,0.6,0.3)},
	"cavalry":{"name":"Jinete","hp":400,"atk":48,"def":25,"speed":0.9,"range":25,"cost":{"gold":120,"food":40},"class":"cavalry","color":Color(0.8,0.5,0.2)},
	"villager":{"name":"Aldeano","hp":100,"atk":8,"def":3,"speed":1.2,"range":20,"cost":{"food":50},"class":"villager","color":Color(0.6,0.4,0.3)},
	"artisan":{"name":"Artesano","hp":80,"atk":5,"def":2,"speed":0.8,"range":15,"cost":{"gold":100,"food":20},"class":"artisan","color":Color(0.7,0.6,0.2)},
	"archer_long":{"name":"Arquero Largo","hp":130,"atk":50,"def":6,"speed":1.2,"range":180,"cost":{"gold":120,"food":20,"wood":50},"class":"archer","color":Color(0.2,0.5,0.3)},
	"cavalry_heavy":{"name":"Jinete Pesado","hp":550,"atk":60,"def":35,"speed":0.7,"range":25,"cost":{"gold":200,"food":60},"class":"cavalry","color":Color(0.9,0.4,0.1)},
	"infantry_sword":{"name":"Espadachin","hp":350,"atk":45,"def":25,"speed":0.9,"range":30,"cost":{"gold":100,"food":35},"class":"infantry","color":Color(0.5,0.5,0.7)},
	"siege_ram":{"name":"Ariete","hp":600,"atk":80,"def":30,"speed":0.4,"range":20,"cost":{"gold":200,"wood":150,"stone":50},"class":"siege","color":Color(0.5,0.3,0.1)},
	"siege_catapult":{"name":"Catapulta","hp":400,"atk":100,"def":15,"speed":0.3,"range":200,"cost":{"gold":300,"wood":200,"stone":100},"class":"siege","color":Color(0.4,0.25,0.1)},
	"ship":{"name":"Barco","hp":500,"atk":30,"def":20,"speed":1.5,"range":50,"cost":{"gold":150,"wood":200},"class":"naval","color":Color(0.3,0.4,0.6)},
}

var building_defs = {
	"wall":{"name":"Muro","hp":2000,"cost":{"stone":10},"size":Vector2(40,20)},
	"gate":{"name":"Puerta","hp":1500,"cost":{"stone":15,"wood":10},"size":Vector2(40,20)},
	"house":{"name":"Casa","hp":800,"cost":{"wood":50,"stone":20},"size":Vector2(40,40)},
	"barracks":{"name":"Cuartel","hp":1500,"cost":{"gold":100,"wood":100},"size":Vector2(50,45)},
	"archery":{"name":"Arqueria","hp":1200,"cost":{"gold":120,"wood":80,"stone":50},"size":Vector2(45,42)},
	"stable":{"name":"Caballeriza","hp":1800,"cost":{"gold":150,"wood":60,"stone":30},"size":Vector2(55,45)},
	"siege":{"name":"Taller Asedio","hp":2000,"cost":{"gold":200,"wood":100,"stone":100},"size":Vector2(50,45)},
	"tower_arrow":{"name":"Torre Flechas","hp":2500,"cost":{"gold":80,"stone":100,"wood":40},"size":Vector2(40,40)},
	"tower_stone":{"name":"Torre Piedra","hp":3500,"cost":{"gold":150,"stone":200,"wood":60},"size":Vector2(50,50)},
	"castle_defense":{"name":"Castillo Defensa","hp":4000,"cost":{"gold":300,"stone":300,"wood":100},"size":Vector2(70,70)},
	"market":{"name":"Mercado","hp":800,"cost":{"gold":120,"wood":80},"size":Vector2(50,45)},
	"church":{"name":"Iglesia","hp":1200,"cost":{"gold":100,"stone":80,"wood":50},"size":Vector2(55,50)},
	"forge":{"name":"Forja","hp":1000,"cost":{"gold":80,"stone":50,"wood":60},"size":Vector2(50,40)},
	"mill":{"name":"Molino","hp":900,"cost":{"gold":60,"wood":80,"stone":30},"size":Vector2(45,40)},
	"shipyard":{"name":"Astillero","hp":1500,"cost":{"gold":200,"wood":300,"stone":50},"size":Vector2(60,45)},
}

var save_slots = {}
var army_counts = {}

func get_hero(id):
	if id>=0 and id<heroes.size(): return heroes[id]
	return heroes[0]
