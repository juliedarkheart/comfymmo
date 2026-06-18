extends RefCounted
class_name LimeZuUITheme

## Asset-backed LimeZu / Modern UI theme contract.
##
## DIRECTION: Stardew Valley / Minecraft / cozy-survival INSPIRED *layout* (bottom hotbar,
## grid inventory, framed panels, dialogue boxes, tabs, tooltips). The ART is the LimeZu
## Modern UI kit — never copied from those games. Panels/slots/buttons render the real
## Modern UI frame art as **9-patch StyleBoxTexture** with per-id texture margins MEASURED
## from the sheet (connected-component + border scan) and sliced x2 NEAREST
## (tools/art/limezu_slice_spike_assets.py). Corners stay crisp; only the flat edges/centre
## stretch -> no distortion. A flat StyleBoxFlat in LimeZu tan is used ONLY as a fallback
## interior when a texture id is missing (clean checkout / unsliced).
##
## The real Modern UI panels are LIGHT TAN parchment, so all text is DARK INK (high
## contrast on tan), like Stardew's menus — NOT cream-on-dark. The flat fallback palette is
## also light tan so the dark text stays readable whether textured or fallback.
##
## API: the *_texture_style() methods return TRUE 9-patch art (or flat fallback); the plain
## *_style() methods are the flat fallbacks; *_text_color() are the ink colours. New
## hotbar_*/dialogue_/tooltip_/text_input_/option_/tab_selected_ methods support the
## Stardew-style layout. is_textured() reports whether real art is live (used by validation).

# --- Logical UI ids (resolved through LimeZuArtRegistry from the local manifest) ---
const ID_PANEL := "ui.panel"
const ID_INVENTORY_PANEL := "ui.inventory_panel"
const ID_DIALOGUE := "ui.dialogue"
const ID_TOOLTIP := "ui.tooltip"
const ID_SLOT := "ui.slot"
const ID_SLOT_SELECTED := "ui.slot_selected"
const ID_BUTTON := "ui.button"
const ID_BUTTON_HOVER := "ui.button_hover"
const ID_BUTTON_PRESSED := "ui.button_pressed"
const ID_TAB := "ui.tab"
const ID_CLOSE := "ui.close"
const ID_CLOSE_HOVER := "ui.close_hover"
const ID_TEXT_INPUT := "ui.text_input"

# --- Per-id 9-slice texture margins [left, top, right, bottom] (measured border * 2; the
# slices are upscaled x2). These are the fix for the previous distortion: corners now match
# the real frame border so they never stretch. ---
const TEX_MARGIN := {
	ID_PANEL: [16, 14, 14, 10],
	ID_INVENTORY_PANEL: [16, 14, 14, 10],
	ID_DIALOGUE: [16, 14, 14, 10],
	ID_TOOLTIP: [16, 14, 14, 10],
	ID_SLOT: [10, 12, 10, 10],
	ID_SLOT_SELECTED: [10, 12, 10, 10],
	ID_BUTTON: [8, 8, 8, 8],
	ID_BUTTON_HOVER: [8, 8, 8, 8],
	ID_BUTTON_PRESSED: [8, 8, 8, 8],
	ID_TAB: [8, 8, 8, 8],
	ID_CLOSE: [4, 4, 4, 6],
	ID_CLOSE_HOVER: [4, 4, 4, 6],
	ID_TEXT_INPUT: [16, 14, 14, 6],
}

# --- Flat fallback palette: LimeZu light-tan parchment (matches the textured art) ---
const PANEL_FILL: Color = Color("#cdb78d")          # tan parchment (ui.panel centre)
const PANEL_BORDER: Color = Color("#86592f")        # warm wood frame
const SLOT_FILL: Color = Color("#c3ac90")
const SLOT_BASE: Color = Color("#c3ac90")           # item slot fill
const SLOT_BORDER: Color = Color("#7d5c39")
const SLOT_SELECTED_FILL: Color = Color("#e6c873")
const SLOT_SELECTED_BORDER: Color = Color("#f0c75c")  # gold highlight
const SLOT_BLOCKED_FILL: Color = Color("#b4a589")
const BUTTON_FILL: Color = Color("#d2bd95")
const BUTTON_HOVER_FILL: Color = Color("#e3cfa3")
const BUTTON_PRESSED_FILL: Color = Color("#bda473")
const BUTTON_BORDER: Color = Color("#86592f")

# --- Text palette: dark ink on tan (Stardew-style, AA contrast) ---
const TEXT_READABLE: Color = Color("#2a1d12")       # body text
const TEXT_TITLE: Color = Color("#3c2410")          # headings (deep warm brown)
const TEXT_MUTED: Color = Color("#6b5a44")          # secondary / hints
const TEXT_BUTTON: Color = Color("#2a1d12")         # button label (dark ink on tan button)
const TEXT_BUTTON_HOVER: Color = Color("#5a3a1e")   # button label on hover
const TEXT_DISABLED: Color = Color("#9a8a70")       # unavailable
const BAD: Color = Color("#a3402a")                 # warning / danger / blocked (dark red)

# Selection / state modulates multiplied over the slot/tab texture so state reads clearly.
const SELECTED_MODULATE := Color(1.18, 1.06, 0.66)
const HOVER_MODULATE := Color(1.12, 1.08, 0.92)
const PRESSED_MODULATE := Color(0.86, 0.82, 0.74)
const BLOCKED_MODULATE := Color(0.82, 0.78, 0.74)

# ---------------------------------------------------------------------------
# Text colours
# ---------------------------------------------------------------------------
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

static func warning_text_color() -> Color:
	return BAD

# ---------------------------------------------------------------------------
# Texture resolution + builder
# ---------------------------------------------------------------------------
## True when the live LimeZu UI textures are available, so the *_texture_style() methods
## return real 9-patch art rather than the flat fallback. Used by callers + validation.
static func is_textured() -> bool:
	return LiveVisualPolicy.live_limezu_slice() and LimeZuArtRegistry.has_asset(ID_PANEL)

static func texture_margin_for(ui_id: String) -> Array:
	return TEX_MARGIN.get(ui_id, [8, 8, 8, 8])

## Build a 9-patch StyleBoxTexture from a Modern UI frame id with its measured per-side
## margins. Returns null when the texture is unavailable so the caller uses a flat fallback.
static func _nine(ui_id: String, content: Array, modulate: Color = Color.WHITE) -> StyleBoxTexture:
	if not LiveVisualPolicy.live_limezu_slice() or not LimeZuArtRegistry.has_asset(ui_id):
		return null
	var tex: Texture2D = LimeZuArtRegistry.resolve_texture(ui_id)
	if tex == null:
		return null
	var m: Array = texture_margin_for(ui_id)
	var box := StyleBoxTexture.new()
	box.texture = tex
	box.texture_margin_left = float(m[0])
	box.texture_margin_top = float(m[1])
	box.texture_margin_right = float(m[2])
	box.texture_margin_bottom = float(m[3])
	box.content_margin_left = float(content[0])
	box.content_margin_top = float(content[1])
	box.content_margin_right = float(content[2])
	box.content_margin_bottom = float(content[3])
	if modulate != Color.WHITE:
		box.modulate_color = modulate
	return box

## Back-compat: build a 9-patch with a uniform texture margin unless the id has measured
## per-side margins, in which case those win (so old callers still get correct frames).
static func texture_stylebox(logical_id: String, texture_margin: int, content_margin: int) -> StyleBoxTexture:
	if not LiveVisualPolicy.live_limezu_slice() or not LimeZuArtRegistry.has_asset(logical_id):
		return null
	var tex: Texture2D = LimeZuArtRegistry.resolve_texture(logical_id)
	if tex == null:
		return null
	var box := StyleBoxTexture.new()
	box.texture = tex
	if TEX_MARGIN.has(logical_id):
		var m: Array = TEX_MARGIN[logical_id]
		box.texture_margin_left = float(m[0])
		box.texture_margin_top = float(m[1])
		box.texture_margin_right = float(m[2])
		box.texture_margin_bottom = float(m[3])
	else:
		box.set_texture_margin_all(float(texture_margin))
	box.set_content_margin_all(float(content_margin))
	return box

# ---------------------------------------------------------------------------
# Flat fallbacks (light tan + dark ink, used when no texture id resolves)
# ---------------------------------------------------------------------------
static func _flat(fill: Color, border: Color, border_w: int, radius: int, content: Array) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = float(content[0])
	sb.content_margin_top = float(content[1])
	sb.content_margin_right = float(content[2])
	sb.content_margin_bottom = float(content[3])
	return sb

static func panel_style(content_margin: int = 14, _fill_alpha: float = 1.0) -> StyleBoxFlat:
	var cm := maxi(content_margin, 12)
	return _flat(PANEL_FILL, PANEL_BORDER, 3, 8, [cm, cm, cm, cm])

static func hud_panel_style() -> StyleBoxFlat:
	return _flat(PANEL_FILL, PANEL_BORDER, 3, 8, [16, 12, 16, 13])

static func minimap_panel_style() -> StyleBoxFlat:
	return _flat(PANEL_FILL, PANEL_BORDER, 3, 8, [10, 9, 10, 9])

static func inventory_panel_style() -> StyleBoxFlat:
	return _flat(PANEL_FILL, PANEL_BORDER, 3, 8, [20, 18, 20, 18])

static func menu_panel_style() -> StyleBoxFlat:
	return _flat(PANEL_FILL, PANEL_BORDER, 3, 8, [18, 16, 18, 16])

static func slot_style(selected: bool = false, blocked: bool = false) -> StyleBoxFlat:
	var fill: Color = SLOT_BLOCKED_FILL if blocked else (SLOT_SELECTED_FILL if selected else SLOT_BASE)
	var border: Color = BAD if blocked else (SLOT_SELECTED_BORDER if selected else SLOT_BORDER)
	return _flat(fill, border, 3 if selected else 2, 5, [6, 8, 6, 6])

# ---------------------------------------------------------------------------
# Slot icon layout — center an item/tool icon inside the slot frame's USABLE INNER
# CAVITY (not the full texture rect). The slot frame's border is uneven (top is thicker:
# TEX_MARGIN[ui.slot] = [10,12,10,10]), so a full-rect-centered icon reads as off-centre
# and large icons overflow the wood. These helpers inset to the cavity and scale-to-fit.
# ---------------------------------------------------------------------------
## The usable inner rect of a slot of the given square size, inset by the frame's measured
## per-side border so an icon sits inside the cavity (honours the uneven top border).
static func slot_inner_rect(slot_size: float) -> Rect2:
	var m: Array = TEX_MARGIN.get(ID_SLOT, [10, 12, 10, 10])
	return Rect2(float(m[0]), float(m[1]), maxf(slot_size - float(m[0]) - float(m[2]), 1.0), maxf(slot_size - float(m[1]) - float(m[3]), 1.0))

## Lay out an item icon inside a slot Panel: fill the inner cavity, scale-to-fit preserving
## aspect, centred, NEAREST. EXPAND_IGNORE_SIZE makes every icon (16/32/48px native) render
## at a consistent centred size instead of native-size top-left (the off-centre bug).
static func apply_slot_icon_layout(icon: TextureRect, slot_size: float = 56.0) -> void:
	var m: Array = TEX_MARGIN.get(ID_SLOT, [10, 12, 10, 10])
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = float(m[0])
	icon.offset_top = float(m[1])
	icon.offset_right = -float(m[2])
	icon.offset_bottom = -float(m[3])
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

## Lay out a count/qty label in the slot's bottom-right corner, inside the cavity, with a
## soft shadow so it stays readable over any icon.
static func apply_slot_count_layout(label: Label, slot_size: float = 56.0) -> void:
	var m: Array = TEX_MARGIN.get(ID_SLOT, [10, 12, 10, 10])
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, int(m[2]) + 1)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", TEXT_READABLE)
	label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.55))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

static func button_style() -> StyleBoxFlat:
	return _flat(BUTTON_FILL, BUTTON_BORDER, 2, 6, [16, 8, 16, 10])

static func button_hover_style() -> StyleBoxFlat:
	return _flat(BUTTON_HOVER_FILL, SLOT_SELECTED_BORDER, 2, 6, [16, 8, 16, 10])

static func button_pressed_style() -> StyleBoxFlat:
	return _flat(BUTTON_PRESSED_FILL, BUTTON_BORDER, 2, 6, [16, 8, 16, 10])

static func close_button_style() -> StyleBoxFlat:
	return _flat(BUTTON_FILL, BUTTON_BORDER, 2, 6, [10, 6, 10, 8])

static func tab_style(selected: bool = false) -> StyleBoxFlat:
	if selected:
		return _flat(SLOT_SELECTED_FILL, SLOT_SELECTED_BORDER, 2, 6, [16, 8, 16, 8])
	return _flat(BUTTON_FILL, BUTTON_BORDER, 2, 6, [16, 8, 16, 8])

# ---------------------------------------------------------------------------
# Texture-backed panels (return real 9-patch art, else flat fallback)
# ---------------------------------------------------------------------------
static func panel_texture_style(content_margin: int = 14, inventory: bool = false) -> StyleBox:
	var logical_id: String = ID_INVENTORY_PANEL if inventory else ID_PANEL
	var cm := maxi(content_margin, 18)
	var sb := _nine(logical_id, [cm + 2, cm, cm + 2, cm])
	return sb if sb != null else panel_style(cm)

static func hud_panel_texture_style() -> StyleBox:
	var sb := _nine(ID_PANEL, [18, 13, 18, 13])
	return sb if sb != null else hud_panel_style()

static func compact_hud_panel_style() -> StyleBox:
	return hud_panel_texture_style()

static func minimap_panel_texture_style() -> StyleBox:
	var sb := _nine(ID_PANEL, [12, 10, 12, 10])
	return sb if sb != null else minimap_panel_style()

static func dialogue_panel_style() -> StyleBox:
	var sb := _nine(ID_DIALOGUE, [22, 16, 22, 16])
	return sb if sb != null else menu_panel_style()

static func tooltip_panel_style() -> StyleBox:
	var sb := _nine(ID_TOOLTIP, [14, 10, 14, 10])
	return sb if sb != null else _flat(PANEL_FILL, PANEL_BORDER, 2, 6, [14, 10, 14, 10])

# ---------------------------------------------------------------------------
# Texture-backed slots / buttons / tabs / close / inputs
# ---------------------------------------------------------------------------
static func slot_texture_style(selected: bool = false) -> StyleBox:
	if selected:
		var sbs := _nine(ID_SLOT_SELECTED, [6, 8, 6, 6], SELECTED_MODULATE)
		return sbs if sbs != null else slot_style(true)
	var sb := _nine(ID_SLOT, [6, 8, 6, 6])
	return sb if sb != null else slot_style(false)

static func slot_blocked_texture_style() -> StyleBox:
	var sb := _nine(ID_SLOT, [6, 8, 6, 6], BLOCKED_MODULATE)
	return sb if sb != null else slot_style(false, true)

static func inventory_slot_style() -> StyleBox:
	return slot_texture_style(false)

static func inventory_slot_selected_style() -> StyleBox:
	return slot_texture_style(true)

static func hotbar_slot_style() -> StyleBox:
	return slot_texture_style(false)

static func hotbar_slot_selected_style() -> StyleBox:
	return slot_texture_style(true)

static func hotbar_panel_style() -> StyleBox:
	# Slots carry their own frames; the strip backing is empty so the hotbar floats
	# (Stardew-style) rather than sitting in a second box.
	return StyleBoxEmpty.new()

## A framed rail behind the hotbar slot row so the slots read as one cohesive bottom HUD
## element instead of a line of loose buttons. Uses the real Modern UI panel 9-patch with
## tight margins so the slots sit snugly inside the frame.
static func hotbar_rail_style() -> StyleBox:
	var sb := _nine(ID_PANEL, [10, 8, 10, 8])
	return sb if sb != null else _flat(PANEL_FILL, PANEL_BORDER, 3, 8, [10, 8, 10, 8])

## A framed square portrait holder for dialogue/nameplate (real slot frame, tight margins).
## The portrait texture itself comes from GeneratorCharacterRegistry; this is just the frame.
static func portrait_frame_style() -> StyleBox:
	var sb := _nine(ID_SLOT, [4, 4, 4, 4])
	return sb if sb != null else _flat(SLOT_FILL, SLOT_BORDER, 2, 5, [4, 4, 4, 4])

static func button_texture_style(hovered: bool = false) -> StyleBox:
	if hovered:
		var sbh := _nine(ID_BUTTON_HOVER, [16, 8, 16, 10], HOVER_MODULATE)
		return sbh if sbh != null else button_hover_style()
	var sb := _nine(ID_BUTTON, [16, 8, 16, 10])
	return sb if sb != null else button_style()

static func button_pressed_texture_style() -> StyleBox:
	var sb := _nine(ID_BUTTON_PRESSED, [16, 8, 16, 10], PRESSED_MODULATE)
	return sb if sb != null else button_pressed_style()

static func button_disabled_style() -> StyleBox:
	var sb := _nine(ID_BUTTON, [16, 8, 16, 10], BLOCKED_MODULATE)
	return sb if sb != null else _flat(SLOT_BLOCKED_FILL, SLOT_BORDER, 2, 6, [16, 8, 16, 10])

static func close_texture_style(hovered: bool = false) -> StyleBox:
	var logical_id: String = ID_CLOSE_HOVER if hovered else ID_CLOSE
	var modulate: Color = HOVER_MODULATE if hovered else Color.WHITE
	var sb := _nine(logical_id, [10, 6, 10, 8], modulate)
	return sb if sb != null else close_button_style()

static func tab_texture_style(selected: bool = false) -> StyleBox:
	var modulate: Color = SELECTED_MODULATE if selected else Color(0.92, 0.88, 0.82)
	var sb := _nine(ID_TAB, [16, 8, 16, 8], modulate)
	return sb if sb != null else tab_style(selected)

static func tab_selected_style() -> StyleBox:
	return tab_texture_style(true)

static func text_input_style() -> StyleBox:
	var sb := _nine(ID_TEXT_INPUT, [12, 6, 12, 8])
	return sb if sb != null else _flat(Color("#d8c8a4"), PANEL_BORDER, 2, 5, [12, 6, 12, 8])

static func option_button_style() -> StyleBox:
	return button_texture_style(false)
