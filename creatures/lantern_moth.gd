extends AmbientCreature
class_name LanternMoth

const OBSERVE_TEXTS: Array[String] = [
	"Tiny wings shimmer in the light.",
	"A soft glow pulses gently.",
	"The moth drifts on a warm breeze.",
	"Its wings leave a faint trail of light.",
]

var _float_timer: float = 0.0
var _wing_timer: float = 0.0
var _left_wing: Polygon2D = null
var _right_wing: Polygon2D = null
var _glow_ring: Polygon2D = null
var _rng_text: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	wander_speed = 22.0
	flee_speed = 52.0
	idle_time_min = 2.5
	idle_time_max = 6.0
	wander_time_min = 3.0
	wander_time_max = 7.5
	super._ready()
	_rng_text.randomize()
	_float_timer = _rng.randf_range(0.0, TAU)
	_wing_timer = _rng.randf_range(0.0, TAU)
	_build_visual()

func get_display_name() -> String:
	return "Lantern Moth"

func get_observe_text() -> String:
	return OBSERVE_TEXTS[_rng_text.randi() % OBSERVE_TEXTS.size()]

func _build_visual() -> void:
	var root: Node2D = Node2D.new()
	root.name = "Body"
	add_child(root)
	_body_node = root

	_glow_ring = Polygon2D.new()
	_glow_ring.polygon = PackedVector2Array([
		Vector2(0, -12), Vector2(12, 0), Vector2(0, 12), Vector2(-12, 0),
	])
	_glow_ring.color = Color(0.95, 0.88, 0.52, 0.20)
	root.add_child(_glow_ring)

	_left_wing = Polygon2D.new()
	_left_wing.position = Vector2(-9, 0)
	_left_wing.polygon = PackedVector2Array([
		Vector2(-9, -5), Vector2(1, -8), Vector2(4, 0), Vector2(1, 7), Vector2(-9, 4),
	])
	_left_wing.color = Color(0.66, 0.85, 0.72, 0.78)
	root.add_child(_left_wing)

	_right_wing = Polygon2D.new()
	_right_wing.position = Vector2(9, 0)
	_right_wing.polygon = PackedVector2Array([
		Vector2(9, -5), Vector2(-1, -8), Vector2(-4, 0), Vector2(-1, 7), Vector2(9, 4),
	])
	_right_wing.color = Color(0.66, 0.85, 0.72, 0.78)
	root.add_child(_right_wing)

	var body: Polygon2D = Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(0, -7), Vector2(4, -2), Vector2(4, 4),
		Vector2(0, 8), Vector2(-4, 4), Vector2(-4, -2),
	])
	body.color = Color("#e8d898")
	root.add_child(body)

	var core: Polygon2D = Polygon2D.new()
	core.position = Vector2(0, 1)
	core.polygon = PackedVector2Array([
		Vector2(0, -3), Vector2(3, 0), Vector2(0, 3), Vector2(-3, 0),
	])
	core.color = Color(1.0, 0.96, 0.72, 0.92)
	root.add_child(core)

	var eye: Polygon2D = Polygon2D.new()
	eye.position = Vector2(0, -3)
	eye.polygon = PackedVector2Array([
		Vector2(0, -2), Vector2(2, 0), Vector2(0, 2), Vector2(-2, 0),
	])
	eye.color = Color("#4a3c1a")
	root.add_child(eye)

func _animate(delta: float) -> void:
	_float_timer += delta * 1.6
	_wing_timer += delta * 9.0

	if _body_node != null:
		_body_node.position.y = sin(_float_timer) * 5.0

	var wing_scale: float = 0.65 + absf(sin(_wing_timer)) * 0.35
	if _left_wing != null:
		_left_wing.scale.x = wing_scale
	if _right_wing != null:
		_right_wing.scale.x = wing_scale

	if _glow_ring != null:
		_glow_ring.color.a = 0.14 + absf(sin(_float_timer * 0.6)) * 0.16
