extends SimpleVillager
class_name BramVillager

## Bram Nettle: rustic grumpy-cute gardener. Same shared chibi build as every
## character, with his own appearance (fluffy hair, mossy forest apron, tiny
## felt hat) and signature stubble.

func _get_visual_id() -> String:
	if visual_id != CharacterArtRegistry.MARIBEL:
		return visual_id
	return CharacterArtRegistry.BRAM

func _get_appearance() -> Dictionary:
	return {
		"skin_tone": "honey",
		"hair_style": "fluffy_short",
		"hair_color": "warm_brown",
		"outfit_style": "forest_apron",
		"outfit_color": "moss_green",
		"accessory": "tiny_hat",
	}

func _decorate(root: Node2D) -> void:
	# Stubble dots on the lower face.
	for sx: float in [-4.0, 0.0, 4.0]:
		var stubble: Polygon2D = Polygon2D.new()
		stubble.position = Vector2(sx, -31)
		stubble.polygon = PackedVector2Array([
			Vector2(0, -0.8), Vector2(0.8, 0), Vector2(0, 0.8), Vector2(-0.8, 0),
		])
		stubble.color = Color("#9a7858")
		root.add_child(stubble)
