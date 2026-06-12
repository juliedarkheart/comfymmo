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
	CharacterVisualBuilder.build(body, appearance)

	var tag: Label = Label.new()
	tag.name = "NameTag"
	tag.text = display_name
	tag.position = Vector2(-60, -86)
	tag.custom_minimum_size = Vector2(120, 0)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 12)
	tag.add_theme_color_override("font_color", Color("#f5f0e6"))
	tag.add_theme_color_override("font_outline_color", Color(0.16, 0.12, 0.09, 0.9))
	tag.add_theme_constant_override("outline_size", 4)
	add_child(tag)

func apply_position(target: Vector2) -> void:
	_target_position = target

func _process(delta: float) -> void:
	position = position.lerp(_target_position, minf(1.0, delta * LERP_SPEED))
