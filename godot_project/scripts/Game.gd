extends Control

# ─── WORLD ───
const WORLD_W = 4000; const WORLD_H = 4000
var cam = Vector2(640, 360)
var cam_target = Vector2(640, 360)
var cam_speed = 300.0
var zoom_level = 1.0
var zoom_target = 1.0
var entities = []
var enemies = []
var buildings = []
var res_nodes = []
var selected = []
var show_menu = false
var placing_building = null

var game_res = {"gold": 200, "stone": 100, "food": 150, "wood": 150, "copper": 0, "bronze": 0, "diamond": 0, "leather": 0}

@onready var world = $World
@onready var ents_node = $World/Entities
@onready var ui = $UI

var rng = RandomNumberGenerator.new()
var hero_data = {}
func _cart_to_iso(cart: Vector2) -> Vector2:
	return Vector2((cart.x - cart.y) * 32, (cart.x + cart.y) * 16)

func _iso_to_cart(iso: Vector2) -> Vector2:
	var cx = iso.x / 32 + iso.y / 16
	var cy = iso.y / 16 - iso.x / 32
	return Vector2(cx / 2, cy / 2)

func _iso_depth(cart: Vector2) -> float:
	# Normalized depth sorting (0-100 range)
	return fmod(cart.x + cart.y, 100)


func _ready():
	hero_data = Globals.get_hero(Globals.selected_hero_id)
	RenderingServer.set_default_clear_color(Color(0.08, 0.18, 0.06))
	_gen_terrain()
	_gen_resources()
	_gen_ambient_particles()
	_gen_buildings()
	_spawn_units()
	_build_hud()
	_build_minimap()

# ═══════════════════════════════════════════════
#  TERRAIN
# ═══════════════════════════════════════════════
func _gen_terrain():
	# Deep background gradient
	var sky = ColorRect.new()
	sky.size = Vector2(WORLD_W, WORLD_H)
	sky.color = Color(0.05, 0.08, 0.15, 0.8)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(sky)
	
	# Ground base
	var ground = ColorRect.new()
	ground.size = Vector2(WORLD_W, WORLD_H)
	ground.color = Color(0.12, 0.25, 0.08)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(ground)
	
	# Grass texture layers
	for i in 4:
		var g = ColorRect.new()
		g.size = Vector2(WORLD_W, WORLD_H)
		g.color = Color(0.15 + i * 0.04, 0.28 + i * 0.03, 0.08 + i * 0.02, 0.2)
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(g)
	
	# Organic terrain patches (circles, not rectangles)
	var patch_colors = [
		Color(0.2, 0.35, 0.12, 0.12), Color(0.28, 0.3, 0.15, 0.08),
		Color(0.15, 0.38, 0.1, 0.1), Color(0.22, 0.28, 0.18, 0.06)]
	for i in 50:
		var p = ColorRect.new()
		var pw = 60 + rng.randi() % 200
		p.size = Vector2(pw, 50 + rng.randi() % 150)
		p.position = Vector2(rng.randi() % (WORLD_W - 200), rng.randi() % (WORLD_H - 150))
		p.color = patch_colors[i % patch_colors.size()]
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(p)
	
	# Dirt paths (organic)
	for i in 5:
		var path = ColorRect.new()
		path.size = Vector2(30 + rng.randi() % 40, 500 + rng.randi() % 400)
		path.position = Vector2(rng.randi() % (WORLD_W - 60), rng.randi() % (WORLD_H - 500))
		path.color = Color(0.3, 0.22, 0.12, 0.08)
		path.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(path)
		
		# Path center
		var pc = ColorRect.new()
		pc.size = Vector2(path.size.x * 0.5, path.size.y)
		pc.position = path.position + Vector2(7, 0)
		pc.color = Color(0.35, 0.25, 0.15, 0.06)
		pc.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(pc)
	
	# River through the middle
	var river = ColorRect.new()
	river.size = Vector2(60, WORLD_H)
	river.position = Vector2(WORLD_W * 0.5 - 30, 0)
	river.color = Color(0.12, 0.28, 0.45, 0.15)
	river.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(river)
	
	# River edge
	var re = ColorRect.new()
	re.size = Vector2(80, WORLD_H)
	re.position = Vector2(WORLD_W * 0.5 - 40, 0)
	re.color = Color(0.15, 0.3, 0.4, 0.06)
	re.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(re)
	
	# Lake (larger, more natural)
	var lake = ColorRect.new()
	lake.size = Vector2(400, 300); lake.position = Vector2(2200, 800)
	lake.color = Color(0.1, 0.25, 0.42, 0.35)
	lake.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(lake)
	# Lake border
	for i in 3:
		var lb = ColorRect.new()
		var s = 20 + i * 15
		lb.size = lake.size + Vector2(s, s)
		lb.position = lake.position - Vector2(s/2, s/2)
		lb.color = Color(0.15, 0.3, 0.4, 0.08 - i * 0.02)
		lb.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(lb)
	
	# Fog/mist layer (bottom)
	var fog = ColorRect.new()
	fog.size = Vector2(WORLD_W, WORLD_H)
	fog.color = Color(0.08, 0.12, 0.15, 0.08)
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(fog)
	
	# Decorative elements - grass tufts, flowers, rocks
	var deco_items = ["🌿", "🌱", "🌾", "🍃", "🌻", "🌸", "🪨"]
	for i in 80:
		var g = Label.new()
		g.text = deco_items[i % deco_items.size()]
		g.add_theme_font_size_override("font_size", 6 + rng.randi() % 8)
		g.position = Vector2(rng.randi() % WORLD_W, rng.randi() % WORLD_H)
		g.modulate = Color(1, 1, 1, 0.04 + rng.randf() * 0.06)
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(g)

func _gen_ambient_particles():
	# Adds floating particles for atmosphere
	for i in 10:
		var p = ColorRect.new()
		p.size = Vector2(2, 2)
		p.position = Vector2(rng.randi() % WORLD_W, rng.randi() % WORLD_H)
		p.color = Color(1, 1, 0.8, 0.08)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.name = "AmbientParticle"
		world.add_child(p)

func _gen_resources():
	var defs = [
		["tree", 45, Color(0.05, 0.3, 0.05), "🌲", 50],
		["gold", 5, Color(0.8, 0.6, 0.08), "💎", 300],
		["stone", 6, Color(0.4, 0.4, 0.4), "🪨", 200],
		["deer", 4, Color(0.45, 0.25, 0.15), "🦌", 30],
	]
	for d in defs:
		for i in range(d[1]):
			var pos = Vector2(100 + rng.randi() % (WORLD_W - 200), 100 + rng.randi() % (WORLD_H - 200))
			# Resource shadow
			var shad = ColorRect.new()
			shad.size = Vector2(24, 6); shad.position = pos - Vector2(6, -4)
			shad.color = Color(0, 0, 0, 0.1); shad.mouse_filter = Control.MOUSE_FILTER_IGNORE
			world.add_child(shad)
			# Resource body
			var r = ColorRect.new()
			r.size = Vector2(22, 22); r.position = pos - Vector2(1, 1)
			r.color = d[2]; r.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(r)
			# Resource icon
			var l = Label.new()
			l.text = d[3]; l.add_theme_font_size_override("font_size", 18)
			l.position = pos - Vector2(9, -15); l.size = Vector2(36, 36)
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
	bnode.position = _cart_to_iso(pos)
	bnode.z_index = _iso_depth(pos)

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
	
	# Spawn enemies on the right side
	_spawn_enemies(1)

func _spawn_enemies(wave_num):
	for i in range(3 + wave_num):
		var pos = Vector2(3500, 500 + rng.randi() % 3000)
		var hp_val = 200 + wave_num * 50
		var atk_val = 15 + wave_num * 5
		_make_enemy("warrior", pos, Color(0.6, 0.15, 0.15), hp_val, atk_val)

func _make_enemy(type, pos, color, hp, atk):
	var ent = preload("res://scenes/EntityRenderer.tscn").instantiate()
	ent.position = pos; ent.entity_type = type
	ent.entity_color = color; ent.hp = hp; ent.max_hp = hp
	ent.entity_team = "enemy"
	ents_node.add_child(ent)
	
	var data = {"type": type, "node": ent, "pos": pos, "target_pos": pos, "hp": hp, "max_hp": hp, "atk": atk, "moving": false, "task": "idle", "anim_time": rng.randf() * 100, "renderer": ent}
	enemies.append(data)
	ent.position = _cart_to_iso(pos)
	ent.z_index = _iso_depth(pos)

func _make_entity(type, pos, icon, color, hp, atk):
	var ent_renderer = preload("res://scenes/EntityRenderer.tscn").instantiate()
	ent_renderer.position = pos
	ent_renderer.entity_type = type
	ent_renderer.entity_color = color
	ent_renderer.hp = hp
	ent_renderer.max_hp = hp
	ent_renderer.is_hero = (type == "hero")
	ents_node.add_child(ent_renderer)
	
	# HP text overlay
	var hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.add_theme_font_size_override("font_size", 7)
	hp_label.position = Vector2(-15, -30); hp_label.size = Vector2(30, 10)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ent_renderer.add_child(hp_label)
	
	var data = {"type": type, "node": ent_renderer, "pos": pos, "target_pos": pos, "hp": hp, "max_hp": hp, "atk": atk, "moving": false, "task": "idle", "gather_target": null, "anim_time": rng.randf() * 100, "renderer": ent_renderer, "hp_label": hp_label}
	entities.append(data)
	ent_renderer.position = _cart_to_iso(pos)
	ent_renderer.z_index = _iso_depth(pos)

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
	ui.add_child(mb); 	mb.pressed.connect(_toggle_menu)
	
	# Zoom indicator
	var zi = Label.new()
	zi.name = "ZoomIndicator"
	zi.text = "🔍 100%"
	zi.add_theme_font_size_override("font_size", 10)
	zi.position = Vector2(1090, 5); zi.size = Vector2(80, 24)
	zi.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(zi)
	
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
	
	# Action buttons (Act0 = Construir, etc)
	for i in 3:
		var act = Button.new()
		act.name = "Act" + str(i)
		act.position = Vector2(480 + i * 90, 685); act.size = Vector2(80, 30)
		act.visible = false; ui.add_child(act)
	
	# Connect Act0 to toggle build menu
	ui.get_node("Act0").pressed.connect(_toggle_build_menu)

func _build_minimap():
	var bg = ColorRect.new()
	bg.name = "MMBg"; bg.size = Vector2(164, 164)
	bg.position = Vector2(1280 - 174, 720 - 174); bg.color = Color(0.03, 0.02, 0.06, 0.95)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS; ui.add_child(bg)
	
	var m = ColorRect.new()
	m.name = "MMap"; m.size = Vector2(160, 160)
	m.position = Vector2(1280 - 172, 720 - 172); m.color = Color(0.08, 0.18, 0.05)
	m.mouse_filter = Control.MOUSE_FILTER_STOP; ui.add_child(m)
	
	# Click handler for minimap navigation
	m.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var sx = event.position.x / 160.0 * WORLD_W
			var sy = event.position.y / 160.0 * WORLD_H
			cam_target = Vector2(clamp(sx, 320, WORLD_W - 320), clamp(sy, 180, WORLD_H - 180))
	)
	
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
		mv = mv.normalized() * cam_speed * delta * (1.0 / zoom_level)
		cam_target += mv
		cam_target.x = clamp(cam_target.x, 320 / zoom_level, WORLD_W - 320 / zoom_level)
		cam_target.y = clamp(cam_target.y, 180 / zoom_level, WORLD_H - 180 / zoom_level)
	
	# Animate ambient particles
	for p in world.get_children():
		if p.name == "AmbientParticle" and is_instance_valid(p):
			p.position.y += delta * 5
			p.modulate.a = 0.05 + sin(Time.get_ticks_msec() * 0.001 + p.position.x) * 0.03
			if p.position.y > WORLD_H: p.position.y = 0; p.position.x = rng.randi() % WORLD_W
	
	# Smooth camera
	cam = cam.lerp(cam_target, delta * 5.0)
	zoom_level = lerp(zoom_level, zoom_target, delta * 5.0)
	world.scale = Vector2(zoom_level, zoom_level)
	var iso_cam = _cart_to_iso(cam)
	world.position = -iso_cam + Vector2(640 / zoom_level, 360 / zoom_level)
	
	# Zoom indicator
	var zi_label = ui.get_node_or_null("ZoomIndicator")
	if zi_label:
		zi_label.text = "🔍 " + str(int(zoom_level * 100)) + "%"
	
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
		var r = e["renderer"]
		if r:
			r.anim_time = e["anim_time"]
			r.hp = e["hp"]; r.max_hp = e["max_hp"]
			r.selected = e.get("sel", false)
			r.is_moving = e["moving"]
			r.queue_redraw()
		
		# HP percentage text
		var hl = e.get("hp_label")
		if hl:
			var pct = ceil(float(e["hp"]) / max(e["max_hp"], 1) * 100)
			hl.text = str(pct) + "%"
			hl.modulate = Color(1, 1, 1) if pct > 50 else (Color(1, 1, 0) if pct > 25 else Color(1, 0.5, 0.5))
		
		if e["hp"] <= 0:
			_destroy_entity(e)
			continue
		
		# Movement
		if e["moving"]:
			var d = e["target_pos"] - e["pos"]
			var dist = d.length()
			if dist < 5:
				e["moving"] = false; e["pos"] = e["target_pos"]
				# Check if reached a resource for gathering
				if e["task"] == "gathering" and e["gather_target"]:
					var res = e["gather_target"]
					if res["amount"] > 0:
						_do_gather(e, res)
			else:
				d = d.normalized()
				e["pos"] += d * 80 * delta
				e["node"].position = _cart_to_iso(e["pos"])
			e["node"].z_index = _iso_depth(e["pos"])
		
		# Idle
		if not e["moving"] and e["task"] == "idle":
			if e["type"] == "villager" and rng.randf() < 0.02:
				_ai_villager(e)
			elif e["type"] == "artisan" and rng.randf() < 0.01:
				e["target_pos"] = e["pos"] + Vector2(rng.randf() * 300 - 150, rng.randf() * 300 - 150)
				e["moving"] = true
			elif e["type"] in ["warrior", "archer", "cavalry"] and rng.randf() < 0.003:
				e["target_pos"] = e["pos"] + Vector2(rng.randf() * 500 - 250, rng.randf() * 500 - 250)
				e["moving"] = true
		
		# ── Military AI ──
	for e in entities:
		if not is_instance_valid(e["node"]): continue
		if e["type"] in ["warrior", "archer", "cavalry", "hero"] and not e["moving"] and e["task"] == "idle":
			# Find nearest enemy
			var near = null; var md = 300.0
			for en in enemies:
				if not is_instance_valid(en["node"]): continue
				var d = e["pos"].distance_to(en["pos"])
				if d < md: md = d; near = en
			if near:
				e["target_pos"] = near["pos"]
				e["moving"] = true
				e["task"] = "fighting"
	
	# ── Enemy AI ──
	for en in enemies:
		if not is_instance_valid(en["node"]): continue
		en["anim_time"] += delta
		var r = en["renderer"]
		if r: r.anim_time = en["anim_time"]; r.hp = en["hp"]; r.max_hp = en["max_hp"]; r.queue_redraw()
		
		if en["hp"] <= 0:
			_enemy_death(en); continue
		
		# Move toward nearest player entity
		var near = null; var md = 600.0
		for e in entities:
			if not is_instance_valid(e["node"]): continue
			var d = en["pos"].distance_to(e["pos"])
			if d < md: md = d; near = e
		if near and not en["moving"]:
			en["target_pos"] = near["pos"]
			en["moving"] = true
		elif not near:
			en["target_pos"] = Vector2(400, WORLD_H/2)
			en["moving"] = true
		
		# Combat - deal damage if close to target
		if near and en["pos"].distance_to(near["pos"]) < 30 and rng.randf() < 0.02:
			near["hp"] -= en["atk"]
		
		# Movement
		if en["moving"]:
			var d = en["target_pos"] - en["pos"]
			var dist = d.length()
			if dist < 5:
				en["moving"] = false; en["pos"] = en["target_pos"]
			else:
				d = d.normalized()
				en["pos"] += d * 40 * delta
				en["node"].position = _cart_to_iso(en["pos"])
				en["node"].z_index = _iso_depth(en["pos"])
	
	# ── Player military attacks ──
	for e in entities:
		if not is_instance_valid(e["node"]): continue
		if e["type"] in ["warrior", "archer", "cavalry", "hero"]:
			for en in enemies:
				if not is_instance_valid(en["node"]): continue
				if e["pos"].distance_to(en["pos"]) < 30 and rng.randf() < 0.03:
					en["hp"] -= e["atk"]
	
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
	# If nearby, start gathering
	elif nearest and md < 30:
		_do_gather(e, nearest)
	else:
		e["target_pos"] = Vector2(200 + rng.randf() * 500, WORLD_H/2 - 200 + rng.randf() * 400)
		e["moving"] = true

func _do_gather(e, res):
	if res["amount"] <= 0: return
	res["amount"] -= 1
	var res_key = res["type"]
	var rewards = {"tree": "wood", "gold": "gold", "stone": "stone", "deer": "food"}
	if rewards.has(res_key):
		game_res[rewards[res_key]] += 2
	# Gathering particle
	var p = ColorRect.new()
	p.size = Vector2(4, 4); p.color = Color(1, 1, 0, 0.7)
	p.position = e["pos"]; p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ents_node.add_child(p)
	var t = create_tween(); t.set_parallel(true)
	t.tween_property(p, "position", e["pos"] + Vector2(0, -20), 0.4)
	t.tween_property(p, "modulate:a", 0.0, 0.4)
	t.tween_callback(p.queue_free)
	
	if res["amount"] <= 0:
		res["node"].queue_free()
		res_nodes.erase(res)
		e["task"] = "idle"
		e["gather_target"] = null

func _destroy_entity(e):
	if e["hp"] <= 0:
		for i in range(8):
			var p = ColorRect.new(); p.size = Vector2(4, 4); p.color = Color(1, 0.3, 0.2, 0.8)
			p.position = e["pos"]; p.mouse_filter = Control.MOUSE_FILTER_IGNORE; ents_node.add_child(p)
			var t = create_tween(); t.set_parallel(true)
			t.tween_property(p, "position", e["pos"] + Vector2(randf() * 40 - 20, -randf() * 30 - 10), 0.5)
			t.tween_property(p, "modulate:a", 0.0, 0.5); t.tween_property(p, "size", Vector2(2, 2), 0.5); t.tween_callback(p.queue_free)
		e["node"].queue_free(); entities.erase(e)
		if e in selected: selected.erase(e)
		if selected.size() == 0: _hide_info()

func _enemy_death(en):
	for i in range(6):
		var p = ColorRect.new(); p.size = Vector2(3, 3); p.color = Color(1, 0.2, 0.2, 0.8)
		p.position = en["pos"]; p.mouse_filter = Control.MOUSE_FILTER_IGNORE; ents_node.add_child(p)
		var t = create_tween(); t.set_parallel(true)
		t.tween_property(p, "position", en["pos"] + Vector2(randf() * 30 - 15, -randf() * 20 - 10), 0.4)
		t.tween_property(p, "modulate:a", 0.0, 0.4); t.tween_callback(p.queue_free)
	en["node"].queue_free(); enemies.erase(en)
	game_res["gold"] += 10; game_res["food"] += 5

# ═══════════════════════════════════════════════
#  SELECTION & INPUT
# ═══════════════════════════════════════════════
func _select_at(wp):
	# Deselect all first
	for oe in entities: 
		oe["sel"] = false
		if oe.get("renderer"): oe["renderer"].selected = false
	selected.clear()
	_hide_info()
	
	# Find nearest entity within click range
	var nearest = null; var min_dist = 25.0
	for e in entities:
		if not is_instance_valid(e.get("node")): continue
		var d = wp.distance_to(e["pos"])
		if d < min_dist: min_dist = d; nearest = e
	
	if nearest:
		_select_entity(nearest)
		return
	
	# Check buildings (only if no entity was found)
	for b in buildings:
		if not is_instance_valid(b.get("node")): continue
		var d = wp.distance_to(b["pos"])
		if d < 40:
			_notify("🏗️ " + b["type"].capitalize() + " HP: " + str(b["hp"]) + "/" + str(b["max_hp"]))
			return

func _select_entity(e):
	if e["type"] == "villager" or e["type"] == "hero" or e["type"] == "artisan" or e["type"] in ["warrior", "archer", "cavalry"]:
		for oe in entities: 
			oe["sel"] = false
			if oe.get("renderer"): oe["renderer"].selected = false
		selected.clear()
		e["sel"] = true
		if e.get("renderer"): e["renderer"].selected = true
		selected.append(e); _show_info(e)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var zoom_center = Vector2(640.0 / zoom_level, 360.0 / zoom_level)
	var iso_pos = (screen_pos + cam - zoom_center) / zoom_level
	var cart = _iso_to_cart(iso_pos)
	return cart

func _input(event):
	if show_menu: return
	
	# Building placement mode (checked FIRST)
	if placing_building and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var wp = _screen_to_world(event.position)
			if wp.x >= 50 and wp.x < WORLD_W - 50 and wp.y >= 50 and wp.y < WORLD_H - 50:
				_confirm_building(placing_building, wp)
			placing_building = null
			get_viewport().set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_LEFT:
			placing_building = null
			_notify("Construccion cancelada")
			get_viewport().set_input_as_handled()
			return
	
	# Left-click: select unit by proximity
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var wp = _screen_to_world(event.position)
		if wp.x >= 0 and wp.x < WORLD_W and wp.y >= 0 and wp.y < WORLD_H:
			_select_at(wp)
			get_viewport().set_input_as_handled()
			return
	
	# Zoom with mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_target = clamp(zoom_target + 0.1, 0.3, 2.0)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_target = clamp(zoom_target - 0.1, 0.3, 2.0)
	
	# Right-click context actions
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and selected.size() > 0:
		var wp = _screen_to_world(event.position)
		if wp.x >= 0 and wp.x < WORLD_W and wp.y >= 0 and wp.y < WORLD_H:
			# Check if clicked on a resource (for villagers)
			var clicked_res = null
			var clicked_enemy = null
			for r in res_nodes:
				if r["amount"] > 0 and wp.distance_to(r["pos"]) < 30:
					clicked_res = r; break
			for en in enemies:
				if is_instance_valid(en.get("node")) and wp.distance_to(en["pos"]) < 30:
					clicked_enemy = en; break
			
			for e in selected:
				# Villager on resource → gather
				if e["type"] == "villager" and clicked_res:
					e["task"] = "gathering"; e["gather_target"] = clicked_res
					e["target_pos"] = clicked_res["pos"]; e["moving"] = true
				# Military on enemy → attack
				elif e["type"] in ["warrior", "archer", "cavalry", "hero"] and clicked_enemy:
					e["task"] = "fighting"; e["target_pos"] = clicked_enemy["pos"]; e["moving"] = true
				# Default: move
				else:
					e["target_pos"] = wp; e["moving"] = true; e["task"] = "idle"; e["gather_target"] = null

func _confirm_building(type, pos):
	var costs = {"wall": {"stone": 50}, "barracks": {"gold": 100, "wood": 100}, "archery": {"gold": 120, "wood": 80, "stone": 50}, "stable": {"gold": 150, "wood": 60, "stone": 30}, "siege": {"gold": 200, "wood": 100, "stone": 100}, "tower_arrow": {"gold": 80, "stone": 100, "wood": 40}}
	var cost = costs.get(type, {})
	for r in cost.keys():
		if game_res.get(r, 0) < cost[r]: _notify("❌ Recursos insuficientes!"); return
	for r in cost.keys(): game_res[r] -= cost[r]
	_make_building(type, pos)
	_notify("✅ " + type.capitalize() + " construido!")

func _show_info(e):
	var ip = ui.get_node("InfoPanel"); var il = ui.get_node("InfoLabel")
	ip.visible = true
	var names = {"hero": "🦸 Heroe", "villager": "👷 Aldeano", "artisan": "🔧 Artesano", "warrior": "⚔️ Guerrero", "archer": "🏹 Arquero", "cavalry": "🐎 Jinete"}
	il.text = names.get(e["type"], e["type"]) + " | HP: " + str(e["hp"]) + "/" + str(e["max_hp"]) + " (" + str(ceil(float(e["hp"])/e["max_hp"]*100)) + "%) | ATK: " + str(e["atk"])
	
	# Hide all build buttons first
	for i in 6:
		var b = ui.get_node("Build" + str(i))
		if b: b.visible = false
	
	# Hide all action buttons first
	for i in 3:
		var act = ui.get_node("Act" + str(i))
		if act: act.visible = false
	
	# Show action buttons based on unit type
	if e["type"] == "villager":
		var act = ui.get_node("Act0")
		if act:
			act.visible = true
			act.text = "🏗️ Construir"

func _toggle_build_menu():
	var vis = not ui.get_node("Build0").visible
	for i in 6:
		var b = ui.get_node("Build" + str(i))
		if b: b.visible = vis
	var it = ui.get_node("InfoText")
	if it: it.text = "Selecciona un edificio para construir. Click derecho en el mapa para colocar." if vis else ""

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
	
	# Enter placement mode
	placing_building = type
	_notify("🔨 Click derecho en el mapa para colocar " + type.capitalize())

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
