extends CanvasLayer

## Build menu (opens with B / when placement starts). A categorized palette:
## category buttons across the top, then a scrollable list of item cards for the
## selected category. Each card shows name, cost, required tool, footprint, and
## interior status (prefab structures), greys out when unbuildable with the
## reason, and has a Select button that arms the placement ghost. Header "Build",
## a Close button, Esc to close, a compact toggle, and placement help text.
##
## Snapshot-driven: the controller supplies getters/callbacks, so the same menu
## works offline and connected. It never traps the player - movement keys keep
## working while it's open.

var _get_all_ids: Callable = Callable()      # () -> Array of placeable ids
var _get_status: Callable = Callable()       # (id) -> {ok, reason}
var _do_select: Callable = Callable()        # (id) -> void
var _get_active: Callable = Callable()       # () -> active id

var _active_category: String = BuildCategories.FOUNDATIONS
var _compact: bool = false
var _category_buttons: Dictionary = {}

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
	_build_header()
	_build_category_buttons()
	_help_label.text = "Click Select to arm a piece, then click in the world to place it (grid-snapped). Tab cycles | Enter places | E edit/move/remove | Esc closes."

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
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close_panel()
		var viewport: Viewport = get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()

func _build_header() -> void:
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	$Panel/Rows.add_child(header)
	$Panel/Rows.move_child(header, 0)

	var title: Label = Label.new()
	title.text = "Build"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#f8de9a"))
	header.add_child(title)

	var compact_button: Button = Button.new()
	compact_button.text = "Compact"
	compact_button.toggle_mode = true
	compact_button.toggled.connect(func(on: bool) -> void:
		_compact = on
		refresh())
	header.add_child(compact_button)

	var close_button: Button = Button.new()
	close_button.text = "Close (Esc)"
	close_button.pressed.connect(close_panel)
	header.add_child(close_button)

func _build_category_buttons() -> void:
	for category in BuildCategories.ORDER:
		var button: Button = Button.new()
		button.text = category
		button.toggle_mode = true
		button.pressed.connect(func() -> void:
			_active_category = category
			refresh())
		_category_row.add_child(button)
		_category_buttons[category] = button

func refresh() -> void:
	if not visible or not _get_all_ids.is_valid():
		return
	for category in _category_buttons.keys():
		(_category_buttons[category] as Button).button_pressed = (category == _active_category)
	for child in _item_list.get_children():
		child.queue_free()

	var all_ids: Array = _get_all_ids.call()
	var ids: Array = BuildCategories.ids_in(_active_category, all_ids)
	var active_id: String = String(_get_active.call()) if _get_active.is_valid() else ""
	if ids.is_empty():
		var empty: Label = Label.new()
		empty.text = "  (no pieces in this category yet)"
		empty.add_theme_color_override("font_color", Color(0.9, 0.86, 0.78, 0.5))
		_item_list.add_child(empty)
		return
	for id_variant in ids:
		_item_list.add_child(_build_card(String(id_variant), active_id))

func _build_card(placeable_id: String, active_id: String) -> Control:
	var status: Dictionary = _get_status.call(placeable_id) if _get_status.is_valid() else {"ok": true, "reason": ""}
	var can_build: bool = bool(status.get("ok", true))
	var is_active: bool = placeable_id == active_id
	var entry: Dictionary = ContentRegistry.placeables().get(placeable_id, {}) as Dictionary
	var name_text: String = String(entry.get("display_name", placeable_id.capitalize()))

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var info: Label = Label.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 14)
	if _compact:
		info.text = "%s%s - %s" % ["> " if is_active else "", name_text, _short_meta(placeable_id, status, can_build)]
	else:
		info.text = "%s%s\n   %s" % ["> " if is_active else "", name_text, _full_meta(placeable_id, status, can_build)]
	info.add_theme_color_override("font_color",
		Color("#f8de9a") if is_active else (Color("#f5f0e6") if can_build else Color(0.96, 0.93, 0.85, 0.5)))
	row.add_child(info)

	var select: Button = Button.new()
	select.text = "Selected" if is_active else "Select"
	select.disabled = is_active
	select.custom_minimum_size = Vector2(76, 0)
	select.pressed.connect(func() -> void:
		if _do_select.is_valid():
			_do_select.call(placeable_id)
		refresh())
	row.add_child(select)
	return row

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
		parts.append("Interior: yes (enter via door)")
	elif ContentRegistry.placeable_category(placeable_id) == "structure":
		parts.append("Interior: coming later")
	if not can_build:
		parts.append("Unavailable: %s" % String(status.get("reason", "")))
	return " | ".join(parts)
