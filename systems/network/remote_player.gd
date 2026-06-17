extends Node2D
class_name RemotePlayer

## Client-side visual for another connected player: the shared chibi build plus
## a floating name tag. Position is server-fed and smoothed locally; remote
## players have no collision and no input — they are presentation only.

const LERP_SPEED := 10.0

var _target_position: Vector2 = Vector2.ZERO

func setup(display_name: String, appearance: Dictionary, start_position: Vector2) -> void:
	position = start_position
	_target_position = start_position

	var body: Node2D = Node2D.new()
	body.name = "Body"
	add_child(body)
	if not CharacterArtRegistry.apply_sprite(body, CharacterArtRegistry.REMOTE_PLAYER):
		CharacterVisualBuilder.build(body, appearance)

	Nameplate.attach(self, display_name, "Player", Color("#bfe0ff"))

func apply_position(target: Vector2) -> void:
	_target_position = target

func _process(delta: float) -> void:
	position = position.lerp(_target_position, minf(1.0, delta * LERP_SPEED))
