extends PlaceableCrate
class_name PlaceableDecor

## Shared root script for the cozy decor placeable set. Extends PlaceableCrate
## so every BuildingPlacementSystem cast and preview/select/move call keeps
## working; the per-item look is drawn at runtime by DecorVisuals from the
## exported decor id (set in each tiny scene file).

@export var decor_id: String = ""

func _ready() -> void:
	DecorVisuals.build(self, decor_id)

## Terrain overlays and floor pieces are walk-over: they still occupy their
## grid tile (placement collision) but never block movement.
func _is_walkable() -> bool:
	var category: String = ContentRegistry.placeable_category(decor_id)
	return category == "terrain" or decor_id == ContentIds.PLACEABLE_FLOOR_DECK or decor_id == ContentIds.PLACEABLE_STONE_FOUNDATION

func set_placed_visual() -> void:
	super.set_placed_visual()
	if _is_walkable():
		collision_shape.disabled = true
