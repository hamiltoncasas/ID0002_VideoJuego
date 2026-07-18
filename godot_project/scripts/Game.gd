extends Control

const WORLD_W = 4000; const WORLD_H = 4000
var cam = Vector2(640, 360)
var cam_speed = 400.0
var zoom = 1.0
var entities = []
var buildings = []
var resources = []
var selected = []
var paused = false
var show_menu = false
var game_res = {"gold": 200, "stone": 100, "food": 150, "wood": 150, "copper": 0, "bronze": 0, "diamond": 0, "leather": 0}

@onready var world = $World
@onready var ents = $World/Entities
@onready var builds = $World/Buildings
@onready var resc = $World/Resources
@onready var ui = $UI

var rng = RandomNumberGenerator.new()

func _ready():
	_gen_terrain()
	_gen_resources()
	_spawn_start()
	_build_hud()
	_gen_minimap()

func _gen_terrain():
	var g = ColorRect.new()
	g.size = Vector2(WORLD_W, WORLD_H); g.color = Color(0.15, 0.3, 0.1)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(g)
	for x in range(0, WORLD_W, 96):
		var l = ColorRect.new()
		l.size = Vector2(1, WORLD_H); l.position = Vector2(x, 0)
		l.color = Color(0.1, 0.25, 0.08, 0.15); l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world.add_child(l)
	for y in range(0, WORLD_H, 96):
		var l = ColorRect.new()
		l.size = Vector2(WORLD_W, 1); l.position = Vector2(0, y)
		l.color = Color(0.1, 0.25, 0.08, 0.15); l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world.add_child(l)
	for i in range(30):
		var p = ColorRect.new()
		p.size = Vector2(80 + rng.randi() % 150, 60 + rng.randi() % 120)
		p.position = Vector2(rng.randi() % (WORLD_W - 200), rng.randi() % (WORLD_H - 150))
		p.color = Color(0.18, 0.35, 0.12, 0.12); p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world.add_child(p)
	var lake = ColorRect.new()
	lake.size = Vector2(300, 200); lake.position = Vector2(2800, 1200)
	lake.color = Color(0.2, 0.4, 0.6, 0.4); lake.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(lake)

func _gen_resources():
	var defs = [
		["tree", 80, Color(0.1, 0.5, 0.1), "tree", 50],
		["gold", 6, Color(1, 0.8, 0.1), "diamond", 300],
		["stone", 8, Color(0.5, 0.5, 0.5), "stone", 200],
		["deer", 5, Color(0.6, 0.4, 0.2), "deer", 30],
	]
	var icons = {"tree": "tree", "gold": "diamond", "stone": "stone_cube", "deer": "deer"}
	for d in defs:
		for i in range(d[1]):
			var pos = Vector2(100 + rng.randi() % (WORLD_W - 200), 100 + rng.randi() % (WORLD_H - 200))
			var r = ColorRect.new()
			r.size = Vector2(18, 18); r.position = pos; r.color = d[2]
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			world.add_child(r)
			var l = Label.new()
			l.text = _res_icon(d[0]); l.add_theme_font_size_override("font_size", 14)
			l.position = pos - Vector2(6, 16); l.size = Vector2(30, 30)
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			world.add_child(l)
			resources.append({"type": d[0], "pos": pos, "amount": d[4] + rng.randi() % 50, "node": r, "icon": l})

func _res_icon(type):
	match type:
		"tree": return "🌲"
		"gold": return "💎"
		"stone": return "🪨"
		"deer": return "🦌"
	return "❓"

func _spawn_start():
	var cp = Vector2(400, WORLD_H / 2 - 40)
	_make_building("castle", cp)
	_make_entity("hero", cp + Vector2(-50, 40), Color(1, 0.7, 0.1), "hero", 1500, 70, 55)
	_make_entity("villager", cp + Vector2(-100, -60), Color(0.6, 0.4, 0.3), "villager", 100, 8, 3)
	_make_entity("villager", cp + Vector2(-100, 80), Color(0.6, 0.4, 0.3), "villager", 100, 8, 3)
	_make_entity("artisan", cp + Vector2(-80, 10), Color(0.7, 0.6, 0.2), "artisan", 80, 5, 2)
	_make_entity("warrior", cp + Vector2(100, -80), Color(0.7, 0.4, 0.2), "warrior", 300, 35, 20)
	_make_entity("archer", cp + Vector2(100, 0), Color(0.3, 0.6, 0.3), "archer", 150, 42, 8)
	_make_entity("cavalry", cp + Vector2(100, 80), Color(0.8, 0.5, 0.2), "cavalry", 400, 48, 25)

func _icon_char(type):
	match type:
		"hero": return "🦸"
		"villager": return "👷"
		"artisan": return "🔧"
		"warrior": return "⚔️"
		"archer": return "🏹"
		"cavalry": return "🐎"
	return "❓"

func _make_entity(type, pos, color, icon_text, hp_val, atk, def_val):
	var r = ColorRect.new()
	r.size = Vector2(14, 18); r.position = pos; r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ents.add_child(r)
	var l = Label.new()
	l.text = _icon_char(type); l.add_theme_font_size_override("font_size", 16)
	l.position = pos - Vector2(7, 20); l.size = Vector2(28, 28)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ents.add_child(l)
	entities.append({"type": type, "node": r, "icon": l, "pos": pos, "hp": hp_val, "max_hp": hp_val, "atk": atk, "def": def_val, "sel": false, "target": null, "moving": false, "move_to": pos, "task": "idle"})

func _make_building(type, pos):
	var bcolors = {"castle": Color(0.4, 0.25, 0.1), "wall": Color(0.4, 0.35, 0.25), "tower_arrow": Color(0.5, 0.3, 0.2)}
	var bicons = {"castle": "castle", "wall": "wall", "tower_arrow": "tower_arrow"}
	var bsizes = {"castle": Vector2(80, 80), "wall": Vector2(40, 16), "tower_arrow": Vector2(40, 40)}
	var bhp = {"castle": 5000, "wall": 2000, "tower_arrow": 2500}
	
	var r = ColorRect.new()
	r.size = bsizes.get(type, Vector2(50, 50)); r.position = pos; r.color = bcolors.get(type, Color(0.3, 0.2, 0.1))
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(r)
	var lbl = Label.new()
	lbl.text = _building_icon(type); lbl.add_theme_font_size_override("font_size", 22)
	lbl.position = pos + Vector2(10, 10); lbl.size = Vector2(50, 40)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(lbl)
	buildings.append({"type": type, "node": r, "icon": lbl, "pos": pos, "hp": bhp.get(type, 1000), "max_hp": bhp.get(type, 1000)})

func _building_icon(type):
	match type:
		"castle": return "🏰"
		"wall": return "🧱"
		"tower_arrow": return "🗼"
	return "🏗️"

func _build_hud():
	var bar = ColorRect.new()
	bar.size = Vector2(1280, 34); bar.color = Color(0, 0, 0, 0.85)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(bar)
	
	var keys = ["gold", "stone", "food", "wood", "copper", "bronze", "diamond", "leather"]
	var icons = ["gold", "stone", "food", "wood", "copper", "bronze", "diamond", "leather"]
	for i in range(8):
		var l = Label.new()
		l.name = "RC" + str(i)
		l.text = _res_short(keys[i]) + " " + keys[i].capitalize() + ": " + str(game_res[keys[i]])
		l.add_theme_font_size_override("font_size", 10)
		l.position = Vector2(15 + i * 155, 5); l.size = Vector2(150, 24)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(l)
	
	var mb = Button.new()
	mb.name = "MenuBtn"; mb.text = "MENU"
	mb.position = Vector2(1180, 3); mb.size = Vector2(90, 28)
	ui.add_child(mb); mb.pressed.connect(_toggle_menu)
	
	var ip = ColorRect.new()
	ip.name = "InfoPanel"; ip.size = Vector2(380, 80)
	ip.position = Vector2(450, 640); ip.color = Color(0, 0, 0, 0.75)
	ip.visible = false; ip.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(ip)
	
	var il = Label.new()
	il.name = "InfoLabel"
	il.position = Vector2(460, 645); il.size = Vector2(360, 40)
	il.add_theme_font_size_override("font_size", 11); il.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(il)
	
	for i in range(3):
		var b = Button.new()
		b.name = "Act" + str(i)
		b.position = Vector2(460 + i * 90, 685); b.size = Vector2(80, 30)
		b.visible = false; ui.add_child(b)

func _res_short(key):
	match key:
		"gold": return "🪙"
		"stone": return "🪨"
		"food": return "🌾"
		"wood": return "🪵"
		"copper": return "🟤"
		"bronze": return "🔶"
		"diamond": return "💎"
		"leather": return "👜"
	return "❓"

func _gen_minimap():
	var bg = ColorRect.new()
	bg.name = "MMBg"; bg.size = Vector2(164, 164)
	bg.position = Vector2(1280 - 174, 720 - 174); bg.color = Color(0.05, 0.03, 0.08, 0.9)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(bg)
	
	var m = ColorRect.new()
	m.name = "MMap"; m.size = Vector2(160, 160)
	m.position = Vector2(1280 - 172, 720 - 172); m.color = Color(0.12, 0.22, 0.06)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(m)
	
	var cc = ColorRect.new()
	cc.name = "MMCam"; cc.size = Vector2(50, 30)
	cc.color = Color(1, 1, 1, 0.2); cc.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(cc)

func _process(delta):
	if show_menu: return
	
	var mv = Vector2()
	if Input.is_key_pressed(KEY_W): mv.y -= 1
	if Input.is_key_pressed(KEY_S): mv.y += 1
	if Input.is_key_pressed(KEY_A): mv.x -= 1
	if Input.is_key_pressed(KEY_D): mv.x += 1
	if Input.is_key_pressed(KEY_UP): mv.y -= 1
	if Input.is_key_pressed(KEY_DOWN): mv.y += 1
	if Input.is_key_pressed(KEY_LEFT): mv.x -= 1
	if Input.is_key_pressed(KEY_RIGHT): mv.x += 1
	
	var ms = get_global_mouse_position()
	if ms.x < 10: mv.x -= 1
	if ms.x > 1270: mv.x += 1
	if ms.y < 40: mv.y -= 1
	if ms.y > 710: mv.y += 1
	
	if mv.length() > 0:
		mv = mv.normalized() * cam_speed * delta
		cam += mv
		cam.x = clamp(cam.x, 320, WORLD_W - 320)
		cam.y = clamp(cam.y, 180, WORLD_H - 180)
	
	world.position = -cam + Vector2(640, 360)
	
	var mm = ui.get_node("MMCam")
	if mm:
		var sx = 160.0 / WORLD_W; var sy = 160.0 / WORLD_H
		mm.position = Vector2(1280 - 172 + cam.x * sx - 25, 720 - 172 + cam.y * sy - 15)
	
	var keys = ["gold", "stone", "food", "wood", "copper", "bronze", "diamond", "leather"]
	for i in range(8):
		var l = ui.get_node("RC" + str(i))
		if l: l.text = _res_short(keys[i]) + " " + keys[i].capitalize() + ": " + str(game_res[keys[i]])
	
	for e in entities:
		if not e["node"] or not is_instance_valid(e["node"]): continue
		
		if e["moving"]:
			var d = e["move_to"] - e["pos"]
			var dist = d.length()
			if dist < 8:
				e["moving"] = false; e["pos"] = e["move_to"]
			else:
				d = d.normalized()
				e["pos"] += d * 60 * delta
				e["node"].position = e["pos"]
				e["icon"].position = e["pos"] - Vector2(7, 20)
		
		if not e["moving"] and e["task"] == "idle":
			if e["type"] == "villager":
				_find_resource(e)
			elif e["type"] == "artisan":
				e["move_to"] = e["pos"] + Vector2(rng.randf() * 200 - 100, rng.randf() * 200 - 100)
				e["moving"] = true
			elif e["type"] in ["warrior", "archer", "cavalry"] and rng.randf() < 0.005:
				e["move_to"] = e["pos"] + Vector2(rng.randf() * 500 - 250, rng.randf() * 500 - 250)
				e["moving"] = true

func _find_resource(e):
	var nearest = null; var md = 99999.0
	for r in resources:
		if r["amount"] <= 0: continue
		var d = e["pos"].distance_to(r["pos"])
		if d < md: md = d; nearest = r
	if nearest and md < 600:
		e["task"] = "gathering"; e["target"] = nearest
		e["move_to"] = nearest["pos"]; e["moving"] = true

func _input(event):
	if show_menu: return
	if event is InputEventMouseButton and event.pressed:
		var wp = event.position + cam - Vector2(640, 360)
		if event.button_index == MOUSE_BUTTON_LEFT:
			_select_at(wp)
		elif event.button_index == MOUSE_BUTTON_RIGHT and selected.size() > 0:
			for e in selected:
				e["move_to"] = wp; e["moving"] = true; e["task"] = "idle"; e["target"] = null

func _select_at(wp):
	for e in entities: e["sel"] = false; e["icon"].modulate = Color(1, 1, 1)
	selected.clear()
	for e in entities:
		if e["pos"].distance_to(wp) < 30:
			e["sel"] = true; e["icon"].modulate = Color(1, 1, 0)
			selected.append(e); _show_info(e); return
	_hide_info()

func _show_info(e):
	var p = ui.get_node("InfoPanel"); var l = ui.get_node("InfoLabel")
	if p: p.visible = true
	if l: l.text = _icon_char(e["type"]) + " " + e["type"].capitalize() + " HP: " + str(e["hp"]) + "/" + str(e["max_hp"])
	for i in range(3):
		var b = ui.get_node("Act" + str(i))
		if b: b.visible = false
	if e["type"] == "villager":
		var b = ui.get_node("Act0")
		if b: b.visible = true; b.text = "Construir"

func _hide_info():
	var p = ui.get_node("InfoPanel")
	if p: p.visible = false

func _toggle_menu():
	show_menu = !show_menu
	if show_menu: _show_menu()
	else: _hide_menu()

func _show_menu():
	var o = ColorRect.new()
	o.name = "MenuO"; o.size = Vector2(1280, 720); o.color = Color(0, 0, 0, 0.7)
	ui.add_child(o)
	var t = Label.new()
	t.text = "MENU DEL JUEGO"; t.add_theme_font_size_override("font_size", 24)
	t.position = Vector2(440, 150); t.size = Vector2(400, 40)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; o.add_child(t)
	var items = [["REANUDAR", "_resume"], ["REINICIAR", "_restart"], ["GUARDAR", "_save"], ["MENU PRINCIPAL", "_main_menu"]]
	for i in range(items.size()):
		var b = Button.new()
		b.text = items[i][0]; b.position = Vector2(490, 220 + i * 60); b.size = Vector2(300, 45)
		o.add_child(b); b.pressed.connect(Callable(self, items[i][1]))

func _hide_menu():
	var o = ui.get_node_or_null("MenuO")
	if o: o.queue_free(); show_menu = false

func _resume(): _hide_menu()
func _restart(): get_tree().reload_current_scene()

func _save():
	for i in range(5):
		if not FileAccess.file_exists("user://save_" + str(i) + ".json"):
			_do_save(i); return
	_do_save(0)

func _do_save(slot):
	var data = {"timestamp": Time.get_datetime_string_from_system(), "resources": game_res, "player": Globals.player_name, "entities": [], "buildings": []}
	for e in entities: data["entities"].append({"type": e["type"], "x": e["pos"].x, "y": e["pos"].y, "hp": e["hp"]})
	for b in buildings: data["buildings"].append({"type": b["type"], "x": b["pos"].x, "y": b["pos"].y, "hp": b["hp"]})
	var f = FileAccess.open("user://save_" + str(slot) + ".json", FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(data)); f.close(); _notify("Guardado en slot " + str(slot + 1))

func _main_menu():
	get_tree().change_scene_to_file("res://scenes/ModeSelect.tscn")

func _notify(txt):
	var n = Label.new()
	n.text = txt; n.add_theme_font_size_override("font_size", 16)
	n.position = Vector2(440, 350); n.size = Vector2(400, 30)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; n.modulate = Color(1, 0.85, 0.3)
	ui.add_child(n)
	create_tween().tween_property(n, "modulate:a", 0.0, 2.0).set_delay(1.0)
	create_tween().tween_callback(n.queue_free).set_delay(3.0)
