extends Node2D
class_name WorldSpaceHint

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/Label

func show_hint(text: String, is_valid: bool, world_position: Vector2) -> void:
	position = world_position + Vector2(0, -44)
	label.text = text
	label.modulate = Color("#d7ffd9") if is_valid else Color("#ffd3d3")
	panel.modulate = Color(0.18, 0.32, 0.18, 0.92) if is_valid else Color(0.38, 0.16, 0.16, 0.92)
	visible = true

func hide_hint() -> void:
	visible = false
