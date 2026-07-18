extends Control

const SCREEN_W = 1280
const SCREEN_H = 720

var time = 0.0
var bg_layers = []
var particles = []
var card_infos = []

func _ready():
	_build_background()
	_build_particles()
	_build_decorations()
	_build_title()
	_build_cards()
	_build_save_slots()

func _build_background():
	for i in 6:
		var r = ColorRect.new()
		r.size = Vector2(SCREEN_W, SCREEN_H)
		var t = i * 0.025
		r.color = Color(0.03 + t, 0.01 + t * 0.2, 0.06 + t * 0.4, 0.4 + i * 0.08)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.name = "BgLayer" + str(i)
		add_child(r)
		bg_layers.append(r)

	var ag = ColorRect.new()
	ag.size = Vector2(SCREEN_W, 300)
	ag.position = Vector2(0, SCREEN_H - 300)
	ag.color = Color(0.2, 0.05, 0.1, 0.1)
	ag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ag)

func _build_particles():
	for i in 25:
		var p = ColorRect.new()
		var sz = 1.5 + randi() % 3
		p.size = Vector2(sz, sz)
		p.position = Vector2(randi() % SCREEN_W, randi() % SCREEN_H)
		var alpha = 0.06 + randf() * 0.2
		var hue = 0.72 + randf() * 0.2
		p.color = Color.from_hsv(hue, 0.5, 0.7, alpha)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.name = "Particle" + str(i)
		add_child(p)
		particles.append({
			rect = p,
			speed = 5 + randf() * 22,
			drift = (randf() - 0.5) * 10,
			phase = randf() * TAU,
			flicker_speed = 1.5 + randf() * 3.0
		})

func _build_decorations():
	var bar = ColorRect.new()
	bar.name = "TopBar"
	bar.size = Vector2(SCREEN_W, 3)
	bar.color = Color(1, 0.7, 0.1, 0.35)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)

	var bbar = ColorRect.new()
	bbar.size = Vector2(SCREEN_W, 2)
	bbar.position = Vector2(0, SCREEN_H - 2)
	bbar.color = Color(0.5, 0.3, 0.1, 0.12)
	bbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bbar)

	for side in [0, 1]:
		var p = ColorRect.new()
		p.size = Vector2(1, SCREEN_H)
		p.position = Vector2(side * (SCREEN_W - 1), 0)
		p.color = Color(0.4, 0.25, 0.08, 0.05)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(p)

func _build_title():
	var title = Label.new()
	title.text = "SELECCIONA MODO DE JUEGO"
	title.add_theme_font_size_override("font_size", 30)
	title.position = Vector2(140, 28)
	title.size = Vector2(1000, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1, 0.85, 0.3)
	add_child(title)

	var gl = ColorRect.new()
	gl.name = "TitleGlow"
	gl.size = Vector2(320, 2)
	gl.position = Vector2(480, 72)
	gl.color = Color(1, 0.65, 0.1, 0.12)
	gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gl)

	var pinfo = Label.new()
	pinfo.text = "ARQUEOLOGO: " + Globals.player_name.to_upper()
	pinfo.add_theme_font_size_override("font_size", 11)
	pinfo.position = Vector2(140, 85)
	pinfo.size = Vector2(1000, 20)
	pinfo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pinfo.modulate = Color(0.55, 0.5, 0.7, 0.65)
	add_child(pinfo)

func _build_cards():
	var card_data = [
		{
			pos = Vector2(90, 125),
			w = 340, h = 290,
			title = "MODO OFFLINE",
			icon = "A",
			desc = "Aventura individual\nMapa completo 4000x4000\nRecursos y construccion\nIA de unidades enemigas",
			accent = Color(0.15, 0.5, 0.2, 0.85),
			callback = "_on_offline"
		},
		{
			pos = Vector2(470, 125),
			w = 340, h = 290,
			title = "ONLINE 1v1",
			icon = "B",
			desc = "Disponible en el futuro\nCombate contra otro\njugador en tiempo real",
			accent = Color(0.5, 0.15, 0.15, 0.85),
			callback = "_on_online1v1"
		},
		{
			pos = Vector2(850, 125),
			w = 340, h = 290,
			title = "ONLINE 3v3",
			icon = "C",
			desc = "Disponible en el futuro\nBatallas por equipos\nEstrategia cooperativa",
			accent = Color(0.5, 0.15, 0.5, 0.85),
			callback = "_on_online3v3"
		}
	]

	for data in card_data:
		_create_card(data)

func _create_card(data):
	var pos = data.pos
	var w = data.w
	var h = data.h
	var title = data.title
	var icon = data.icon
	var desc = data.desc
	var accent = data.accent
	var callback = data.callback

	var shadow = ColorRect.new()
	shadow.size = Vector2(w + 6, h + 6)
	shadow.position = pos + Vector2(4, 4)
	shadow.color = Color(0, 0, 0, 0.35)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shadow)

	var card = ColorRect.new()
	card.size = Vector2(w, h)
	card.position = pos
	card.color = Color(0.07, 0.05, 0.14, 0.92)
	card.name = "Card" + title.replace(" ", "")
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(card)

	var ci = {
		rect = card,
		base_pos = pos,
		base_color = Color(0.07, 0.05, 0.14, 0.92),
		hover_color = Color(0.12, 0.08, 0.22, 0.95),
		hover_target = pos - Vector2(0, 6),
		is_hovered = false
	}
	card_infos.append(ci)

	card.mouse_entered.connect(_on_card_hover_start.bind(ci))
	card.mouse_exited.connect(_on_card_hover_end.bind(ci))

	var bar = ColorRect.new()
	bar.size = Vector2(w, 4)
	bar.color = accent
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(bar)

	var icon_bg = ColorRect.new()
	icon_bg.size = Vector2(50, 50)
	icon_bg.position = Vector2(w / 2 - 25, 20)
	icon_bg.color = Color(accent.r, accent.g, accent.b, 0.08)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon_bg)

	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 26)
	icon_label.position = Vector2(w / 2 - 15, 26)
	icon_label.size = Vector2(30, 35)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.modulate = Color(accent.r * 2.5, accent.g * 2.5, accent.b * 2.5, 0.55)
	card.add_child(icon_label)

	var tl = Label.new()
	tl.text = title
	tl.add_theme_font_size_override("font_size", 18)
	tl.position = Vector2(20, 75)
	tl.size = Vector2(w - 40, 30)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.modulate = Color(1, 0.85, 0.3)
	card.add_child(tl)

	var cd = ColorRect.new()
	cd.size = Vector2(w - 80, 1)
	cd.position = Vector2(40, 108)
	cd.color = Color(1, 0.65, 0.1, 0.07)
	card.add_child(cd)

	var dl = Label.new()
	dl.text = desc
	dl.add_theme_font_size_override("font_size", 11)
	dl.position = Vector2(25, 120)
	dl.size = Vector2(w - 50, 95)
	dl.modulate = Color(0.6, 0.6, 0.72)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(dl)

	var btn = Button.new()
	btn.text = "JUGAR"
	btn.position = Vector2(w / 2 - 75, 235)
	btn.size = Vector2(150, 42)
	btn.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	btn.add_theme_color_override("button_normal", Color(0.1, 0.07, 0.18, 0.9))
	btn.add_theme_color_override("button_hover", Color(0.16, 0.1, 0.28, 0.95))
	btn.add_theme_color_override("button_pressed", Color(0.08, 0.05, 0.14, 0.95))
	card.add_child(btn)
	btn.pressed.connect(Callable(self, callback))

func _on_card_hover_start(ci):
	if ci.is_hovered:
		return
	ci.is_hovered = true
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(ci.rect, "color", ci.hover_color, 0.2)
	tween.parallel().tween_property(ci.rect, "position", ci.hover_target, 0.2)

func _on_card_hover_end(ci):
	if not ci.is_hovered:
		return
	ci.is_hovered = false
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(ci.rect, "color", ci.base_color, 0.2)
	tween.parallel().tween_property(ci.rect, "position", ci.base_pos, 0.2)

func _build_save_slots():
	var sl = Label.new()
	sl.text = "PARTIDAS GUARDADAS"
	sl.add_theme_font_size_override("font_size", 13)
	sl.position = Vector2(70, 455)
	sl.size = Vector2(400, 25)
	sl.modulate = Color(0.6, 0.55, 0.42, 0.75)
	add_child(sl)

	var dv = ColorRect.new()
	dv.size = Vector2(1140, 1)
	dv.position = Vector2(70, 478)
	dv.color = Color(1, 0.65, 0.1, 0.06)
	add_child(dv)

	for i in range(5):
		var slot_bg = ColorRect.new()
		slot_bg.size = Vector2(218, 68)
		slot_bg.position = Vector2(72 + i * 230, 490)
		slot_bg.color = Color(0.05, 0.035, 0.1, 0.88)
		slot_bg.name = "SlotBg" + str(i)
		add_child(slot_bg)

		var sg = ColorRect.new()
		sg.size = Vector2(218, 2)
		sg.position = Vector2(72 + i * 230, 490)
		sg.color = Color(0.5, 0.3, 0.1, 0.12)
		sg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sg)

		var sborder = ColorRect.new()
		sborder.size = Vector2(222, 72)
		sborder.position = Vector2(70 + i * 230, 488)
		sborder.color = Color(0.4, 0.25, 0.08, 0.06)
		sborder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sborder)

		var snum = Label.new()
		snum.text = str(i + 1)
		snum.add_theme_font_size_override("font_size", 8)
		snum.position = Vector2(76 + i * 230, 493)
		snum.size = Vector2(14, 14)
		snum.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		snum.modulate = Color(1, 0.7, 0.1, 0.18)
		add_child(snum)

		var slbl = Label.new()
		slbl.name = "SlotLabel" + str(i)
		slbl.text = "Slot " + str(i + 1) + "\n- Vacio -"
		slbl.add_theme_font_size_override("font_size", 10)
		slbl.position = Vector2(82 + i * 230, 497)
		slbl.size = Vector2(195, 52)
		slbl.modulate = Color(0.55, 0.5, 0.6, 0.65)
		add_child(slbl)

		if FileAccess.file_exists("user://save_" + str(i) + ".json"):
			var raw = FileAccess.get_file_as_string("user://save_" + str(i) + ".json")
			var data = JSON.parse_string(raw)
			if data and data.has("timestamp"):
				var ts = str(data["timestamp"])
				slbl.text = "Slot " + str(i + 1) + "\n" + ts
				slbl.modulate = Color(0.75, 0.7, 0.55)
				slot_bg.color = Color(0.07, 0.05, 0.14, 0.92)
				sg.color = Color(0.5, 0.3, 0.1, 0.3)

func _process(delta):
	time += delta

	for i in range(bg_layers.size()):
		var r = bg_layers[i]
		var t = i * 0.025
		var pulse = sin(time * 0.1 + i * 0.6) * 0.005
		r.color = Color(
			0.03 + t + pulse,
			0.01 + t * 0.2 + pulse * 0.5,
			0.06 + t * 0.4 + pulse * 0.3,
			0.4 + i * 0.08
		)

	for p in particles:
		var rect = p.rect
		var pos = rect.position
		pos.y -= p.speed * delta
		pos.x += sin(time * 0.35 + p.phase) * p.drift * delta
		if pos.y < -10:
			pos.y = SCREEN_H + 5 + randi() % 30
			pos.x = randi() % SCREEN_W
		rect.position = pos

		var flicker = 0.5 + sin(time * p.flicker_speed + p.phase) * 0.5
		var c = rect.color
		rect.color = Color(c.r, c.g, c.b, c.a * (0.3 + flicker * 0.7))

	var top_bar = get_node_or_null("TopBar")
	if top_bar:
		top_bar.color = Color(1, 0.7, 0.1, 0.25 + sin(time * 0.55) * 0.15)

	var gl = get_node_or_null("TitleGlow")
	if gl:
		gl.color = Color(1, 0.65, 0.1, 0.08 + sin(time * 0.8) * 0.05)

func _on_offline():
	Globals.game_mode = "offline"
	get_tree().change_scene_to_file("res://scenes/HeroSelect.tscn")

func _on_online1v1():
	_show_coming_soon()

func _on_online3v3():
	_show_coming_soon()

func _show_coming_soon():
	var overlay = ColorRect.new()
	overlay.name = "Popup"
	overlay.size = Vector2(SCREEN_W, SCREEN_H)
	overlay.color = Color(0, 0, 0, 0.8)
	add_child(overlay)

	var msg = Label.new()
	msg.text = "MODO DISPONIBLE EN EL FUTURO\n\nEstamos trabajando en esta funcionalidad.\nVuelve pronto, Arqueologo."
	msg.add_theme_font_size_override("font_size", 18)
	msg.position = Vector2(340, 250)
	msg.size = Vector2(600, 150)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg.modulate = Color(1, 0.8, 0.3)
	overlay.add_child(msg)

	var close = Button.new()
	close.text = "CERRAR"
	close.position = Vector2(540, 420)
	close.size = Vector2(200, 40)
	close.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	overlay.add_child(close)
	close.pressed.connect(func(): overlay.queue_free())
