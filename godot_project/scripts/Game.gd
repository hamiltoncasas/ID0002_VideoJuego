extends Control

const WORLD_W=6000; const WORLD_H=6000
var cam=Vector2(500,1800); var cam_target=Vector2(500,1800)
var cam_speed=400.0; var zoom_level=1.0; var zoom_target=1.0
var entities=[]; var enemies=[]; var buildings=[]; var res_nodes=[]
var selected=[]; var placing_building=null; var selected_building=null
var game_res={"gold":300,"stone":200,"food":200,"wood":200}
var show_menu=false

@onready var world=$World; @onready var ents=$World/Entities; @onready var ui=$UI
var rng=RandomNumberGenerator.new()

func _ready():
	_gen_terrain(); _gen_resources(); _gen_buildings(); _spawn_units()
	_build_hud(); _build_minimap()

# ═══════════ TERRAIN ═══════════
func _gen_terrain():
	var bg=ColorRect.new(); bg.size=Vector2(WORLD_W,WORLD_H); bg.color=Color(0.1,0.25,0.07)
	bg.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(bg)
	for i in 40:
		var p=ColorRect.new(); p.size=Vector2(40+rng.randi()%200,30+rng.randi()%150)
		p.position=Vector2(rng.randi()%(WORLD_W-200),rng.randi()%(WORLD_H-150))
		p.color=Color(0.15+rng.randf()*0.08,0.28+rng.randf()*0.08,0.08+rng.randf()*0.05,0.12)
		p.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(p)
	var lake=ColorRect.new(); lake.size=Vector2(300,200); lake.position=Vector2(2500,1200)
	lake.color=Color(0.1,0.3,0.45,0.3); lake.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(lake)

func _gen_resources():
	for i in range(30):
		var pos=Vector2(100+rng.randi()%(WORLD_W-200),100+rng.randi()%(WORLD_H-200))
		var r=ColorRect.new(); r.size=Vector2(20,20); r.position=pos; r.color=Color(0.05,0.4,0.05)
		r.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(r)
		var l=Label.new(); l.text="🌲"; l.add_theme_font_size_override("font_size",16)
		l.position=pos-Vector2(8,16); l.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(l)
		res_nodes.append({"type":"tree","pos":pos,"amount":50+rng.randi()%30,"node":r})
	for i in range(5):
		var pos=Vector2(100+rng.randi()%(WORLD_W-200),100+rng.randi()%(WORLD_H-200))
		var r=ColorRect.new(); r.size=Vector2(18,18); r.position=pos; r.color=Color(1,0.7,0.1)
		r.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(r)
		var l=Label.new(); l.text="💎"; l.add_theme_font_size_override("font_size",14)
		l.position=pos-Vector2(7,14); l.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(l)
		res_nodes.append({"type":"gold","pos":pos,"amount":200+rng.randi()%100,"node":r})
	for i in range(5):
		var pos=Vector2(100+rng.randi()%(WORLD_W-200),100+rng.randi()%(WORLD_H-200))
		var r=ColorRect.new(); r.size=Vector2(18,18); r.position=pos; r.color=Color(0.5,0.5,0.5)
		r.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(r)
		var l=Label.new(); l.text="🪨"; l.add_theme_font_size_override("font_size",14)
		l.position=pos-Vector2(7,14); l.mouse_filter=Control.MOUSE_FILTER_IGNORE; world.add_child(l)
		res_nodes.append({"type":"stone","pos":pos,"amount":150+rng.randi()%100,"node":r})

func _gen_buildings():
	_make_building("castle",Vector2(400,WORLD_H/2-40))
	_make_building("barracks",Vector2(300,WORLD_H/2-120))
	_make_building("archery",Vector2(300,WORLD_H/2+80))

func _make_building(type,pos):
	var sizes={"castle":Vector2(80,80),"barracks":Vector2(50,45),"archery":Vector2(45,42),"stable":Vector2(55,45),"wall":Vector2(40,20)}
	var colors={"castle":Color(0.5,0.3,0.15),"barracks":Color(0.45,0.2,0.1),"archery":Color(0.4,0.25,0.1),"stable":Color(0.45,0.3,0.12),"wall":Color(0.5,0.4,0.3)}
	var icons={"castle":"🏰","barracks":"⚔","archery":"🏹","stable":"🐎","wall":"🧱"}
	var hp_vals={"castle":5000,"barracks":1500,"archery":1200,"stable":1800,"wall":2000}
	var bnode=Node2D.new(); bnode.position=pos; world.add_child(bnode)
	var body=ColorRect.new(); body.size=sizes.get(type,Vector2(50,50)); body.position=-body.size/2
	body.color=colors.get(type,Color(0.3,0.2,0.1)); body.mouse_filter=Control.MOUSE_FILTER_IGNORE; bnode.add_child(body)
	var lbl=Label.new(); lbl.text=icons.get(type,"🏗"); lbl.add_theme_font_size_override("font_size",22)
	lbl.position=Vector2(-15,-12); bnode.add_child(lbl)
	buildings.append({"type":type,"node":bnode,"pos":pos,"hp":hp_vals.get(type,1000),"max_hp":hp_vals.get(type,1000)})

func _spawn_units():
	var cp=Vector2(400,WORLD_H/2-40)
	_make_entity("hero",cp+Vector2(-40,20),Color(1,0.7,0.1),1500,70)
	_make_entity("villager",cp+Vector2(-90,-60),Color(0.55,0.35,0.25),100,8)
	_make_entity("villager",cp+Vector2(-90,80),Color(0.55,0.35,0.25),100,8)
	_make_entity("warrior",cp+Vector2(80,-80),Color(0.65,0.35,0.2),300,35)
	_make_entity("archer",cp+Vector2(80,0),Color(0.25,0.55,0.25),150,42)
	_make_entity("cavalry",cp+Vector2(80,80),Color(0.75,0.45,0.2),400,48)
	_spawn_enemies()

func _make_entity(type,pos,color,hp,atk):
	var ent=Node2D.new(); ent.position=pos; ent.z_index=100; ents.add_child(ent)
	var body=ColorRect.new(); body.size=Vector2(22,22); body.position=Vector2(-11,-11)
	body.color=color; body.mouse_filter=Control.MOUSE_FILTER_IGNORE; ent.add_child(body)
	var hb=ColorRect.new(); hb.size=Vector2(22,3); hb.position=Vector2(-11,-28)
	hb.color=Color(0.15,0.03,0.03,0.7); hb.mouse_filter=Control.MOUSE_FILTER_IGNORE; ent.add_child(hb)
	var hf=ColorRect.new(); hf.size=Vector2(22,3); hf.position=Vector2(-11,-28)
	hf.color=Color(0.2,0.8,0.2,0.9); hf.mouse_filter=Control.MOUSE_FILTER_IGNORE; ent.add_child(hf)
	var ht=Label.new(); ht.add_theme_font_size_override("font_size",6)
	ht.position=Vector2(-11,-36); ht.size=Vector2(22,8); ht.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	ht.mouse_filter=Control.MOUSE_FILTER_IGNORE; ent.add_child(ht)
	var sel=ColorRect.new(); sel.size=Vector2(26,26); sel.position=Vector2(-13,-13)
	sel.color=Color(0,0,0,0); sel.mouse_filter=Control.MOUSE_FILTER_IGNORE; ent.add_child(sel)
	entities.append({"type":type,"node":ent,"pos":pos,"target_pos":pos,"hp":hp,"max_hp":hp,"atk":atk,"moving":false,"task":"idle","anim_time":rng.randf()*100,"hp_fill":hf,"hp_text":ht,"sel_ring":sel})

func _spawn_enemies():
	for i in range(5):
		var pos=Vector2(3000+rng.randi()%500,500+rng.randi()%4000)
		var ent=Node2D.new(); ent.position=pos; ent.z_index=100; ents.add_child(ent)
		var body=ColorRect.new(); body.size=Vector2(20,20); body.position=Vector2(-10,-10)
		body.color=Color(0.5,0.12,0.12); body.mouse_filter=Control.MOUSE_FILTER_IGNORE; ent.add_child(body)
		var lbl=Label.new(); lbl.text="⚔"; lbl.add_theme_font_size_override("font_size",14)
		lbl.position=Vector2(-7,-22); lbl.mouse_filter=Control.MOUSE_FILTER_IGNORE; ent.add_child(lbl)
		enemies.append({"type":"enemy","node":ent,"pos":pos,"target_pos":pos,"hp":150,"atk":10,"moving":false})

# ═══════════ HUD ═══════════
func _build_hud():
	var bar=ColorRect.new(); bar.size=Vector2(1280,34); bar.color=Color(0,0,0,0.85)
	bar.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(bar)
	var keys=["gold","stone","food","wood"]; var icons=["🪙","🪨","🌾","🪵"]
	for i in 4:
		var l=Label.new(); l.text=icons[i]+" "+keys[i]+": "+str(game_res[keys[i]])
		l.add_theme_font_size_override("font_size",11); l.position=Vector2(15+i*180,6); l.size=Vector2(170,24)
		l.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(l)
	var mb=Button.new(); mb.text="☰ MENU"; mb.position=Vector2(1180,4); mb.size=Vector2(90,28)
	ui.add_child(mb); mb.pressed.connect(_toggle_menu)
	# Info panel
	var ip=ColorRect.new(); ip.name="InfoPanel"; ip.size=Vector2(1280,100); ip.position=Vector2(0,620)
	ip.color=Color(0,0,0,0.8); ip.visible=false; ui.add_child(ip)
	var il=Label.new(); il.name="InfoLabel"; il.position=Vector2(20,625); il.size=Vector2(400,50)
	il.add_theme_font_size_override("font_size",13); ui.add_child(il)
	# Build buttons
	var btypes=["wall","barracks","archery","stable","tower"]
	var bnames=["🧱 Muro","⚔ Cuartel","🏹 Arqueria","🐎 Caballeriza","🗼 Torre"]
	for i in 5:
		var b=Button.new(); b.name="Build"+str(i); b.position=Vector2(20+i*130,670); b.size=Vector2(120,40)
		b.visible=false; ui.add_child(b)
		var bi=i; b.pressed.connect(func(): _start_placing(btypes[bi]))
	# Action buttons
	for i in 3:
		var act=Button.new(); act.name="Act"+str(i); act.position=Vector2(480+i*90,685); act.size=Vector2(80,30)
		act.visible=false; ui.add_child(act)
		var ai=i; act.pressed.connect(func(): _on_action(ai))

func _build_minimap():
	var bg=ColorRect.new(); bg.size=Vector2(164,164); bg.position=Vector2(1280-204,720-204)
	bg.color=Color(0.03,0.02,0.06,0.95); ui.add_child(bg)
	var m=ColorRect.new(); m.size=Vector2(160,160); m.position=Vector2(1280-202,720-202)
	m.color=Color(0.08,0.18,0.05); ui.add_child(m)

# ═══════════ LOOP ═══════════
func _process(delta):
	if show_menu: return
	var mv=Vector2()
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): mv.x-=1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): mv.x+=1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): mv.y-=1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): mv.y+=1
	if mv.length()<0.1:
		var ms=get_global_mouse_position()
		if ms.x<15: mv.x-=1; if ms.x>1265: mv.x+=1; if ms.y<42: mv.y-=1; if ms.y>710: mv.y+=1
	if mv.length()>0:
		mv=mv.normalized()*cam_speed*delta*(1.0/zoom_level); cam_target+=mv
		cam_target.x=clamp(cam_target.x,320,WORLD_W-320)
		cam_target.y=clamp(cam_target.y,180,WORLD_H-180)
	cam=cam.lerp(cam_target,delta*5.0); zoom_level=lerp(zoom_level,zoom_target,delta*5.0)
	world.scale=Vector2(zoom_level,zoom_level); world.position=-cam+Vector2(640/zoom_level,360/zoom_level)
	# Update entities
	for e in entities:
		if not is_instance_valid(e["node"]): continue
		e["anim_time"]+=delta
		var hp_pct=float(e["hp"])/max(e["max_hp"],1)
		e["hp_fill"].size.x=22*hp_pct
		e["hp_text"].text=str(ceil(hp_pct*100))+"%"
		e["sel_ring"].color=Color(1,0.8,0,0.3) if e.get("sel",false) else Color(0,0,0,0)
		if e["hp"]<=0: e["node"].queue_free(); entities.erase(e); continue
		if e["moving"]:
			var d=e["target_pos"]-e["pos"]; var dist=d.length()
			if dist<5: e["moving"]=false; e["pos"]=e["target_pos"]
			else:
				d=d.normalized(); e["pos"]+=d*200*delta; e["node"].position=e["pos"]
				e["node"].position.y+=sin(e["anim_time"]*12)*2
		else: e["node"].position.y=e["pos"].y+sin(e["anim_time"]*2)*0.8
		if not e["moving"] and e["task"]=="idle" and e["type"]=="villager" and rng.randf()<0.02:
			_ai_gather(e)
	# Enemies move toward player
	for en in enemies:
		if not is_instance_valid(en["node"]): continue
		if en["hp"]<=0: en["node"].queue_free(); enemies.erase(en); game_res["gold"]+=10; continue
		var near=null; var md=600.0
		for e in entities:
			if not is_instance_valid(e["node"]): continue
			var d=en["pos"].distance_to(e["pos"]); if d<md: md=d; near=e
		if near: en["target_pos"]=near["pos"]; en["moving"]=true
		if near and en["pos"].distance_to(near["pos"])<30 and rng.randf()<0.02: near["hp"]-=en["atk"]
		if en["moving"]:
			var d=en["target_pos"]-en["pos"]; var dist=d.length()
			if dist<5: en["moving"]=false; en["pos"]=en["target_pos"]
			else: en["pos"]+=(en["target_pos"]-en["pos"]).normalized()*40*delta; en["node"].position=en["pos"]
	# Player military attacks nearby enemies
	for e in entities:
		if e["type"] in ["warrior","archer","cavalry","hero"]:
			for en in enemies:
				if not is_instance_valid(en["node"]): continue
				if e["pos"].distance_to(en["pos"])<30 and rng.randf()<0.03: en["hp"]-=e["atk"]
	# Towers attack
	for b in buildings:
		if b["type"] in ["tower","castle"]:
			for en in enemies:
				if not is_instance_valid(en["node"]): continue
				if b["pos"].distance_to(en["pos"])<200 and rng.randf()<0.02: en["hp"]-=15

func _ai_gather(e):
	var nearest=null; var md=99999.0
	for r in res_nodes:
		if r["amount"]<=0: continue
		var d=e["pos"].distance_to(r["pos"]); if d<md: md=d; nearest=r
	if nearest and md<500: e["task"]="gathering"; e["target_pos"]=nearest["pos"]; e["moving"]=true
	elif nearest and md<30: nearest["amount"]-=1; game_res[nearest["type"]]+=2

# ═══════════ INPUT ═══════════
func _input(event):
	if show_menu: return
	# Minimap click
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var mx=event.position.x; var my=event.position.y
		if mx>=1078 and mx<=1238 and my>=518 and my<=678:
			cam_target=Vector2(clamp((mx-1078)/160.0*WORLD_W,320,WORLD_W-320),clamp((my-518)/160.0*WORLD_H,180,WORLD_H-180))
			get_viewport().set_input_as_handled(); return
	# Building placement
	if placing_building and event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_RIGHT:
			var wp=_sw(event.position)
			if wp.x>=50 and wp.x<WORLD_W-50 and wp.y>=50 and wp.y<WORLD_H-50: _place_building(placing_building,wp)
			placing_building=null; get_viewport().set_input_as_handled(); return
		elif event.button_index==MOUSE_BUTTON_LEFT:
			placing_building=null; get_viewport().set_input_as_handled(); return
	# Right click with villager = build menu
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT and selected.size()>0:
		if selected[0]["type"]=="villager": _toggle_build()
		get_viewport().set_input_as_handled(); return
	# Left click = select or move
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var wp=_sw(event.position)
		if wp.x>=0 and wp.x<WORLD_W and wp.y>=0 and wp.y<WORLD_H:
			if selected.size()>0:
				for e in selected: e["target_pos"]=wp; e["moving"]=true; e["task"]="idle"
				_deselect_all()
			else: _select_at(wp)
		get_viewport().set_input_as_handled(); return
	# Zoom
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: zoom_target=clamp(zoom_target+0.1,0.3,2.0)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN: zoom_target=clamp(zoom_target-0.1,0.3,2.0)

func _sw(s): return (s+cam-Vector2(640.0/zoom_level,360.0/zoom_level))/zoom_level

func _toggle_build():
	var vis=not ui.get_node("Build0").visible
	for i in 5: var b=ui.get_node("Build"+str(i)); if b: b.visible=vis

func _start_placing(type): placing_building=type; _notify("Click DERECHO en mapa para colocar")

func _place_building(type,pos):
	var costs={"wall":{"stone":10},"barracks":{"gold":100,"wood":100},"archery":{"gold":120,"wood":80},"stable":{"gold":150,"wood":60},"tower":{"gold":80,"stone":100}}
	var cost=costs.get(type,{})
	for r in cost:
		if game_res.get(r,0)<cost[r]: _notify("Sin recursos"); return
	for r in cost: game_res[r]-=cost[r]
	_make_building(type,pos); _notify("Construido!")

func _select_at(wp):
	_deselect_all()
	for e in entities:
		if is_instance_valid(e.get("node")) and wp.distance_to(e["pos"])<40:
			e["sel"]=true; selected.append(e); _show_info(e); return
	for b in buildings:
		if is_instance_valid(b.get("node")) and wp.distance_to(b["pos"])<50:
			_show_building(b); return

func _show_info(e):
	var ip=ui.get_node("InfoPanel"); var il=ui.get_node("InfoLabel"); ip.visible=true
	var names={"hero":"Heroe","villager":"Aldeano","warrior":"Guerrero","archer":"Arquero","cavalry":"Jinete"}
	il.text=names.get(e["type"],e["type"])+" | HP:"+str(e["hp"])+"/"+str(e["max_hp"])+" | ATK:"+str(e["atk"])
	_hide_build_btns()
	if e["type"]=="villager":
		var act=ui.get_node("Act0"); act.visible=true; act.text="🏗 Construir"

func _show_building(b):
	selected_building=b
	var ip=ui.get_node("InfoPanel"); var il=ui.get_node("InfoLabel"); ip.visible=true
	il.text=b["type"]+" | HP:"+str(b["hp"])+"/"+str(b["max_hp"])
	_hide_build_btns()

func _deselect_all():
	for oe in entities: oe["sel"]=false
	selected.clear()
	var ip=ui.get_node("InfoPanel"); ip.visible=false
	_hide_build_btns()

func _hide_build_btns():
	for i in 5: var b=ui.get_node("Build"+str(i)); if b: b.visible=false
	for i in 3: var act=ui.get_node("Act"+str(i)); if act: act.visible=false

func _on_action(idx):
	if idx==0 and selected.size()>0 and selected[0]["type"]=="villager": _toggle_build()

# ═══════════ MENU ═══════════
func _toggle_menu():
	show_menu=!show_menu
	if show_menu:
		var o=ColorRect.new(); o.name="MenuO"; o.size=Vector2(1280,720); o.color=Color(0,0,0,0.75); ui.add_child(o)
		var t=Label.new(); t.text="MENU"; t.add_theme_font_size_override("font_size",24)
		t.position=Vector2(440,150); t.size=Vector2(400,40); t.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; o.add_child(t)
		for i in range(4):
			var b=Button.new(); b.text=["REANUDAR","REINICIAR","GUARDAR","SALIR"][i]
			b.position=Vector2(490,220+i*60); b.size=Vector2(300,45); o.add_child(b)
			var ci=i; b.pressed.connect(func():
				if ci==0: _hide_menu()
				elif ci==1: get_tree().reload_current_scene()
				elif ci==2: _do_save()
				elif ci==3: get_tree().change_scene_to_file("res://scenes/ModeSelect.tscn"))
	else: _hide_menu()

func _hide_menu():
	var o=ui.get_node_or_null("MenuO"); if o: o.queue_free(); show_menu=false

func _do_save():
	var f=FileAccess.open("user://save.json",FileAccess.WRITE)
	if f: f.store_string(JSON.stringify({"resources":game_res})); f.close(); _notify("Guardado!")

func _notify(txt):
	var n=Label.new(); n.text=txt; n.add_theme_font_size_override("font_size",14)
	n.position=Vector2(440,350); n.size=Vector2(400,30); n.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; n.modulate=Color(1,0.85,0.3)
	ui.add_child(n); create_tween().tween_property(n,"modulate:a",0.0,2.0).set_delay(1.2)
	create_tween().tween_callback(n.queue_free).set_delay(3.0)
