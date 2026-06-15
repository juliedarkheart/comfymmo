extends RefCounted
class_name Nameplate

## Floating name label above a character (NPCs, the local player, remote
## players). A name line plus an optional subtitle role line, outlined so they
## stay readable over any terrain. Purely presentational — no collision, no
## input. Returns the holder Node2D so callers can update or free it.

static func attach(parent: Node2D, character_name: String, subtitle: String = "", name_color: Color = Color("#f5f0e6")) -> Node2D:
	var holder: Node2D = Node2D.new()
	holder.name = "Nameplate"
	holder.position = Vector2(0, -84)
	holder.z_index = 50
	parent.add_child(holder)

	var name_label: Label = _make_label(character_name, 13, name_color)
	holder.add_child(name_label)

	if not subtitle.is_empty():
		var subtitle_label: Label = _make_label(subtitle, 11, Color(0.82, 0.88, 0.78, 0.92))
		subtitle_label.position.y = 15.0
		holder.add_child(subtitle_label)
	return holder

## Update the name line of an existing nameplate holder (e.g. on rename).
static func set_name_text(holder: Node2D, character_name: String) -> void:
	if holder == null or not is_instance_valid(holder) or holder.get_child_count() == 0:
		return
	(holder.get_child(0) as Label).text = character_name

static func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = Vector2(-70, 0)
	label.custom_minimum_size = Vector2(140, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.14, 0.1, 0.07, 0.92))
	label.add_theme_constant_override("outline_size", 5)
	return label
