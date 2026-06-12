extends Node2D
class_name AvatarVisual

## The player's visual body, built at runtime from appearance data by
## CharacterVisualBuilder. This node is named "Body" in player_avatar.tscn so
## AvatarController's existing facing code flips the whole character (it
## previously only flipped the torso polygon). Appearance is default-only for
## now; a future character creator calls `rebuild()` with new data — no save
## integration yet (see docs/character_customization.md).

func _ready() -> void:
	rebuild(CharacterAppearance.default_appearance())

func rebuild(appearance: Dictionary) -> void:
	for child in get_children():
		child.queue_free()
	CharacterVisualBuilder.build(self, appearance)
