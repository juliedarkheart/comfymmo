extends CanvasLayer

## Full player inventory (I): identity header plus item categories. Snapshot
## driven like the crafting/progression panels, so the same panel serves offline
## and connected sessions. Esc, I, or the Close button hides it.

var _get_count: Callable = Callable()       # (item_id) -> int
var _get_identity: Callable = Callable()    # () -> Dictionary

var _identity_label: Label = null
var _body: VBoxContainer = null

@onready var _panel: PanelContainer = $Panel
@onready var _root_rows: VBoxContainer = $Panel/Rows
@onready var _scroll_body: VBoxContainer = $Panel/Rows/Scroll/Body

func setup(get_count: Callable, get_identity: Callable) -> void:
	_get_count = get_count
	_get_identity = get_identity

func _ready() -> void:
	visible = false
	_body = _scroll_body
	CozyUITheme.apply_panel(_panel)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	_root_rows.add_child(header)
	_root_rows.move_child(header, 0)

	var title := Label.new()
	title.text = "Inventory"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	CozyUITheme.apply_heading_label(title, 20)
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "Close (Esc)"
	close_button.pressed.connect(close_panel)
	CozyUITheme.apply_close_button(close_button)
	header.add_child(close_button)

	_identity_label = Label.new()
	_identity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	CozyUITheme.apply_body_label(_identity_label, 14)
	_root_rows.add_child(_identity_label)
	_root_rows.move_child(_identity_label, 1)

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

func refresh() -> void:
	if not visible:
		return
	_refresh_identity()
	for child in _body.get_children():
		child.queue_free()
	_add_category("Materials", ResourceIds.ALL_MATERIALS + [ContentIds.ITEM_CARROT, ContentIds.ITEM_TURNIP, ContentIds.ITEM_BERRY])
	_add_category("Components", ResourceIds.ALL_COMPONENTS)
	_add_category("Tools", ItemIds.ALL_TOOLS, true)
	_add_category("Tokens", ItemIds.ALL_QUEST_ITEMS, true)
	_add_category("Weapons", ItemIds.ALL_WEAPONS)
	_add_category("Wearables", ItemIds.ALL_WEARABLES)

func _refresh_identity() -> void:
	if _identity_label == null:
		return
	var identity: Dictionary = _get_identity.call() if _get_identity.is_valid() else {}
	var short_id: String = String(identity.get("profile_id", "")).substr(0, 10)
	_identity_label.text = "%s (@%s) | %s | Plot: %s\nProfile %s" % [
		String(identity.get("display_name", "Villager")),
		String(identity.get("username", "villager")),
		String(identity.get("mode", "Offline")),
		String(identity.get("plot_status", "-")),
		short_id,
	]

func _add_category(title: String, ids: Array, always_show: bool = false) -> void:
	var header := Label.new()
	header.text = title
	CozyUITheme.apply_heading_label(header, 15)
	_body.add_child(header)

	var entries: Array = []
	for id_variant in ids:
		var item_id: String = String(id_variant)
		var count: int = int(_get_count.call(item_id)) if _get_count.is_valid() else 0
		if count <= 0 and not always_show:
			continue
		entries.append({"item_id": item_id, "count": count, "owned": count > 0})

	if entries.is_empty():
		var none_line := Label.new()
		none_line.text = "None yet"
		CozyUITheme.apply_secondary_label(none_line, 13)
		_body.add_child(none_line)
		return

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	_body.add_child(grid)
	for entry_variant in entries:
		var entry: Dictionary = entry_variant as Dictionary
		grid.add_child(_build_inventory_slot(
			String(entry["item_id"]),
			int(entry["count"]),
			bool(entry["owned"])
		))

func _build_inventory_slot(item_id: String, count: int, owned: bool) -> Control:
	var slot := PanelContainer.new()
	slot.name = "InventorySlot_%s" % item_id
	slot.custom_minimum_size = Vector2(104, 78)
	CozyUITheme.apply_slot(slot, owned, not owned)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 2)
	rows.alignment = BoxContainer.ALIGNMENT_CENTER
	slot.add_child(rows)

	# Cozy registry icon when one resolves (never the missing-art X).
	var icon_path: String = ObjectArtRegistry.texture_path(item_id)
	if ObjectArtRegistry.source_of(icon_path) != "missing":
		var icon := TextureRect.new()
		icon.texture = load(icon_path) as Texture2D
		icon.custom_minimum_size = Vector2(32, 32)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.modulate.a = 1.0 if owned else 0.55
		rows.add_child(icon)

	var name_label := Label.new()
	name_label.text = _item_label(item_id)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	CozyUITheme.apply_body_label(name_label, 12)
	rows.add_child(name_label)

	var count_label := Label.new()
	count_label.text = "x%d" % count if owned else "Missing"
	CozyUITheme.apply_secondary_label(count_label, 11)
	rows.add_child(count_label)
	return slot

func _item_label(item_id: String) -> String:
	if ItemIds.is_storable(item_id):
		return ItemIds.display_name(item_id)
	var item: Dictionary = ContentRegistry.items().get(item_id, {}) as Dictionary
	if not item.is_empty():
		return String(item.get("display_name", item_id.capitalize()))
	return item_id.capitalize()
