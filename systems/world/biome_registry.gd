extends RefCounted
class_name BiomeRegistry

## Central biome catalog. One source of truth for biome ids + their cozy colors,
## so plots, chunks, ground painting, the minimap, and the HUD all agree. Plots
## and (future) world chunks carry a biome id; everything visual asks here.
##
## Terrain ids extend the same palette for build/world-builder paint styles that
## are not biomes, such as dirt paths, stone paths, and water.
##
## `ACTIVE` biomes are in use today; `FUTURE` are reserved ids the generator will
## grow into (beach/mountain/swamp/snow) — listed so docs + validation can see the
## roadmap without us drawing them yet.

const ACTIVE: Array[String] = [
	"meadow", "forest", "orchard", "creekside", "hilltop", "grove", "brook",
	"town", "farmland",
]
const FUTURE: Array[String] = ["beach", "mountain", "swamp", "snow"]

## Wilderness biomes the chunk generator may roll for unclaimed land.
const WILD: Array[String] = ["meadow", "forest", "creekside", "hilltop", "grove", "orchard"]
const TERRAIN_STYLES: Array[String] = ["dirt_path", "stone_path", "tilled_soil", "water", "road", "plot_boundary"]

static func _table() -> Dictionary:
	return {
		# id            display          ground tint   minimap tint
		"meadow":    {"name": "Meadow",       "ground": "#83b06b", "minimap": "#8cbf72"},
		"forest":    {"name": "Forest",       "ground": "#557d49", "minimap": "#4e7a4a"},
		"orchard":   {"name": "Orchard",      "ground": "#7fab5e", "minimap": "#86b35f"},
		"creekside": {"name": "Creekside",    "ground": "#7bac74", "minimap": "#79b0a0"},
		"hilltop":   {"name": "Hilltop",      "ground": "#90b873", "minimap": "#9cc07d"},
		"grove":     {"name": "Grove",        "ground": "#5d8c52", "minimap": "#5d8c52"},
		"brook":     {"name": "Brook",        "ground": "#79ab78", "minimap": "#74ad97"},
		"town":      {"name": "Town",         "ground": "#9fa86a", "minimap": "#b6a06a"},
		"farmland":  {"name": "Farmland",     "ground": "#a6864f", "minimap": "#b8924f"},
		# Reserved / future generation targets (colors ready, not yet placed).
		"beach":     {"name": "Beach",        "ground": "#d9c98c", "minimap": "#ddca8a"},
		"mountain":  {"name": "Mountain",     "ground": "#9a958c", "minimap": "#a9a39a"},
		"swamp":     {"name": "Swamp",        "ground": "#5f6f4a", "minimap": "#566640"},
		"snow":      {"name": "Snow",         "ground": "#dfe7ee", "minimap": "#e6edf3"},
	}

static func has_biome(biome_id: String) -> bool:
	return _table().has(biome_id)

static func ids() -> Array:
	return ACTIVE.duplicate()

static func display_name(biome_id: String) -> String:
	return String((_table().get(biome_id, {}) as Dictionary).get("name", biome_id.capitalize()))

static func ground_color(biome_id: String) -> Color:
	return Color(String((_table().get(biome_id, _table()["meadow"]) as Dictionary).get("ground", "#83b06b")))

static func minimap_tint(biome_id: String) -> Color:
	return Color(String((_table().get(biome_id, _table()["meadow"]) as Dictionary).get("minimap", "#8cbf72")))

static func terrain_ids() -> Array[String]:
	var ids: Array[String] = ACTIVE.duplicate()
	ids.append_array(TERRAIN_STYLES)
	return ids

static func terrain_color(terrain_id: String, alternate: bool = false) -> Color:
	var safe_id: String = String(terrain_id).to_lower()
	if has_biome(safe_id):
		var base: Color = ground_color(safe_id)
		return base.darkened(0.07) if alternate else base
	match safe_id:
		"dirt_path", "road":
			return Color("#c2a071").darkened(0.06) if alternate else Color("#c2a071")
		"stone_path":
			return Color("#bfc0c4").darkened(0.08) if alternate else Color("#bfc0c4")
		"tilled_soil":
			return Color("#8c6740").darkened(0.07) if alternate else Color("#8c6740")
		"water":
			return Color("#6faecc").darkened(0.06) if alternate else Color("#6faecc")
		"plot_boundary":
			return Color("#e6c76d")
		_:
			return ground_color("meadow").darkened(0.07) if alternate else ground_color("meadow")

static func terrain_detail_color(terrain_id: String) -> Color:
	match String(terrain_id).to_lower():
		"dirt_path", "road":
			return Color("#b88d5a")
		"stone_path":
			return Color("#d7d7dd")
		"tilled_soil":
			return Color("#6f4c2f")
		"water":
			return Color("#d8f2ff")
		"plot_boundary":
			return Color("#fff0a8")
		_:
			return ground_color(String(terrain_id)).lightened(0.12)

static func path_color(path_id: String = "dirt_path") -> Color:
	return terrain_color(path_id)

static func water_color() -> Color:
	return terrain_color("water")
