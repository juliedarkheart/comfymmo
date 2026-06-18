extends RefCounted
class_name Nameplate

## Floating name label above a character (NPCs, the local player, remote
## players). A name line plus an optional subtitle role line, outlined so they
## stay readable over any terrain. Purely presentational — no collision, no
## input. Returns the holder Node2D so callers can update or free it.

## Floating name above a character. The role SUBTITLE is hidden by default to keep
## the scene uncluttered (every NPC stacking a "Villager"/"Mentor" line read as
## noise); pass show_subtitle=true only where a role line is genuinely useful.
static func attach(parent: Node2D, character_name: String, subtitle: String = "", name_color: Color = Color("#f5f0e6"), show_subtitle: bool = false, portrait_id: String = "") -> Node2D:
	var holder: Node2D = Node2D.new()
	holder.name = "Nameplate"
	holder.position = Vector2(0, -52)
	holder.z_index = 50
	parent.add_child(holder)

	# Generator-aware: when a character has a LimeZu-generator portrait cataloged locally,
	# show a small framed portrait chip above the name. Opt-in (portrait_id set) and
	# fallback-safe — no entry/output -> no chip, never a broken/placeholder image.
	if not portrait_id.is_empty():
		var portrait: Texture2D = GeneratorCharacterRegistry.portrait_texture(portrait_id)
		if portrait != null:
			var frame := Panel.new()
			frame.custom_minimum_size = Vector2(30, 30)
			frame.size = Vector2(30, 30)
			frame.position = Vector2(-15, -34)
			frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			frame.add_theme_stylebox_override("panel", LimeZuUITheme.portrait_frame_style())
			var pic := TextureRect.new()
			pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			pic.offset_left = 4; pic.offset_top = 4; pic.offset_right = -4; pic.offset_bottom = -4
			pic.texture = portrait
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			frame.add_child(pic)
			holder.add_child(frame)

	var name_label: Label = _make_label(character_name, 11, name_color)
	holder.add_child(name_label)

	if show_subtitle and not subtitle.is_empty():
		var subtitle_label: Label = _make_label(subtitle, 10, Color(0.82, 0.88, 0.78, 0.92))
		subtitle_label.position.y = 13.0
		holder.add_child(subtitle_label)
	return holder

## Update the name line of an existing nameplate holder (e.g. on rename).
static func set_name_text(holder: Node2D, character_name: String) -> void:
	if holder == null or not is_instance_valid(holder) or holder.get_child_count() == 0:
		return
	(holder.get_child(0) as Label).text = character_name

static func _make_label(text: String, font_size: int, color: Color) -> Label:
	# Clean cozy nameplate: warm cream/gold text with a thin soft outline + drop shadow for
	# legibility over any terrain — NO heavy dark backing box (that black blob read as ugly).
	var label: Label = Label.new()
	label.text = text
	label.position = Vector2(-70, 0)
	label.custom_minimum_size = Vector2(140, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", maxi(font_size, 12))
	label.add_theme_color_override("font_color", color)
	# Thin outline keeps the text readable on light/dark ground without a box.
	label.add_theme_color_override("font_outline_color", Color(0.16, 0.11, 0.07, 0.85))
	label.add_theme_constant_override("outline_size", 3)
	# Subtle drop shadow for depth instead of a backing panel.
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.45))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("shadow_outline_size", 1)
	return label
