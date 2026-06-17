extends CharacterBody2D
class_name AvatarController

## Local avatar controller. Later networking can feed movement intent through
## this boundary while keeping authoritative state outside presentation code.

@export var move_speed: float = 180.0
var movement_enabled: bool = true

## Resolved once from the owning map's visual projection (top-down vs legacy iso),
## so movement matches what the player sees. Empty until first resolved.
var _projection_mode: String = ""

func _physics_process(_delta: float) -> void:
	var input_vector: Vector2 = Vector2.ZERO
	if movement_enabled:
		input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = get_desired_motion(input_vector)
	move_and_slide()
	_update_facing(input_vector)

## Walk up the tree to the owning map (HomesteadMap exposes visual_projection_mode);
## fall back to the project default. Cached after the first lookup.
func _resolve_projection_mode() -> String:
	if not _projection_mode.is_empty():
		return _projection_mode
	var node: Node = get_parent()
	while node != null:
		if node.has_method("visual_projection_mode"):
			_projection_mode = String(node.call("visual_projection_mode"))
			return _projection_mode
		node = node.get_parent()
	_projection_mode = WorldProjection.DEFAULT_MODE
	return _projection_mode

func set_movement_enabled(is_enabled: bool) -> void:
	movement_enabled = is_enabled
	if movement_enabled:
		return

	velocity = Vector2.ZERO

func get_desired_motion(input_vector: Vector2) -> Vector2:
	if input_vector == Vector2.ZERO:
		return Vector2.ZERO

	# Top-down (sprout_topdown, the live mode): move straight along screen axes so
	# pressing up goes up. The old isometric skew only applies in the legacy iso
	# projection, where screen space is the diamond grid.
	if WorldProjection.is_sprout_compatible(_resolve_projection_mode()):
		return input_vector.normalized() * move_speed

	var isometric_motion: Vector2 = Vector2(
		input_vector.x - input_vector.y,
		(input_vector.x + input_vector.y) * 0.5
	)
	return isometric_motion.normalized() * move_speed

func _update_facing(input_vector: Vector2) -> void:
	if input_vector.x == 0.0:
		return

	var body: Node2D = get_node_or_null("Body") as Node2D
	if body == null:
		return

	body.scale.x = -1.0 if input_vector.x < 0.0 else 1.0
