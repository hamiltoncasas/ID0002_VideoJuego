extends Node

# Generates all game textures programmatically at startup
# This avoids needing external image files

var _generated = false

func ensure_generated():
	if _generated:
		return
	_generated = true
	print("Generating game assets...")

func create_unit_texture(color: Color, size: Vector2, team: String) -> ImageTexture:
	var img = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	
	var base_color = color
	if team == "enemy":
		base_color = Color(color.r * 0.6, color.g * 0.2, color.b * 0.2)
	
	# Draw body
	for x in range(int(size.x)):
		for y in range(int(size.y)):
			var cx = x - size.x / 2
			var cy = y - size.y / 2
			var dist = sqrt(cx * cx + cy * cy * 1.5)
			var max_dist = min(size.x, size.y) * 0.45
			
			if dist < max_dist:
				var brightness = 1.0 - (dist / max_dist) * 0.3
				var c = base_color * brightness
				img.set_pixel(x, y, c)
				
				# Highlight top
				if y < size.y * 0.3:
					var highlight = 1.0 - (y / (size.y * 0.3)) * 0.2
					img.set_pixel(x, y, c * (1.0 + highlight * 0.15))
	
	# Border
	var border_color = Color(1, 1, 1, 0.3) if team == "player" else Color(1, 0.3, 0.3, 0.3)
	for x in range(int(size.x)):
		for y in range(int(size.y)):
			var cx = x - size.x / 2
			var cy = y - size.y / 2
			var dist = sqrt(cx * cx + cy * cy * 1.5)
			var max_dist = min(size.x, size.y) * 0.45
			if dist > max_dist - 2 and dist < max_dist:
				img.set_pixel(x, y, border_color)
	
	return ImageTexture.create_from_image(img)

func create_hero_texture(hero_data: Dictionary) -> ImageTexture:
	var size = Vector2(48, 48)
	var img = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var color = hero_data["color"]
	
	# Body circle
	for x in range(48):
		for y in range(48):
			var cx = x - 24
			var cy = y - 24
			var dist = sqrt(cx * cx + cy * cy)
			
			if dist < 20:
				var c = color * (1.0 - dist / 22 * 0.25)
				img.set_pixel(x, y, c)
				
				# Eyes
				if dist < 15 and y > 18 and y < 24:
					if abs(cx - 5) < 3 or abs(cx + 5) < 3:
						img.set_pixel(x, y, Color(0, 0, 0, 0.8))
	
	# Crown/helmet indicator based on rarity
	var rarity_color = Color(1, 0.8, 0)  # gold
	match hero_data["rarity"]:
		"Épico": rarity_color = Color(0.8, 0.2, 1.0)
		"Raro": rarity_color = Color(0.3, 0.5, 1.0)
	
	for x in range(48):
		for y in range(48):
			var cx = x - 24
			var cy = y - 24
			var dist = sqrt(cx * cx + cy * cy)
			# Crown shape
			if dist > 17 and dist < 21 and y < 12:
				img.set_pixel(x, y, rarity_color)
	
	return ImageTexture.create_from_image(img)

func create_background_texture(width: int, height: int, base: Color, accent: Color) -> ImageTexture:
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	for x in range(width):
		for y in range(height):
			var noise = sin(x * 0.03) * cos(y * 0.05) * 0.05
			var grad = float(y) / height
			var c = base.lerp(accent, grad) * (1.0 + noise)
			img.set_pixel(x, y, c)
	
	return ImageTexture.create_from_image(img)

func create_hp_bar(width: int, pct: float, color: Color) -> ImageTexture:
	var h = 6
	var img = Image.create(width, h, false, Image.FORMAT_RGBA8)
	
	var fill = int(width * pct)
	
	for x in range(width):
		for y in range(h):
			if x < fill:
				var bright = 1.0 - y * 0.1
				img.set_pixel(x, y, color * bright)
			else:
				img.set_pixel(x, y, Color(0.2, 0.05, 0.05, 0.6))
			
			# Border
			if y == 0 or y == h-1 or x == 0 or x == width-1:
				img.set_pixel(x, y, Color(0.8, 0.8, 0.8, 0.5))
	
	return ImageTexture.create_from_image(img)

func get_enemy_color(base: Color) -> Color:
	return Color(base.r * 0.7, base.g * 0.3, base.b * 0.3)
