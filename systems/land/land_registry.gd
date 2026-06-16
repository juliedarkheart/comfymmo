extends RefCounted
class_name LandRegistry

## Land plot catalog. Plots are tile rectangles on the buildable grid, spread
## across distinct regions of the (expanded) overworld with varied sizes and
## biomes — no longer a tight cluster. The original homestead core (tiles
## 0..21 x 0..17) stays Farmer Rowan's training land.
##
## Two layers:
## - STATIC defaults below (always present; validation sees only these).
## - RUNTIME plots added by the in-game world-builder editor, kept in a static
##   overlay so every query (plot_at_tile, claimable list, bounds, minimap,
##   build permission) picks them up automatically. The controller loads/saves
##   the overlay to the offline save; server-side custom plots are deferred.
##
## Iso note: a tile rect projects to a diamond, so a 16x16 lot reads as a big
## yard. Sizes/positions are chosen so corners stay inside the expanded walls.

const AREA_LANDING := "landing"
const AREA_TOWN := "town"
const AREA_FARMER_TRAINING := "farmer_training"
const AREA_NEIGHBORHOOD := "neighborhood"
const AREA_WILDERNESS := "wilderness"

# Runtime plots authored in-game (plot_id -> plot dict). Static across the
# session; the controller persists/loads it. Empty during validation.
static var _runtime_plots: Dictionary = {}

static func _static_definitions() -> Dictionary:
	return {
		# Six lots, spread out, varied sizes (14x14 .. 20x20) and biomes.
		"meadow_lot_1": _plot("meadow_lot_1", "Meadow Lot", Rect2i(24, 15, 16, 16), "meadow"),
		"orchard_lot_1": _plot("orchard_lot_1", "Orchard Lot", Rect2i(26, 37, 20, 20), "orchard"),
		"creekside_lot_1": _plot("creekside_lot_1", "Creekside Lot", Rect2i(10, 40, 14, 14), "creekside"),
		"hilltop_lot_1": _plot("hilltop_lot_1", "Hilltop Lot", Rect2i(24, -6, 16, 16), "hilltop"),
		"grove_lot_1": _plot("grove_lot_1", "Grove Lot", Rect2i(46, 28, 16, 16), "grove"),
		"brook_lot_1": _plot("brook_lot_1", "Brook Lot", Rect2i(2, 22, 14, 14), "brook"),
		# Farmer Rowan's training land in the core: NPC-owned, never claimable.
		"rowan_training_plot": {
			"plot_id": "rowan_training_plot", "display_name": "Rowan's Training Farm",
			"area_id": AREA_FARMER_TRAINING, "rect": Rect2i(4, 5, 6, 6), "biome": "meadow",
			"claimable": false, "npc_owned": true, "tutorial_build": true, "price_tokens": 0,
		},
	}

static func _plot(plot_id: String, display_name: String, rect: Rect2i, biome: String) -> Dictionary:
	return {
		"plot_id": plot_id, "display_name": display_name,
		"area_id": AREA_NEIGHBORHOOD, "rect": rect, "biome": biome,
		"claimable": true, "price_tokens": 1,
	}

## Static defaults merged with runtime (editor) plots. Runtime wins on id clash.
static func definitions() -> Dictionary:
	var merged: Dictionary = _static_definitions()
	for plot_id in _runtime_plots.keys():
		merged[plot_id] = _runtime_plots[plot_id]
	return merged

# --- Runtime (in-game editor) overlay ----------------------------------------

static func add_runtime_plot(plot_id: String, display_name: String, rect: Rect2i, biome: String = "meadow") -> void:
	_runtime_plots[plot_id] = _plot(plot_id, display_name, rect, biome)

static func remove_runtime_plot(plot_id: String) -> void:
	_runtime_plots.erase(plot_id)

static func is_runtime_plot(plot_id: String) -> bool:
	return _runtime_plots.has(plot_id)

static func runtime_plots() -> Dictionary:
	return _runtime_plots.duplicate(true)

## Replace the whole runtime overlay (e.g. loading from a save), keeping only
## valid records so a corrupt file can never crash plot queries.
static func load_runtime_plots(data: Dictionary) -> void:
	_runtime_plots.clear()
	for plot_id_variant in data.keys():
		var record: Variant = data[plot_id_variant]
		if typeof(record) != TYPE_DICTIONARY:
			continue
		var raw_rect: Variant = (record as Dictionary).get("rect", null)
		var rect: Rect2i = raw_rect if raw_rect is Rect2i else _rect_from_array((record as Dictionary).get("rect", []))
		if rect.size.x <= 0 or rect.size.y <= 0:
			continue
		add_runtime_plot(
			String(plot_id_variant),
			String((record as Dictionary).get("display_name", plot_id_variant)),
			rect,
			String((record as Dictionary).get("biome", "meadow"))
		)

## Serialize the runtime overlay to JSON-safe data (Rect2i -> [x,y,w,h]).
static func runtime_plots_save_data() -> Dictionary:
	var data: Dictionary = {}
	for plot_id in _runtime_plots.keys():
		var plot: Dictionary = _runtime_plots[plot_id]
		var rect: Rect2i = plot["rect"] as Rect2i
		data[plot_id] = {
			"display_name": String(plot["display_name"]),
			"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
			"biome": String(plot.get("biome", "meadow")),
		}
	return data

static func _rect_from_array(arr: Variant) -> Rect2i:
	if typeof(arr) == TYPE_ARRAY and (arr as Array).size() == 4:
		return Rect2i(int(arr[0]), int(arr[1]), int(arr[2]), int(arr[3]))
	return Rect2i()

# --- Queries (include runtime plots automatically) ---------------------------

static func get_plot(plot_id: String) -> Dictionary:
	var entry: Variant = definitions().get(plot_id, {})
	return entry as Dictionary if typeof(entry) == TYPE_DICTIONARY else {}

static func has_plot(plot_id: String) -> bool:
	return definitions().has(plot_id)

static func claimable_plot_ids() -> Array:
	var result: Array = []
	for plot in definitions().values():
		if bool((plot as Dictionary).get("claimable", false)):
			result.append(String((plot as Dictionary)["plot_id"]))
	return result

## Every plot tile rect (claimable + training), used by OverworldMap to make the
## plots buildable and to draw their ground.
static func all_plot_rects() -> Array:
	var rects: Array = []
	for plot in definitions().values():
		var rect: Variant = (plot as Dictionary).get("rect", null)
		if rect is Rect2i:
			rects.append(rect)
	return rects

static func plot_at_tile(tile: Vector2i) -> Dictionary:
	for plot in definitions().values():
		var rect: Variant = (plot as Dictionary).get("rect", null)
		if rect is Rect2i and (rect as Rect2i).has_point(tile):
			return plot as Dictionary
	return {}

## Front-center sign tile (one row past the plot's south edge).
static func marker_tile(plot_id: String) -> Vector2i:
	var rect: Rect2i = get_plot(plot_id).get("rect", Rect2i()) as Rect2i
	return Vector2i(rect.position.x + rect.size.x / 2, rect.end.y)

static func corner_tiles(plot_id: String) -> Array:
	var rect: Rect2i = get_plot(plot_id).get("rect", Rect2i()) as Rect2i
	return [
		rect.position,
		Vector2i(rect.end.x - 1, rect.position.y),
		Vector2i(rect.position.x, rect.end.y - 1),
		Vector2i(rect.end.x - 1, rect.end.y - 1),
	]

## Soft per-biome ground tint for plot drawing + minimap variety.
static func biome_color(biome: String) -> Color:
	match biome:
		"orchard": return Color("#7fab5e")
		"creekside": return Color("#7bac74")
		"hilltop": return Color("#90b873")
		"grove": return Color("#5d8c52")
		"brook": return Color("#79ab78")
		_: return Color("#83b06b")  # meadow
