extends CanvasLayer

signal selected_tool_changed(selected_hotbar_index: int, selected_item_id: String, held_visual_id: String)
signal quickbar_assignments_changed(assignments: Array, selected_hotbar_index: int)

## Bottom-centre QUICKBAR: inventory-owned shortcut slots, not a hidden equipment
## system. Slots store item ids (or "" for empty), number keys select shortcuts,
## and the selected shortcut drives only the held visual.

const SLOT_COUNT := 9
const SLOT_SIZE := Vector2(58, 58)
const EMPTY_SLOT_ID := ""

const DEFAULT_ASSIGNMENTS: Array[String] = [
	ItemIds.TOOL_WORN_AXE, ItemIds.TOOL_WORN_PICKAXE, ItemIds.TOOL_WORN_HOE,
	ItemIds.TOOL_WATERING_CAN, ItemIds.TOOL_SIMPLE_HAMMER, ItemIds.TOOL_BASIC_SHOVEL,
	ContentIds.ITEM_PLACEHOLDER_SEED_PACKET, EMPTY_SLOT_ID, EMPTY_SLOT_ID,
]

const ITEM_GLYPHS := {
	ItemIds.TOOL_WORN_AXE: "Axe",
	ItemIds.TOOL_WORN_PICKAXE: "Pick",
	ItemIds.TOOL_WORN_HOE: "Hoe",
	ItemIds.TOOL_WATERING_CAN: "Water",
	ItemIds.TOOL_SIMPLE_HAMMER: "Build",
	ItemIds.TOOL_BASIC_SHOVEL: "Path",
	ResourceIds.MATERIAL_WOOD: "Wood",
	ResourceIds.MATERIAL_STONE: "Stn",
	ResourceIds.MATERIAL_FIBER: "Fib",
	ResourceIds.MATERIAL_CLAY: "Clay",
	ContentIds.ITEM_CARROT: "Car",
	ContentIds.ITEM_TURNIP: "Trn",
	ContentIds.ITEM_BERRY: "Ber",
	ContentIds.ITEM_PLACEHOLDER_SEED_PACKET: "Seed",
}

const TOOL_HINTS := {
	ItemIds.TOOL_WORN_AXE: "chop trees",
	ItemIds.TOOL_WORN_PICKAXE: "mine stone",
	ItemIds.TOOL_WORN_HOE: "till soil",
	ItemIds.TOOL_WATERING_CAN: "water crops",
	ItemIds.TOOL_SIMPLE_HAMMER: "place objects",
	ItemIds.TOOL_BASIC_SHOVEL: "dig clay, lay paths",
	ContentIds.ITEM_PLACEHOLDER_SEED_PACKET: "plant on tilled soil",
	ResourceIds.COMPONENT_SEED_PACKET: "plant on tilled soil",
}

const HELD_TOOL_VISUAL_IDS := {
	ItemIds.TOOL_WORN_AXE: "icon.tool_axe",
	ItemIds.TOOL_WATERING_CAN: "icon.tool_watering_can",
	ItemIds.TOOL_BASIC_SHOVEL: "icon.tool_shovel",
}

var _get_count: Callable = Callable()
var _slots: Array = []          # [{panel, icon, glyph, count, item_id}]
var _assignments: Array[String] = []
var _selected: int = 0
var _pending_assignment_item_id: String = ""

@onready var _rail: PanelContainer = $Wrap/Rail
@onready var _strip: HBoxContainer = $Wrap/Rail/Strip
@onready var _selected_name: Label = $Wrap/SelectedName

func _ready() -> void:
	_rail.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_rail.add_theme_stylebox_override("panel", LimeZuUITheme.hotbar_rail_style())
	_selected_name.add_theme_stylebox_override("normal", LimeZuUITheme.tooltip_panel_style())
	_selected_name.add_theme_color_override("font_color", LimeZuUITheme.title_text_color())
	_selected_name.add_theme_font_size_override("font_size", 13)
	_selected_name.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _assignments.is_empty():
		_assignments = default_assignments()
	_build_slots()

func setup(get_count: Callable, initial_assignments: Array = [], initial_selected_index: int = 0) -> void:
	_get_count = get_count
	set_quickbar_assignments(initial_assignments if not initial_assignments.is_empty() else default_assignments(), initial_selected_index, false)

static func default_assignments() -> Array[String]:
	var defaults: Array[String] = []
	for item_id in DEFAULT_ASSIGNMENTS:
		defaults.append(String(item_id))
	return defaults

static func normalize_assignments(raw_assignments: Array) -> Array[String]:
	var normalized: Array[String] = []
	for i in range(SLOT_COUNT):
		var item_id := ""
		if i < raw_assignments.size():
			item_id = String(raw_assignments[i]).strip_edges()
		if not item_id.is_empty() and not _is_quickbar_item(item_id):
			item_id = ""
		normalized.append(item_id)
	return normalized

static func _is_quickbar_item(item_id: String) -> bool:
	return item_id.is_empty() or ItemIds.is_storable(item_id) or ContentRegistry.items().has(item_id)

func _build_slots() -> void:
	for child in _strip.get_children():
		child.queue_free()
	_slots.clear()
	for i in range(SLOT_COUNT):
		var item_id: String = _assignments[i] if i < _assignments.size() else ""

		var panel := Panel.new()
		panel.custom_minimum_size = SLOT_SIZE
		panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		panel.mouse_filter = Control.MOUSE_FILTER_PASS
		panel.gui_input.connect(_on_slot_input.bind(i))

		var icon := TextureRect.new()
		LimeZuUITheme.apply_slot_icon_layout(icon, SLOT_SIZE.y)
		panel.add_child(icon)

		var glyph := Label.new()
		var inner: Rect2 = LimeZuUITheme.slot_inner_rect(SLOT_SIZE.y)
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		glyph.offset_left = inner.position.x
		glyph.offset_top = inner.position.y
		glyph.offset_right = -(SLOT_SIZE.x - inner.end.x)
		glyph.offset_bottom = -(SLOT_SIZE.y - inner.end.y)
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.add_theme_font_size_override("font_size", 12)
		glyph.add_theme_color_override("font_color", LimeZuUITheme.readable_text_color())
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(glyph)

		var num := Label.new()
		num.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 4)
		num.text = str(i + 1)
		num.add_theme_font_size_override("font_size", 10)
		num.add_theme_color_override("font_color", LimeZuUITheme.muted_text_color())
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(num)

		var count := Label.new()
		LimeZuUITheme.apply_slot_count_layout(count, SLOT_SIZE.y)
		panel.add_child(count)

		_strip.add_child(panel)
		_slots.append({"panel": panel, "icon": icon, "glyph": glyph, "count": count, "item_id": item_id})
	refresh()

func _on_slot_input(event: InputEvent, index: int) -> void:
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if not _pending_assignment_item_id.is_empty():
				assign_quickbar_slot(index, _pending_assignment_item_id)
			else:
				_select_or_unequip(index)
		MOUSE_BUTTON_RIGHT:
			clear_quickbar_slot(index)
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: int = (event as InputEventKey).keycode
	if key >= KEY_1 and key <= KEY_9:
		_select_or_unequip(key - KEY_1)
		get_viewport().set_input_as_handled()
	elif key == KEY_0:
		unequip()
		get_viewport().set_input_as_handled()

func begin_quickbar_assignment(item_id: String) -> bool:
	item_id = item_id.strip_edges()
	if item_id.is_empty() or not _is_quickbar_item(item_id):
		return false
	_pending_assignment_item_id = item_id
	_refresh_selected_name()
	return true

func clear_assignment_mode() -> void:
	_pending_assignment_item_id = ""
	_refresh_selected_name()

func assign_quickbar_slot(index: int, item_id: String) -> bool:
	if index < 0 or index >= SLOT_COUNT:
		return false
	item_id = item_id.strip_edges()
	if item_id.is_empty() or not _is_quickbar_item(item_id):
		return false
	_assignments[index] = item_id
	_pending_assignment_item_id = ""
	_selected = index
	_sync_slot_item_ids()
	refresh()
	_emit_quickbar_assignments_changed()
	return true

func clear_quickbar_slot(index: int) -> bool:
	if index < 0 or index >= SLOT_COUNT:
		return false
	_assignments[index] = ""
	if _selected == index:
		_selected = index
	_pending_assignment_item_id = ""
	_sync_slot_item_ids()
	refresh()
	_emit_quickbar_assignments_changed()
	return true

func set_quickbar_assignments(assignments: Array, selected_index: int = 0, emit_change: bool = false) -> void:
	_assignments = normalize_assignments(assignments)
	_selected = clampi(selected_index, -1, SLOT_COUNT - 1)
	_sync_slot_item_ids()
	refresh()
	if emit_change:
		_emit_quickbar_assignments_changed()

func quickbar_assignments() -> Array[String]:
	var copy: Array[String] = []
	for item_id in _assignments:
		copy.append(String(item_id))
	return copy

func select_hotbar_index(index: int) -> void:
	_select_or_unequip(index)

func unequip() -> void:
	if _selected == -1 and _pending_assignment_item_id.is_empty():
		return
	_selected = -1
	_pending_assignment_item_id = ""
	refresh()

func selected_hotbar_index() -> int:
	return _selected

func selected_item_id() -> String:
	if _slots.is_empty() or _selected < 0 or _selected >= _slots.size():
		return ""
	var slot: Dictionary = _slots[_selected]
	var item_id: String = String(slot["item_id"])
	if item_id.is_empty() or not _get_count.is_valid() or int(_get_count.call(item_id)) <= 0:
		return ""
	return item_id

func held_visual_id() -> String:
	var item_id := selected_item_id()
	if item_id.is_empty():
		return ""
	if LiveVisualPolicy.live_limezu_slice():
		var limezu_id: String = String(HELD_TOOL_VISUAL_IDS.get(item_id, ""))
		if not limezu_id.is_empty() and LimeZuArtRegistry.has_asset(limezu_id):
			return limezu_id
	return item_id

func _select_or_unequip(index: int) -> void:
	if index < 0 or index >= _slots.size():
		return
	_pending_assignment_item_id = ""
	if index == _selected:
		unequip()
		return
	_selected = index
	refresh()

func refresh() -> void:
	if _slots.is_empty():
		return
	for i in range(_slots.size()):
		var slot: Dictionary = _slots[i]
		var item_id: String = String(slot["item_id"])
		var owned: bool = not item_id.is_empty() and _get_count.is_valid() and int(_get_count.call(item_id)) > 0
		var selected: bool = (i == _selected)

		var panel: Panel = slot["panel"]
		panel.add_theme_stylebox_override("panel", LimeZuUITheme.slot_texture_style(selected))

		var icon: TextureRect = slot["icon"]
		var glyph: Label = slot["glyph"]
		var count: Label = slot["count"]
		var tex: Texture2D = _item_icon(item_id)
		if tex != null:
			icon.texture = tex
			icon.visible = true
			icon.modulate = Color(1, 1, 1, 1) if owned else Color(1, 1, 1, 0.38)
			glyph.visible = false
		elif not item_id.is_empty():
			icon.visible = false
			glyph.visible = true
			glyph.text = String(ITEM_GLYPHS.get(item_id, _item_label(item_id).substr(0, 3)))
			glyph.modulate = Color(1, 1, 1, 1) if owned else Color(1, 1, 1, 0.42)
		else:
			icon.visible = false
			glyph.visible = true
			glyph.text = "Empty"
			glyph.modulate = Color(1, 1, 1, 0.28)
		count.visible = owned and int(_get_count.call(item_id)) > 1
		count.text = _count_text(int(_get_count.call(item_id))) if count.visible else ""

	_refresh_selected_name()
	_emit_selected_tool_changed()

func _sync_slot_item_ids() -> void:
	for i in range(_slots.size()):
		var slot: Dictionary = _slots[i]
		slot["item_id"] = _assignments[i] if i < _assignments.size() else ""
		_slots[i] = slot

func _refresh_selected_name() -> void:
	if not _pending_assignment_item_id.is_empty():
		_selected_name.text = "Assign to hotbar: %s" % _item_summary(_pending_assignment_item_id)
		_selected_name.visible = true
		return
	var item_id: String = selected_item_id()
	if item_id.is_empty():
		_selected_name.text = "Hotbar: Empty Slot — hands empty"
		_selected_name.visible = true
		return
	_selected_name.text = "Hotbar: %s" % _item_summary(item_id)
	_selected_name.visible = true

func _emit_selected_tool_changed() -> void:
	selected_tool_changed.emit(_selected, selected_item_id(), held_visual_id())

func _emit_quickbar_assignments_changed() -> void:
	quickbar_assignments_changed.emit(quickbar_assignments(), _selected)

func _item_icon(item_id: String) -> Texture2D:
	return ObjectArtRegistry.icon_texture_for_item(item_id)

func _item_label(item_id: String) -> String:
	if ItemIds.is_storable(item_id):
		return ItemIds.display_name(item_id)
	var item: Dictionary = ContentRegistry.items().get(item_id, {}) as Dictionary
	if not item.is_empty():
		return String(item.get("display_name", item_id.capitalize()))
	return item_id.capitalize()

func _item_summary(item_id: String) -> String:
	var label := _item_label(item_id)
	var hint := _item_hint(item_id)
	if hint.is_empty():
		return label
	return "%s — %s" % [label, hint]

func _item_hint(item_id: String) -> String:
	return String(TOOL_HINTS.get(item_id, ""))

func _count_text(count: int) -> String:
	return "x%d" % count
