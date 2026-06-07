extends Node2D
class_name DevWorldMarker

## A temporary, visual-only developer marker for authoring the overworld. It has no
## collision and is never saved — markers exist only for the current session unless
## exported to a local file. Set `position`, call `setup(...)`, then add it to a
## world-space layer; `_ready` builds the pin + label from the stored fields.

var marker_id: int = 0
var area_label: String = ""
var marker_type: String = "marker"

func setup(id: int, area: String, type: String) -> void:
	marker_id = id
	area_label = area
	marker_type = type

func _ready() -> void:
	z_index = 200

	var shadow: Polygon2D = Polygon2D.new()
	shadow.position = Vector2(0, 2)
	shadow.polygon = PackedVector2Array([Vector2(-6, -1), Vector2(6, -1), Vector2(4, 2), Vector2(-4, 2)])
	shadow.color = Color(0, 0, 0, 0.25)
	add_child(shadow)

	var pin: Polygon2D = Polygon2D.new()
	pin.polygon = PackedVector2Array([Vector2(0, -22), Vector2(8, -9), Vector2(0, 0), Vector2(-8, -9)])
	pin.color = _type_color()
	add_child(pin)

	var head: Polygon2D = Polygon2D.new()
	head.position = Vector2(0, -15)
	head.polygon = PackedVector2Array([Vector2(0, -4), Vector2(4, 0), Vector2(0, 4), Vector2(-4, 0)])
	head.color = Color(1, 1, 1, 0.9)
	add_child(head)

	var label: Label = Label.new()
	label.position = Vector2(10, -32)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 4)
	label.text = "#%d %s\n(%d, %d)\n%s" % [marker_id, marker_type, int(position.x), int(position.y), area_label]
	add_child(label)

func _type_color() -> Color:
	match marker_type:
		"blocked_note":
			return Color(0.92, 0.5, 0.2)
		"spawn_note":
			return Color(0.4, 0.7, 0.95)
		"inspect":
			return Color(0.85, 0.82, 0.4)
		_:
			return Color(0.95, 0.3, 0.4)
