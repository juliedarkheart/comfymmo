extends RefCounted
class_name WorldAreaRegistry

## Fixed, authored world areas in WORLD (pixel) space — the parts of the map that
## are hand-built and must NOT be procedurally overwritten: the starter landing /
## training core, the town, and the forest edge. Each carries a biome id so the
## HUD/minimap can label the region the player is standing in. The claimable
## neighborhood and wilderness are derived elsewhere (plots + chunk generation),
## so they are intentionally absent here. World-space rects match overworld_map.gd.

static func areas() -> Array:
	return [
		{
			"id": "farmer_training", "display_name": "Farmer Training", "biome": "farmland",
			"rect": Rect2(-640, -120, 1400, 820), "protected": true, "buildable": true,
		},
		{
			"id": "town", "display_name": "Town", "biome": "town",
			"rect": Rect2(1150, -260, 900, 1180), "protected": true, "buildable": false,
		},
		{
			"id": "forest_edge", "display_name": "Forest Edge", "biome": "forest",
			"rect": Rect2(2550, -260, 1500, 1280), "protected": false, "buildable": false,
		},
	]

## The fixed area containing a world position, or {} if none (wilderness/plots).
static func area_at(world_pos: Vector2) -> Dictionary:
	for area in areas():
		if (area["rect"] as Rect2).has_point(world_pos):
			return area
	return {}

## Does this world position sit inside a protected fixed area (no claiming there)?
static func is_protected(world_pos: Vector2) -> bool:
	var area: Dictionary = area_at(world_pos)
	return not area.is_empty() and bool(area.get("protected", false))
