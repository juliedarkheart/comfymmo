extends CanvasLayer

## Plot info + claim panel (opened from a plot sign). Shows the plot's name,
## status, owner, member count, cost, the player's land tokens, and whether
## they can build — with a Claim button when claimable and an Invite hint for
## owners. The controller passes a plot-info dict and a claim callback, so the
## panel stays presentation-only and works the same offline and connected.
## Keyboard claim still works at the sign; this adds the mouse-friendly button.

var _claim_callback: Callable = Callable()
var _current_plot_id: String = ""

@onready var _rows: VBoxContainer = $Panel/Rows
var _title_label: Label = null
var _info_label: Label = null
var _claim_button: Button = null

func setup(claim_callback: Callable) -> void:
	_claim_callback = claim_callback

func _ready() -> void:
	visible = false
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", Color("#f8de9a"))
	_rows.add_child(_title_label)

	_info_label = Label.new()
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_label.add_theme_font_size_override("font_size", 14)
	_info_label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.85, 1.0))
	_rows.add_child(_info_label)

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	_rows.add_child(buttons)

	_claim_button = Button.new()
	_claim_button.text = "Claim Plot"
	_claim_button.pressed.connect(_on_claim_pressed)
	buttons.add_child(_claim_button)

	var close_button: Button = Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(close_panel)
	buttons.add_child(close_button)

func open_for_plot(info: Dictionary) -> void:
	_current_plot_id = String(info.get("plot_id", ""))
	_title_label.text = String(info.get("display_name", "Plot"))
	var lines: Array[String] = [
		String(info.get("size_text", "")),
		"Status: %s" % String(info.get("status_text", "—")),
		"Owner: %s" % String(info.get("owner", "Unclaimed")),
		"Members: %d friend(s)" % int(info.get("members", 0)),
		"Cost: %d Land Token" % int(info.get("cost", 1)),
		"Your Land Tokens: %d" % int(info.get("tokens", 0)),
		"",
		String(info.get("permission_text", "")),
	]
	if bool(info.get("is_owner", false)):
		lines.append("You own this plot. Build with B; invite a friend with /invite <username> (server).")
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
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close_panel()
		var viewport: Viewport = get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()

func _on_claim_pressed() -> void:
	if _claim_callback.is_valid() and not _current_plot_id.is_empty():
		_claim_callback.call(_current_plot_id)
	close_panel()
