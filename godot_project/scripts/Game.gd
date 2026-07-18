extends Control

# ─── WORLD ───
const WORLD_W = 4000; const WORLD_H = 4000
var cam = Vector2(640, 360)
var cam_speed = 400.0
var entities = []
var buildings = []
var res_nodes = []
var selected = []
var show_menu = false
var game_res = {"gold": 200, "stone": 100, "food": 150, "wood": 150, "copper": 0, "bronze": 0, "diamond": 0, "leather": 0}

@onready var world = $World
@onready var ents_node = $World/Entities
@onready var builds_node = $World/Buildings
@onready var res_node = $World/Resources
@onready var ui = $UI

var rng = RandomNumberGenerator.new()

func _ready():
	RenderingServer.set_default_clear_color(Color(0.1, 0.22, 0.08))
	_generate_terrain()
	_generate_resources()
	_spawn_entities()
	_build_ui()
	_build_minimap()

# ─── TERRAIN ───
func _generate_terrain():
	# Base grass with gradient-like layers
	for i in 3:
		var layer = ColorRect.new()
		layer.size = Vector2(WORLD_W, WORLD_H)
		layer.color = Color(0.12 + i * 0.03, 0.28 + i * 0.04, 0.08 + i * 0.02, 0.4)
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world.add_child(layer)
	
	# Grid
	for x in range(0, WORLD_W, 64):
		var l = ColorRect.new()
		l.size = Vector2(1, WORLD_H); l.position = Vector2(x, 0)
		l.color = Color(0.08, 0.2, 0.06, 0.12); l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world.add_child(l)
	for y in range(0, WORLD_H, 64):
		var l = ColorRect.new()
		l.size = Vector2(WORLD_W, 1); l.position = Vector2(0, y)
		l.color = Color(0.08, 0.2, 0.06, 0.12); l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world.add_child(l)
	
	# Terrain patches
	var pat_colors = [Color(0.2, 0.38, 0.12, 0.1), Color(0.25, 0.35, 0.15, 0.08), Color(0.15, 0.4, 0.1, 0.06)]
	for i in 40:
		var p = ColorRect.new()
		p.size = Vector2(60 + rng.randi() % 200, 50 + rng.randi() % 160)
		p.position = Vector2(rng.randi() % (WORLD_W - 200), rng.randi() % (WORLD_H - 150))
		p.color = pat_colors[i % pat_colors.size()]
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world.add_child(p)
	
	# Dirt paths
	for i in range(5):
		var path = ColorRect.new()
		path.size = Vector2(40 + rng.randi() % 60, 800 + rng.randi() % 600)
		path.position = Vector2(rng.randi() % (WORLD_W - 100), rng.randi() % (WORLD_H - 600))
		path.color = Color(0.3, 0.22, 0.12, 0.12)
		path.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world.add_child(path)
	
	# Lake
	var lake = ColorRect.new()
	lake.size = Vector2(350, 250); lake.position = Vector2(2800, 1100)
	lake.color = Color(0.15, 0.35, 0.55, 0.45)
	lake.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(lake)
	# Lake border
	var lb = ColorRect.new()
	lb.size = Vector2(380, 280); lb.position = Vector2(2785, 1085)
	lb.color = Color(0.2, 0.4, 0.5, 0.15)
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(lb)

	# Decorative grass tufts
	for i in 60:
		var g = Label.new()
		var items = ["🌿", "🌱", "🌾", "🍃"]
		g.text = items[i % items.size()]
		g.add_theme_font_size_override("font_size", 8 + rng.randi() % 8)
		g.position = Vector2(rng.randi() % WORLD_W, rng.randi() % WORLD_H)
		g.modulate = Color(1, 1, 1, 0.08 + rng.randf() * 0.08)
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world.add_child(g)

func _generate_resources():
	var defs = [
		["tree", 60, Color(0.08, 0.4, 0.08), "🌲", 50],
		["gold", 5, Color(0.9, 0.7, 0.1), "🪨", 300],
		["stone", 6, Color(0.5, 0.5, 0.5), "🪨", 200],
		["deer", 4, Color(0.55, 0.35, 0.2), "🦌", 30],
	]
	for d in defs:
		for i in range(d[1]):
			var pos = Vector2(100 + rng.randi() % (WORLD_W - 200), 100 + rng.randi() % (WORLD_H - 200))
			var r = ColorRect.new()
			r.size = Vector2(22, 22); r.position = pos - Vector2(2, 2)
			r.color = d[2]; r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			world.add_child(r)
			var l = Label.new()
			l.text = d[3]; l.add_theme_font_size_override("font_size", 18)
			l.position = pos - Vector2(9, 18); l.size = Vector2(36, 36)
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			world.add_child(l)
			res_nodes.append({"type": d[0], "pos": pos, "amount": d[4] + rng.randi() % 30, "node": r})

func _spawn_entities():
	var cp = Vector2(400, WORLD_H / 2 - 40)
	_make_building("castle", cp)
	_make_entity("hero", cp + Vector2(-60, 40), "🦸", Color(1, 0.7, 0.1), 1500, 70)
	_make_entity("villager", cp + Vector2(-110, -70), "👷", Color(0.6, 0.4, 0.3), 100, 8)
	_make_entity("villager", cp + Vector2(-110, 90), "👷", Color(0.6, 0.4, 0.3), 100, 8)
	_make_entity("artisan", cp + Vector2(-90, 10), "🔧", Color(0.7, 0.6, 0.2), 80, 5)
	_make_entity("warrior", cp + Vector2(100, -90), "⚔️", Color(0.7, 0.4, 0.2), 300, 35)
	_make_entity("archer", cp + Vector2(100, 0), "🏹", Color(0.3, 0.6, 0.3), 150, 42)
	_make_entity("cavalry", cp + Vector2(100, 90), "🐎", Color(0.8, 0.5, 0.2), 400, 48)

func _make_entity(type, pos, icon, color, hp, atk):
	var container = Node2D.new()
	container.position = pos
	ents_node.add_child(container)
	
	var body = ColorRect.new()
	body.size = Vector2(18, 22); body.position = Vector2(-9, -11)
	body.color = color; body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(body)
	
	var hp_bg = ColorRect.new()
	hp_bg.size = Vector2(22, 3); hp_bg.position = Vector2(-11, -15)
	hp_bg.color = Color(0.2, 0.05, 0.05, 0.6); hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bg.name = "hp_bg"; container.add_child(hp_bg)
	
	var hp_fill = ColorRect.new()
	hp_fill.size = Vector2(22, 3); hp_fill.position = Vector2(-11, -15)
	hp_fill.color = Color(0.2, 0.8, 0.2, 0.9); hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_fill.name = "hp_fill"; container.add_child(hp_fill)
	
	var label = Label.new()
	label.text = icon; label.add_theme_font_size_override("font_size", 18)
	label.position = Vector2(-9, -10); label.size = Vector2(28, 28)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE; label.name = "icon"
	container.add_child(label)
	
	# Selection ring
	var sel = ColorRect.new()
	sel.size = Vector2(30, 34); sel.position = Vector2(-15, -17)
	sel.color = Color(0, 0, 0, 0); sel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sel.name = "sel"; container.add_child(sel)
	
	# Area2D for clicks
	var area = Area2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(30, 30)
	var col = CollisionShape2D.new()
	col.shape = shape
	area.add_child(col)
	container.add_child(area)
	
	entities.append({
		"type": type, "node": container, "pos": pos, "target_pos": pos,
		"hp": hp, "max_hp": hp, "atk": atk, "moving": false, "task": "idle",
		"gather_target": null, "anim_time": rng.randf() * 100,
		"sel_ring": sel, "hp_fill": hp_fill, "label": label, "area": area
	})

func _make_building(type, pos):
	var bnode = Node2D.new()
	bnode.position = pos
	world.add_child(bnode)
	
	var body = ColorRect.new()
	var colors = {"castle": Color(0.45, 0.3, 0.15), "wall": Color(0.5, 0.4, 0.3), "tower_arrow": Color(0.5, 0.35, 0.2)}
	var sizes = {"castle": Vector2(80, 80), "wall": Vector2(40, 16), "tower_arrow": Vector2(40, 40)}
	var max_hp = {"castle": 5000, "wall": 2000, "tower_arrow": 2500}
	var icons = {"castle": "🏰", "wall": "🧱", "tower_arrow": "🗼"}
	
	body.size = sizes.get(type, Vector2(50, 50))
	body.position = -body.size / 2
	body.color = colors.get(type, Color(0.3, 0.2, 0.1))
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bnode.add_child(body)
	
	var lbl = Label.new()
	lbl.text = icons.get(type, "🏗️")
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.position = Vector2(-15, -10); lbl.size = Vector2(40, 40)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bnode.add_child(lbl)
	
	buildings.append({"type": type, "node": bnode, "pos": pos, "hp": max_hp.get(type, 1000), "max_hp": max_hp.get(type, 1000)})

# ─── HUD ───
func _build_ui():
	var bar = ColorRect.new()
	bar.size = Vector2(1280, 34); bar.color = Color(0, 0, 0, 0.85)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(bar)
	
	var rkeys = ["gold", "stone", "food", "wood", "copper", "bronze", "diamond", "leather"]
	var ricons = ["🪙", "🪨", "🌾", "🪵", "🟤", "🔶", "💎", "👜"]
	for i in range(8):
		var l = Label.new()
		l.name = "RC" + str(i)
		l.text = ricons[i] + " " + rkeys[i].capitalize() + ": " + str(game_res[rkeys[i]])
		l.add_theme_font_size_override("font_size", 10)
		l.position = Vector2(15 + i * 155, 5); l.size = Vector2(150, 24)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(l)
	
	var mb = Button.new()
	mb.name = "MenuBtn"; mb.text = "☰ MENU"
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

func _build_minimap():
	var bg = ColorRect.new()
	bg.name = "MMBg"; bg.size = Vector2(164, 164)
	bg.position = Vector2(1280 - 174, 720 - 174); bg.color = Color(0.03, 0.02, 0.06, 0.95)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(bg)
	
	var m = ColorRect.new()
	m.name = "MMap"; m.size = Vector2(160, 160)
	m.position = Vector2(1280 - 172, 720 - 172); m.color = Color(0.1, 0.2, 0.06)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(m)
	
	var cc = ColorRect.new()
	cc.name = "MMCam"; cc.size = Vector2(50, 30)
	cc.color = Color(1, 1, 1, 0.15); cc.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(cc)

# ─── GAME LOOP ───
func _process(delta):
	if show_menu: return
	
	# Camera
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
	if ms.x < 15: mv.x -= 1
	if ms.x > 1265: mv.x += 1
	if ms.y < 40: mv.y -= 1
	if ms.y > 715: mv.y += 1
	
	if mv.length() > 0:
		mv = mv.normalized() * cam_speed * delta
		cam += mv
		cam.x = clamp(cam.x, 320, WORLD_W - 320)
		cam.y = clamp(cam.y, 180, WORLD_H - 180)
	
	world.position = -cam + Vector2(640, 360)
	
	# Minimap
	var mm = ui.get_node("MMCam")
	if mm:
		mm.position = Vector2(1280 - 172 + cam.x * 160.0 / WORLD_W - 25, 720 - 172 + cam.y * 160.0 / WORLD_H - 15)
	
	# Resource UI
	var rkeys = ["gold", "stone", "food", "wood", "copper", "bronze", "diamond", "leather"]
	var ricons = ["🪙", "🪨", "🌾", "🪵", "🟤", "🔶", "💎", "👜"]
	for i in range(8):
		var l = ui.get_node("RC" + str(i))
		if l: l.text = ricons[i] + " " + rkeys[i].capitalize() + ": " + str(game_res[rkeys[i]])
	
	# Update entities
	for e in entities:
		if not is_instance_valid(e["node"]): continue
		e["anim_time"] += delta
		
		# Movement
		if e["moving"]:
			var d = e["target_pos"] - e["pos"]
			var dist = d.length()
			if dist < 5:
				e["moving"] = false; e["pos"] = e["target_pos"]
			else:
				d = d.normalized()
				e["pos"] += d * 80 * delta
				e["node"].position = e["pos"]
				# Bob animation while moving
				var bob = sin(e["anim_time"] * 10) * 1.5
				e["node"].position.y += bob
		
		# Idle breathing
		if not e["moving"] and e["task"] == "idle":
			var breathe = sin(e["anim_time"] * 2) * 0.8
			e["node"].position.y = e["pos"].y + breathe
			
			# AI
			if e["type"] == "villager":
				_ai_villager(e)
			elif e["type"] == "artisan" and rng.randf() < 0.01:
				e["target_pos"] = e["pos"] + Vector2(rng.randf() * 300 - 150, rng.randf() * 300 - 150)
				e["moving"] = true
			elif e["type"] in ["warrior", "archer", "cavalry"] and rng.randf() < 0.003:
				e["target_pos"] = e["pos"] + Vector2(rng.randf() * 400 - 200, rng.randf() * 400 - 200)
				e["moving"] = true
		
		# Selection pulse
		if e.get("sel", false):
			var pulse = 0.15 + sin(e["anim_time"] * 3) * 0.1
			e["sel_ring"].color = Color(1, 1, 0, pulse)
		else:
			e["sel_ring"].color = Color(0, 0, 0, 0)

func _ai_villager(e):
	var nearest = null; var md = 99999.0
	for r in res_nodes:
		if r["amount"] <= 0: continue
		var d = e["pos"].distance_to(r["pos"])
		if d < md: md = d; nearest = r
	if nearest and md < 500:
		e["task"] = "gathering"
		e["gather_target"] = nearest
		e["target_pos"] = nearest["pos"]
		e["moving"] = true

func _input(event):
	if show_menu: return
	if event is InputEventMouseButton and event.pressed:
		var wp = event.position + cam - Vector2(640, 360)
		if event.button_index == MOUSE_BUTTON_LEFT:
			_select_at(wp)
		elif event.button_index == MOUSE_BUTTON_RIGHT and selected.size() > 0:
			for e in selected:
				e["target_pos"] = wp; e["moving"] = true; e["task"] = "idle"; e["gather_target"] = null

func _select_at(wp):
	for e in entities:
		e["sel"] = false
	selected.clear()
	
	# Check clicks on entity areas
	for e in entities:
		if not is_instance_valid(e["node"]): continue
		var dist = e["pos"].distance_to(wp)
		if dist < 25:
			e["sel"] = true; selected.append(e); _show_info(e); return
	_hide_info()

func _show_info(e):
	var p = ui.get_node("InfoPanel"); var l = ui.get_node("InfoLabel")
	if p: p.visible = true
	if l: l.text = _get_name(e["type"]) + " HP: " + str(e["hp"]) + "/" + str(e["max_hp"])
	for i in range(3):
		var b = ui.get_node("Act" + str(i))
		if b: b.visible = false
	if e["type"] == "villager":
		var b = ui.get_node("Act0")
		if b: b.visible = true; b.text = "🏗️ Construir"

func _get_name(type):
	match type:
		"hero": return "Heroe"
		"villager": return "Aldeano"
		"artisan": return "Artesano"
		"warrior": return "Guerrero"
		"archer": return "Arquero"
		"cavalry": return "Jinete"
	return type

func _hide_info():
	var p = ui.get_node("InfoPanel")
	if p: p.visible = false

# ─── MENU ───
func _toggle_menu():
	show_menu = !show_menu
	if show_menu: _show_menu()
	else: _hide_menu()

func _show_menu():
	var o = ColorRect.new()
	o.name = "MenuO"; o.size = Vector2(1280, 720); o.color = Color(0, 0, 0, 0.75)
	ui.add_child(o)
	var t = Label.new()
	t.text = "☰ MENU DEL JUEGO"; t.add_theme_font_size_override("font_size", 24)
	t.position = Vector2(440, 150); t.size = Vector2(400, 40)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; o.add_child(t)
	var items = [["▶ REANUDAR", "_resume"], ["🔄 REINICIAR", "_restart"], ["💾 GUARDAR", "_save"], ["🏠 MENU PRINCIPAL", "_main_menu"]]
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
	if f: f.store_string(JSON.stringify(data)); f.close(); _notify("💾 Guardado en slot " + str(slot + 1))

func _main_menu(): get_tree().change_scene_to_file("res://scenes/ModeSelect.tscn")

func _notify(txt):
	var n = Label.new()
	n.text = txt; n.add_theme_font_size_override("font_size", 16)
	n.position = Vector2(440, 350); n.size = Vector2(400, 30)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; n.modulate = Color(1, 0.85, 0.3)
	ui.add_child(n)
	create_tween().tween_property(n, "modulate:a", 0.0, 2.0).set_delay(1.0)
	create_tween().tween_callback(n.queue_free).set_delay(3.0)
