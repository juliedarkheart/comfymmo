extends Node2D
class_name WorldSpaceHint

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/Label

func _ready() -> void:
	CozyUITheme.apply_slot(panel, false, false)
	CozyUITheme.apply_body_label(label, 12)

func show_hint(text: String, is_valid: bool, world_position: Vector2) -> void:
	position = world_position + Vector2(0, -44)
	label.text = text
	panel.modulate = Color.WHITE
	panel.add_theme_stylebox_override("panel", CozyUITheme.slot_box(is_valid, not is_valid))
	label.add_theme_color_override(
		"font_color",
		LimeZuUITheme.readable_text_color() if is_valid and LiveVisualPolicy.live_limezu_slice() else (CozyUITheme.INK if is_valid else CozyUITheme.BAD)
	)
	visible = true

func hide_hint() -> void:
	visible = false
