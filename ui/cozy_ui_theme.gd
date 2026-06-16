extends RefCounted
class_name CozyUITheme

## Shared cozy UI style — a warm parchment/honey palette with thick pixel-style
## borders, modeled on the Stardew-like reference screenshots (readable, warm,
## not transparent chaos). Panels call these factory helpers instead of each
## reinventing colors, so the menus feel like one coherent set. Pure helpers
## (StyleBoxFlat factories + small apply methods) — no Theme resource wrangling.

const PARCHMENT: Color = Color("#f3e0b0")      # panel fill
const PARCHMENT_DEEP: Color = Color("#e7cb8d")  # inset / alt fill
const SLOT: Color = Color("#f6ead0")            # item slot fill
const SLOT_SELECTED: Color = Color("#ffe9a8")   # highlighted slot
const BORDER: Color = Color("#86511f")          # thick outer border
const BORDER_LIGHT: Color = Color("#c8893f")    # inner bevel border
const INK: Color = Color("#4a3420")             # body text
const INK_SOFT: Color = Color("#7a5a36")        # secondary text
const HONEY: Color = Color("#e0a64b")           # accent / headings
const GOOD: Color = Color("#5f9150")            # affordable / allowed
const BAD: Color = Color("#b5563f")             # blocked / missing

## Main panel: parchment fill, thick warm border, rounded corners.
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

## Inset sub-panel (tooltip / info box).
static func inset_style(fill: Color = PARCHMENT_DEEP) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = BORDER_LIGHT
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	return style

## An inventory/build item slot; `selected` gives the warm highlight + thicker edge.
static func slot_style(selected: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = SLOT_SELECTED if selected else SLOT
	style.border_color = HONEY if selected else BORDER_LIGHT
	style.set_border_width_all(3 if selected else 2)
	style.set_corner_radius_all(5)
	return style

## Apply the cozy panel look to a Panel (or PanelContainer) node.
static func apply_panel(panel: Control, fill: Color = PARCHMENT) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", panel_style(fill))

## A heading label in honey, larger.
static func heading(text: String, size: int = 18) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", HONEY)
	return label

## Style a button warm (parchment with a honey hover).
static func apply_button(button: Button) -> void:
	if button == null:
		return
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", BORDER)
	button.add_theme_stylebox_override("normal", slot_style(false))
	button.add_theme_stylebox_override("hover", slot_style(true))
	button.add_theme_stylebox_override("pressed", slot_style(true))
