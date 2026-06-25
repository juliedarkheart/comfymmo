extends CharacterBody2D
class_name AvatarController

## Local avatar controller. Later networking can feed movement intent through
## this boundary while keeping authoritative state outside presentation code.

@export var move_speed: float = 180.0
var movement_enabled: bool = true
var facing_direction: String = AvatarVisual.FACING_DOWN
var movement_vector: Vector2 = Vector2.ZERO
var _last_side_sign: float = -1.0

## Resolved once from the owning map's visual projection (top-down vs legacy iso),
## so movement matches what the player sees. Empty until first resolved.
var _projection_mode: String = ""

func _physics_process(_delta: float) -> void:
	var input_vector: Vector2 = Vector2.ZERO
	if movement_enabled:
		input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	movement_vector = input_vector
	velocity = get_desired_motion(input_vector)
	move_and_slide()
	_update_visual_state(input_vector)

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

func set_selected_hotbar_tool(selected_hotbar_index: int, selected_item_id: String, held_visual_id: String = "") -> void:
	var body: Node2D = get_node_or_null("Body") as Node2D
	if body == null:
		return
	if body.has_method("set_held_tool_contract"):
		body.call("set_held_tool_contract", selected_hotbar_index, selected_item_id, held_visual_id)

func _update_visual_state(input_vector: Vector2) -> void:
	var body: Node2D = get_node_or_null("Body") as Node2D
	if body == null:
		return
	var side_sign: float = _last_side_sign
	if input_vector != Vector2.ZERO:
		if absf(input_vector.x) >= absf(input_vector.y) and not is_zero_approx(input_vector.x):
			facing_direction = AvatarVisual.FACING_SIDE
			_last_side_sign = -1.0 if input_vector.x < 0.0 else 1.0
			side_sign = _last_side_sign
		elif input_vector.y < 0.0:
			facing_direction = AvatarVisual.FACING_UP
		else:
			facing_direction = AvatarVisual.FACING_DOWN
	if body.has_method("set_facing_direction"):
		body.call("set_facing_direction", facing_direction, side_sign)
	elif not is_zero_approx(side_sign):
		body.scale.x = -1.0 if side_sign < 0.0 else 1.0

	if body.has_method("set_animation_state"):
		body.call("set_animation_state", _animation_state_for(input_vector), input_vector)

func _animation_state_for(input_vector: Vector2) -> String:
	var walking := input_vector != Vector2.ZERO
	match facing_direction:
		AvatarVisual.FACING_UP:
			return AvatarVisual.STATE_WALK_UP if walking else AvatarVisual.STATE_IDLE_UP
		AvatarVisual.FACING_SIDE:
			return AvatarVisual.STATE_WALK_SIDE if walking else AvatarVisual.STATE_IDLE_SIDE
		_:
			return AvatarVisual.STATE_WALK_DOWN if walking else AvatarVisual.STATE_IDLE_DOWN
