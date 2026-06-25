extends RefCounted
class_name Nameplate

## Floating name label above a character (NPCs, the local player, remote
## players). A name line plus an optional subtitle role line, outlined so they
## stay readable over any terrain. Purely presentational — no collision, no
## input. Returns the holder Node2D so callers can update or free it.

## Floating name above a character. The role SUBTITLE is hidden by default to keep
## the scene uncluttered (every NPC stacking a "Villager"/"Mentor" line read as
## noise); pass show_subtitle=true only where a role line is genuinely useful.
# --- Nameplate vertical placement (px from the character ROOT/feet origin) ----------------
# The avatar is a 16x32 frame at x2 (≈64px tall, feet at y=0). Measured visual tops from the
# character root: normal hair ≈ -44, beanie ≈ -48, and the TALLEST equipped accessory (chef hat)
# ≈ -62. The name's bottom must clear the tallest case so it never slices into head/hair/hats.
# Derived: tallest_top(-62) - clearance(6) - approx label height(18) ≈ -86. A safe minimum floor
# keeps the name well above the head even if these constants drift. Stable constant (not the
# bobbing Body), so the label never jitters while walking.
const AVATAR_TALLEST_TOP_Y := -62.0
const NAME_CLEARANCE := 6.0
const APPROX_LABEL_HEIGHT := 18.0
const SAFE_MIN_OFFSET_Y := -70.0  # name never sits lower (less negative) than this
const NAME_OFFSET_Y := minf(AVATAR_TALLEST_TOP_Y - NAME_CLEARANCE - APPROX_LABEL_HEIGHT, SAFE_MIN_OFFSET_Y)

static func attach(parent: Node2D, character_name: String, subtitle: String = "", name_color: Color = Color("#f5f0e6"), show_subtitle: bool = false, portrait_id: String = "") -> Node2D:
	var holder: Node2D = Node2D.new()
	holder.name = "Nameplate"
	holder.position = Vector2(0, NAME_OFFSET_Y)  # clearly above the head/hat, not cutting in
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
	# Cozy floating name: the shared Hearthvale UI text style (CozyUITheme.apply_nameplate_label)
	# — warm cream/accent text with a thick dark-ink outline + soft shadow for legibility over any
	# terrain, NO heavy backing box. Centralized so it matches the rest of the UI.
	var label: Label = Label.new()
	label.text = text
	label.position = Vector2(-70, 0)
	label.custom_minimum_size = Vector2(140, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CozyUITheme.apply_nameplate_label(label, maxi(font_size, 13), color)
	return label
