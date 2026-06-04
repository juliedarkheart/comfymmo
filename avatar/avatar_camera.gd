extends Camera2D

const LIMIT_LEFT := -430
const LIMIT_TOP := -120
const LIMIT_RIGHT := 430
const LIMIT_BOTTOM := 520

func _ready() -> void:
	enabled = true
	make_current()
	limit_left = LIMIT_LEFT
	limit_top = LIMIT_TOP
	limit_right = LIMIT_RIGHT
	limit_bottom = LIMIT_BOTTOM
