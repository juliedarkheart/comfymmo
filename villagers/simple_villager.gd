extends Node2D
class_name SimpleVillager

@export var villager_name: String = "Villager"
@export var first_visit_text: String = "Hello."
@export var repeat_visit_text: String = "Good to see you again."
@export var repeat_visit_lines: PackedStringArray = PackedStringArray()

var _idle_timer: float = 0.0
var _body_node: Node2D = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_idle_timer = _rng.randf_range(0.0, TAU)
	_build_visual()

func _process(delta: float) -> void:
	_idle_timer += delta * 0.9
	if _body_node != null:
		_body_node.position.y = sin(_idle_timer) * 2.5

func get_repeat_line(visit_count: int) -> String:
	if repeat_visit_lines.size() > 0:
		return repeat_visit_lines[visit_count % repeat_visit_lines.size()]
	return repeat_visit_text

## Villagers share the chibi visual language with the player: the shared
## CharacterVisualBuilder draws the base character from an appearance dict,
## then _decorate() layers on this villager's signature details. Subclasses
## override _get_appearance()/_decorate() instead of redrawing from scratch.
func _build_visual() -> void:
	var root: Node2D = Node2D.new()
	root.name = "Body"
	add_child(root)
	_body_node = root

	var shadow: Polygon2D = Polygon2D.new()
	shadow.position = Vector2(0, 2)
	shadow.polygon = PackedVector2Array([
		Vector2(-13, 0), Vector2(-9, -3), Vector2(0, -4), Vector2(9, -3),
		Vector2(13, 0), Vector2(9, 3), Vector2(0, 4), Vector2(-9, 3),
	])
	shadow.color = Color(0.1, 0.08, 0.06, 0.16)
	root.add_child(shadow)

	CharacterVisualBuilder.build(root, _get_appearance())
	_decorate(root)

## Default appearance is Maribel Tock: soft curls, a terracotta tunic.
func _get_appearance() -> Dictionary:
	return {
		"skin_tone": "honey",
		"hair_style": "soft_curls",
		"hair_color": "warm_brown",
		"outfit_style": "cozy_tunic",
		"outfit_color": "terracotta",
		"accessory": "none",
	}

## Maribel's signature details: half-frame glasses and her clock brooch.
func _decorate(root: Node2D) -> void:
	for gx: float in [-5.5, 5.5]:
		var rim: Polygon2D = Polygon2D.new()
		rim.position = Vector2(gx, -44.5)
		rim.polygon = PackedVector2Array([
			Vector2(-4, 0), Vector2(4, 0), Vector2(4, 1.2), Vector2(-4, 1.2),
		])
		rim.color = Color("#5a4030")
		root.add_child(rim)

	var bridge: Polygon2D = Polygon2D.new()
	bridge.position = Vector2(0, -44)
	bridge.polygon = PackedVector2Array([
		Vector2(-1.5, 0), Vector2(1.5, 0), Vector2(1.5, 1), Vector2(-1.5, 1),
	])
	bridge.color = Color("#5a4030")
	root.add_child(bridge)

	var brooch: Polygon2D = Polygon2D.new()
	brooch.position = Vector2(5, -22)
	brooch.polygon = PackedVector2Array([
		Vector2(0, -3), Vector2(3, 0), Vector2(0, 3), Vector2(-3, 0),
	])
	brooch.color = Color("#d4a84a")
	root.add_child(brooch)

	var brooch_mark: Polygon2D = Polygon2D.new()
	brooch_mark.position = Vector2(5, -24)
	brooch_mark.polygon = PackedVector2Array([
		Vector2(-0.5, 0), Vector2(0.5, 0), Vector2(0.5, 2), Vector2(-0.5, 2),
	])
	brooch_mark.color = Color("#8a6020")
	root.add_child(brooch_mark)
