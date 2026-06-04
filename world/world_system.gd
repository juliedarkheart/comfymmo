extends Node

## Placeholder for isometric world loading and simulation coordination.

const TILE_WIDTH := 64
const TILE_HEIGHT := 32

func grid_to_world(tile: Vector2i) -> Vector2:
	return Vector2(
		(tile.x - tile.y) * TILE_WIDTH * 0.5,
		(tile.x + tile.y) * TILE_HEIGHT * 0.5
	)

func world_to_grid(position: Vector2) -> Vector2i:
	var x := int(round((position.x / (TILE_WIDTH * 0.5) + position.y / (TILE_HEIGHT * 0.5)) * 0.5))
	var y := int(round((position.y / (TILE_HEIGHT * 0.5) - position.x / (TILE_WIDTH * 0.5)) * 0.5))
	return Vector2i(x, y)

func get_tile_diamond() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -TILE_HEIGHT * 0.5),
		Vector2(TILE_WIDTH * 0.5, 0),
		Vector2(0, TILE_HEIGHT * 0.5),
		Vector2(-TILE_WIDTH * 0.5, 0),
	])
