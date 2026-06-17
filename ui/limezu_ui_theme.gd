extends RefCounted
class_name LimeZuUITheme

## Clean, scalable LimeZu-flavoured UI styles for the live LimeZu visual mode.
##
## The LimeZu Modern UI art is small, non-square pixel art (e.g. the panel is 47x31,
## the button 29x11). Stretched as a StyleBoxTexture/NinePatch across a large HUD/menu
## it distorts badly (a ~3px button center blown up ~9x, warped borders, text spilling
## past the frame). Per the art direction, when the asset cannot 9-slice cleanly we use
## a clean StyleBoxFlat in LimeZu colours instead of distorted texture art. These
## factories are that fallback theme: warm dark-wood panels, amber borders, gold
## titles, cream text — readable over the bright LimeZu world, never stretched.

# Palette (warm wood + cream, distinct from the old Sprout parchment / old dark HUD).
const PANEL_FILL: Color = Color("#33291e")          # warm dark wood panel
const PANEL_BORDER: Color = Color("#9c7748")        # amber wood frame
const SLOT_FILL: Color = Color("#46372704")         # subtle inset (alpha handled below)
const SLOT_BASE: Color = Color("#473726")           # item slot fill
const SLOT_BORDER: Color = Color("#7d5c39")
const SLOT_SELECTED_FILL: Color = Color("#5b4631")
const SLOT_SELECTED_BORDER: Color = Color("#f0c75c")  # gold highlight
const SLOT_BLOCKED_FILL: Color = Color("#2c2620")
const BUTTON_FILL: Color = Color("#4a3826")
const BUTTON_HOVER_FILL: Color = Color("#5e4731")
const BUTTON_PRESSED_FILL: Color = Color("#382a1c")
const BUTTON_BORDER: Color = Color("#9c7748")
const TEXT_READABLE: Color = Color("#f3e7cf")        # body text (cream on dark wood)
const TEXT_TITLE: Color = Color("#f2c75c")           # headings (gold)
const TEXT_MUTED: Color = Color("#c9b896")           # secondary text
const BAD: Color = Color("#c46a52")                  # blocked / unavailable

static func readable_text_color() -> Color:
	return TEXT_READABLE

static func title_text_color() -> Color:
	return TEXT_TITLE

static func muted_text_color() -> Color:
	return TEXT_MUTED

## Base panel: warm dark wood, amber border, rounded, soft shadow.
static func panel_style(content_margin: int = 14, fill_alpha: float = 0.95) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PANEL_FILL.r, PANEL_FILL.g, PANEL_FILL.b, fill_alpha)
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(content_margin)
	style.shadow_color = Color(0, 0, 0, 0.30)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	return style

static func hud_panel_style() -> StyleBoxFlat:
	var style := panel_style(13, 0.95)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 11
	style.content_margin_bottom = 12
	return style

static func minimap_panel_style() -> StyleBoxFlat:
	return panel_style(8, 0.95)

static func inventory_panel_style() -> StyleBoxFlat:
	return panel_style(14, 0.96)

static func menu_panel_style() -> StyleBoxFlat:
	return panel_style(14, 0.96)

static func slot_style(selected: bool = false, blocked: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = SLOT_BLOCKED_FILL if blocked else (SLOT_SELECTED_FILL if selected else SLOT_BASE)
	style.border_color = BAD if blocked else (SLOT_SELECTED_BORDER if selected else SLOT_BORDER)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(6)
	return style

static func button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BUTTON_FILL
	style.border_color = BUTTON_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	# Generous horizontal padding so labels never clip.
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

static func button_hover_style() -> StyleBoxFlat:
	var style := button_style()
	style.bg_color = BUTTON_HOVER_FILL
	style.border_color = SLOT_SELECTED_BORDER
	return style

static func button_pressed_style() -> StyleBoxFlat:
	var style := button_style()
	style.bg_color = BUTTON_PRESSED_FILL
	return style

static func close_button_style() -> StyleBoxFlat:
	var style := button_style()
	style.content_margin_left = 10
	style.content_margin_right = 10
	return style

static func tab_style(selected: bool = false) -> StyleBoxFlat:
	var style := button_style()
	if selected:
		style.bg_color = SLOT_SELECTED_FILL
		style.border_color = SLOT_SELECTED_BORDER
	return style
