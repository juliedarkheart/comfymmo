extends Node2D
class_name AmbientCreature

const FLEE_RADIUS: float = 60.0
const FLEE_CLEAR_RADIUS: float = 88.0
const WANDER_RADIUS: float = 110.0

@export var wander_speed: float = 32.0
@export var flee_speed: float = 65.0
@export var idle_time_min: float = 2.0
@export var idle_time_max: float = 4.5
@export var wander_time_min: float = 2.5
@export var wander_time_max: float = 5.5

var _player: Node2D = null
var _wander_origin: Vector2 = Vector2.ZERO
var _state: String = "idle"
var _state_timer: float = 0.0
var _move_dir: Vector2 = Vector2.ZERO
var _body_node: Node2D = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_wander_origin = global_position
	_rng.randomize()
	_enter_idle()

func configure_creature(player: Node2D) -> void:
	_player = player

func get_display_name() -> String:
	return "Creature"

func get_observe_text() -> String:
	return "..."

func _process(delta: float) -> void:
	var flee_dir: Vector2 = _compute_flee_direction()

	if flee_dir != Vector2.ZERO:
		_state = "flee"
		_move_dir = flee_dir
		_apply_movement(flee_speed, delta)
		_update_facing()
		_animate(delta)
		return

	if _state == "flee":
		_enter_idle()

	match _state:
		"idle":
			_state_timer -= delta
			if _state_timer <= 0.0:
				_enter_wander()
		"wander":
			_state_timer -= delta
			_apply_movement(wander_speed, delta)
			_update_facing()
			if _state_timer <= 0.0:
				_enter_idle()
			elif global_position.distance_to(_wander_origin) > WANDER_RADIUS:
				_move_dir = (_wander_origin - global_position).normalized()

	_animate(delta)

func _compute_flee_direction() -> Vector2:
	if _player == null or not is_instance_valid(_player):
		return Vector2.ZERO
	var dist: float = global_position.distance_to(_player.global_position)
	if _state == "flee" and dist < FLEE_CLEAR_RADIUS:
		return (global_position - _player.global_position).normalized()
	if dist < FLEE_RADIUS:
		return (global_position - _player.global_position).normalized()
	return Vector2.ZERO

func _apply_movement(speed: float, delta: float) -> void:
	position += _move_dir * speed * delta

func _enter_idle() -> void:
	_state = "idle"
	_move_dir = Vector2.ZERO
	_state_timer = _rng.randf_range(idle_time_min, idle_time_max)

func _enter_wander() -> void:
	_state = "wander"
	var angle: float = _rng.randf_range(0.0, TAU)
	_move_dir = Vector2(cos(angle), sin(angle) * 0.5).normalized()
	_state_timer = _rng.randf_range(wander_time_min, wander_time_max)

func _update_facing() -> void:
	if _body_node == null or _move_dir.x == 0.0:
		return
	_body_node.scale.x = -1.0 if _move_dir.x < 0.0 else 1.0

func _animate(_delta: float) -> void:
	pass
