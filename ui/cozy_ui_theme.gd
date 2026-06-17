extends RefCounted
class_name CozyUITheme

## Shared cozy UI style: warm parchment, honey accents, clear borders, and
## readable slots. Panels call these factory helpers instead of reinventing
## colors, so future menus inherit the same Hearthvale visual language.

const PARCHMENT: Color = Color("#f3e0b0")       # panel fill
const PARCHMENT_DEEP: Color = Color("#e7cb8d")  # inset / alt fill
const WOOD: Color = Color("#6d472b")            # dark frame fill
const WOOD_DARK: Color = Color("#3e2e23")       # HUD / dim fill
const SLOT: Color = Color("#f6ead0")            # item slot fill
const SLOT_SELECTED: Color = Color("#ffe9a8")   # highlighted slot
const SLOT_BLOCKED: Color = Color("#d8c4a6")    # unavailable slot fill
const BORDER: Color = Color("#86511f")          # thick outer border
const BORDER_LIGHT: Color = Color("#c8893f")    # inner bevel border
const INK: Color = Color("#4a3420")             # body text
const INK_SOFT: Color = Color("#7a5a36")        # secondary text
const CREAM_TEXT: Color = Color("#f8efd8")      # text on dark HUD panels
const HONEY: Color = Color("#e0a64b")           # accent / headings
const GOOD: Color = Color("#5f9150")            # affordable / allowed
const BAD: Color = Color("#b5563f")             # blocked / missing

static func active_ui_source() -> String:
	return UIArtRegistry.active_source()

static func _tag_ui_source(control: Control) -> void:
	if control != null:
		control.set_meta("ui_art_source", active_ui_source())

static func panel_style(fill: Color = PARCHMENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = BORDER
	style.set_border_width_all(4)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 6
	return style

static func hud_panel_style(fill: Color = WOOD_DARK) -> StyleBoxFlat:
	var style := panel_style(fill)
	style.border_color = BORDER_LIGHT
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.24)
	style.shadow_size = 8
	return style

static func inset_style(fill: Color = PARCHMENT_DEEP) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = BORDER_LIGHT
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	return style

static func slot_style(selected: bool = false, blocked: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = SLOT_BLOCKED if blocked else (SLOT_SELECTED if selected else SLOT)
	style.border_color = BAD if blocked else (HONEY if selected else BORDER_LIGHT)
	style.set_border_width_all(3 if selected else 2)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(8)
	return style

static func apply_panel(panel: Control, fill: Color = PARCHMENT) -> void:
	if panel == null:
		return
	_tag_ui_source(panel)
	panel.add_theme_stylebox_override("panel", panel_style(fill))

static func apply_hud_panel(panel: Control) -> void:
	if panel == null:
		return
	_tag_ui_source(panel)
	panel.add_theme_stylebox_override("panel", hud_panel_style())

static func apply_slot(panel: Control, selected: bool = false, blocked: bool = false) -> void:
	if panel == null:
		return
	_tag_ui_source(panel)
	panel.add_theme_stylebox_override("panel", slot_style(selected, blocked))

static func heading(text: String, size: int = 18) -> Label:
	var label := Label.new()
	label.text = text
	apply_heading_label(label, size)
	return label

static func apply_heading_label(label: Label, size: int = 18) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", HONEY)

static func apply_body_label(label: Label, size: int = 14, on_dark: bool = false) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", CREAM_TEXT if on_dark else INK)

static func apply_secondary_label(label: Label, size: int = 12, on_dark: bool = false) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(CREAM_TEXT.r, CREAM_TEXT.g, CREAM_TEXT.b, 0.78) if on_dark else INK_SOFT)

static func apply_button(button: Button) -> void:
	if button == null:
		return
	_tag_ui_source(button)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", BORDER)
	button.add_theme_stylebox_override("normal", slot_style(false))
	button.add_theme_stylebox_override("hover", slot_style(true))
	button.add_theme_stylebox_override("pressed", slot_style(true))
	button.add_theme_stylebox_override("disabled", slot_style(false, true))

static func apply_tab_button(button: Button, selected: bool) -> void:
	if button == null:
		return
	apply_button(button)
	button.add_theme_stylebox_override("normal", slot_style(selected))
	button.add_theme_color_override("font_color", BORDER if selected else INK)

static func apply_close_button(button: Button) -> void:
	if button == null:
		return
	apply_button(button)
	button.text = button.text if not button.text.is_empty() else "Close"

static func apply_danger_button(button: Button) -> void:
	if button == null:
		return
	apply_button(button)
	var danger := slot_style(false)
	danger.bg_color = Color("#f1c6ae")
	danger.border_color = BAD
	button.add_theme_stylebox_override("normal", danger)
	button.add_theme_stylebox_override("hover", slot_style(false, true))

static func apply_all_buttons(root: Node) -> void:
	if root == null:
		return
	for node in root.find_children("*", "Button", true, false):
		apply_button(node as Button)
