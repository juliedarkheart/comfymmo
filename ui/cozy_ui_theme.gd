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
	if LiveVisualPolicy.live_limezu_slice() and LimeZuArtRegistry.has_asset("ui.panel"):
		return "limezu_modern_ui"
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

## Solid dark HUD backing. The HUD floats over the bright top-down world, so it
## needs strong contrast for its cream text — it intentionally stays a dark, mostly
## opaque cozy card (with a honey border) rather than the pale Sprout parchment
## panel, which left light text unreadable. Generous content margins keep text off
## the border.
static func hud_panel_style(fill: Color = WOOD_DARK) -> StyleBoxFlat:
	var solid := Color(fill.r, fill.g, fill.b, 0.88)
	var style := panel_style(solid)
	style.border_color = BORDER_LIGHT
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 14
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 5
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

static func slot_box(selected: bool = false, blocked: bool = false) -> StyleBox:
	var ui_id: String = "slot_selected" if selected else "slot"
	var fallback: StyleBox = slot_style(selected, blocked)
	if blocked and LiveVisualPolicy.live_limezu_slice():
		return LimeZuUITheme.slot_style(false, true)
	return fallback if blocked else _ui_box(ui_id, fallback, 8)

## LimeZu Modern UI ids for each cozy ui_id, used when LimeZu is the live provider.
const LIMEZU_UI_MAP := {
	"panel": "ui.panel",
	"inventory_panel": "ui.inventory_panel",
	"slot": "ui.slot",
	"slot_selected": "ui.slot_selected",
	"button": "ui.button",
	"button_hover": "ui.button_hover",
	"close": "ui.close",
	"close_hover": "ui.close_hover",
	"tab": "ui.tab",
}

## In LimeZu live mode, panels and compact controls use reviewed Modern UI textures.
## Layouts stay compact so the UI fits the small asset kit instead of hiding behind
## custom flat boxes.
static func _limezu_box(ui_id: String, content_margin: int) -> StyleBox:
	if not LiveVisualPolicy.live_limezu_slice():
		return null
	match ui_id:
		"panel":
			return LimeZuUITheme.panel_texture_style(content_margin)
		"inventory_panel":
			return LimeZuUITheme.panel_texture_style(content_margin, true)
		"slot":
			return LimeZuUITheme.slot_texture_style(false)
		"slot_selected":
			return LimeZuUITheme.slot_texture_style(true)
		"button":
			return LimeZuUITheme.button_texture_style(false)
		"button_hover":
			return LimeZuUITheme.button_texture_style(true)
		"button_pressed":
			return LimeZuUITheme.button_texture_style(true)
		"close":
			return LimeZuUITheme.close_texture_style(false)
		"close_hover":
			return LimeZuUITheme.close_texture_style(true)
		"tab":
			return LimeZuUITheme.tab_texture_style(true)
		_:
			return null

## Single UI skin switch: LimeZu Modern UI when it is the live provider, else an
## activated Sprout UI nine-patch, else the code-drawn cozy box. Every panel that
## styles itself through CozyUITheme picks this up automatically.
static func _ui_box(ui_id: String, fallback: StyleBox, content_margin: int = 12) -> StyleBox:
	var limezu: StyleBox = _limezu_box(ui_id, content_margin)
	if limezu != null:
		return limezu
	var textured: StyleBoxTexture = UIArtRegistry.texture_stylebox(ui_id, content_margin)
	return textured if textured != null else fallback

## Crisp pixel filtering for LimeZu-skinned controls (16px UI art scaled up).
static func _maybe_pixel_filter(control: Control) -> void:
	if LiveVisualPolicy.live_limezu_slice():
		control.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

static func apply_panel(panel: Control, fill: Color = PARCHMENT) -> void:
	if panel == null:
		return
	_tag_ui_source(panel)
	_maybe_pixel_filter(panel)
	panel.add_theme_stylebox_override("panel", _ui_box("panel", panel_style(fill), 14))

static func apply_inventory_panel(panel: Control) -> void:
	if panel == null:
		return
	_tag_ui_source(panel)
	_maybe_pixel_filter(panel)
	panel.add_theme_stylebox_override("panel", _ui_box("inventory_panel", panel_style(PARCHMENT), 14))

static func apply_hud_panel(panel: Control) -> void:
	if panel == null:
		return
	_tag_ui_source(panel)
	_maybe_pixel_filter(panel)
	# In LimeZu live mode the HUD/minimap/prompt cards use the Modern UI panel asset
	# and dark ink labels; in Sprout mode they keep the solid dark cozy backing.
	if LiveVisualPolicy.live_limezu_slice():
		panel.add_theme_stylebox_override("panel", LimeZuUITheme.hud_panel_texture_style())
	else:
		panel.add_theme_stylebox_override("panel", hud_panel_style())

static func apply_slot(panel: Control, selected: bool = false, blocked: bool = false) -> void:
	if panel == null:
		return
	_tag_ui_source(panel)
	_maybe_pixel_filter(panel)
	# Blocked slots stay code-drawn so "unavailable" reads clearly regardless of skin.
	panel.add_theme_stylebox_override("panel", slot_box(selected, blocked))

static func heading(text: String, size: int = 18) -> Label:
	var label := Label.new()
	label.text = text
	apply_heading_label(label, size)
	return label

static func apply_heading_label(label: Label, size: int = 18) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", size)
	# LimeZu panels are parchment-like Modern UI frames -> dark warm ink title.
	var color: Color = LimeZuUITheme.title_text_color() if LiveVisualPolicy.live_limezu_slice() else HONEY
	label.add_theme_color_override("font_color", color)

static func apply_body_label(label: Label, size: int = 14, on_dark: bool = false) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", size)
	# LimeZu live mode uses parchment-like Modern UI panels -> dark ink body text.
	# Sprout still uses cream on the dark HUD and dark ink on parchment menus.
	var color: Color
	if LiveVisualPolicy.live_limezu_slice():
		color = LimeZuUITheme.readable_text_color()
	else:
		color = CREAM_TEXT if on_dark else INK
	label.add_theme_color_override("font_color", color)

static func apply_secondary_label(label: Label, size: int = 12, on_dark: bool = false) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", size)
	var dim_cream := Color(CREAM_TEXT.r, CREAM_TEXT.g, CREAM_TEXT.b, 0.78)
	var color: Color
	if LiveVisualPolicy.live_limezu_slice():
		color = LimeZuUITheme.muted_text_color()
	else:
		color = INK_SOFT if not on_dark else dim_cream
	label.add_theme_color_override("font_color", color)

static func apply_button(button: Button) -> void:
	if button == null:
		return
	_tag_ui_source(button)
	_maybe_pixel_filter(button)
	var live_limezu: bool = LiveVisualPolicy.live_limezu_slice()
	# LimeZu buttons are dark strips -> cream label, gold on hover. Sprout uses dark ink.
	var min_size: Vector2 = button.custom_minimum_size
	min_size.x = maxf(min_size.x, 54.0)
	min_size.y = maxf(min_size.y, 28.0)
	button.custom_minimum_size = min_size
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", LimeZuUITheme.button_text_color() if live_limezu else INK)
	button.add_theme_color_override("font_hover_color", LimeZuUITheme.button_hover_text_color() if live_limezu else BORDER)
	button.add_theme_color_override("font_disabled_color", LimeZuUITheme.disabled_text_color() if live_limezu else INK_SOFT)
	button.add_theme_stylebox_override("normal", _ui_box("button", slot_style(false), 8))
	button.add_theme_stylebox_override("hover", _ui_box("button_hover", slot_style(true), 8))
	button.add_theme_stylebox_override("pressed", _ui_box("button_pressed", slot_style(true), 8))
	# Disabled stays code-drawn so unavailable actions read clearly on any skin.
	button.add_theme_stylebox_override("disabled", LimeZuUITheme.slot_style(false, true) if live_limezu else slot_style(false, true))

static func apply_tab_button(button: Button, selected: bool) -> void:
	if button == null:
		return
	apply_button(button)
	var live_limezu: bool = LiveVisualPolicy.live_limezu_slice()
	var ui_id: String = "slot_selected" if selected else "tab"
	button.add_theme_stylebox_override("normal", _ui_box(ui_id, slot_style(selected), 8))
	if live_limezu:
		button.add_theme_color_override("font_color", LimeZuUITheme.button_hover_text_color() if selected else LimeZuUITheme.button_text_color())
	else:
		button.add_theme_color_override("font_color", BORDER if selected else INK)

static func apply_close_button(button: Button) -> void:
	if button == null:
		return
	apply_button(button)
	button.text = button.text if not button.text.is_empty() else "Close"
	button.add_theme_stylebox_override("normal", _ui_box("close", slot_style(false), 8))
	button.add_theme_stylebox_override("hover", _ui_box("close_hover", slot_style(true), 8))
	button.add_theme_stylebox_override("pressed", _ui_box("close_hover", slot_style(true), 8))

static func apply_danger_button(button: Button) -> void:
	if button == null:
		return
	apply_button(button)
	var live_limezu: bool = LiveVisualPolicy.live_limezu_slice()
	var danger := slot_style(false)
	danger.bg_color = LimeZuUITheme.SLOT_BASE if live_limezu else Color("#f1c6ae")
	danger.border_color = LimeZuUITheme.BAD if live_limezu else BAD
	# LimeZu: warm red label that stays readable on dark wood, cream on hover.
	button.add_theme_color_override("font_color", LimeZuUITheme.BAD if live_limezu else BAD)
	button.add_theme_color_override("font_hover_color", LimeZuUITheme.button_text_color() if live_limezu else INK)
	button.add_theme_stylebox_override("normal", _ui_box("close", danger, 8))
	button.add_theme_stylebox_override("hover", _ui_box("close_hover", slot_style(false, true), 8))
	button.add_theme_stylebox_override("pressed", _ui_box("close_hover", slot_style(false, true), 8))

static func apply_option_button(button: OptionButton) -> void:
	if button == null:
		return
	apply_button(button)

static func apply_text_input(edit: LineEdit) -> void:
	if edit == null:
		return
	_tag_ui_source(edit)
	_maybe_pixel_filter(edit)
	var live_limezu: bool = LiveVisualPolicy.live_limezu_slice()
	var min_size: Vector2 = edit.custom_minimum_size
	min_size.y = maxf(min_size.y, 28.0)
	edit.custom_minimum_size = min_size
	edit.add_theme_font_size_override("font_size", 12)
	edit.add_theme_color_override("font_color", LimeZuUITheme.readable_text_color() if live_limezu else INK)
	edit.add_theme_color_override("font_placeholder_color", LimeZuUITheme.muted_text_color() if live_limezu else INK_SOFT)
	edit.add_theme_color_override("caret_color", LimeZuUITheme.title_text_color() if live_limezu else BORDER)
	edit.add_theme_stylebox_override("normal", _ui_box("slot", inset_style(SLOT), 8))
	edit.add_theme_stylebox_override("focus", _ui_box("slot_selected", slot_style(true), 8))
	edit.add_theme_stylebox_override("read_only", slot_style(false, true))

static func apply_all_buttons(root: Node) -> void:
	if root == null:
		return
	for node in root.find_children("*", "Button", true, false):
		apply_button(node as Button)
