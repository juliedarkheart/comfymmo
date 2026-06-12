extends PlaceableCrate
class_name PlaceableDecor

## Shared root script for the cozy decor placeable set. Extends PlaceableCrate
## so every BuildingPlacementSystem cast and preview/select/move call keeps
## working; the per-item look is drawn at runtime by DecorVisuals from the
## exported decor id (set in each tiny scene file).

@export var decor_id: String = ""

func _ready() -> void:
	DecorVisuals.build(self, decor_id)
