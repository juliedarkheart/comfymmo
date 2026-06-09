extends RefCounted
class_name IsoMapHelpers

## Pure, stateless isometric grid math shared by the outdoor maps. The formulas are
## the exact ones HomesteadMap has always used; the maps delegate to these so the
## grid math is no longer "owned" by the homestead and can be reused by any future
## map (continuous overworld, instances, etc.) without inheritance.
##
## Tile dimensions are passed in so callers keep their own TILE_WIDTH / TILE_HEIGHT.
## Behaviour must stay identical — placement, farming, and collision depend on it.

static func grid_to_world(tile: Vector2i, tile_w: int, tile_h: int) -> Vector2:
	return Vector2(
		(tile.x - tile.y) * tile_w * 0.5,
		(tile.x + tile.y) * tile_h * 0.5
	)

static func world_to_grid(position: Vector2, tile_w: int, tile_h: int) -> Vector2i:
	var x: int = int(round((position.x / (tile_w * 0.5) + position.y / (tile_h * 0.5)) * 0.5))
	var y: int = int(round((position.y / (tile_h * 0.5) - position.x / (tile_w * 0.5)) * 0.5))
	return Vector2i(x, y)

static func tile_diamond(tile_w: int, tile_h: int) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -tile_h * 0.5),
		Vector2(tile_w * 0.5, 0),
		Vector2(0, tile_h * 0.5),
		Vector2(-tile_w * 0.5, 0),
	])
