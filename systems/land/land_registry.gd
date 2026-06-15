extends RefCounted
class_name LandRegistry

## Static plot catalog. Plots are tile rectangles on the buildable grid. The
## original homestead core (tiles 0..21 x 0..17) is Farmer Rowan's training
## land; the NEIGHBORHOOD is a separate buildable region east and south of the
## core (see OverworldMap.is_tile_in_bounds / _build_neighborhood) holding the
## real homestead-sized claimable lots. Town/forest are OFF the grid and so are
## structurally unbuildable — "town land can't be claimed" is enforced by
## construction, not just a check.
##
## Iso note: a tile rect projects to a diamond in world space, so an 8x6 plot
## reads as a large yard (~hundreds of px across) — much bigger than a 1x1 or
## 2x2 object footprint. Plot sizes are kept so that x+y stays under the south
## movement wall (world_y = (x+y)*16 < ~900).

# Area ids for HUD/admin classification (a richer view than ContentIds areas).
const AREA_LANDING := "landing"
const AREA_TOWN := "town"
const AREA_FARMER_TRAINING := "farmer_training"
const AREA_NEIGHBORHOOD := "neighborhood"
const AREA_WILDERNESS := "wilderness"

static func definitions() -> Dictionary:
	return {
		# --- Neighborhood: four true homestead-sized 12x12 lots in a 2x2 grid
		# south-east of the farm, with path gaps (x34,35 / y32,33) between them.
		# 144 tiles each — a full yard for a cottage, garden, shed, fences, paths.
		"meadow_lot_1": _plot("meadow_lot_1", "Meadow Lot 1", Rect2i(22, 20, 12, 12)),
		"meadow_lot_2": _plot("meadow_lot_2", "Meadow Lot 2", Rect2i(36, 20, 12, 12)),
		"orchard_lot_1": _plot("orchard_lot_1", "Orchard Lot 1", Rect2i(22, 34, 12, 12)),
		"orchard_lot_2": _plot("orchard_lot_2", "Orchard Lot 2", Rect2i(36, 34, 12, 12)),
		# --- Farmer Rowan's training land: the cottage + farm strip in the core.
		# NPC-owned, never claimable; building allowed (tutorial zone; pre-plot
		# saves placed objects here). ---
		"rowan_training_plot": {
			"plot_id": "rowan_training_plot", "display_name": "Rowan's Training Farm",
			"area_id": AREA_FARMER_TRAINING, "rect": Rect2i(4, 5, 6, 6),
			"claimable": false, "npc_owned": true, "tutorial_build": true, "price_tokens": 0,
		},
	}

static func _plot(plot_id: String, display_name: String, rect: Rect2i) -> Dictionary:
	return {
		"plot_id": plot_id, "display_name": display_name,
		"area_id": AREA_NEIGHBORHOOD, "rect": rect,
		"claimable": true, "price_tokens": 1,
	}

static func get_plot(plot_id: String) -> Dictionary:
	var entry: Variant = definitions().get(plot_id, {})
	if typeof(entry) == TYPE_DICTIONARY:
		return entry as Dictionary
	return {}

static func has_plot(plot_id: String) -> bool:
	return definitions().has(plot_id)

static func claimable_plot_ids() -> Array:
	var result: Array = []
	for plot in definitions().values():
		if bool((plot as Dictionary).get("claimable", false)):
			result.append(String((plot as Dictionary)["plot_id"]))
	return result

## Every tile rect that should be buildable (all plots + training land). Used by
## OverworldMap to expand placement bounds beyond the original core.
static func all_plot_rects() -> Array:
	var rects: Array = []
	for plot in definitions().values():
		var rect: Variant = (plot as Dictionary).get("rect", null)
		if rect is Rect2i:
			rects.append(rect)
	return rects

## Plot definition covering a grid tile, or {} for the public commons.
static func plot_at_tile(tile: Vector2i) -> Dictionary:
	for plot in definitions().values():
		var rect: Variant = (plot as Dictionary).get("rect", null)
		if rect is Rect2i and (rect as Rect2i).has_point(tile):
			return plot as Dictionary
	return {}

## A friendly sign position for a plot (front-center tile, one row ahead).
static func marker_tile(plot_id: String) -> Vector2i:
	var rect: Rect2i = get_plot(plot_id).get("rect", Rect2i()) as Rect2i
	return Vector2i(rect.position.x + rect.size.x / 2, rect.end.y)

## The four corner tiles of a plot (for corner posts / boundary visuals).
static func corner_tiles(plot_id: String) -> Array:
	var rect: Rect2i = get_plot(plot_id).get("rect", Rect2i()) as Rect2i
	return [
		rect.position,
		Vector2i(rect.end.x - 1, rect.position.y),
		Vector2i(rect.position.x, rect.end.y - 1),
		Vector2i(rect.end.x - 1, rect.end.y - 1),
	]
