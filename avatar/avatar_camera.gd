extends Camera2D
class_name AvatarCamera

@export var default_zoom: Vector2 = Vector2(1.1, 1.1)
@export var default_limit_left: int = -430
@export var default_limit_top: int = -120
@export var default_limit_right: int = 430
@export var default_limit_bottom: int = 520

func _ready() -> void:
	enabled = true
	make_current()
	zoom = default_zoom
	apply_limits(default_limit_left, default_limit_top, default_limit_right, default_limit_bottom)

func apply_limits(left: int, top: int, right: int, bottom: int) -> void:
	limit_left = left
	limit_top = top
	limit_right = right
	limit_bottom = bottom

func apply_region_view(region_zoom: Vector2, limits: Rect2i) -> void:
	zoom = region_zoom
	apply_limits(limits.position.x, limits.position.y, limits.end.x, limits.end.y)
