extends Node

# Generates high-quality sprites procedurally
# Used as fallback when external assets aren't available

static func generate_unit_texture(type: String, team: String, color: Color, size: int) -> ImageTexture:
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half = size / 2.0
	
	var base = color
	if team == "enemy":
		base = Color(color.r * 0.5, color.g * 0.2, color.b * 0.2)
	
	for x in range(size):
		for y in range(size):
			var dx = x - half; var dy = y - half
			var dist = sqrt(dx * dx + dy * dy)
			var max_d = half * 0.85
			
			if dist < max_d:
				var brightness = 1.0 - (dist / max_d) * 0.35
				# Center highlight
				if dist < max_d * 0.4:
					brightness += 0.15
				var c = base * brightness
				
				# Border pixel
				if dist > max_d - 2:
					c = Color(0, 0, 0, 0.5)
				
				img.set_pixel(x, y, c)
	
	return ImageTexture.create_from_image(img)

static func generate_terrain_tile(tile_type: String, w: int, h: int) -> ImageTexture:
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	
	for x in range(w):
		for y in range(h):
			var noise1 = sin(x * 0.1 + y * 0.08) * 0.04
			var noise2 = sin(x * 0.05 - y * 0.12) * 0.03
			var noise = noise1 + noise2
			
			match tile_type:
				"grass":
					var g = 0.25 + noise + (y % 3) * 0.01
					img.set_pixel(x, y, Color(0.1, g, 0.06))
				"dirt":
					var d = 0.3 + noise
					img.set_pixel(x, y, Color(d * 0.8, d * 0.6, d * 0.3))
				"water":
					var wv = 0.3 + sin(x * 0.2 + y * 0.15) * 0.05
					img.set_pixel(x, y, Color(0.1, 0.3, wv + 0.2))
	
	return ImageTexture.create_from_image(img)
