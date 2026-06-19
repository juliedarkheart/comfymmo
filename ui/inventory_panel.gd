extends CanvasLayer

signal quickbar_assign_requested(item_id: String)

## Full player inventory (I): identity header plus item categories. Snapshot
## driven like the crafting/progression panels, so the same panel serves offline
## and connected sessions. Esc, I, or the Close button hides it.

var _get_count: Callable = Callable()       # (item_id) -> int
var _get_identity: Callable = Callable()    # () -> Dictionary

var _identity_label: Label = null
var _detail_label: Label = null
var _body: VBoxContainer = null
const DEFAULT_DETAIL := "Hover an item for details."
const ASSIGN_DETAIL := "Click an item to assign it to the quickbar; right-click a quickbar slot to clear it."
const SLOT_PX := 56.0

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
	close_button.clip_text = false
	close_button.custom_minimum_size = Vector2(92, 32)
	header.add_child(close_button)

	# One compact status line (no verbose profile id / duplicated name).
	_identity_label = Label.new()
	_identity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	CozyUITheme.apply_secondary_label(_identity_label, 12)
	_root_rows.add_child(_identity_label)
	_root_rows.move_child(_identity_label, 1)

	# A thin wood divider separates the header/status from the item grid for hierarchy.
	var divider := ColorRect.new()
	divider.color = Color(LimeZuUITheme.PANEL_BORDER.r, LimeZuUITheme.PANEL_BORDER.g, LimeZuUITheme.PANEL_BORDER.b, 0.55)
	divider.custom_minimum_size = Vector2(0, 2)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root_rows.add_child(divider)
	_root_rows.move_child(divider, 2)

	# Grid-first inventory: item names live on this hover/selection detail line at the
	# bottom (Stardew-style) instead of wrapping under every slot.
	_detail_label = Label.new()
	_detail_label.text = ASSIGN_DETAIL
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.add_theme_stylebox_override("normal", LimeZuUITheme.tooltip_panel_style())
	_detail_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_detail_label.custom_minimum_size = Vector2(0, 42)
	_detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	CozyUITheme.apply_body_label(_detail_label, 12)
	_root_rows.add_child(_detail_label)

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
	if _detail_label != null:
		_detail_label.text = ASSIGN_DETAIL
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
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	_body.add_child(grid)
	for entry_variant in entries:
		var entry: Dictionary = entry_variant as Dictionary
		grid.add_child(_build_inventory_slot(String(entry["item_id"]), int(entry["count"])))
	return entries.size()

## Grid-first square item slot: a LimeZu Modern UI slot frame with a centered icon and a
## bottom-right count overlay. The item NAME is shown on the panel's hover/detail line (set
## via mouse_entered), not under every slot — so the grid stays tidy and aligned.
func _build_inventory_slot(item_id: String, count: int) -> Control:
	var slot := Panel.new()
	slot.name = "InventorySlot_%s" % item_id
	slot.custom_minimum_size = Vector2(SLOT_PX, SLOT_PX)
	slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	slot.mouse_filter = Control.MOUSE_FILTER_PASS
	slot.add_theme_stylebox_override("panel", LimeZuUITheme.slot_texture_style(false))

	var tex: Texture2D = _icon_texture_for_item(item_id)
	if tex != null:
		var icon := TextureRect.new()
		icon.texture = tex
		LimeZuUITheme.apply_slot_icon_layout(icon, SLOT_PX)
		slot.add_child(icon)
	else:
		var glyph := Label.new()
		var inner: Rect2 = LimeZuUITheme.slot_inner_rect(SLOT_PX)
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		glyph.offset_left = inner.position.x
		glyph.offset_top = inner.position.y
		glyph.offset_right = -(SLOT_PX - inner.end.x)
		glyph.offset_bottom = -(SLOT_PX - inner.end.y)
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.text = _item_label(item_id).substr(0, 3)
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		CozyUITheme.apply_body_label(glyph, 11)
		slot.add_child(glyph)

	var count_label := Label.new()
	count_label.text = "%d" % count
	LimeZuUITheme.apply_slot_count_layout(count_label, SLOT_PX)
	slot.add_child(count_label)

	var detail: String = "%s   x%d" % [_item_label(item_id), count]
	slot.mouse_entered.connect(func() -> void: _set_detail(detail))
	slot.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			quickbar_assign_requested.emit(item_id)
			_set_detail("Assign %s: click a quickbar slot. Right-click quickbar slot to clear." % _item_label(item_id))
			var viewport := get_viewport()
			if viewport != null:
				viewport.set_input_as_handled()
	)
	return slot

func _set_detail(text: String) -> void:
	if _detail_label != null:
		_detail_label.text = text

## LimeZu live icon where mapped, else the cozy ObjectArtRegistry icon, else null.
func _icon_texture_for_item(item_id: String) -> Texture2D:
	return ObjectArtRegistry.icon_texture_for_item(item_id)

func _item_label(item_id: String) -> String:
	if ItemIds.is_storable(item_id):
		return ItemIds.display_name(item_id)
	var item: Dictionary = ContentRegistry.items().get(item_id, {}) as Dictionary
	if not item.is_empty():
		return String(item.get("display_name", item_id.capitalize()))
	return item_id.capitalize()
