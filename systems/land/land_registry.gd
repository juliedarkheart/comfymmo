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
## Projection note: a tile rect is gameplay-authoritative; the renderer may draw
## it as the primary top-down square grid or the legacy iso diamond fallback.
## Sizes/positions are chosen so corners stay inside the expanded walls.

const AREA_LANDING := "landing"
const AREA_TOWN := "town"
const AREA_FARMER_TRAINING := "farmer_training"
const AREA_NEIGHBORHOOD := "neighborhood"
const AREA_WILDERNESS := "wilderness"
const MIN_RUNTIME_PLOT_SIZE := 8

# Runtime plots authored in-game (plot_id -> plot dict). Static across the
# session; the controller persists/loads it. Empty during validation.
static var _runtime_plots: Dictionary = {}

static func _static_definitions() -> Dictionary:
	return {
		# Six LARGE homestead lots (28..32 tiles) laid out as a roomy 3x2
		# neighborhood west + south of the core, with 4..8 tile road gutters
		# between every lot (the roads in overworld_map.gd run through those
		# gutters, never across a lot). Each lot is a distinct biome so the
		# neighborhood reads as varied land, not one flat zone.
		"meadow_homestead_a": _plot("meadow_homestead_a", "Meadow Homestead A", Rect2i(-54, 20, 30, 30), "meadow"),
		"orchard_homestead": _plot("orchard_homestead", "Orchard Homestead", Rect2i(-18, 20, 28, 28), "orchard"),
		"hilltop_homestead": _plot("hilltop_homestead", "Hilltop Homestead", Rect2i(18, 20, 32, 32), "hilltop"),
		"creekside_homestead": _plot("creekside_homestead", "Creekside Homestead", Rect2i(-54, 56, 28, 28), "creekside"),
		"grove_homestead": _plot("grove_homestead", "Forest Grove Homestead", Rect2i(-18, 56, 32, 32), "grove"),
		"meadow_homestead_b": _plot("meadow_homestead_b", "Meadow Homestead B", Rect2i(18, 56, 30, 30), "meadow"),
		# Farmer Rowan's training land in the core: NPC-owned, never claimable.
		"rowan_training_plot": {
			"plot_id": "rowan_training_plot", "display_name": "Rowan's Training Farm",
			"area_id": AREA_FARMER_TRAINING, "rect": Rect2i(4, 5, 6, 6), "biome": "farmland",
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
	if plot_id.is_empty() or not _is_valid_runtime_rect(rect):
		return
	var safe_name: String = display_name if not display_name.is_empty() else plot_id
	_runtime_plots[plot_id] = _plot(plot_id, safe_name, rect, _normalized_runtime_biome(biome))

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
		if not _is_valid_runtime_rect(rect):
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

static func _is_valid_runtime_rect(rect: Rect2i) -> bool:
	return rect.size.x >= MIN_RUNTIME_PLOT_SIZE and rect.size.y >= MIN_RUNTIME_PLOT_SIZE

static func _normalized_runtime_biome(biome: String) -> String:
	return biome if BiomeRegistry.has_biome(biome) else "meadow"

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
		Vector2i(rect.end.x - 1, rect.end.y - 1),
		Vector2i(rect.position.x, rect.end.y - 1),
	]

## Soft per-biome ground tint for plot drawing + minimap variety. Delegates to
## the central BiomeRegistry so plots, chunks, ground, and minimap all agree.
static func biome_color(biome: String) -> Color:
	return BiomeRegistry.ground_color(biome)
