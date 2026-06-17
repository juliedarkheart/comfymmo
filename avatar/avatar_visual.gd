extends Node2D
class_name AvatarVisual

## The player's visual body. Live gameplay uses a registry-backed top-down
## sprite so actors share the same visual source as terrain/objects. The older
## polygon CharacterVisualBuilder is kept as a safe dev fallback if the sprite
## cannot load.

func _ready() -> void:
	rebuild(CharacterAppearance.default_appearance())

func rebuild(appearance: Dictionary) -> void:
	for child in get_children():
		child.queue_free()
	if CharacterArtRegistry.apply_sprite(self, CharacterArtRegistry.PLAYER):
		return
	CharacterVisualBuilder.build(self, appearance)
