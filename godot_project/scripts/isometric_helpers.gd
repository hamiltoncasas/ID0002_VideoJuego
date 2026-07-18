extends Node

# Isometric coordinate conversion helpers
# Tile dimensions for the isometric grid
const TILE_W = 64
const TILE_H = 32

# Convert cartesian world coordinates to isometric screen coordinates
func cart_to_iso(cart: Vector2) -> Vector2:
	var sx = (cart.x - cart.y) * TILE_W / 2
	var sy = (cart.x + cart.y) * TILE_H / 2
	return Vector2(sx, sy)

# Convert isometric screen coordinates to cartesian world coordinates
func iso_to_cart(iso: Vector2) -> Vector2:
	var cx = iso.x / (TILE_W / 2) + iso.y / (TILE_H / 2)
	var cy = iso.y / (TILE_H / 2) - iso.x / (TILE_W / 2)
	return Vector2(cx / 2, cy / 2)

# Snap cartesian coordinates to nearest isometric tile
func snap_to_tile(cart: Vector2) -> Vector2:
	var iso = cart_to_iso(cart)
	# Snap to nearest tile center
	var tx = round(iso.x / TILE_W) * TILE_W
	var ty = round(iso.y / TILE_H) * TILE_H
	return iso_to_cart(Vector2(tx, ty))
