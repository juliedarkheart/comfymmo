extends RefCounted
class_name LimeZuUITheme

## Clean, scalable LimeZu-flavoured UI styles for the live LimeZu visual mode.
##
## The LimeZu Modern UI art is small, non-square pixel art (e.g. the panel is 47x31,
## the button 29x11). The live UI now keeps panels/buttons compact and uses reviewed
## nine-slice margins so those textures remain visible instead of falling back to
## the old code-drawn prototype shell. Flat factories remain as safe fallbacks when
## a licensed UI texture is absent.

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
const TEXT_READABLE: Color = Color("#3f2d22")        # body text (dark ink on UI parchment)
const TEXT_TITLE: Color = Color("#6b3526")           # headings (warm ink)
const TEXT_MUTED: Color = Color("#7a6652")           # secondary text
const TEXT_BUTTON: Color = Color("#f3e7cf")          # button text (cream on dark button art)
const TEXT_BUTTON_HOVER: Color = Color("#f2c75c")
const TEXT_DISABLED: Color = Color("#b99a72")        # disabled text on dark unavailable slots
const BAD: Color = Color("#c46a52")                  # blocked / unavailable

static func readable_text_color() -> Color:
	return TEXT_READABLE

static func title_text_color() -> Color:
	return TEXT_TITLE

static func muted_text_color() -> Color:
	return TEXT_MUTED

static func button_text_color() -> Color:
	return TEXT_BUTTON

static func button_hover_text_color() -> Color:
	return TEXT_BUTTON_HOVER

static func disabled_text_color() -> Color:
	return TEXT_DISABLED

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

static func texture_stylebox(logical_id: String, texture_margin: int, content_margin: int) -> StyleBoxTexture:
	if not LiveVisualPolicy.live_limezu_slice() or not LimeZuArtRegistry.has_asset(logical_id):
		return null
	var tex: Texture2D = LimeZuArtRegistry.resolve_texture(logical_id)
	if tex == null:
		return null
	var box := StyleBoxTexture.new()
	box.texture = tex
	box.set_texture_margin_all(texture_margin)
	box.set_content_margin_all(content_margin)
	return box

static func panel_texture_style(content_margin: int = 14, inventory: bool = false) -> StyleBox:
	var logical_id := "ui.inventory_panel" if inventory else "ui.panel"
	if not LiveVisualPolicy.live_limezu_slice() or not LimeZuArtRegistry.has_asset(logical_id):
		return panel_style(content_margin)
	var tex: Texture2D = LimeZuArtRegistry.resolve_texture(logical_id)
	if tex == null:
		return panel_style(content_margin)
	var box := StyleBoxTexture.new()
	box.texture = tex
	# The slice includes transparent padding before the visible posts. Capture the
	# full side-post area in the border margins so it does not stretch through center.
	box.texture_margin_left = 15
	box.texture_margin_right = 15
	box.texture_margin_top = 7
	box.texture_margin_bottom = 6
	box.set_content_margin_all(maxi(content_margin, 18))
	return box

static func hud_panel_texture_style() -> StyleBox:
	return panel_texture_style(14)

static func slot_texture_style(selected: bool = false) -> StyleBox:
	var logical_id: String = "ui.slot_selected" if selected else "ui.slot"
	var margin: int = 9 if selected else 8
	var textured: StyleBoxTexture = texture_stylebox(logical_id, margin, 6)
	return textured if textured != null else slot_style(selected)

static func button_texture_style(hovered: bool = false) -> StyleBox:
	var logical_id: String = "ui.button_hover" if hovered else "ui.button"
	var textured: StyleBoxTexture = texture_stylebox(logical_id, 5, 7)
	return textured if textured != null else (button_hover_style() if hovered else button_style())

static func close_texture_style(hovered: bool = false) -> StyleBox:
	var logical_id: String = "ui.close_hover" if hovered else "ui.close"
	var textured: StyleBoxTexture = texture_stylebox(logical_id, 5, 7)
	return textured if textured != null else (button_hover_style() if hovered else close_button_style())

static func tab_texture_style(selected: bool = false) -> StyleBox:
	var textured: StyleBoxTexture = texture_stylebox("ui.tab", 5, 7)
	return textured if textured != null else tab_style(selected)
