extends Camera2D
class_name AvatarCamera

@export var default_zoom: Vector2 = Vector2(1.1, 1.1)
@export var default_limit_left: int = -430
@export var default_limit_top: int = -120
@export var default_limit_right: int = 430
@export var default_limit_bottom: int = 520

# Runtime test zoom controls (handy on 4K monitors). These only change the camera
# zoom — position smoothing and mouse/world-space transforms are untouched, so
# placement coordinates and world hints stay correct at any zoom.
const ZOOM_MIN: float = 0.6
const ZOOM_MAX: float = 2.8
const ZOOM_STEP: float = 1.12

var _base_zoom: Vector2 = Vector2(1.1, 1.1)

func _ready() -> void:
	enabled = true
	make_current()
	zoom = default_zoom
	_base_zoom = default_zoom
	# Gentle position smoothing softens the rigid, boxed feel and eases the camera
	# toward the player instead of hard-snapping at region borders.
	position_smoothing_enabled = true
	position_smoothing_speed = 6.0
	apply_limits(default_limit_left, default_limit_top, default_limit_right, default_limit_bottom)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	match event.keycode:
		KEY_PAGEUP, KEY_EQUAL, KEY_KP_ADD:
			_apply_zoom_factor(ZOOM_STEP)
			_consume_input()
		KEY_PAGEDOWN, KEY_MINUS, KEY_KP_SUBTRACT:
			_apply_zoom_factor(1.0 / ZOOM_STEP)
			_consume_input()
		KEY_R:
			zoom = _base_zoom
			_consume_input()

func _apply_zoom_factor(factor: float) -> void:
	var level: float = clampf(zoom.x * factor, ZOOM_MIN, ZOOM_MAX)
	zoom = Vector2(level, level)

func get_zoom_level() -> float:
	return zoom.x

func _consume_input() -> void:
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()

func apply_limits(left: int, top: int, right: int, bottom: int) -> void:
	limit_left = left
	limit_top = top
	limit_right = right
	limit_bottom = bottom

func apply_region_view(region_zoom: Vector2, limits: Rect2i) -> void:
	zoom = region_zoom
	_base_zoom = region_zoom
	apply_limits(limits.position.x, limits.position.y, limits.end.x, limits.end.y)
	# Settle smoothing on the freshly spawned camera so it starts centered on the
	# player at the destination spawn instead of easing in from its initial point.
	reset_smoothing()
