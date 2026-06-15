extends CanvasLayer

## Prototype prefab interior — an instanced "room view" overlay (NOT a physical
## space in the overworld, so the player keeps their world position and exiting
## returns them exactly where they entered). Draws a simple cozy room per
## template (cottage/shed/workshop/barn) with a labeled exit door. F or Esc or
## the Exit button closes it. Decoration/persistence and multiplayer interior
## sync are future work (docs/interiors_strategy.md).

signal interior_closed()

@onready var _room: Control = $Dim/Room
@onready var _title_label: Label = $Dim/Room/Title
@onready var _template_label: Label = $Dim/Room/Canvas/TemplateLabel

var _template: String = "cottage"

func _ready() -> void:
	visible = false
	$Dim/Room/Canvas.draw.connect(_draw_room)
	$Dim/Room/ExitButton.pressed.connect(close_interior)

func open_interior(template_id: String, title: String) -> void:
	_template = template_id
	_title_label.text = title
	_template_label.text = "A cozy %s interior (prototype). Decorate it in a future update." % template_id
	visible = true
	$Dim/Room/Canvas.queue_redraw()

func close_interior() -> void:
	if not visible:
		return
	visible = false
	interior_closed.emit()

func is_open() -> bool:
	return visible

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.keycode == KEY_F):
		close_interior()
		var viewport: Viewport = get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()

func _draw_room() -> void:
	var canvas: Control = $Dim/Room/Canvas
	var size: Vector2 = canvas.size
	# Floor (warm wood) + back wall (cream), a window, and a rug — a readable
	# cozy room; the per-template tint hints at the building type.
	var wall: Color = Color("#f2dfb8")
	var floor_color: Color = Color("#caa06a")
	match _template:
		"shed", "workshop":
			wall = Color("#d9c39a"); floor_color = Color("#b58c5e")
		"barn":
			wall = Color("#d8a0a0"); floor_color = Color("#b58c5e")
	canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.55)), wall)
	canvas.draw_rect(Rect2(Vector2(0, size.y * 0.55), Vector2(size.x, size.y * 0.45)), floor_color)
	# Window on the back wall.
	canvas.draw_rect(Rect2(Vector2(size.x * 0.62, size.y * 0.14), Vector2(size.x * 0.22, size.y * 0.26)), Color("#f7dfa0"))
	canvas.draw_rect(Rect2(Vector2(size.x * 0.62, size.y * 0.14), Vector2(size.x * 0.22, size.y * 0.26)), Color("#a87848"), false, 3.0)
	# Rug on the floor.
	canvas.draw_rect(Rect2(Vector2(size.x * 0.18, size.y * 0.66), Vector2(size.x * 0.4, size.y * 0.22)), Color("#c87858"))
	# Exit doormat hint at the bottom-left (the ExitButton sits over it).
	canvas.draw_rect(Rect2(Vector2(size.x * 0.04, size.y * 0.78), Vector2(size.x * 0.18, size.y * 0.12)), Color("#8a5e3c"))
