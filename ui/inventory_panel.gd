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
	CozyUITheme.apply_inventory_panel(_panel)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	_root_rows.add_child(header)
	_root_rows.move_child(header, 0)

	var title := Label.new()
	title.text = "Inventory"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	CozyUITheme.apply_heading_label(title, 18)
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(close_panel)
	CozyUITheme.apply_close_button(close_button)
	header.add_child(close_button)

	# One compact status line (no verbose profile id / duplicated name).
	_identity_label = Label.new()
	_identity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	CozyUITheme.apply_secondary_label(_identity_label, 12)
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
	# Owned items only, grouped; empty categories are skipped entirely (no header, no
	# "None yet" filler) so the window stays compact instead of a wall of blanks.
	var shown: int = 0
	shown += _add_category("Materials", ResourceIds.ALL_MATERIALS + [ContentIds.ITEM_CARROT, ContentIds.ITEM_TURNIP, ContentIds.ITEM_BERRY])
	shown += _add_category("Components", ResourceIds.ALL_COMPONENTS)
	shown += _add_category("Tools", ItemIds.ALL_TOOLS)
	shown += _add_category("Tokens", ItemIds.ALL_QUEST_ITEMS)
	shown += _add_category("Weapons", ItemIds.ALL_WEAPONS)
	shown += _add_category("Wearables", ItemIds.ALL_WEARABLES)
	if shown == 0:
		var empty := Label.new()
		empty.text = "Nothing yet - gather materials (F) and craft tools (K)."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		CozyUITheme.apply_secondary_label(empty, 13)
		_body.add_child(empty)

func _refresh_identity() -> void:
	if _identity_label == null:
		return
	var identity: Dictionary = _get_identity.call() if _get_identity.is_valid() else {}
	_identity_label.text = "@%s | %s | %s" % [
		String(identity.get("username", "villager")),
		String(identity.get("mode", "Offline")),
		String(identity.get("plot_status", "-")),
	]

## Adds a category section for the OWNED items in `ids`. Returns how many slots it
## added (0 = nothing owned, section skipped) so refresh() can show an empty state.
func _add_category(title: String, ids: Array) -> int:
	var entries: Array = []
	for id_variant in ids:
		var item_id: String = String(id_variant)
		var count: int = int(_get_count.call(item_id)) if _get_count.is_valid() else 0
		if count <= 0:
			continue
		entries.append({"item_id": item_id, "count": count})
	if entries.is_empty():
		return 0

	var header := Label.new()
	header.text = title
	CozyUITheme.apply_heading_label(header, 14)
	_body.add_child(header)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 4)
	_body.add_child(grid)
	for entry_variant in entries:
		var entry: Dictionary = entry_variant as Dictionary
		grid.add_child(_build_inventory_slot(String(entry["item_id"]), int(entry["count"])))
	return entries.size()

## Compact item cell: a LimeZu-compatible square slot (centered icon + count) with the
## item name on a tidy line beneath, so icons stay aligned and labels never overlap.
func _build_inventory_slot(item_id: String, count: int) -> Control:
	var cell := VBoxContainer.new()
	cell.custom_minimum_size = Vector2(94, 0)
	cell.add_theme_constant_override("separation", 1)

	var slot := PanelContainer.new()
	slot.name = "InventorySlot_%s" % item_id
	slot.custom_minimum_size = Vector2(88, 48)
	CozyUITheme.apply_slot(slot, false, false)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 0)
	slot.add_child(stack)

	# LimeZu live icons where mapped; otherwise the existing registry fallback.
	var limezu_icon: Texture2D = _limezu_icon_for_item(item_id)
	if limezu_icon != null:
		var icon := TextureRect.new()
		icon.texture = limezu_icon
		icon.custom_minimum_size = Vector2(32, 32)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		stack.add_child(icon)
	else:
		var icon_path: String = ObjectArtRegistry.texture_path(item_id)
		if ObjectArtRegistry.source_of(icon_path) != "missing":
			var icon := TextureRect.new()
			icon.texture = load(icon_path) as Texture2D
			icon.custom_minimum_size = Vector2(32, 32)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			stack.add_child(icon)

	var count_label := Label.new()
	count_label.text = "x%d" % count
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CozyUITheme.apply_secondary_label(count_label, 11)
	stack.add_child(count_label)
	cell.add_child(slot)

	var name_label := Label.new()
	name_label.text = _item_label(item_id)
	name_label.custom_minimum_size = Vector2(94, 24)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.clip_text = false
	CozyUITheme.apply_body_label(name_label, 10)
	cell.add_child(name_label)
	return cell

func _limezu_icon_for_item(item_id: String) -> Texture2D:
	if not LiveVisualPolicy.live_limezu_slice():
		return null
	var limezu_id: String = ""
	match item_id:
		ContentIds.ITEM_CARROT:
			limezu_id = "icon.carrot"
		ResourceIds.MATERIAL_WOOD:
			limezu_id = "icon.wood"
		ResourceIds.COMPONENT_SEED_PACKET:
			limezu_id = "icon.seed"
		ItemIds.TOOL_WORN_AXE:
			limezu_id = "icon.tool_axe"
		ItemIds.TOOL_WATERING_CAN:
			limezu_id = "icon.tool_watering_can"
		ItemIds.TOOL_BASIC_SHOVEL:
			limezu_id = "icon.tool_shovel"
		_:
			pass
	if limezu_id.is_empty() or not LimeZuArtRegistry.has_asset(limezu_id):
		return null
	return LimeZuArtRegistry.resolve_texture(limezu_id)

func _item_label(item_id: String) -> String:
	if ItemIds.is_storable(item_id):
		return ItemIds.display_name(item_id)
	var item: Dictionary = ContentRegistry.items().get(item_id, {}) as Dictionary
	if not item.is_empty():
		return String(item.get("display_name", item_id.capitalize()))
	return item_id.capitalize()
