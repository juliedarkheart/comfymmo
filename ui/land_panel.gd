extends CanvasLayer

## Plot info + claim panel (opened from a plot sign). Shows name, status,
## owner, members, cost, current land tokens, and whether the player can build.

var _claim_callback: Callable = Callable()
var _current_plot_id: String = ""

@onready var _panel: PanelContainer = $Panel
@onready var _rows: VBoxContainer = $Panel/Rows
var _title_label: Label = null
var _info_label: Label = null
var _claim_button: Button = null

const SAFE_DOCK_RECT := Rect2(440, 180, 400, 300)

func setup(claim_callback: Callable) -> void:
	_claim_callback = claim_callback

func _ready() -> void:
	visible = false
	_apply_safe_dock()
	CozyUITheme.apply_panel(_panel)

	_title_label = Label.new()
	CozyUITheme.apply_heading_label(_title_label, 20)
	_rows.add_child(_title_label)

	_info_label = Label.new()
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	CozyUITheme.apply_body_label(_info_label, 14)
	_rows.add_child(_info_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	_rows.add_child(buttons)

	_claim_button = Button.new()
	_claim_button.text = "Claim Plot"
	_claim_button.pressed.connect(_on_claim_pressed)
	CozyUITheme.apply_button(_claim_button)
	buttons.add_child(_claim_button)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(close_panel)
	CozyUITheme.apply_close_button(close_button)
	buttons.add_child(close_button)

func _apply_safe_dock() -> void:
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	_panel.offset_left = SAFE_DOCK_RECT.position.x
	_panel.offset_top = SAFE_DOCK_RECT.position.y
	_panel.offset_right = SAFE_DOCK_RECT.end.x
	_panel.offset_bottom = SAFE_DOCK_RECT.end.y

func open_for_plot(info: Dictionary) -> void:
	_current_plot_id = String(info.get("plot_id", ""))
	_title_label.text = String(info.get("display_name", "Plot"))
	var lines: Array[String] = [
		String(info.get("size_text", "")),
		"Status: %s" % String(info.get("status_text", "-")),
		"Owner: %s" % String(info.get("owner", "Unclaimed")),
		"Members: %d friend(s)" % int(info.get("members", 0)),
		"Cost: %d Land Token" % int(info.get("cost", 1)),
		"Your Land Tokens: %d" % int(info.get("tokens", 0)),
		"",
		String(info.get("permission_text", "")),
	]
	if bool(info.get("is_owner", false)):
		lines.append("You own this plot. Build with B; invite a friend with /invite <username> on a server.")
	_info_label.text = "\n".join(lines)
	_claim_button.visible = bool(info.get("can_claim", false))
	_claim_button.disabled = not bool(info.get("can_claim", false))
	visible = true

func close_panel() -> void:
	visible = false

func is_open() -> bool:
	return visible

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

func _on_claim_pressed() -> void:
	if _claim_callback.is_valid() and not _current_plot_id.is_empty():
		_claim_callback.call(_current_plot_id)
	close_panel()
