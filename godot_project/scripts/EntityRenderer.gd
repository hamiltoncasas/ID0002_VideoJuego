extends Node2D

var entity_type = "villager"
var entity_team = "player"
var entity_color = Color(0.6, 0.4, 0.3)
var hp = 100; var max_hp = 100
var selected = false; var is_moving = false
var anim_time = 0.0; var is_hero = false
var _sprites_loaded = false
var _sprite: Sprite2D

# Cached textures
static var _texture_cache = {}

func _ready():
	_load_sprite()
	queue_redraw()

func _load_sprite():
	if _sprite: return
	_sprite = Sprite2D.new()
	_sprite.name = "UnitSprite"
	add_child(_sprite)
	
	# Determine sprite file
	var prefix = "enemy_" if entity_team == "enemy" else ""
	var key = prefix + entity_type
	key = "hero" if entity_type == "hero" and entity_team == "player" else key
	key = "enemy_hero" if entity_type == "hero" and entity_team == "enemy" else key
	
	var path = "res://assets/sprites/" + key + ".png"
	
	if _texture_cache.has(path):
		_sprite.texture = _texture_cache[path]
		return
	
	var tex = load(path) if ResourceLoader.exists(path) else null
	if tex:
		_texture_cache[path] = tex
		_sprite.texture = tex
		_sprite.centered = true
	_sprite.scale = Vector2(2, 2)
	
	# HP Bar BG
	var hb = ColorRect.new()
	hb.name = "hp_bg"
	hb.size = Vector2(30, 4)
	hb.position = Vector2(-15, -30)
	hb.color = Color(0.1, 0.02, 0.02, 0.65)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hb)
	
	# HP Bar fill
	var hf = ColorRect.new()
	hf.name = "hp_fill"
	hf.size = Vector2(30, 4)
	hf.position = Vector2(-15, -30)
	hf.color = Color(0.2, 0.75, 0.2, 0.9)
	hf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hf)

func _process(delta):
	anim_time += delta
	
	var hp_pct = float(hp) / max(1, max_hp)
	
	# Update HP bar
	var hf = get_node_or_null("hp_fill")
	if hf:
		hf.size.x = 30 * hp_pct
		if hp_pct > 0.5: hf.color = Color(0.2, 0.75, 0.2, 0.9)
		elif hp_pct > 0.25: hf.color = Color(0.8, 0.65, 0.1, 0.9)
		else: hf.color = Color(0.8, 0.15, 0.1, 0.9)
	
	# Idle bob
	var bob = sin(anim_time * 2) * 0.5
	if _sprite: _sprite.position.y = bob
	
	# Selection glow
	if selected:
		var pulse = 0.1 + sin(anim_time * 3) * 0.08
		modulate = Color(1, 1, 1 + pulse * 0.5, 1)
	else:
		modulate = Color(1, 1, 1, 1)
