extends CanvasLayer

## Full player inventory (I): identity header + every item category (materials,
## crops, components, tools, tokens, weapons, wearables). Snapshot-driven like
## the crafting/progression panels — the controller supplies a per-item count
## getter and an identity getter, so the same panel serves offline (local
## InventorySystem) and connected (server pouch). Esc or I closes. Unknown ids
## degrade to a capitalized label rather than crashing.

var _get_count: Callable = Callable()       # (item_id) -> int
var _get_identity: Callable = Callable()    # () -> Dictionary

var _identity_label: Label = null
var _body: VBoxContainer = null

@onready var _root_rows: VBoxContainer = $Panel/Rows
@onready var _scroll_body: VBoxContainer = $Panel/Rows/Scroll/Body

func setup(get_count: Callable, get_identity: Callable) -> void:
	_get_count = get_count
	_get_identity = get_identity

func _ready() -> void:
	visible = false
	_body = _scroll_body
	var title: Label = Label.new()
	title.text = "Inventory  —  I or Esc to close"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("#f8de9a"))
	_root_rows.add_child(title)
	_root_rows.move_child(title, 0)

	_identity_label = Label.new()
	_identity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_identity_label.add_theme_font_size_override("font_size", 14)
	_identity_label.add_theme_color_override("font_color", Color("#bfe0ff"))
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
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
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
	_identity_label.text = "%s (@%s)  ·  %s  ·  Plot: %s\nProfile %s" % [
		String(identity.get("display_name", "Villager")),
		String(identity.get("username", "villager")),
		String(identity.get("mode", "Offline")),
		String(identity.get("plot_status", "—")),
		short_id,
	]

## One category section: a header plus a line per id. `always_show` lists every
## id even at 0 (tools/tokens); otherwise only owned items show, with "None"
## when the category is empty.
func _add_category(title: String, ids: Array, always_show: bool = false) -> void:
	var header: Label = Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 15)
	header.add_theme_color_override("font_color", Color("#f8de9a"))
	_body.add_child(header)

	var shown: int = 0
	for id_variant in ids:
		var item_id: String = String(id_variant)
		var count: int = int(_get_count.call(item_id)) if _get_count.is_valid() else 0
		if count <= 0 and not always_show:
			continue
		shown += 1
		var line: Label = Label.new()
		var mark: String = ("✓ " if count > 0 else "·  ") if always_show else ""
		line.text = "  %s%s × %d" % [mark, _item_label(item_id), count]
		line.add_theme_font_size_override("font_size", 14)
		line.add_theme_color_override("font_color", Color(0.96, 0.93, 0.85, 1.0) if count > 0 else Color(0.96, 0.93, 0.85, 0.5))
		_body.add_child(line)

	if shown == 0:
		var none_line: Label = Label.new()
		none_line.text = "  None yet"
		none_line.add_theme_font_size_override("font_size", 14)
		none_line.add_theme_color_override("font_color", Color(0.96, 0.93, 0.85, 0.5))
		_body.add_child(none_line)

func _item_label(item_id: String) -> String:
	if ItemIds.is_storable(item_id):
		return ItemIds.display_name(item_id)
	var item: Dictionary = ContentRegistry.items().get(item_id, {}) as Dictionary
	if not item.is_empty():
		return String(item.get("display_name", item_id.capitalize()))
	return item_id.capitalize()
