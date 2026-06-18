extends CanvasLayer

## Bottom-centre HOTBAR — cozy-survival / Stardew-INSPIRED layout (not copied), built from
## the LimeZu Modern UI slot art. A row of framed slots holds the starter tools; each slot
## shows a number key (1-9/0), the tool icon (LimeZu icon where mapped, else a short text
## glyph), and a dim state when the tool is not yet owned. One slot is "selected" (gold
## frame) and the held tool's name shows on a small framed label above the bar.
##
## Selection is purely presentational (the game checks tool OWNERSHIP, not an active slot),
## so number keys / clicks only move the highlight — no gameplay/selection system is added.
## Slot framing comes from CozyUITheme -> LimeZuUITheme.slot_texture_style (real 9-patch).

const SLOT_COUNT := 9
const SLOT_SIZE := Vector2(58, 58)

const TOOL_ORDER: Array[String] = [
	ItemIds.TOOL_WORN_AXE, ItemIds.TOOL_WORN_PICKAXE, ItemIds.TOOL_WORN_HOE,
	ItemIds.TOOL_WATERING_CAN, ItemIds.TOOL_SIMPLE_HAMMER, ItemIds.TOOL_BASIC_SHOVEL,
]
const TOOL_GLYPHS := {
	"worn_axe": "Axe", "worn_pickaxe": "Pick", "worn_hoe": "Hoe",
	"watering_can": "Can", "simple_hammer": "Hmr", "basic_shovel": "Shvl",
}
const TOOL_ICON_IDS := {
	"worn_axe": "icon.tool_axe",
	"watering_can": "icon.tool_watering_can",
	"basic_shovel": "icon.tool_shovel",
}

var _get_count: Callable = Callable()
var _slots: Array = []          # [{panel, icon, glyph, count, tool_id}]
var _selected: int = 0

@onready var _strip: HBoxContainer = $Wrap/Strip
@onready var _selected_name: Label = $Wrap/SelectedName

func _ready() -> void:
	_selected_name.add_theme_stylebox_override("normal", LimeZuUITheme.tooltip_panel_style())
	_selected_name.add_theme_color_override("font_color", LimeZuUITheme.title_text_color())
	_selected_name.add_theme_font_size_override("font_size", 13)
	_selected_name.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_slots()

func setup(get_count: Callable) -> void:
	_get_count = get_count
	refresh()

func _build_slots() -> void:
	for i in range(SLOT_COUNT):
		var tool_id: String = TOOL_ORDER[i] if i < TOOL_ORDER.size() else ""

		var panel := Panel.new()
		panel.custom_minimum_size = SLOT_SIZE
		panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		panel.mouse_filter = Control.MOUSE_FILTER_PASS
		panel.gui_input.connect(_on_slot_input.bind(i))

		# Centered icon (LimeZu icon where mapped).
		var icon := TextureRect.new()
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 9
		icon.offset_top = 9
		icon.offset_right = -9
		icon.offset_bottom = -9
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(icon)

		# Centered short text glyph (used only when no icon is available).
		var glyph := Label.new()
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.add_theme_font_size_override("font_size", 12)
		glyph.add_theme_color_override("font_color", LimeZuUITheme.readable_text_color())
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(glyph)

		# Number key (top-left).
		var num := Label.new()
		num.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 4)
		num.text = str((i + 1) % 10)
		num.add_theme_font_size_override("font_size", 10)
		num.add_theme_color_override("font_color", LimeZuUITheme.muted_text_color())
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(num)

		# Count (bottom-right) — hidden for single tools, shown for stackable items.
		var count := Label.new()
		count.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 4)
		count.add_theme_font_size_override("font_size", 11)
		count.add_theme_color_override("font_color", LimeZuUITheme.readable_text_color())
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(count)

		_strip.add_child(panel)
		_slots.append({"panel": panel, "icon": icon, "glyph": glyph, "count": count, "tool_id": tool_id})
	refresh()

func _on_slot_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select(index)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: int = (event as InputEventKey).keycode
	if key >= KEY_1 and key <= KEY_9:
		_select(key - KEY_1)

func _select(index: int) -> void:
	if index < 0 or index >= _slots.size() or index == _selected:
		return
	_selected = index
	refresh()

func refresh() -> void:
	if _slots.is_empty():
		return
	for i in range(_slots.size()):
		var slot: Dictionary = _slots[i]
		var tool_id: String = String(slot["tool_id"])
		var owned: bool = not tool_id.is_empty() and _get_count.is_valid() and int(_get_count.call(tool_id)) > 0
		var selected: bool = (i == _selected)

		var panel: Panel = slot["panel"]
		panel.add_theme_stylebox_override("panel", LimeZuUITheme.slot_texture_style(selected))

		var icon: TextureRect = slot["icon"]
		var glyph: Label = slot["glyph"]
		var tex: Texture2D = _tool_icon(tool_id)
		if tex != null:
			icon.texture = tex
			icon.visible = true
			icon.modulate = Color(1, 1, 1, 1) if owned else Color(1, 1, 1, 0.38)
			glyph.visible = false
		elif not tool_id.is_empty():
			icon.visible = false
			glyph.visible = true
			glyph.text = String(TOOL_GLYPHS.get(tool_id, "?"))
			glyph.modulate = Color(1, 1, 1, 1) if owned else Color(1, 1, 1, 0.42)
		else:
			icon.visible = false
			glyph.visible = false

	_refresh_selected_name()

func _refresh_selected_name() -> void:
	var slot: Dictionary = _slots[_selected]
	var tool_id: String = String(slot["tool_id"])
	if tool_id.is_empty():
		_selected_name.visible = false
		return
	_selected_name.text = ItemIds.display_name(tool_id)
	_selected_name.visible = true

func _tool_icon(tool_id: String) -> Texture2D:
	if tool_id.is_empty() or not LiveVisualPolicy.live_limezu_slice():
		return null
	var icon_id: String = String(TOOL_ICON_IDS.get(tool_id, ""))
	if icon_id.is_empty() or not LimeZuArtRegistry.has_asset(icon_id):
		return null
	return LimeZuArtRegistry.resolve_texture(icon_id)
