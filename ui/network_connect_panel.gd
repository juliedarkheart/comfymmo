extends CanvasLayer

## Prototype multiplayer panel (F8): shows the active local profile, lets you
## edit the display name, and connects/disconnects a local Hearthvale server.
## Offline stays the default — nothing here runs unless the player acts.
## Mouse-friendly, dev-grade UI in the same cozy style as the other panels.

var _profile_manager: LocalProfileManager = null
var _session: Node = null

@onready var _rows: VBoxContainer = $Panel/Rows
@onready var _panel: PanelContainer = $Panel
var _status_label: Label = null
var _profile_label: Label = null
var _username_edit: LineEdit = null
var _name_edit: LineEdit = null
var _ip_edit: LineEdit = null
var _port_edit: LineEdit = null
var _connect_button: Button = null
var _disconnect_button: Button = null

func setup(profile_manager: LocalProfileManager) -> void:
	_profile_manager = profile_manager
	_refresh_from_profile()

func _ready() -> void:
	visible = false
	CozyUITheme.apply_panel(_panel)
	_build_rows()
	# Runtime autoload lookup (direct identifier breaks --script validation).
	_session = get_node_or_null("/root/NetworkSession")
	if _session != null:
		_session.connect("connection_state_changed", _on_connection_state_changed)

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("toggle_network_panel"):
		return
	visible = not visible
	if visible:
		_refresh_from_profile()
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()

func _build_rows() -> void:
	var title: Label = Label.new()
	title.text = "Multiplayer"
	CozyUITheme.apply_heading_label(title, 18)
	_rows.add_child(title)

	_status_label = Label.new()
	_status_label.text = "Offline"
	CozyUITheme.apply_body_label(_status_label, 12)
	_rows.add_child(_status_label)

	_profile_label = Label.new()
	CozyUITheme.apply_secondary_label(_profile_label, 11)
	_rows.add_child(_profile_label)

	_username_edit = _add_field("Username", "villager")
	_name_edit = _add_field("Display Name", "Villager")
	_ip_edit = _add_field("Server IP", "127.0.0.1")
	_port_edit = _add_field("Port", str(ServerConfig.DEFAULT_PORT))

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	_rows.add_child(buttons)

	_connect_button = Button.new()
	_connect_button.text = "Connect"
	_connect_button.pressed.connect(_on_connect_pressed)
	CozyUITheme.apply_button(_connect_button)
	buttons.add_child(_connect_button)

	_disconnect_button = Button.new()
	_disconnect_button.text = "Disconnect"
	_disconnect_button.disabled = true
	_disconnect_button.pressed.connect(_on_disconnect_pressed)
	CozyUITheme.apply_button(_disconnect_button)
	buttons.add_child(_disconnect_button)

	var close_button: Button = Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(func() -> void: visible = false)
	CozyUITheme.apply_close_button(close_button)
	buttons.add_child(close_button)

	var hint: Label = Label.new()
	hint.text = (
		"Run a server first (tools/run_server_local.ps1).\n"
		+ "Same PC: 127.0.0.1 | LAN: host's LAN IP (ipconfig)\n"
		+ "Internet: host's public IP, UDP port forwarded"
	)
	CozyUITheme.apply_secondary_label(hint, 11)
	_rows.add_child(hint)

func _add_field(label_text: String, default_value: String) -> LineEdit:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_rows.add_child(row)
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(96, 0)
	CozyUITheme.apply_body_label(label, 12)
	row.add_child(label)
	var edit: LineEdit = LineEdit.new()
	edit.text = default_value
	edit.custom_minimum_size = Vector2(190, 28)
	CozyUITheme.apply_text_input(edit)
	row.add_child(edit)
	return edit

func _refresh_from_profile() -> void:
	if _profile_manager == null or _name_edit == null:
		return
	var profile: Dictionary = _profile_manager.get_active_profile()
	_username_edit.text = String(profile.get("username", "villager"))
	_name_edit.text = String(profile.get("display_name", "Villager"))
	_ip_edit.text = String(profile.get("last_server_ip", "127.0.0.1"))
	_port_edit.text = str(int(profile.get("last_server_port", ServerConfig.DEFAULT_PORT)))
	if _profile_label != null:
		# Your profile id IS your server identity (auto-registered on first
		# join; no password). Shown so playtesters know who they are.
		_profile_label.text = "Profile id: %s" % String(profile.get("profile_id", "?"))

func _on_connect_pressed() -> void:
	if _session == null or String(_session.call("get_mode")) != NetworkMode.OFFLINE:
		return
	var ip: String = _ip_edit.text.strip_edges()
	var port: int = clampi(int(_port_edit.text), 1, 65535)
	var profile: Dictionary = {}
	if _profile_manager != null:
		# Username: lowercase a-z, 0-9, _ and -, 3-20 chars; your persistent
		# handle on a server (first join registers it, no password).
		var username: String = PlayerIdentity.sanitize_username(_username_edit.text)
		if username.length() < PlayerIdentity.USERNAME_MIN_LENGTH:
			if _status_label != null:
				_status_label.text = "Pick a username first (3-20 chars: a-z, 0-9, _ or -)."
			return
		_profile_manager.update_active_profile({"username": username})
		_username_edit.text = username
		_profile_manager.set_display_name(_name_edit.text)
		_profile_manager.remember_server(ip, port)
		profile = _profile_manager.get_active_profile()
	if bool(_session.call("connect_to_server", ip, port, PlayerIdentity.build_join_payload(profile))):
		_connect_button.disabled = true
		_disconnect_button.disabled = false

func _on_disconnect_pressed() -> void:
	if _session != null:
		_session.call("disconnect_session")

func _on_connection_state_changed(state_text: String) -> void:
	if _status_label != null:
		_status_label.text = state_text
	var offline: bool = _session == null or String(_session.call("get_mode")) == NetworkMode.OFFLINE
	if _connect_button != null:
		_connect_button.disabled = not offline
	if _disconnect_button != null:
		_disconnect_button.disabled = offline
