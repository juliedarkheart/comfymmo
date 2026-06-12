extends Node2D
class_name ResourceNode

## A gatherable spot in the world: a wood pile, a stone outcrop, a fiber bush,
## or a clay pit. Visual + yield data only; the area controller registers the
## interaction and adds the materials to the inventory. Nodes are infinite for
## the prototype (cozy, no depletion punishment) — a respawn/cooldown pass is
## documented future work.

const TYPE_WOOD := "wood_source"
const TYPE_STONE := "stone_source"
const TYPE_FIBER := "fiber_source"
const TYPE_CLAY := "clay_source"

var resource_type: String = TYPE_WOOD

static func definitions() -> Dictionary:
	return {
		TYPE_WOOD: {"material_id": ResourceIds.MATERIAL_WOOD, "min": 1, "max": 2, "prompt": "Press F to gather wood", "verb": "gather"},
		TYPE_STONE: {"material_id": ResourceIds.MATERIAL_STONE, "min": 1, "max": 2, "prompt": "Press F to gather stone", "verb": "chip off"},
		TYPE_FIBER: {"material_id": ResourceIds.MATERIAL_FIBER, "min": 1, "max": 3, "prompt": "Press F to gather fiber", "verb": "snip"},
		TYPE_CLAY: {"material_id": ResourceIds.MATERIAL_CLAY, "min": 1, "max": 2, "prompt": "Press F to dig clay", "verb": "scoop"},
	}

func configure(target_type: String) -> void:
	resource_type = target_type
	_build_visual()

func get_definition() -> Dictionary:
	return definitions().get(resource_type, definitions()[TYPE_WOOD]) as Dictionary

func get_prompt() -> String:
	return String(get_definition().get("prompt", "Press F to gather"))

func roll_yield(rng: RandomNumberGenerator) -> Dictionary:
	var definition: Dictionary = get_definition()
	return {
		"material_id": String(definition.get("material_id", ResourceIds.MATERIAL_WOOD)),
		"amount": rng.randi_range(int(definition.get("min", 1)), int(definition.get("max", 2))),
		"verb": String(definition.get("verb", "gather")),
	}

func _build_visual() -> void:
	var shadow: Polygon2D = Polygon2D.new()
	shadow.polygon = TerrainShapes.ellipse(Vector2(0, 1), 15.0, 6.0)
	shadow.color = Color(0.16, 0.12, 0.08, 0.2)
	add_child(shadow)
	match resource_type:
		TYPE_STONE:
			TerrainShapes.add_ellipse(self, Vector2(-4, -4), 10.0, 7.5, Color("#a8a49c"))
			TerrainShapes.add_ellipse(self, Vector2(7, -2), 7.0, 5.0, Color("#bab6ad"))
			TerrainShapes.add_ellipse(self, Vector2(-6, -8), 4.0, 2.5, Color("#cdc9bf"), 10)
		TYPE_FIBER:
			TerrainShapes.add_ellipse(self, Vector2(0, -7), 13.0, 9.5, Color("#7da964"))
			TerrainShapes.add_ellipse(self, Vector2(-4, -10), 6.0, 4.0, Color("#9cc47e"))
			for tuft_x: float in [-8.0, 0.0, 8.0]:
				TerrainShapes.add_polygon(self, PackedVector2Array([
					Vector2(tuft_x - 1, -12), Vector2(tuft_x + 1, -12), Vector2(tuft_x, -19),
				]), Color("#8cba74"))
		TYPE_CLAY:
			TerrainShapes.add_ellipse(self, Vector2(0, -1), 14.0, 7.5, Color("#b07a5a"))
			TerrainShapes.add_ellipse(self, Vector2(0, -2), 9.0, 4.5, Color("#c08a64"))
			TerrainShapes.add_ellipse(self, Vector2(3, -3), 4.0, 2.0, Color("#9c6a4c"), 10)
		_:
			for log_data in [Vector2(-7, -4), Vector2(1, -4), Vector2(9, -4), Vector2(-3, -10), Vector2(5, -10)]:
				TerrainShapes.add_ellipse(self, log_data, 5.0, 4.2, Color("#c89a64"), 10)
				TerrainShapes.add_ellipse(self, log_data, 2.6, 2.2, Color("#e0bf8a"), 8)
