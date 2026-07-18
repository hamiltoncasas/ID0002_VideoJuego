extends Control

# ─── WORLD ───
const WORLD_W = 4000; const WORLD_H = 4000
var cam = Vector2(640, 360)
var cam_target = Vector2(640, 360)
var cam_speed = 300.0
var entities = []
var buildings = []
var res_nodes = []
var selected = []
var show_menu = false
var build_mode = false
var build_queue = []

var game_res = {"gold": 200, "stone": 100, "food": 150, "wood": 150, "copper": 0, "bronze": 0, "diamond": 0, "leather": 0}

@onready var world = $World
@onready var ents_node = $World/Entities
@onready var builds_node = $World/Buildings
@onready var res_node = $World/Resources
@onready var ui = $UI

var rng = RandomNumberGenerator.new()
var hero_data = {}

func _ready():
	hero_data = Globals.get_hero(Globals.selected_hero_id)
	RenderingServer.set_default_clear_color(Color(0.08, 0.18, 0.06))
	_gen_terrain()
	_gen_resources()
	_gen_buildings()
	_spawn_units()
	_build_hud()
	_build_minimap()

# ═══════════════════════════════════════════════
#  TERRAIN
# ═══════════════════════════════════════════════
func _gen_terrain():
	for i in 3:
		var l = ColorRect.new()
		l.size = Vector2(WORLD_W, WORLD_H)
		l.color = Color(0.1 + i * 0.03, 0.25 + i * 0.04, 0.07 + i * 0.02, 0.35)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(l)
	
	for x in range(0, WORLD_W, 64):
		var l = ColorRect.new()
		l.size = Vector2(1, WORLD_H); l.position = Vector2(x, 0)
		l.color = Color(0.06, 0.18, 0.05, 0.08); l.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(l)
	for y in range(0, WORLD_H, 64):
		var l = ColorRect.new()
		l.size = Vector2(WORLD_W, 1); l.position = Vector2(0, y)
		l.color = Color(0.06, 0.18, 0.05, 0.08); l.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(l)
	
	for i in 35:
		var p = ColorRect.new()
		p.size = Vector2(50 + rng.randi() % 180, 40 + rng.randi() % 140)
		p.position = Vector2(rng.randi() % (WORLD_W - 200), rng.randi() % (WORLD_H - 150))
		p.color = Color(0.18, 0.32, 0.1, 0.1); p.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(p)
	
	for i in 4:
		var path = ColorRect.new()
		path.size = Vector2(30 + rng.randi() % 50, 600 + rng.randi() % 500)
		path.position = Vector2(rng.randi() % (WORLD_W - 80), rng.randi() % (WORLD_H - 500))
		path.color = Color(0.28, 0.2, 0.1, 0.1); path.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(path)
	
	var lake = ColorRect.new()
	lake.size = Vector2(350, 250); lake.position = Vector2(2800, 1100)
	lake.color = Color(0.12, 0.3, 0.5, 0.4); lake.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(lake)
	
	var lb = ColorRect.new()
	lb.size = Vector2(380, 280); lb.position = Vector2(2785, 1085)
	lb.color = Color(0.18, 0.35, 0.45, 0.12); lb.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(lb)
	
	for i in 50:
		var g = Label.new()
		g.text = ["🌿", "🌱", "🌾", "🍃"][i % 4]
		g.add_theme_font_size_override("font_size", 6 + rng.randi() % 6)
		g.position = Vector2(rng.randi() % WORLD_W, rng.randi() % WORLD_H)
		g.modulate = Color(1, 1, 1, 0.06 + rng.randf() * 0.06)
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(g)

func _gen_resources():
	var defs = [
		["tree", 50, Color(0.06, 0.35, 0.06), "🌲", 50],
		["gold", 5, Color(0.85, 0.65, 0.08), "💎", 300],
		["stone", 6, Color(0.45, 0.45, 0.45), "🪨", 200],
		["deer", 4, Color(0.5, 0.3, 0.18), "🦌", 30],
	]
	for d in defs:
		for i in range(d[1]):
			var pos = Vector2(100 + rng.randi() % (WORLD_W - 200), 100 + rng.randi() % (WORLD_H - 200))
			var r = ColorRect.new()
			r.size = Vector2(20, 20); r.position = pos - Vector2(1, 1)
			r.color = d[2]; r.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(r)
			var l = Label.new()
			l.text = d[3]; l.add_theme_font_size_override("font_size", 16)
			l.position = pos - Vector2(8, 16); l.size = Vector2(32, 32)
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(l)
			res_nodes.append({"type": d[0], "pos": pos, "amount": d[4] + rng.randi() % 30, "node": r})

# ═══════════════════════════════════════════════
#  BUILDINGS
# ═══════════════════════════════════════════════
func _gen_buildings():
	var cp = Vector2(400, WORLD_H / 2 - 40)
	_make_building("castle", cp)
	_make_building("barracks", cp + Vector2(-160, -120))
	_make_building("archery", cp + Vector2(-160, 120))

func _make_building(type, pos):
	var colors = {"castle": Color(0.5, 0.3, 0.15), "barracks": Color(0.5, 0.2, 0.1), "archery": Color(0.4, 0.25, 0.1), "stable": Color(0.45, 0.3, 0.12), "siege": Color(0.4, 0.35, 0.2)}
	var icons = {"castle": "🏰", "barracks": "⚔️", "archery": "🏹", "stable": "🐎", "siege": "💣"}
	var sizes = {"castle": Vector2(80, 80), "barracks": Vector2(50, 40), "archery": Vector2(45, 40), "stable": Vector2(55, 40), "siege": Vector2(50, 45)}
	var max_hp = {"castle": 5000, "barracks": 1500, "archery": 1200, "stable": 1800, "siege": 2000}
	
	var bnode = Node2D.new(); bnode.position = pos; world.add_child(bnode)
	
	var body = ColorRect.new()
	body.size = sizes.get(type, Vector2(50, 50)); body.position = -body.size / 2
	body.color = colors.get(type, Color(0.3, 0.2, 0.1))
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE; bnode.add_child(body)
	
	var lbl = Label.new()
	lbl.text = icons.get(type, "🏗"); lbl.add_theme_font_size_override("font_size", 22)
	lbl.position = Vector2(-15, -12); lbl.size = Vector2(40, 40)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE; bnode.add_child(lbl)
	
	var hp_bg = ColorRect.new()
	hp_bg.size = Vector2(body.size.x + 4, 4); hp_bg.position = Vector2(-body.size.x/2 - 2, -body.size.y/2 - 6)
	hp_bg.color = Color(0.2, 0.05, 0.05, 0.6); hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE; hp_bg.name = "hp_bg"; bnode.add_child(hp_bg)
	
	var hp_fill = ColorRect.new()
	hp_fill.size = Vector2(body.size.x + 4, 4); hp_fill.position = Vector2(-body.size.x/2 - 2, -body.size.y/2 - 6)
	hp_fill.color = Color(0.2, 0.8, 0.2, 0.9); hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE; hp_fill.name = "hp_fill"; bnode.add_child(hp_fill)
	
	var hp_txt = Label.new()
	hp_txt.name = "hp_txt"; hp_txt.add_theme_font_size_override("font_size", 7)
	hp_txt.position = Vector2(-body.size.x/2 - 2, -body.size.y/2 - 18); hp_txt.size = Vector2(body.size.x + 4, 10)
	hp_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hp_txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bnode.add_child(hp_txt)
	
	buildings.append({"type": type, "node": bnode, "pos": pos, "hp": max_hp.get(type, 1000), "max_hp": max_hp.get(type, 1000)})

# ═══════════════════════════════════════════════
#  UNITS
# ═══════════════════════════════════════════════
func _spawn_units():
	var cp = Vector2(400, WORLD_H / 2 - 40)
	# Hero from selection
	_make_entity("hero", cp + Vector2(-60, 40), "🦸", hero_data["color"], hero_data["hp"], hero_data["atk"])
	_make_entity("villager", cp + Vector2(-120, -80), "👷", Color(0.6, 0.4, 0.3), 100, 8)
	_make_entity("villager", cp + Vector2(-120, 100), "👷", Color(0.6, 0.4, 0.3), 100, 8)
	_make_entity("artisan", cp + Vector2(-100, 10), "🔧", Color(0.7, 0.6, 0.2), 80, 5)
	_make_entity("warrior", cp + Vector2(100, -100), "⚔️", Color(0.7, 0.4, 0.2), 300, 35)
	_make_entity("archer", cp + Vector2(100, 0), "🏹", Color(0.3, 0.6, 0.3), 150, 42)
	_make_entity("cavalry", cp + Vector2(100, 100), "🐎", Color(0.8, 0.5, 0.2), 400, 48)

func _make_entity(type, pos, icon, color, hp, atk):
	var c = Node2D.new(); c.position = pos; ents_node.add_child(c)
	
	# Shadow
	var shad = ColorRect.new()
	shad.size = Vector2(16, 4); shad.position = Vector2(-8, 10)
	shad.color = Color(0, 0, 0, 0.15); shad.mouse_filter = Control.MOUSE_FILTER_IGNORE; c.add_child(shad)
	
	# Body
	var body = ColorRect.new()
	body.size = Vector2(18, 22); body.position = Vector2(-9, -11)
	body.color = color; body.mouse_filter = Control.MOUSE_FILTER_IGNORE; body.name = "body"; c.add_child(body)
	
	# HP bar bg
	var hb = ColorRect.new()
	hb.size = Vector2(26, 4); hb.position = Vector2(-13, -17)
	hb.color = Color(0.15, 0.04, 0.04, 0.7); hb.mouse_filter = Control.MOUSE_FILTER_IGNORE; hb.name = "hp_bg"; c.add_child(hb)
	
	# HP bar fill
	var hf = ColorRect.new()
	hf.size = Vector2(26, 4); hf.position = Vector2(-13, -17)
	hf.color = Color(0.2, 0.85, 0.2, 0.95); hf.mouse_filter = Control.MOUSE_FILTER_IGNORE; hf.name = "hp_fill"; c.add_child(hf)
	
	# HP text
	var ht = Label.new()
	ht.name = "hp_txt"; ht.add_theme_font_size_override("font_size", 7)
	ht.position = Vector2(-13, -30); ht.size = Vector2(26, 10)
	ht.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; ht.mouse_filter = Control.MOUSE_FILTER_IGNORE; c.add_child(ht)
	
	# Icon
	var lbl = Label.new()
	lbl.text = icon; lbl.add_theme_font_size_override("font_size", 18)
	lbl.position = Vector2(-9, -10); lbl.size = Vector2(28, 28)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE; c.add_child(lbl)
	
	# Selection ring
	var sel = ColorRect.new()
	sel.size = Vector2(32, 36); sel.position = Vector2(-16, -18)
	sel.color = Color(0, 0, 0, 0); sel.mouse_filter = Control.MOUSE_FILTER_IGNORE; sel.name = "sel"; c.add_child(sel)
	
	# Area2D for clicks
	var area = Area2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 36)
	area.collision_layer = 0; area.collision_mask = 0
	var col = CollisionShape2D.new(); col.shape = shape; area.add_child(col)
	c.add_child(area)
	var data = {"type": type, "node": c, "pos": pos, "target_pos": pos, "hp": hp, "max_hp": hp, "atk": atk, "moving": false, "task": "idle", "gather_target": null, "anim_time": rng.randf() * 100, "sel": sel, "hp_fill": hf, "hp_txt": ht, "label": lbl, "body": body, "area": area}
	entities.append(data)
	# Store the entity index in the area for click detection
	var ent_idx = entities.size() - 1
	area.input_event.connect(func(_vp, event, _si):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if ent_idx >= 0 and ent_idx < entities.size():
				_select_entity(entities[ent_idx]))

# ═══════════════════════════════════════════════
#  HUD
# ═══════════════════════════════════════════════
func _build_hud():
	var bar = ColorRect.new()
	bar.size = Vector2(1280, 36); bar.color = Color(0, 0, 0, 0.88)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(bar)
	
	var rkeys = ["gold", "stone", "food", "wood", "copper", "bronze", "diamond", "leather"]
	var ricons = ["🪙", "🪨", "🌾", "🪵", "🟤", "🔶", "💎", "👜"]
	for i in range(8):
		var l = Label.new()
		l.name = "RC" + str(i)
		l.text = ricons[i] + " " + rkeys[i].capitalize() + ": " + str(game_res[rkeys[i]])
		l.add_theme_font_size_override("font_size", 10)
		l.position = Vector2(12 + i * 155, 6); l.size = Vector2(145, 24)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(l)
	
	var mb = Button.new()
	mb.name = "MenuBtn"; mb.text = "☰ MENU"
	mb.position = Vector2(1180, 4); mb.size = Vector2(90, 28)
	ui.add_child(mb); mb.pressed.connect(_toggle_menu)
	
	var ip = ColorRect.new()
	ip.name = "InfoPanel"
	ip.size = Vector2(1280, 100); ip.position = Vector2(0, 620)
	ip.color = Color(0, 0, 0, 0.8); ip.visible = false; ip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(ip)
	
	var il = Label.new()
	il.name = "InfoLabel"
	il.position = Vector2(20, 625); il.size = Vector2(400, 50)
	il.add_theme_font_size_override("font_size", 13); il.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(il)
	
	# Build buttons
	var btypes = ["wall", "barracks", "archery", "stable", "siege", "tower_arrow"]
	var bnames = ["🧱 Muro", "⚔️ Cuartel", "🏹 Arquería", "🐎 Caballeriza", "💣 Asedio", "🗼 Torre"]
	for i in 6:
		var b = Button.new()
		b.name = "Build" + str(i)
		b.text = bnames[i]; b.position = Vector2(20 + i * 115, 670); b.size = Vector2(105, 40)
		b.visible = false; b.mouse_filter = Control.MOUSE_FILTER_PASS
		ui.add_child(b)
		var bidx = i
		b.pressed.connect(func(): _place_building(btypes[bidx]))
	
	# Info text
	var it = Label.new()
	it.name = "InfoText"
	it.position = Vector2(20, 690); it.size = Vector2(1240, 25)
	it.add_theme_font_size_override("font_size", 10); it.modulate = Color(0.7, 0.7, 0.5)
	it.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(it)

func _build_minimap():
	var bg = ColorRect.new()
	bg.name = "MMBg"; bg.size = Vector2(164, 164)
	bg.position = Vector2(1280 - 174, 720 - 174); bg.color = Color(0.03, 0.02, 0.06, 0.95)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(bg)
	
	var m = ColorRect.new()
	m.name = "MMap"; m.size = Vector2(160, 160)
	m.position = Vector2(1280 - 172, 720 - 172); m.color = Color(0.08, 0.18, 0.05)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(m)
	
	var cc = ColorRect.new()
	cc.name = "MMCam"; cc.size = Vector2(50, 30)
	cc.color = Color(1, 1, 1, 0.15); cc.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(cc)
	
	# Unit dots on minimap are drawn in _process

# ═══════════════════════════════════════════════
#  GAME LOOP
# ═══════════════════════════════════════════════
func _process(delta):
	if show_menu: return
	
	# ── Camera ──
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
	if ms.y < 42: mv.y -= 1
	if ms.y > 710: mv.y += 1
	
	if mv.length() > 0:
		mv = mv.normalized() * cam_speed * delta
		cam_target += mv
		cam_target.x = clamp(cam_target.x, 320, WORLD_W - 320)
		cam_target.y = clamp(cam_target.y, 180, WORLD_H - 180)
	
	# Smooth camera
	cam = cam.lerp(cam_target, delta * 5.0)
	world.position = -cam + Vector2(640, 360)
	
	# ── Resource UI ──
	var rkeys = ["gold", "stone", "food", "wood", "copper", "bronze", "diamond", "leather"]
	var ricons = ["🪙", "🪨", "🌾", "🪵", "🟤", "🔶", "💎", "👜"]
	for i in range(8):
		var l = ui.get_node("RC" + str(i))
		if l: l.text = ricons[i] + " " + rkeys[i].capitalize() + ": " + str(game_res[rkeys[i]])
	
	# ── Entities ──
	for e in entities:
		if not is_instance_valid(e["node"]): continue
		e["anim_time"] += delta
		var hp_pct = float(e["hp"]) / max(e["max_hp"], 1) * 100
		
		# HP bar
		var hf = e["hp_fill"]; var ht = e["hp_txt"]
		if hf: hf.size.x = 26 * (e["hp"] / max(e["max_hp"], 1))
		if ht: ht.text = str(ceil(hp_pct)) + "%"
		
		if e["hp"] <= 0:
			_destroy_entity(e)
			continue
		
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
				var bob = sin(e["anim_time"] * 10) * 1.2
				e["node"].position.y += bob
		
		# Idle
		if not e["moving"] and e["task"] == "idle":
			var br = sin(e["anim_time"] * 2) * 0.6
			e["node"].position.y = e["pos"].y + br
			
			if e["type"] == "villager" and rng.randf() < 0.02:
				_ai_villager(e)
			elif e["type"] == "artisan" and rng.randf() < 0.01:
				e["target_pos"] = e["pos"] + Vector2(rng.randf() * 300 - 150, rng.randf() * 300 - 150)
				e["moving"] = true
			elif e["type"] in ["warrior", "archer", "cavalry"] and rng.randf() < 0.003:
				e["target_pos"] = e["pos"] + Vector2(rng.randf() * 500 - 250, rng.randf() * 500 - 250)
				e["moving"] = true
		
		# Selection pulse
		var pulse = (0.15 + sin(e["anim_time"] * 3) * 0.1) if e.get("sel", false) else 0.0
		e["sel"].color = Color(1, 1, 0, pulse)
	
	# ── Buildings HP ──
	for b in buildings:
		if not is_instance_valid(b["node"]): continue
		var hf = b["node"].get_node_or_null("hp_fill")
		var ht = b["node"].get_node_or_null("hp_txt")
		if hf: hf.size.x = (b["node"].get_node("hp_bg").size.x) * (b["hp"] / max(b["max_hp"], 1))
		if ht: ht.text = str(ceil(float(b["hp"]) / b["max_hp"] * 100)) + "%"
	
	# ── Minimap entities ──
	_draw_minimap_entities()

func _draw_minimap_entities():
	var mm = ui.get_node("MMap")
	if not mm: return
	# Remove old dots
	for c in mm.get_children(): c.queue_free()
	
	var sx = 160.0 / WORLD_W; var sy = 160.0 / WORLD_H
	
	# Building dots
	for b in buildings:
		var d = ColorRect.new()
		d.size = Vector2(3, 3); d.color = Color(0.6, 0.4, 0.2)
		d.position = Vector2(b["pos"].x * sx - 1.5, b["pos"].y * sy - 1.5)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE; mm.add_child(d)
	
	# Entity dots
	for e in entities:
		if not is_instance_valid(e["node"]): continue
		var c = Color(0.2, 0.8, 0.2) if e["type"] == "villager" else (Color(1, 0.8, 0) if e["type"] == "hero" else Color(0.8, 0.2, 0.2))
		if e["type"] == "artisan": c = Color(0.8, 0.7, 0.2)
		var d = ColorRect.new()
		d.size = Vector2(2, 2); d.color = c
		d.position = Vector2(e["pos"].x * sx - 1, e["pos"].y * sy - 1)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE; mm.add_child(d)

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
	else:
		e["target_pos"] = Vector2(200 + rng.randf() * 500, WORLD_H/2 - 200 + rng.randf() * 400)
		e["moving"] = true

func _destroy_entity(e):
	if e["hp"] <= 0:
		e["node"].queue_free()
		entities.erase(e)
		if e in selected:
			selected.erase(e)
			if selected.size() == 0: _hide_info()

# ═══════════════════════════════════════════════
#  SELECTION & INPUT
# ═══════════════════════════════════════════════
func _select_entity(e):
	if e["type"] == "villager" or e["type"] == "hero" or e["type"] == "artisan" or e["type"] in ["warrior", "archer", "cavalry"]:
		for oe in entities: oe["sel"] = false
		selected.clear()
		e["sel"] = true; selected.append(e); _show_info(e)

func _input(event):
	if show_menu: return
	
	# Right-click move
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and selected.size() > 0:
		var wp = event.position + cam - Vector2(640, 360)
		if wp.x >= 0 and wp.x < WORLD_W and wp.y >= 0 and wp.y < WORLD_H:
			for e in selected:
				e["target_pos"] = wp; e["moving"] = true; e["task"] = "idle"; e["gather_target"] = null

func _show_info(e):
	var ip = ui.get_node("InfoPanel"); var il = ui.get_node("InfoLabel")
	ip.visible = true
	var names = {"hero": "🦸 Heroe", "villager": "👷 Aldeano", "artisan": "🔧 Artesano", "warrior": "⚔️ Guerrero", "archer": "🏹 Arquero", "cavalry": "🐎 Jinete"}
	il.text = names.get(e["type"], e["type"]) + " | HP: " + str(e["hp"]) + "/" + str(e["max_hp"]) + " (" + str(ceil(float(e["hp"])/e["max_hp"]*100)) + "%) | ATK: " + str(e["atk"])
	
	# Hide build buttons
	for i in 6:
		var b = ui.get_node("Build" + str(i))
		if b: b.visible = false
	
	# Show build buttons for villager
	if e["type"] == "villager":
		for i in 6:
			var b = ui.get_node("Build" + str(i))
			if b: b.visible = true

func _hide_info():
	var ip = ui.get_node("InfoPanel")
	if ip: ip.visible = false
	for i in 6:
		var b = ui.get_node("Build" + str(i))
		if b: b.visible = false

func _place_building(type):
	var costs = {"wall": {"stone": 50}, "barracks": {"gold": 100, "wood": 100}, "archery": {"gold": 120, "wood": 80, "stone": 50}, "stable": {"gold": 150, "wood": 60, "stone": 30}, "siege": {"gold": 200, "wood": 100, "stone": 100}, "tower_arrow": {"gold": 80, "stone": 100, "wood": 40}}
	
	var cost = costs.get(type, {})
	for r in cost.keys():
		if game_res.get(r, 0) < cost[r]: _notify("❌ Recursos insuficientes!"); return
	
	for r in cost.keys(): game_res[r] -= cost[r]
	
	# Place near castle
	var cp = Vector2(400, WORLD_H / 2 - 40)
	var pos = cp + Vector2(-80 + rng.randf() * 300, -100 + rng.randf() * 200)
	_make_building(type, pos)
	_notify("✅ " + type.capitalize() + " construido!")

# ═══════════════════════════════════════════════
#  MENU
# ═══════════════════════════════════════════════
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
		if not FileAccess.file_exists("user://save_" + str(i) + ".json"): _do_save(i); return
	_do_save(0)

func _do_save(slot):
	var data = {"timestamp": Time.get_datetime_string_from_system(), "resources": game_res, "player": Globals.player_name, "hero_id": Globals.selected_hero_id, "entities": [], "buildings": []}
	for e in entities: data["entities"].append({"type": e["type"], "x": e["pos"].x, "y": e["pos"].y, "hp": e["hp"]})
	for b in buildings: data["buildings"].append({"type": b["type"], "x": b["pos"].x, "y": b["pos"].y, "hp": b["hp"]})
	var f = FileAccess.open("user://save_" + str(slot) + ".json", FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(data)); f.close(); _notify("💾 Guardado en slot " + str(slot + 1))

func _main_menu(): get_tree().change_scene_to_file("res://scenes/ModeSelect.tscn")

func _notify(txt):
	var n = Label.new()
	n.text = txt; n.add_theme_font_size_override("font_size", 14)
	n.position = Vector2(440, 350); n.size = Vector2(400, 30)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; n.modulate = Color(1, 0.85, 0.3)
	ui.add_child(n)
	create_tween().tween_property(n, "modulate:a", 0.0, 2.0).set_delay(1.5)
	create_tween().tween_callback(n.queue_free).set_delay(3.5)
