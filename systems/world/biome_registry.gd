extends RefCounted
class_name BiomeRegistry

## Central biome catalog. One source of truth for biome ids + their cozy colors,
## so plots, chunks, ground painting, the minimap, and the HUD all agree. Plots
## and (future) world chunks carry a biome id; everything visual asks here.
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
