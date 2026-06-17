extends AmbientCreature
class_name StumpTurtle

const OBSERVE_TEXTS: Array[String] = [
	"The stump turtle blinks very slowly.",
	"A little moss grows happily on its shell.",
	"It seems to have all the time in the world.",
]

var _wobble_timer: float = 0.0
var _shell_node: Node2D = null
var _head_node: Node2D = null
var _rng_text: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	# Sleepy and slow: gentle wander, soft unhurried retreat, long idle pauses.
	wander_speed = 13.0
	flee_speed = 19.0
	idle_time_min = 4.0
	idle_time_max = 9.0
	wander_time_min = 1.8
	wander_time_max = 3.6
	super._ready()
	_rng_text.randomize()
	_wobble_timer = _rng.randf_range(0.0, TAU)
	_build_visual()

func get_display_name() -> String:
	return "Stump Turtle"

func get_observe_text() -> String:
	return OBSERVE_TEXTS[_rng_text.randi() % OBSERVE_TEXTS.size()]

func _build_visual() -> void:
	var root: Node2D = Node2D.new()
	root.name = "Body"
	add_child(root)
	_body_node = root

	if CharacterArtRegistry.apply_sprite(root, CharacterArtRegistry.STUMP_TURTLE):
		return

	var shadow: Polygon2D = Polygon2D.new()
	shadow.position = Vector2(0, 8)
	shadow.polygon = PackedVector2Array([
		Vector2(-15, 0), Vector2(15, 0), Vector2(11, 4), Vector2(-11, 4),
	])
	shadow.color = Color(0.1, 0.08, 0.06, 0.16)
	root.add_child(shadow)

	# Stubby legs poke out under the shell
	var leg_offsets: Array[Vector2] = [
		Vector2(-11, 4), Vector2(11, 4), Vector2(-8, 8), Vector2(8, 8),
	]
	for offset: Vector2 in leg_offsets:
		var leg: Polygon2D = Polygon2D.new()
		leg.position = offset
		leg.polygon = PackedVector2Array([
			Vector2(-3, -2), Vector2(3, -2), Vector2(2, 4), Vector2(-2, 4),
		])
		leg.color = Color("#8a9a5c")
		root.add_child(leg)

	# Sleepy head poking out the front, bobs gently
	var head: Node2D = Node2D.new()
	head.position = Vector2(0, 4)
	root.add_child(head)
	_head_node = head

	var neck: Polygon2D = Polygon2D.new()
	neck.polygon = PackedVector2Array([
		Vector2(-4, -2), Vector2(4, -2), Vector2(4, 4), Vector2(-4, 4),
	])
	neck.color = Color("#93a064")
	head.add_child(neck)

	var head_top: Polygon2D = Polygon2D.new()
	head_top.position = Vector2(0, -2)
	head_top.polygon = PackedVector2Array([
		Vector2(0, -6), Vector2(6, -3), Vector2(6, 2),
		Vector2(0, 5), Vector2(-6, 2), Vector2(-6, -3),
	])
	head_top.color = Color("#a3b06f")
	head.add_child(head_top)

	# Slow, sleepy eyes — short horizontal lids rather than open dots
	for ex: int in [-3, 3]:
		var eyelid: Polygon2D = Polygon2D.new()
		eyelid.position = Vector2(ex, -2)
		eyelid.polygon = PackedVector2Array([
			Vector2(-1.5, 0), Vector2(1.5, 0), Vector2(1.5, 1), Vector2(-1.5, 1),
		])
		eyelid.color = Color("#3e3220")
		head.add_child(eyelid)

	# Mossy stump shell — wobbles gently; drawn after head so it overlaps the neck
	var shell: Node2D = Node2D.new()
	shell.position = Vector2(0, -4)
	root.add_child(shell)
	_shell_node = shell

	var shell_base: Polygon2D = Polygon2D.new()
	shell_base.polygon = PackedVector2Array([
		Vector2(-14, 2), Vector2(-12, -6), Vector2(-6, -11), Vector2(0, -12),
		Vector2(6, -11), Vector2(12, -6), Vector2(14, 2),
		Vector2(8, 6), Vector2(0, 7), Vector2(-8, 6),
	])
	shell_base.color = Color("#6b4f32")
	shell.add_child(shell_base)

	# Stump rings on the shell edge for a cut-wood feel
	var ring: Polygon2D = Polygon2D.new()
	ring.position = Vector2(0, -2)
	ring.polygon = PackedVector2Array([
		Vector2(-10, 1), Vector2(-8, -4), Vector2(0, -7),
		Vector2(8, -4), Vector2(10, 1), Vector2(0, 4),
	])
	ring.color = Color("#7d5e3c")
	shell.add_child(ring)

	# Moss cap on top of the shell
	var moss: Polygon2D = Polygon2D.new()
	moss.position = Vector2(0, -7)
	moss.polygon = PackedVector2Array([
		Vector2(-9, 2), Vector2(-6, -3), Vector2(0, -5),
		Vector2(6, -3), Vector2(9, 2), Vector2(0, 4),
	])
	moss.color = Color("#6f9d54")
	shell.add_child(moss)

	# Little moss tufts
	var tuft_offsets: Array[Vector2] = [
		Vector2(-4, -9), Vector2(3, -10), Vector2(-1, -7),
	]
	for offset: Vector2 in tuft_offsets:
		var tuft: Polygon2D = Polygon2D.new()
		tuft.position = offset
		tuft.polygon = PackedVector2Array([
			Vector2(0, -2), Vector2(2, 0), Vector2(0, 2), Vector2(-2, 0),
		])
		tuft.color = Color("#8cbf68")
		shell.add_child(tuft)

func _animate(delta: float) -> void:
	# Speed of wobble follows whether the turtle is plodding along or resting.
	var wobble_rate: float = 3.2 if _state == "wander" or _state == "flee" else 1.1
	_wobble_timer += delta * wobble_rate

	if _shell_node != null:
		_shell_node.rotation = sin(_wobble_timer) * 0.07
	if _head_node != null:
		_head_node.position.y = 4.0 + sin(_wobble_timer * 1.3) * 1.3
