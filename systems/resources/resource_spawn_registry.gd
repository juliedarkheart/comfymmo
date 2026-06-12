extends RefCounted
class_name ResourceSpawnRegistry

## The shared catalog of gatherable resource node placements. Both sides read
## it: the overworld controller SPAWNS nodes from these definitions, and the
## server VALIDATES gather requests against the same ids — so a client can
## never invent a gather spot. Anchors: "homestead" entries are grid tiles on
## the homestead placement grid; "village"/"forest" entries are world-space
## offsets from those area origins.

const COOLDOWN_SECONDS := 20.0

static func definitions() -> Array:
	return [
		# Homestead (grid tiles, clear of cottage/trees/fence/path/spawn).
		{"node_id": "gather_home_wood", "type": ResourceNode.TYPE_WOOD, "anchor": "homestead", "x": 3, "y": 14},
		{"node_id": "gather_home_stone", "type": ResourceNode.TYPE_STONE, "anchor": "homestead", "x": 17, "y": 13},
		{"node_id": "gather_home_fiber", "type": ResourceNode.TYPE_FIBER, "anchor": "homestead", "x": 12, "y": 3},
		{"node_id": "gather_home_clay", "type": ResourceNode.TYPE_CLAY, "anchor": "homestead", "x": 16, "y": 2},
		{"node_id": "gather_home_wood_2", "type": ResourceNode.TYPE_WOOD, "anchor": "homestead", "x": 1, "y": 9},
		# Village square (world offsets from OverworldMap.VILLAGE_OFFSET).
		{"node_id": "gather_village_fiber", "type": ResourceNode.TYPE_FIBER, "anchor": "village", "x": -160, "y": 320},
		{"node_id": "gather_village_stone", "type": ResourceNode.TYPE_STONE, "anchor": "village", "x": 300, "y": 330},
		# Forest edge (world offsets from OverworldMap.FOREST_OFFSET).
		{"node_id": "gather_forest_wood", "type": ResourceNode.TYPE_WOOD, "anchor": "forest", "x": -220, "y": 390},
		{"node_id": "gather_forest_stone", "type": ResourceNode.TYPE_STONE, "anchor": "forest", "x": 70, "y": 430},
		{"node_id": "gather_forest_clay", "type": ResourceNode.TYPE_CLAY, "anchor": "forest", "x": 300, "y": 250},
		{"node_id": "gather_forest_fiber", "type": ResourceNode.TYPE_FIBER, "anchor": "forest", "x": -320, "y": 240},
		{"node_id": "gather_forest_wood_2", "type": ResourceNode.TYPE_WOOD, "anchor": "forest", "x": 420, "y": 400},
	]

static func find(node_id: String) -> Dictionary:
	for definition in definitions():
		if String((definition as Dictionary).get("node_id", "")) == node_id:
			return definition as Dictionary
	return {}

static func has_node_id(node_id: String) -> bool:
	return not find(node_id).is_empty()
