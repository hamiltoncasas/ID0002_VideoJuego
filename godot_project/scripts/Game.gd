extends Control

# ─── WORLD ───
const WORLD_W = 6000; const WORLD_H = 6000
var cam = Vector2(640, 360); var cam_target = Vector2(640, 360)
var cam_speed = 400.0; var zoom_level = 1.0; var zoom_target = 1.0
var entities = []; var enemies = []; var buildings = []; var res_nodes = []
var selected = []; var show_menu = false; var placing_building = null
var selected_building = null
var key_left = false; var key_right = false; var key_up = false; var key_down = false

var game_res = {"gold": 300, "stone": 200, "food": 200, "wood": 200, "copper": 50, "bronze": 0, "diamond": 0, "leather": 0}

@onready var world = $World; @onready var ents_node = $World/Entities; @onready var ui = $UI
var rng = RandomNumberGenerator.new(); var hero_data = {}

func _ready():
	hero_data = Globals.get_hero(Globals.selected_hero_id)
	cam = Vector2(500, 1800); cam_target = Vector2(500, 1800)
	_gen_terrain(); _gen_resources(); _gen_buildings(); _spawn_units()
	_build_hud(); _build_minimap()

# ════════════════════════════ TERRAIN ════════════════════════════
func _gen_terrain():
	# Base sky/ground
	var sky = ColorRect.new(); sky.size = Vector2(WORLD_W, WORLD_H)
	sky.color = Color(0.1, 0.22, 0.07); sky.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(sky)
	# Organic grass patches with varied colors
	for i in 80:
		var p = ColorRect.new()
		p.size = Vector2(30+rng.randi()%250, 25+rng.randi()%180)
		p.position = Vector2(rng.randi()%(WORLD_W-250), rng.randi()%(WORLD_H-180))
		var g=rng.randf(); p.color = Color(0.12+g*0.1, 0.25+g*0.12, 0.06+g*0.06, 0.1+rng.randf()*0.1)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(p)
	# Rocky areas near stone resources
	for i in 15:
		var p = ColorRect.new()
		p.size = Vector2(40+rng.randi()%100, 30+rng.randi()%80)
		p.position = Vector2(rng.randi()%(WORLD_W-150), rng.randi()%(WORLD_H-100))
		p.color = Color(0.35,0.32,0.28,0.08); p.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(p)
	# River through map
	var river = ColorRect.new(); river.size = Vector2(50, WORLD_H)
	river.position = Vector2(WORLD_W*0.35, 0)
	river.color = Color(0.08,0.22,0.4,0.2); river.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(river)
	# Lake
	var lake = ColorRect.new(); lake.size = Vector2(350,250); lake.position = Vector2(2500,1200)
	lake.color = Color(0.08,0.25,0.42,0.35); lake.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(lake)
	# Fish in lake/river
	for i in range(10):
		var fp=Vector2(2500+rng.randi()%350,1200+rng.randi()%250)
		var fr=Label.new(); fr.text="🐟"; fr.add_theme_font_size_override("font_size",12)
		fr.position=fp; fr.size=Vector2(20,20); fr.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(fr)
		res_nodes.append({"type":"fish","pos":fp,"amount":20+rng.randi()%15,"node":fr,"renewable":true})
	for i in range(8):
		var fp=Vector2(WORLD_W*0.35+rng.randi()%50,rng.randi()%WORLD_H)
		var fr=Label.new(); fr.text="🐟"; fr.add_theme_font_size_override("font_size",10)
		fr.position=fp; fr.size=Vector2(18,18); fr.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(fr)
		res_nodes.append({"type":"fish","pos":fp,"amount":15+rng.randi()%10,"node":fr,"renewable":true})
	# Decorative elements (trees, rocks, flowers)
	var deco = ["🌿","🌱","🪨","🌲","🌾","🍃","🌻","🌸"]
	for i in 100:
		var d = Label.new(); d.text = deco[i%deco.size()]
		d.add_theme_font_size_override("font_size", 5+rng.randi()%10)
		d.position = Vector2(rng.randi()%WORLD_W, rng.randi()%WORLD_H)
		d.modulate = Color(1,1,1,0.04+rng.randf()*0.08)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(d)
	# Map borders (walls)
	var bc = Color(0.25,0.2,0.15,0.3)
	for x in range(0,WORLD_W,40):
		var w=ColorRect.new(); w.size=Vector2(40,16); w.position=Vector2(x,0); w.color=bc; w.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(w)
		var w2=ColorRect.new(); w2.size=Vector2(40,16); w2.position=Vector2(x,WORLD_H-16); w2.color=bc; w2.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(w2)
	for y in range(0,WORLD_H,40):
		var w=ColorRect.new(); w.size=Vector2(16,40); w.position=Vector2(0,y); w.color=bc; w.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(w)
		var w2=ColorRect.new(); w2.size=Vector2(16,40); w2.position=Vector2(WORLD_W-16,y); w2.color=bc; w2.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(w2)

func _gen_resources():
	var defs = [["tree",35,Color(0.05,0.4,0.05),"🌲",50],["gold",5,Color(1,0.7,0.1),"💎",300],["stone",6,Color(0.5,0.5,0.5),"🪨",200]]
	for d in defs:
		for i in range(d[1]):
			var pos = Vector2(100+rng.randi()%(WORLD_W-200),100+rng.randi()%(WORLD_H-200))
				var tex=null
			if d[0]=="tree": tex=_load_sprite("tree_"+str(i%4))
			if tex:
				var spr=Sprite2D.new(); spr.texture=tex; spr.centered=true; spr.scale=Vector2(0.8,0.8); spr.position=pos; world.add_child(spr)
				res_nodes.append({"type":d[0],"pos":pos,"amount":d[4]+rng.randi()%30,"node":spr})
			else:
				var r = ColorRect.new(); r.size=Vector2(20,20); r.position=pos; r.color=d[2]; r.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(r)
				var l=Label.new(); l.text=d[3]; l.add_theme_font_size_override("font_size",16); l.position=pos-Vector2(8,16); l.size=Vector2(32,32); l.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(l)
				res_nodes.append({"type":d[0],"pos":pos,"amount":d[4]+rng.randi()%30,"node":r})
	# Animals
	var animals=[["wolf","🐺",30,Color(0.5,0.3,0.2)],["cow","🐄",40,Color(0.8,0.7,0.5)],["pig","🐖",35,Color(1,0.7,0.6)],["buffalo","🐃",50,Color(0.4,0.2,0.1)]]
	for a in animals:
		for i in range(4):
			var pos=Vector2(200+rng.randi()%(WORLD_W-400),200+rng.randi()%(WORLD_H-400))
			var r=ColorRect.new(); r.size=Vector2(18,18); r.position=pos; r.color=a[3]; r.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(r)
			var l=Label.new(); l.text=a[1]; l.add_theme_font_size_override("font_size",14); l.position=pos-Vector2(7,16); l.size=Vector2(28,28); l.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(l)
			res_nodes.append({"type":a[0],"pos":pos,"amount":a[2],"node":r})
	# Wild crops (non-renewable)
	var crops=[["wheat","🌾",25,Color(0.9,0.8,0.3)],["potato","🥔",20,Color(0.7,0.5,0.3)],["corn","🌽",30,Color(1,0.9,0.2)]]
	for c in crops:
		for i in range(6):
			var pos=Vector2(300+rng.randi()%(WORLD_W-600),300+rng.randi()%(WORLD_H-600))
			var r=ColorRect.new(); r.size=Vector2(16,16); r.position=pos; r.color=c[3]; r.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(r)
			var l=Label.new(); l.text=c[1]; l.add_theme_font_size_override("font_size",12); l.position=pos-Vector2(6,14); l.size=Vector2(24,24); l.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(l)
			res_nodes.append({"type":c[0],"pos":pos,"amount":c[2],"node":r,"renewable":false})

func _gen_buildings():
	_make_building("castle", Vector2(400,WORLD_H/2-40))
	_make_building("barracks", Vector2(300,WORLD_H/2-120))
	_make_building("archery", Vector2(300,WORLD_H/2+80))

func _make_building(type, pos):
	var colors={"castle":Color(0.5,0.3,0.15),"barracks":Color(0.45,0.2,0.1),"archery":Color(0.4,0.25,0.1),"stable":Color(0.45,0.3,0.12),"siege":Color(0.4,0.35,0.2),"wall":Color(0.5,0.4,0.3),"gate":Color(0.45,0.35,0.25),"house":Color(0.5,0.35,0.2),"tower_arrow":Color(0.5,0.3,0.2),"tower_stone":Color(0.4,0.35,0.3),"castle_defense":Color(0.4,0.25,0.15),"market":Color(0.55,0.4,0.15),"church":Color(0.6,0.5,0.3),"forge":Color(0.3,0.2,0.15),"mill":Color(0.55,0.4,0.2),"shipyard":Color(0.3,0.35,0.45)}
	var icons={"castle":"🏰","barracks":"⚔","archery":"🏹","stable":"🐎","siege":"💣","wall":"🧱","gate":"🚪","house":"🏠","tower_arrow":"🗼","tower_stone":"🏰","castle_defense":"🏯","market":"🏪","church":"⛪","forge":"🔨","mill":"🏭","shipyard":"🚢"}
	var sizes={"castle":Vector2(80,80),"barracks":Vector2(50,45),"archery":Vector2(45,42),"stable":Vector2(55,45),"siege":Vector2(50,45),"wall":Vector2(40,20),"gate":Vector2(40,20),"house":Vector2(40,40),"tower_arrow":Vector2(40,40),"tower_stone":Vector2(50,50),"castle_defense":Vector2(70,70),"market":Vector2(50,45),"church":Vector2(55,50),"forge":Vector2(50,40),"mill":Vector2(45,40),"shipyard":Vector2(60,45)}
	var max_hp={"castle":5000,"barracks":1500,"archery":1200,"stable":1800,"siege":2000,"wall":2000,"gate":1500,"house":800,"tower_arrow":2500,"tower_stone":3500,"castle_defense":4000,"market":800,"church":1200,"forge":1000,"mill":900,"shipyard":1500}
	var level=1
	var bnode=Node2D.new(); bnode.position=pos; world.add_child(bnode)
	# Level label
	var lvl=Label.new(); lvl.text="Lv."+str(level); lvl.add_theme_font_size_override("font_size",8)
	lvl.position=Vector2(-15,-35); lvl.size=Vector2(30,10); lvl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	lvl.mouse_filter=Control.MOUSE_FILTER_IGNORE; bnode.add_child(lvl)
	var tex=_load_sprite("building_"+type)
	if tex:
		var spr=Sprite2D.new(); spr.texture=tex; spr.centered=true; spr.scale=Vector2(2.0,2.0); bnode.add_child(spr)
	else:
		var body=ColorRect.new(); body.size=sizes.get(type,Vector2(50,50)); body.position=-body.size/2
		body.color=colors.get(type,Color(0.3,0.2,0.1)); body.mouse_filter=Control.MOUSE_FILTER_IGNORE; bnode.add_child(body)
		var lbl=Label.new(); lbl.text=icons.get(type,"🏗"); lbl.add_theme_font_size_override("font_size",22)
		lbl.position=Vector2(-15,-12); lbl.size=Vector2(40,40); lbl.mouse_filter=Control.MOUSE_FILTER_IGNORE; bnode.add_child(lbl)
	buildings.append({"type":type,"node":bnode,"pos":pos,"hp":max_hp.get(type,1000),"max_hp":max_hp.get(type,1000)})

func _spawn_units():
	var cp = Vector2(400,WORLD_H/2-40)
	_make_entity("hero",cp+Vector2(-40,20),"🦸",hero_data["color"],hero_data["hp"],hero_data["atk"])
	_make_entity("villager",cp+Vector2(-90,-60),"👷",Color(0.55,0.35,0.25),100,8)
	_make_entity("villager",cp+Vector2(-90,80),"👷",Color(0.55,0.35,0.25),100,8)
	_make_entity("artisan",cp+Vector2(-70,10),"🔧",Color(0.7,0.55,0.2),80,5)
	_make_entity("warrior",cp+Vector2(80,-80),"⚔",Color(0.65,0.35,0.2),300,35)
	_make_entity("archer",cp+Vector2(80,0),"🏹",Color(0.25,0.55,0.25),150,42)
	_make_entity("cavalry",cp+Vector2(80,80),"🐎",Color(0.75,0.45,0.2),400,48)
	_spawn_enemies(1)

func _make_entity(type, pos, icon, color, hp, atk):
	var ent=Node2D.new(); ent.position=pos; ent.z_index=100; ents_node.add_child(ent)
	# Try to load sprite PNG
	var tex=_load_sprite(type)
	if tex:
		var spr=Sprite2D.new(); spr.texture=tex; spr.centered=true; spr.scale=Vector2(1.5,1.5); ent.add_child(spr)
	else:
		var body=ColorRect.new(); body.size=Vector2(24,24); body.position=Vector2(-12,-12)
		body.color=color; body.mouse_filter=Control.MOUSE_FILTER_IGNORE; ent.add_child(body)
		var lbl=Label.new(); lbl.text=icon; lbl.add_theme_font_size_override("font_size",18)
		lbl.position=Vector2(-9,-26); lbl.size=Vector2(28,28); lbl.mouse_filter=Control.MOUSE_FILTER_IGNORE; ent.add_child(lbl)
	# HP bar
	var hb=ColorRect.new(); hb.size=Vector2(24,3); hb.position=Vector2(-12,-30)
	hb.color=Color(0.15,0.03,0.03,0.7); hb.mouse_filter=Control.MOUSE_FILTER_IGNORE; ent.add_child(hb)
	var hf=ColorRect.new(); hf.size=Vector2(24,3); hf.position=Vector2(-12,-30)
	hf.color=Color(0.2,0.8,0.2,0.9); hf.mouse_filter=Control.MOUSE_FILTER_IGNORE; ent.add_child(hf)
	var ht=Label.new(); ht.add_theme_font_size_override("font_size",6)
	ht.position=Vector2(-12,-38); ht.size=Vector2(24,8); ht.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	ht.mouse_filter=Control.MOUSE_FILTER_IGNORE; ent.add_child(ht)
	var sel_ring=ColorRect.new(); sel_ring.size=Vector2(28,28); sel_ring.position=Vector2(-14,-14)
	sel_ring.color=Color(0,0,0,0); sel_ring.mouse_filter=Control.MOUSE_FILTER_IGNORE; ent.add_child(sel_ring)
	var data={"type":type,"node":ent,"pos":pos,"target_pos":pos,"hp":hp,"max_hp":hp,"atk":atk,"moving":false,"task":"idle","gather_target":null,"anim_time":rng.randf()*100,"hp_fill":hf,"hp_text":ht,"sel_ring":sel_ring}
	entities.append(data)

func _load_sprite(type):
	var path="res://assets/sprites/"+type+".png"
	var img=Image.new()
	if img.load(path)==OK: return ImageTexture.create_from_image(img)
	return null

func _spawn_enemies(wave_num):
	var types = ["warrior","archer","cavalry"]
	var count = 3 + wave_num * Globals.difficulty * Globals.enemy_kingdoms
	for ki in range(Globals.enemy_kingdoms):
		var bx = 2500 + ki * 800
		for i in range(count):
			var t = types[i % types.size()]
			var pos = Vector2(bx + rng.randi() % 500, 500 + rng.randi() % 4000)
			var hp_val = 200 + wave_num * 50 * Globals.difficulty
			var atk_val = 15 + wave_num * 5 * Globals.difficulty
			_make_enemy(t, pos, Color(0.5, 0.12, 0.12), hp_val, atk_val)

func _make_enemy(type, pos, color, hp, atk):
	var ent=Node2D.new(); ent.position=pos; ent.z_index=100; ents_node.add_child(ent)
	var tex=_load_sprite("enemy_"+type)
	if tex:
		var spr=Sprite2D.new(); spr.texture=tex; spr.centered=true; spr.scale=Vector2(1.5,1.5); ent.add_child(spr)
	else:
		var body=ColorRect.new(); body.size=Vector2(22,22); body.position=Vector2(-11,-11)
		body.color=color; body.mouse_filter=Control.MOUSE_FILTER_IGNORE; ent.add_child(body)
		var lbl=Label.new(); lbl.text="⚔"; lbl.add_theme_font_size_override("font_size",14)
		lbl.position=Vector2(-7,-24); lbl.size=Vector2(24,24); lbl.mouse_filter=Control.MOUSE_FILTER_IGNORE; ent.add_child(lbl)
	var data={"type":type,"node":ent,"pos":pos,"target_pos":pos,"hp":hp,"max_hp":hp,"atk":atk,"moving":false,"task":"idle","anim_time":rng.randf()*100}
	enemies.append(data)

# ════════════════════════════ HUD ════════════════════════════
func _build_hud():
	var bar=ColorRect.new(); bar.size=Vector2(1280,34); bar.color=Color(0,0,0,0.85); bar.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(bar)
	var rkeys=["gold","stone","food","wood","copper","bronze","diamond","leather"]
	var ricons=["🪙","🪨","🌾","🪵","🟤","🔶","💎","👜"]
	for i in range(8):
		var l=Label.new(); l.name="RC"+str(i)
		l.text=ricons[i]+" "+rkeys[i].capitalize()+": "+str(game_res[rkeys[i]])
		l.add_theme_font_size_override("font_size",10); l.position=Vector2(12+i*155,6); l.size=Vector2(145,24)
		l.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(l)
	var mb=Button.new(); mb.name="MenuBtn"; mb.text="☰ MENU"; mb.position=Vector2(1180,4); mb.size=Vector2(90,28); ui.add_child(mb); mb.pressed.connect(_toggle_menu)
	var ip=ColorRect.new(); ip.name="InfoPanel"; ip.size=Vector2(1280,100); ip.position=Vector2(0,620)
	ip.color=Color(0,0,0,0.8); ip.visible=false; ip.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(ip)
	var il=Label.new(); il.name="InfoLabel"; il.position=Vector2(20,625); il.size=Vector2(400,50)
	il.add_theme_font_size_override("font_size",13); il.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(il)
	var btypes=["wall","gate","house","barracks","archery","stable","siege","tower_arrow","tower_stone","castle_defense","market","church","forge"]
	var bnames=["🧱Muro","🚪Puerta","🏠Casa","⚔Cuartel","🏹Arqueria","🐎Caballer","💣Asedio","🗼T.Flechas","🏰T.Piedra","🏯C.Defensa","🏪Mercado","⛪Iglesia","🔨Forja"]
	for i in range(13):
		var b=Button.new(); b.name="Build"+str(i)
		var row=floor(i/7); var col=i%7
		b.position=Vector2(20+col*100, 665+row*28); b.size=Vector2(92, 24)
		b.visible=false; b.mouse_filter=Control.MOUSE_FILTER_PASS; ui.add_child(b)
		var bidx=i; b.pressed.connect(func(): _place_building(btypes[bidx]))
	for i in 3:
		var act=Button.new(); act.name="Act"+str(i); act.position=Vector2(480+i*90,685); act.size=Vector2(80,30)
		act.visible=false; ui.add_child(act); var aidx=i; act.pressed.connect(func(): _on_act(aidx))
	var it=Label.new(); it.name="InfoText"; it.position=Vector2(20,690); it.size=Vector2(1240,25)
	it.add_theme_font_size_override("font_size",10); it.modulate=Color(0.7,0.7,0.5); it.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(it)
	var zi=Label.new(); zi.name="ZoomIndicator"; zi.text="🔍 100%"; zi.add_theme_font_size_override("font_size",10)
	zi.position=Vector2(1090,5); zi.size=Vector2(80,24); zi.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(zi)

func _build_minimap():
	var margin = 204; var offset=202
	var bg=ColorRect.new(); bg.name="MMBg"; bg.size=Vector2(164,164); bg.position=Vector2(1280-margin,720-margin)
	bg.color=Color(0.03,0.02,0.06,0.95); bg.mouse_filter=Control.MOUSE_FILTER_PASS; ui.add_child(bg)
	var m=ColorRect.new(); m.name="MMap"; m.size=Vector2(160,160); m.position=Vector2(1280-offset,720-offset)
	m.color=Color(0.08,0.18,0.05); m.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(m)
	var cc=ColorRect.new(); cc.name="MMCam"; cc.size=Vector2(50,30)
	cc.color=Color(1,1,1,0.15); cc.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(cc)

# ════════════════════════════ GAME LOOP ════════════════════════════
func _process(delta):
	if show_menu: return
	var mv=Vector2()
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): mv.x-=1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): mv.x+=1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): mv.y-=1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): mv.y+=1
	var kb = mv.length()>0
	if not kb:
		var ms=get_global_mouse_position()
		if ms.x<15: mv.x-=1; if ms.x>1265: mv.x+=1; if ms.y<42: mv.y-=1; if ms.y>710: mv.y+=1
	if mv.length()>0:
		mv=mv.normalized()*cam_speed*delta*(1.0/zoom_level); cam_target+=mv
		cam_target.x=clamp(cam_target.x,320/zoom_level,WORLD_W-320/zoom_level)
		cam_target.y=clamp(cam_target.y,180/zoom_level,WORLD_H-180/zoom_level)
	cam=cam.lerp(cam_target,delta*5.0); zoom_level=lerp(zoom_level,zoom_target,delta*5.0)
	world.scale=Vector2(zoom_level,zoom_level); world.position=-cam+Vector2(640/zoom_level,360/zoom_level)
	var zi=ui.get_node_or_null("ZoomIndicator")
	if zi: zi.text="🔍 "+str(int(zoom_level*100))+"%"
	var rkeys=["gold","stone","food","wood","copper","bronze","diamond","leather"]
	var ricons=["🪙","🪨","🌾","🪵","🟤","🔶","💎","👜"]
	for i in range(8):
		var l=ui.get_node("RC"+str(i))
		if l: l.text=ricons[i]+" "+rkeys[i].capitalize()+": "+str(game_res[rkeys[i]])
	# Entities
	for e in entities:
		if not is_instance_valid(e["node"]): continue
		e["anim_time"]+=delta
		var hp_pct=float(e["hp"])/max(e["max_hp"],1)
		if e.get("hp_fill"): e["hp_fill"].size.x=24*hp_pct
		if e.get("hp_text"): e["hp_text"].text=str(ceil(hp_pct*100))+"%"
		if e.get("sel_ring"):
			e["sel_ring"].color=Color(1,1,0,0.15+sin(e["anim_time"]*3)*0.1) if e.get("sel",false) else Color(0,0,0,0)
		if e["hp"]<=0: _destroy_entity(e); continue
		if e["moving"]:
			var d=e["target_pos"]-e["pos"]; var dist=d.length()
			if dist<5:
				e["moving"]=false; e["pos"]=e["target_pos"]
				if e["task"]=="gathering" and e["gather_target"]:
					var res=e["gather_target"]
					if res["amount"]>0: _do_gather(e,res)
			else:
				d=d.normalized(); e["pos"]+=d*80*delta; e["node"].position=e["pos"]
		if not e["moving"] and e["task"]=="idle":
			if e["type"]=="villager" and rng.randf()<0.02: _ai_villager(e)
			elif e["type"]=="artisan" and rng.randf()<0.01: e["target_pos"]=e["pos"]+Vector2(rng.randf()*300-150,rng.randf()*300-150); e["moving"]=true
			elif e["type"] in ["warrior","archer","cavalry"] and rng.randf()<0.003: e["target_pos"]=e["pos"]+Vector2(rng.randf()*500-250,rng.randf()*500-250); e["moving"]=true
	# Enemies
	for en in enemies:
		if not is_instance_valid(en["node"]): continue
		if en["hp"]<=0: _enemy_death(en); continue
		var near=null; var md=600.0
		for e in entities:
			if not is_instance_valid(e["node"]): continue
			var d=en["pos"].distance_to(e["pos"])
			if d<md: md=d; near=e
		if near and not en["moving"]:
			en["target_pos"]=near["pos"]; en["moving"]=true
		elif not near:
			en["target_pos"]=Vector2(400,WORLD_H/2); en["moving"]=true
		if near and en["pos"].distance_to(near["pos"])<30 and rng.randf()<0.02:
			near["hp"]-=en["atk"]
		if en["moving"]:
			var d=en["target_pos"]-en["pos"]; var dist=d.length()
			if dist<5: en["moving"]=false; en["pos"]=en["target_pos"]
			else: en["pos"]+=(en["target_pos"]-en["pos"]).normalized()*40*delta; en["node"].position=en["pos"]
	# Player attacks
	for e in entities:
		if not is_instance_valid(e["node"]): continue
		if e["type"] in ["warrior","archer","cavalry","hero"]:
			for en in enemies:
				if not is_instance_valid(en["node"]): continue
				if e["pos"].distance_to(en["pos"])<30 and rng.randf()<0.03: en["hp"]-=e["atk"]
	# Towers auto-attack enemies
	for b in buildings:
		if b["type"] in ["tower_arrow","tower_stone","castle_defense","castle"]:
			for en in enemies:
				if not is_instance_valid(en.get("node")): continue
				if b["pos"].distance_to(en["pos"])<200 and rng.randf()<0.02: en["hp"]-=15

	# Crop growth
	for r in res_nodes:
		if r["type"]=="planted_crop" and r.get("growth",0)<100:
			r["growth"]=r.get("growth",0)+delta*0.12
			if r.get("growth",0)>=100:
				r["amount"]=30; r["type"]="wheat"
				if r.get("node"): r["node"].color=Color(1,0.85,0.2,0.7)
				if r.get("icon"): r["icon"].text="🌾"

	# Minimap
	_update_minimap()

func _update_minimap():
	var mm=ui.get_node("MMap"); if not mm: return
	for c in mm.get_children(): c.queue_free()
	var sx=160.0/WORLD_W; var sy=160.0/WORLD_H
	for b in buildings:
		var d=ColorRect.new(); d.size=Vector2(3,3); d.color=Color(0.6,0.4,0.2)
		d.position=Vector2(b["pos"].x*sx-1.5,b["pos"].y*sy-1.5); d.mouse_filter=Control.MOUSE_FILTER_IGNORE; mm.add_child(d)
	for e in entities:
		var d=ColorRect.new(); d.size=Vector2(2,2)
		d.color=Color(0.2,0.8,0.2) if e["type"]=="villager" else (Color(1,0.8,0) if e["type"]=="hero" else Color(0.8,0.2,0.2))
		d.position=Vector2(e["pos"].x*sx-1,e["pos"].y*sy-1); d.mouse_filter=Control.MOUSE_FILTER_IGNORE; mm.add_child(d)

# ════════════════════════════ AI ════════════════════════════
func _ai_villager(e):
	var nearest=null; var md=99999.0
	for r in res_nodes:
		if r["amount"]<=0: continue
		var d=e["pos"].distance_to(r["pos"]); if d<md: md=d; nearest=r
	if nearest and md<500: e["task"]="gathering"; e["gather_target"]=nearest; e["target_pos"]=nearest["pos"]; e["moving"]=true
	else: e["target_pos"]=Vector2(200+rng.randf()*500,WORLD_H/2-200+rng.randf()*400); e["moving"]=true

func _do_gather(e,res):
	if res["amount"]<=0: return
	res["amount"]-=1
	var rewards={"tree":"wood","gold":"gold","stone":"stone","deer":"food","wolf":"food","cow":"food","pig":"food","buffalo":"food","wheat":"food","potato":"food","corn":"food","fish":"food","planted_crop":"food"}
	var values={"tree":2,"gold":3,"stone":2,"deer":5,"wolf":3,"cow":6,"pig":4,"buffalo":8,"wheat":5,"potato":2,"corn":10,"fish":3,"planted_crop":5}
	if rewards.has(res["type"]):
		game_res[rewards[res["type"]]]+=values.get(res["type"],2)
	# Check mills nearby for bonus
	for b in buildings:
		if b["type"]=="mill" and res["pos"].distance_to(b["pos"])<200:
			game_res[rewards[res["type"]]]+=2
	if res["amount"]<=0:
		if res.get("renewable",true):
			res["amount"]=50+rng.randi()%20  # Mines/forests renew
		else:
			res["node"].queue_free(); res_nodes.erase(res)
		e["task"]="idle"; e["gather_target"]=null

func _destroy_entity(e):
	e["node"].queue_free(); entities.erase(e); if e in selected: selected.erase(e)
	if selected.size()==0: _hide_info()

func _enemy_death(en):
	en["node"].queue_free(); enemies.erase(en); game_res["gold"]+=10; game_res["food"]+=5

# ════════════════════════════ INPUT ════════════════════════════
func _input(event):
	if show_menu: return
	# Minimap click navigation
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var mx=event.position.x; var my=event.position.y
		if mx>=1078 and mx<=1238 and my>=518 and my<=678:
			var sx=(mx-1078)/160.0*WORLD_W; var sy=(my-518)/160.0*WORLD_H
			cam_target=Vector2(clamp(sx,320,WORLD_W-320),clamp(sy,180,WORLD_H-180))
			get_viewport().set_input_as_handled(); return
	
	if placing_building and event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_RIGHT:
			var wp=_sw(event.position)
			if wp.x>=50 and wp.x<WORLD_W-50 and wp.y>=50 and wp.y<WORLD_H-50: _confirm_building(placing_building,wp)
			placing_building=null; get_viewport().set_input_as_handled(); return
		elif event.button_index==MOUSE_BUTTON_LEFT:
			placing_building=null; get_viewport().set_input_as_handled(); return
	
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var wp=_sw(event.position)
		if wp.x>=0 and wp.x<WORLD_W and wp.y>=0 and wp.y<WORLD_H: _select_at(wp)
		get_viewport().set_input_as_handled(); return
	
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: zoom_target=clamp(zoom_target+0.1,0.3,2.0)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN: zoom_target=clamp(zoom_target-0.1,0.3,2.0)
	
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT and selected.size()>0:
		var wp=_sw(event.position)
		if wp.x>=0 and wp.x<WORLD_W and wp.y>=0 and wp.y<WORLD_H:
			var ck_res=null; var ck_en=null
			for r in res_nodes:
				if r["amount"]>0 and wp.distance_to(r["pos"])<30: ck_res=r; break
			for en in enemies:
				if is_instance_valid(en["node"]) and wp.distance_to(en["pos"])<30: ck_en=en; break
			for e in selected:
				if e["type"]=="villager" and ck_res: e["task"]="gathering"; e["gather_target"]=ck_res; e["target_pos"]=ck_res["pos"]; e["moving"]=true
				elif e["type"] in ["warrior","archer","cavalry","hero"] and ck_en: e["target_pos"]=ck_en["pos"]; e["moving"]=true
				else: e["target_pos"]=wp; e["moving"]=true; e["task"]="idle"; e["gather_target"]=null

func _sw(s): return (s+cam-Vector2(640.0/zoom_level,360.0/zoom_level))/zoom_level

func _select_at(wp):
	for oe in entities: oe["sel"]=false
	selected.clear(); _hide_info()
	var nearest=null; var md=40.0
	for e in entities:
		if not is_instance_valid(e["node"]): continue
		var abs_pos=e["pos"]+world.position; var d=wp.distance_to(abs_pos)
		if d<md: md=d; nearest=e
	if nearest: _select_entity(nearest); return
	for b in buildings:
		if not is_instance_valid(b["node"]): continue
		if wp.distance_to(b["pos"])<50: _select_building(b); return

func _select_entity(e):
	if e["type"] in ["villager","hero","artisan","warrior","archer","cavalry"]:
		# Ctrl+click = multi-select
		if Input.is_key_pressed(KEY_CTRL):
			e["sel"]=true; selected.append(e); _show_multi_info()
			return
		for oe in entities: oe["sel"]=false
		selected.clear(); e["sel"]=true; selected.append(e); _show_info(e)

func _show_info(e):
	var ip=ui.get_node("InfoPanel"); var il=ui.get_node("InfoLabel"); ip.visible=true
	var names={"hero":"Heroe","villager":"Aldeano","artisan":"Artesano","warrior":"Guerrero","archer":"Arquero","cavalry":"Jinete"}
	var ico={"hero":"🦸","villager":"👷","artisan":"🔧","warrior":"⚔","archer":"🏹","cavalry":"🐎"}
	il.text=ico.get(e["type"],"?")+" "+names.get(e["type"],e["type"])+" | HP:"+str(e["hp"])+"/"+str(e["max_hp"])+" ("+str(ceil(float(e["hp"])/e["max_hp"]*100))+"%) | ATK:"+str(e["atk"])
	for i in range(13): var b=ui.get_node("Build"+str(i)); if b: b.visible=false
	for i in 3: var act=ui.get_node("Act"+str(i)); if act: act.visible=false
	# Show actions based on unit type
	var actions=[]
	if e["type"]=="villager": actions=["🏗 Construir","🌱 Cultivar","🏃 Mover a"]
	elif e["type"]=="artisan": actions=["🔧 Mejorar Unidad","🔨 Mejorar Arma","🏃 Mover a"]
	elif e["type"] in ["warrior","archer","cavalry"]: actions=["⚔ Atacar","🗺 Explorar","🏃 Mover a"]
	elif e["type"]=="hero": actions=["⚡ Habilidad","⚔ Atacar","🏃 Mover a"]
	for i in 3:
		var act=ui.get_node("Act"+str(i))
		if act and i<actions.size(): act.visible=true; act.text=actions[i]

func _show_multi_info():
	var ip=ui.get_node("InfoPanel"); var il=ui.get_node("InfoLabel"); ip.visible=true
	il.text=str(selected.size())+" unidades seleccionadas"
	for i in range(13): var b=ui.get_node("Build"+str(i)); if b: b.visible=false
	var act=ui.get_node("Act0")
	if act: act.visible=true; act.text="🏃 Mover todas"

func _select_building(b):
	selected_building=b
	var ip=ui.get_node("InfoPanel"); var il=ui.get_node("InfoLabel"); ip.visible=true
	var names={"castle":"🏰 Castillo","barracks":"⚔ Cuartel","archery":"🏹 Arqueria","stable":"🐎 Caballeriza","siege":"💣 Asedio","wall":"🧱 Muralla","gate":"🚪 Puerta","house":"🏠 Casa","tower_arrow":"🗼 T.Flechas","tower_stone":"🏰 T.Piedra","castle_defense":"🏯 C.Defensa","market":"🏪 Mercado","church":"⛪ Iglesia","forge":"🔨 Forja","mill":"🏭 Molino","shipyard":"🚢 Astillero"}
	il.text=names.get(b["type"],b["type"])+" | HP:"+str(b["hp"])+"/"+str(b["max_hp"])
	for i in range(13): var btn=ui.get_node("Build"+str(i)); if btn: btn.visible=false
	for i in 3: var act=ui.get_node("Act"+str(i)); if act: act.visible=false
	var bu={"barracks":[["Guerrero","50🪙"],["Espadachin","100🪙"]],"archery":[["Arquero","80🪙"],["Arquero Largo","120🪙"]],"stable":[["Jinete","120🪙"],["Jinete Pesado","200🪙"]],"siege":[["Ariete","200🪙"],["Catapulta","300🪙"]],"shipyard":[["Barco","150🪙"]]}
	if b["type"]=="church":
		for i in [0,1]:
			var act=ui.get_node("Act"+str(i))
			if act: act.visible=true; act.text=["✨ Revivir","💚 Sanar"][i]
	if b["type"]=="forge":
		for i in [0,1]:
			var act=ui.get_node("Act"+str(i))
			if act: act.visible=true; act.text=["⚔ +ATK(100🪙)","🛡 +DEF(80🪙)"][i]
	if bu.has(b["type"]):
		var units=bu[b["type"]]
		for i in 3:
			var act=ui.get_node("Act"+str(i))
			if act and i<units.size(): act.visible=true; act.text=units[i][0]+"\n"+units[i][1]
func _on_act(idx):
	if selected_building:
		# Train units from building
		var train={"barracks":["warrior"],"archery":["archer"],"stable":["cavalry"],"siege":["siege_ram"]}
		var btype=selected_building["type"]
		if train.has(btype) and idx<train[btype].size():
			var unit=train[btype][idx]
			var costs={"warrior":{"gold":50,"food":25},"archer":{"gold":80,"food":15,"wood":30},"cavalry":{"gold":120,"food":40},"siege_ram":{"gold":200,"wood":150}}
			var cost=costs.get(unit,{"gold":50})
			for r in cost:
				if game_res.get(r,0)<cost[r]: _notify("Sin recursos"); return
			for r in cost: game_res[r]-=cost[r]
			var sp=selected_building["pos"]+Vector2(40+rng.randi()%20,-10+rng.randi()%20)
			var d=Globals.unit_defs.get(unit,Globals.unit_defs["warrior"])
			_make_entity(unit,sp,"?",d["color"],d["hp"],d["atk"])
			_notify("Unidad entrenada!"); return
	if selected.size()==0: return
	var e=selected[0]
	# Villager actions
	if e["type"]=="villager":
		if idx==0: _toggle_build_menu()
		elif idx==1: _plant_crop(e)
		elif idx==2: _notify("Click derecho en destino")
	# Artisan actions
	elif e["type"]=="artisan":
		if idx==0: _notify("Selecciona unidad aliada para mejorar (+5 ATK, -50 oro)")
		elif idx==1: _notify("Selecciona edificio para mejorar armas")
	# Military actions
	elif e["type"] in ["warrior","archer","cavalry"]:
		if idx==0: _notify("Click derecho en enemigo para atacar")
		elif idx==1: _notify("La unidad explorara automaticamente")
		elif idx==2: _notify("Click derecho en destino para mover")
	# Hero actions
	elif e["type"]=="hero":
		if idx==0: _use_hero_skill()
		elif idx==1: _notify("Click derecho en enemigo para atacar")

func _use_hero_skill():
	var e=selected[0]; if not e["type"]=="hero": return
	e["hp"]=min(e["max_hp"],e["hp"]+50)
	for en in enemies:
		if not is_instance_valid(en.get("node")): continue
		if e["pos"].distance_to(en["pos"])<200: en["hp"]-=e["atk"]*2
	_notify("Habilidad del heroe activada!")

func _plant_crop(e):
	if game_res["food"]<10: _notify("Necesitas 10 comida para plantar"); return
	game_res["food"]-=10
	var pos=e["pos"]+Vector2(rng.randi()%40-20,rng.randi()%40-20)
	var r=ColorRect.new(); r.size=Vector2(16,16); r.position=pos
	r.color=Color(0.5,0.8,0.2,0.6); r.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(r)
	var l=Label.new(); l.text="🌱"; l.add_theme_font_size_override("font_size",12)
	l.position=pos-Vector2(6,14); l.size=Vector2(24,24); l.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(l)
	res_nodes.append({"type":"planted_crop","pos":pos,"amount":5,"node":r,"icon":l,"growth":0,"renewable":false})

func _toggle_build_menu():
	var vis=not ui.get_node("Build0").visible
	for i in range(13): var b=ui.get_node("Build"+str(i)); if b: b.visible=vis
	var it=ui.get_node("InfoText")
	if it: it.text="Selecciona un edificio. Click derecho en el mapa para colocar." if vis else ""

func _hide_info():
	var ip=ui.get_node("InfoPanel"); if ip: ip.visible=false
	for i in range(13): var b=ui.get_node("Build"+str(i)); if b: b.visible=false
	for i in 3: var act=ui.get_node("Act"+str(i)); if act: act.visible=false
	selected_building=null

func _place_building(type):
	placing_building=type; _notify("🔨 Click derecho en el mapa para colocar")

func _confirm_building(type,pos):
	var costs={"wall":{"stone":10},"gate":{"stone":15,"wood":10},"house":{"wood":50,"stone":20},"barracks":{"gold":100,"wood":100},"archery":{"gold":120,"wood":80,"stone":50},"stable":{"gold":150,"wood":60,"stone":30},"siege":{"gold":200,"wood":100,"stone":100},"tower_arrow":{"gold":80,"stone":100,"wood":40},"tower_stone":{"gold":150,"stone":200,"wood":60},"castle_defense":{"gold":300,"stone":300,"wood":100},"market":{"gold":120,"wood":80},"church":{"gold":100,"stone":80,"wood":50},"forge":{"gold":80,"stone":50,"wood":60},"mill":{"gold":60,"wood":80,"stone":30},"shipyard":{"gold":200,"wood":300,"stone":50}}
	var cost=costs.get(type,{})
	for r in cost:
		if game_res.get(r,0)<cost[r]: _notify("❌ Recursos insuficientes!"); return
	for r in cost: game_res[r]-=cost[r]
	_make_building(type,pos); _notify("✅ Construido!")

# ════════════════════════════ MENU ════════════════════════════
func _toggle_menu():
	show_menu=!show_menu
	if show_menu: _show_menu()
	else: _hide_menu()

func _show_menu():
	var o=ColorRect.new(); o.name="MenuO"; o.size=Vector2(1280,720); o.color=Color(0,0,0,0.75); ui.add_child(o)
	var t=Label.new(); t.text="☰ MENU DEL JUEGO"; t.add_theme_font_size_override("font_size",24)
	t.position=Vector2(440,150); t.size=Vector2(400,40); t.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; o.add_child(t)
	var items=[["▶ REANUDAR","_resume"],["🔄 REINICIAR","_restart"],["💾 GUARDAR","_save"],["🏠 MENU PRINCIPAL","_main_menu"]]
	for i in range(items.size()):
		var b=Button.new(); b.text=items[i][0]; b.position=Vector2(490,220+i*60); b.size=Vector2(300,45)
		o.add_child(b); b.pressed.connect(Callable(self,items[i][1]))

func _hide_menu():
	var o=ui.get_node_or_null("MenuO"); if o: o.queue_free(); show_menu=false

func _resume(): _hide_menu()
func _restart(): get_tree().reload_current_scene()
func _save():
	for i in range(5):
		if not FileAccess.file_exists("user://save_"+str(i)+".json"): _do_save(i); return
	_do_save(0)

func _do_save(slot):
	var data={"timestamp":Time.get_datetime_string_from_system(),"resources":game_res,"player":Globals.player_name}
	var f=FileAccess.open("user://save_"+str(slot)+".json",FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(data)); f.close(); _notify("💾 Guardado slot "+str(slot+1))

func _main_menu(): get_tree().change_scene_to_file("res://scenes/ModeSelect.tscn")

func _notify(txt):
	var n=Label.new(); n.text=txt; n.add_theme_font_size_override("font_size",14)
	n.position=Vector2(440,350); n.size=Vector2(400,30); n.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; n.modulate=Color(1,0.85,0.3)
	ui.add_child(n); create_tween().tween_property(n,"modulate:a",0.0,2.0).set_delay(1.5)
	create_tween().tween_callback(n.queue_free).set_delay(3.5)
