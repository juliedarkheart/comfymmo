extends PlaceableCrate
class_name PlaceableDecor

## Shared root script for the cozy decor placeable set. Extends PlaceableCrate
## so every BuildingPlacementSystem cast and preview/select/move call keeps
## working; the per-item look is drawn at runtime by DecorVisuals from the
## exported decor id (set in each tiny scene file).

@export var decor_id: String = ""

func _ready() -> void:
	_ensure_selection_highlight()
	_apply_registry_art()
	if get_node_or_null("RegistryArtSprite") == null:
		DecorVisuals.build(self, decor_id)
		set_meta("debug_visual_asset_id", _art_object_id())
		if not has_meta("debug_visual_fallback"):
			set_meta("debug_visual_fallback", false)
	_apply_visual_state()

func _art_object_id() -> String:
	return decor_id if not decor_id.is_empty() else super._art_object_id()

## Terrain overlays and floor pieces are walk-over: they still occupy their
## grid tile (placement collision) but never block movement.
func _is_walkable() -> bool:
	var category: String = ContentRegistry.placeable_category(decor_id)
	return category == "terrain" or decor_id == ContentIds.PLACEABLE_FLOOR_DECK or decor_id == ContentIds.PLACEABLE_STONE_FOUNDATION

func set_placed_visual() -> void:
	super.set_placed_visual()
	if _is_walkable():
		collision_shape.disabled = true
