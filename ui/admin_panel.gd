extends CanvasLayer

## Admin / world-builder panel (F7). Trust-based prototype (offline you are the
## owner; on a server the world-save roles map governs — see docs/admin_tools.md).
## Buttons mostly reuse the chat command router on the controller so there's one
## source of truth; a couple call controller helpers directly (teleport, debug
## overlay). Shows current role, area, plot, and admin-build state.

var _controller: Node = null
var _info_label: Label = null
var _build_button: Button = null
var _biome_picker: OptionButton = null
var _marker_picker: OptionButton = null
var _plot_teleport_box: VBoxContainer = null

@onready var _rows: VBoxContainer = $Panel/Scroll/Rows

func setup(controller: Node) -> void:
	_controller = controller

func _ready() -> void:
	visible = false
	var title: Label = Label.new()
	title.text = "World Builder (F7)"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", CozyUITheme.HONEY)
	_rows.add_child(title)

	_info_label = Label.new()
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_label.add_theme_font_size_override("font_size", 13)
	_info_label.add_theme_color_override("font_color", CozyUITheme.INK)
	_rows.add_child(_info_label)

	_build_button = _add_button("Toggle Admin Build", func() -> void:
		_cmd("/adminbuild"); _refresh())
	_add_button("Save World", func() -> void: _cmd("/save"))
	_add_button("List Plots", func() -> void: _cmd("/plots"))
	_add_button("Where Am I", func() -> void: _cmd("/where"))
	_add_button("Give Land Token", func() -> void: _cmd("/give land_token 1"); _refresh())
	_add_button("Give Starter Materials", func() -> void:
		for pair in [["wood", 20], ["stone", 20], ["fiber", 20], ["clay", 20]]:
			_cmd("/give %s %d" % [pair[0], pair[1]])
		_refresh())
	_add_button("Toggle World Overlay", func() -> void:
		if _controller != null and _controller.has_method("admin_toggle_world_overlay"):
			_controller.call("admin_toggle_world_overlay"))

	# --- World-builder: plots --------------------------------------------------
	_add_heading("World Builder · Plots")
	_biome_picker = OptionButton.new()
	for biome in ["meadow", "orchard", "creekside", "hilltop", "grove", "brook", "forest", "farmland"]:
		_biome_picker.add_item(String(biome).capitalize())
	_rows.add_child(_biome_picker)
	_add_button("Create Plot Here (24x24)", func() -> void:
		_call("admin_create_plot", [_picked_biome(), 24]))
	var plot_edit_row: HBoxContainer = _add_row()
	_row_button(plot_edit_row, "Grow +2", func() -> void: _call("admin_resize_plot_here", [2]))
	_row_button(plot_edit_row, "Shrink -2", func() -> void: _call("admin_resize_plot_here", [-2]))
	_row_button(plot_edit_row, "Remove Here", func() -> void: _call("admin_remove_plot_here", []))
	_add_button("Recolor Plot Here (biome)", func() -> void: _call("admin_set_plot_biome_here", [_picked_biome()]))

	# --- Visual parcel tool: stake two corners, see a preview, confirm ---------
	_add_heading("Visual Parcel Tool")
	var help: Label = Label.new()
	help.text = "Stand at corner A → Start. Walk to the far corner (preview follows) → Confirm."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 11)
	help.add_theme_color_override("font_color", CozyUITheme.INK_SOFT)
	_rows.add_child(help)
	var parcel_row: HBoxContainer = _add_row()
	_row_button(parcel_row, "Start", func() -> void: _call("admin_parcel_start", []))
	_row_button(parcel_row, "Confirm", func() -> void: _call("admin_parcel_confirm", [""]))
	_row_button(parcel_row, "Cancel", func() -> void: _call("admin_parcel_cancel", []))
	_add_button("Set Parcel Biome (from picker)", func() -> void: _call("admin_set_parcel_biome", [_picked_biome()]))

	# --- World-builder: markers ------------------------------------------------
	_add_heading("World Builder · Markers")
	_marker_picker = OptionButton.new()
	for marker_type in ["spawn", "resource", "npc", "sign", "landmark", "decor"]:
		_marker_picker.add_item(String(marker_type).capitalize())
	_rows.add_child(_marker_picker)
	var marker_row: HBoxContainer = _add_row()
	_row_button(marker_row, "Place Marker Here", func() -> void:
		_call("admin_place_marker", [_marker_picker.get_item_text(_marker_picker.selected).to_lower(), ""]))
	_row_button(marker_row, "Remove Marker Here", func() -> void: _call("admin_remove_marker_here", []))

	# --- Teleport: fixed anchors + every plot ----------------------------------
	_add_heading("Teleport")
	var teleport_row: HBoxContainer = _add_row()
	for dest in ["landing", "neighborhood", "town"]:
		_row_button(teleport_row, String(dest).capitalize(), func() -> void: _call("admin_teleport", [dest]))
	_plot_teleport_box = VBoxContainer.new()
	_rows.add_child(_plot_teleport_box)

	_add_button("Close", close_panel)

func toggle_panel() -> void:
	visible = not visible
	if visible:
		_refresh()
		_refresh_plot_teleports()

func close_panel() -> void:
	visible = false

func _add_button(text: String, on_press: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.pressed.connect(on_press)
	_rows.add_child(button)
	return button

func _add_heading(text: String) -> void:
	var heading: Label = Label.new()
	heading.text = text
	heading.add_theme_font_size_override("font_size", 14)
	heading.add_theme_color_override("font_color", CozyUITheme.HONEY)
	_rows.add_child(heading)

## The biome currently chosen in the picker (lowercased id).
func _picked_biome() -> String:
	if _biome_picker == null:
		return "meadow"
	return _biome_picker.get_item_text(_biome_picker.selected).to_lower()

func _add_row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_rows.add_child(row)
	return row

func _row_button(row: HBoxContainer, text: String, on_press: Callable) -> void:
	var button: Button = Button.new()
	button.text = text
	button.pressed.connect(on_press)
	row.add_child(button)

## Call a controller method by name with an argument array (no-op if absent).
func _call(method: String, args: Array) -> void:
	if _controller != null and _controller.has_method(method):
		_controller.callv(method, args)
	_refresh()
	_refresh_plot_teleports()

func _cmd(command: String) -> void:
	if _controller != null and _controller.has_method("_handle_chat_command"):
		_controller.call("_handle_chat_command", command)

## Rebuild the per-plot teleport buttons from the controller's plot directory.
func _refresh_plot_teleports() -> void:
	if _plot_teleport_box == null or _controller == null:
		return
	for child in _plot_teleport_box.get_children():
		child.queue_free()
	if not _controller.has_method("admin_plot_directory"):
		return
	var directory: Array = _controller.call("admin_plot_directory")
	var row: HBoxContainer = null
	for i in range(directory.size()):
		if i % 2 == 0:
			row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			_plot_teleport_box.add_child(row)
		var entry: Dictionary = directory[i] as Dictionary
		var plot_id: String = String(entry.get("plot_id", ""))
		var button: Button = Button.new()
		button.text = String(entry.get("display_name", plot_id))
		button.tooltip_text = plot_id
		button.pressed.connect(func() -> void: _call("admin_teleport_plot", [plot_id]))
		row.add_child(button)

func _refresh() -> void:
	if _info_label == null or _controller == null:
		return
	var info: Dictionary = {}
	if _controller.has_method("admin_get_info"):
		info = _controller.call("admin_get_info")
	_info_label.text = "Role: %s\nArea: %s\nAdmin Build: %s" % [
		String(info.get("role", "owner")),
		String(info.get("area", "—")),
		"ON" if bool(info.get("admin_build", false)) else "OFF",
	]
	if _build_button != null:
		_build_button.text = "Admin Build: %s" % ("ON" if bool(info.get("admin_build", false)) else "OFF")

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close_panel()
		var viewport: Viewport = get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()
