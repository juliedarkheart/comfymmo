extends CharacterBody2D
class_name AvatarController

## Local avatar controller. Later networking can feed movement intent through
## this boundary while keeping authoritative state outside presentation code.

@export var move_speed := 180.0

func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = get_desired_motion(input_vector)
	move_and_slide()
	_update_facing(input_vector)

func get_desired_motion(input_vector: Vector2) -> Vector2:
	if input_vector == Vector2.ZERO:
		return Vector2.ZERO

	var isometric_motion := Vector2(
		input_vector.x - input_vector.y,
		(input_vector.x + input_vector.y) * 0.5
	)
	return isometric_motion.normalized() * move_speed

func _update_facing(input_vector: Vector2) -> void:
	if input_vector.x == 0.0:
		return

	var body := get_node_or_null("Body")
	if body == null:
		return

	body.scale.x = -1.0 if input_vector.x < 0.0 else 1.0
