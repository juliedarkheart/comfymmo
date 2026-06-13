extends CanvasLayer

## Cozy chat / event log, lower-left. Always shows the last few lines (system
## toasts like "+2 Wood" appear here offline too); Enter opens the input when
## connected-world chat makes sense. PROTOTYPE chat: no moderation, no admin
## commands, no filtering, no history — see docs/networking_plan.md.
##
## Focus rules: while the input has focus, the player's movement is disabled so
## WASD types instead of walking; Esc (or sending) releases focus and restores
## movement. Enter never opens chat during placement/edit or while another
## panel is open (the controller supplies `can_open`).

const MAX_LINES := 10

var _player: AvatarController = null
var _can_open: Callable = Callable()
var _command_handler: Callable = Callable()
var _session: Node = null

@onready var _log_box: VBoxContainer = $Panel/Rows/LogBox
@onready var _input: LineEdit = $Panel/Rows/Input

func setup(player: AvatarController, can_open: Callable, command_handler: Callable = Callable()) -> void:
	_player = player
	_can_open = can_open
	_command_handler = command_handler

func _ready() -> void:
	_input.visible = false
	_input.max_length = ChatMessage.MAX_LENGTH
	_input.text_submitted.connect(_on_text_submitted)
	_input.focus_exited.connect(_close_input)
	# Runtime autoload lookup (direct identifier breaks --script validation).
	_session = get_node_or_null("/root/NetworkSession")
	if _session != null:
		_session.connect("chat_received", _on_chat_received)
		_session.connect("chat_system_received", add_system_line)
		_session.connect("connection_state_changed", add_system_line)

func _unhandled_input(event: InputEvent) -> void:
	if _input.visible:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode != KEY_ENTER and event.keycode != KEY_KP_ENTER:
		return
	if _can_open.is_valid() and not bool(_can_open.call()):
		return
	_open_input()
	get_viewport().set_input_as_handled()

func _open_input() -> void:
	_input.visible = true
	_input.clear()
	_input.grab_focus()
	if _player != null and is_instance_valid(_player):
		_player.set_movement_enabled(false)

func _close_input() -> void:
	_input.visible = false
	_input.clear()
	if _player != null and is_instance_valid(_player):
		_player.set_movement_enabled(true)

func _on_text_submitted(text: String) -> void:
	var clean: String = ChatMessage.sanitize(text)
	if not clean.is_empty():
		if clean.begins_with("/") and _command_handler.is_valid():
			_command_handler.call(clean)
		elif _session != null and bool(_session.call("is_client_connected")):
			_session.call("send_chat", clean)
		else:
			add_system_line("Offline — connect to a server (F8) to chat.")
	_input.release_focus()
	_close_input()

func _on_chat_received(display_name: String, text: String) -> void:
	_add_line("%s: %s" % [display_name, text], Color("#f5f0e6"))

func add_system_line(text: String) -> void:
	if text.is_empty():
		return
	_add_line(text, Color("#d9c89a"))

func _add_line(text: String, color: Color) -> void:
	var line: Label = Label.new()
	line.text = text
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.add_theme_font_size_override("font_size", 14)
	line.add_theme_color_override("font_color", color)
	line.add_theme_color_override("font_outline_color", Color(0.13, 0.1, 0.07, 0.85))
	line.add_theme_constant_override("outline_size", 4)
	_log_box.add_child(line)
	while _log_box.get_child_count() > MAX_LINES:
		var oldest: Node = _log_box.get_child(0)
		_log_box.remove_child(oldest)
		oldest.queue_free()
