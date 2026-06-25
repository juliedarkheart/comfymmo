extends CanvasLayer

## Build menu (B while placement is active). A categorized, non-modal palette:
## category tabs, selected-piece info, item cards with costs/requirements, and
## clear controls for place/edit/move/rotate/delete/cancel.

var _get_all_ids: Callable = Callable()      # () -> Array of placeable ids
var _get_status: Callable = Callable()       # (id) -> {ok, reason}
var _do_select: Callable = Callable()        # (id) -> void
var _get_active: Callable = Callable()       # () -> active id

var _active_category: String = BuildCategories.FOUNDATIONS
var _compact: bool = false
var _category_buttons: Dictionary = {}
var _selected_info: Label = null

const SAFE_DOCK_RECT := Rect2(860, 204, 392, 410)

const CATEGORY_LABELS := {
	BuildCategories.FOUNDATIONS: "Found",
	BuildCategories.WALLS: "Walls",
	BuildCategories.DOORS_WINDOWS: "Doors",
	BuildCategories.ROOFS: "Roofs",
	BuildCategories.FENCES_GATES: "Fence",
	BuildCategories.STRUCTURES: "Struct",
	BuildCategories.CRAFTING: "Craft",
	BuildCategories.STORAGE: "Storage",
	BuildCategories.FARMING: "Farm",
	BuildCategories.PATHS: "Paths",
	BuildCategories.FURNITURE: "Furn",
	BuildCategories.DECOR: "Decor",
}

@onready var _panel: PanelContainer = $Panel
@onready var _category_row: HFlowContainer = $Panel/Rows/Categories
@onready var _item_list: VBoxContainer = $Panel/Rows/Scroll/Items
@onready var _help_label: Label = $Panel/Rows/Help

func setup(get_all_ids: Callable, get_status: Callable, do_select: Callable, get_active: Callable) -> void:
	_get_all_ids = get_all_ids
	_get_status = get_status
	_do_select = do_select
	_get_active = get_active

func _ready() -> void:
	visible = false
	_apply_safe_dock()
	CozyUITheme.apply_panel(_panel)
	_build_header()
	_build_selected_info()
	_build_category_buttons()
	_help_label.text = "Place: click/Enter/A | Edit: E | Rotate: Q/RB\nDelete: Del/Y | Cancel: Esc/B"
	CozyUITheme.apply_secondary_label(_help_label, 11)

func _apply_safe_dock() -> void:
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	_panel.offset_left = SAFE_DOCK_RECT.position.x
	_panel.offset_top = SAFE_DOCK_RECT.position.y
	_panel.offset_right = SAFE_DOCK_RECT.end.x
	_panel.offset_bottom = SAFE_DOCK_RECT.end.y

func open_panel() -> void:
	visible = true
	refresh()

func close_panel() -> void:
	visible = false

func is_open() -> bool:
	return visible

func toggle_panel() -> void:
	if visible:
		close_panel()
	else:
		open_panel()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("cancel_action"):
		close_panel()
		var viewport: Viewport = get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()

func _build_header() -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	$Panel/Rows.add_child(header)
	$Panel/Rows.move_child(header, 0)

	var title := Label.new()
	title.text = "Build Kit"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	CozyUITheme.apply_heading_label(title, 18)
	header.add_child(title)

	var compact_button := Button.new()
	compact_button.text = "Cards"
	compact_button.toggle_mode = true
	compact_button.toggled.connect(func(on: bool) -> void:
		_compact = on
		refresh())
	CozyUITheme.apply_button(compact_button)
	# Header buttons must fit their full label (the framed button adds ~32px of side
	# padding, which clipped "Cards"/"Close" to "Car"/"Clos" at the default min width).
	compact_button.clip_text = false
	compact_button.custom_minimum_size = Vector2(96, 32)
	header.add_child(compact_button)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(close_panel)
	CozyUITheme.apply_close_button(close_button)
	close_button.clip_text = false
	close_button.custom_minimum_size = Vector2(96, 32)
	header.add_child(close_button)

func _build_selected_info() -> void:
	_selected_info = Label.new()
	_selected_info.name = "SelectedInfo"
	_selected_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	CozyUITheme.apply_body_label(_selected_info, 12)
	$Panel/Rows.add_child(_selected_info)
	$Panel/Rows.move_child(_selected_info, 1)

func _build_category_buttons() -> void:
	for category in BuildCategories.ORDER:
		var button := Button.new()
		button.text = _category_label(category)
		button.tooltip_text = category
		button.set_meta("category_id", category)
		button.custom_minimum_size = Vector2(70, 28)
		button.toggle_mode = true
		button.pressed.connect(func() -> void:
			_active_category = category
			refresh())
		_category_row.add_child(button)
		_category_buttons[category] = button

func refresh() -> void:
	if not visible or not _get_all_ids.is_valid():
		return
	var active_id: String = String(_get_active.call()) if _get_active.is_valid() else ""
	_refresh_selected_info(active_id)
	for category in _category_buttons.keys():
		var is_active: bool = category == _active_category
		var button: Button = _category_buttons[category] as Button
		button.button_pressed = is_active
		CozyUITheme.apply_tab_button(button, is_active)
	for child in _item_list.get_children():
		child.queue_free()

	var all_ids: Array = _get_all_ids.call()
	var ids: Array = BuildCategories.ids_in(_active_category, all_ids)
	if ids.is_empty():
		var empty := Label.new()
		empty.text = "(nothing here yet — keep gathering and crafting!)"
		CozyUITheme.apply_secondary_label(empty, 13)
		_item_list.add_child(empty)
		return
	for id_variant in ids:
		_item_list.add_child(_build_card(String(id_variant), active_id))

func _refresh_selected_info(active_id: String) -> void:
	if _selected_info == null:
		return
	if active_id.is_empty() or not ContentRegistry.placeables().has(active_id):
		_selected_info.text = "Selected: none. Choose a piece below."
		return
	var entry: Dictionary = ContentRegistry.placeables().get(active_id, {}) as Dictionary
	var name_text: String = String(entry.get("display_name", active_id.capitalize()))
	var footprint: Vector2i = ContentRegistry.placeable_footprint(active_id)
	var cost: String = BuildCosts.cost_text(active_id)
	_selected_info.text = "Selected: %s | Cost: %s | Size: %dx%d" % [
		name_text,
		cost if not cost.is_empty() else "free",
		footprint.x,
		footprint.y,
	]

func _build_card(placeable_id: String, active_id: String) -> Control:
	var status: Dictionary = _get_status.call(placeable_id) if _get_status.is_valid() else {"ok": true, "reason": ""}
	var can_build: bool = bool(status.get("ok", true))
	var is_active: bool = placeable_id == active_id
	var entry: Dictionary = ContentRegistry.placeables().get(placeable_id, {}) as Dictionary
	var name_text: String = String(entry.get("display_name", placeable_id.capitalize()))

	var card := PanelContainer.new()
	card.name = "BuildItemCard_%s" % placeable_id
	CozyUITheme.apply_slot(card, is_active, not can_build)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)

	var info := Label.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	CozyUITheme.apply_body_label(info, 12)
	if _compact:
		info.text = "%s%s - %s" % ["> " if is_active else "", name_text, _short_meta(placeable_id, status, can_build)]
	else:
		info.text = "%s%s\n%s" % ["> " if is_active else "", name_text, _full_meta(placeable_id, status, can_build)]
	if not can_build:
		info.add_theme_color_override(
			"font_color",
			LimeZuUITheme.disabled_text_color() if LiveVisualPolicy.live_limezu_slice() else CozyUITheme.INK_SOFT
		)
	row.add_child(info)

	var select := Button.new()
	select.text = "On" if is_active else ("Locked" if not can_build else "Select")
	select.tooltip_text = String(status.get("reason", "")) if not can_build else name_text
	select.disabled = is_active or not can_build
	select.custom_minimum_size = Vector2(76, 28)
	select.pressed.connect(func() -> void:
		if _do_select.is_valid():
			_do_select.call(placeable_id)
		refresh())
	CozyUITheme.apply_button(select)
	row.add_child(select)
	return card

func _category_label(category: String) -> String:
	return String(CATEGORY_LABELS.get(category, category))

func _short_meta(placeable_id: String, status: Dictionary, can_build: bool) -> String:
	var cost: String = BuildCosts.cost_text(placeable_id)
	var bits: String = cost if not cost.is_empty() else "free"
	if not can_build:
		bits += " | unavailable: %s" % String(status.get("reason", ""))
	return bits

func _full_meta(placeable_id: String, status: Dictionary, can_build: bool) -> String:
	var footprint: Vector2i = ContentRegistry.placeable_footprint(placeable_id)
	var tool_id: String = ContentRegistry.placeable_required_tool(placeable_id)
	var cost: String = BuildCosts.cost_text(placeable_id)
	var parts: Array[String] = []
	parts.append("Cost: %s" % (cost if not cost.is_empty() else "free"))
	parts.append("Tool: %s" % ItemIds.display_name(tool_id))
	parts.append("Size: %dx%d" % [footprint.x, footprint.y])
	if PrefabInteriors.has_interior(placeable_id):
		parts.append("Interior: yes")
	elif ContentRegistry.placeable_category(placeable_id) == "structure":
		parts.append("Interior: coming later")
	if not can_build:
		parts.append("Unavailable: %s" % String(status.get("reason", "")))
	return " | ".join(parts)
