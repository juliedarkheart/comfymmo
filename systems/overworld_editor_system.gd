extends CanvasLayer
class_name OverworldEditorSystem

## Dev-only overlay + lightweight world authoring tools, toggled with F10. While dev
## mode is active it lets you select a tool (1-4), drop temporary visual-only markers
## at the mouse world position (M or left-click in Marker tool), clear them (C), and
## export them to a local JSON file (E). Markers never block movement and are never
## saved with the game; they vanish on scene reload unless exported.
##
## Dev keys are handled in `_input` (which runs before every `_unhandled_input`
## handler) and only consumed while dev mode is on, so they can never collide with
## gameplay or building placement, and nothing leaks to gameplay while dev mode is
## off (only F10 is watched then).

const EXPORT_PATH := "user://dev_marker_export.json"

var _state: DevToolState = DevToolState.new()
var _player: Node2D
var _camera: Camera2D
var _marker_layer: Node2D
var _label: Label
var _audit_log: AuditLog = AuditLog.new()
var _markers: Array[DevWorldMarker] = []
var _next_marker_id: int = 1
var _last_marker_pos: Vector2 = Vector2.ZERO
var _export_status: String = ""

func setup(player: Node2D, camera: Camera2D, marker_layer: Node2D) -> void:
	_player = player
	_camera = camera
	_marker_layer = marker_layer

func _ready() -> void:
	layer = 90
	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(24, 240)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	_label = Label.new()
	margin.add_child(_label)

	visible = false
	set_process(false)

func _input(event: InputEvent) -> void:
	# F10 always toggles dev mode.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		var enabled: bool = _state.toggle()
		visible = enabled
		set_process(enabled)
		_consume()
		return

	# While disabled, the editor watches nothing else, so normal gameplay input is
	# untouched.
	if not _state.dev_mode_enabled:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_state.active_tool = DevToolState.TOOL_INSPECT
				_consume()
			KEY_2:
				_state.active_tool = DevToolState.TOOL_MARKER
				_consume()
			KEY_3:
				_state.active_tool = DevToolState.TOOL_BLOCKED_NOTE
				_consume()
			KEY_4:
				_state.active_tool = DevToolState.TOOL_SPAWN_NOTE
				_consume()
			KEY_M:
				_place_marker()
				_consume()
			KEY_C:
				_clear_markers()
				_consume()
			KEY_E:
				_export_markers()
				_consume()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Left-click only drops a marker in the dedicated Marker tool, so other tools
		# (e.g. Inspect) leave clicks alone.
		if _state.active_tool == DevToolState.TOOL_MARKER:
			_place_marker()
			_consume()

func _consume() -> void:
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()

func _process(_delta: float) -> void:
	if not _state.dev_mode_enabled:
		return
	_label.text = _format_overlay()

func _place_marker() -> void:
	if _marker_layer == null or not is_instance_valid(_marker_layer):
		return
	if _camera == null or not is_instance_valid(_camera):
		return

	var pos: Vector2 = _camera.get_global_mouse_position()
	var area: String = DevToolState.area_label(pos)
	var marker_type: String = _state.active_tool

	var marker: DevWorldMarker = DevWorldMarker.new()
	marker.position = pos
	marker.setup(_next_marker_id, area, marker_type)
	_marker_layer.add_child(marker)
	_markers.append(marker)
	_last_marker_pos = pos

	_audit_log.append("dev_marker_added", {
		"marker_id": _next_marker_id,
		"position": {"x": pos.x, "y": pos.y},
		"area": area,
		"type": marker_type,
	})
	_next_marker_id += 1

func _clear_markers() -> void:
	var count: int = _markers.size()
	for marker in _markers:
		if is_instance_valid(marker):
			marker.queue_free()
	_markers.clear()
	if count > 0:
		_audit_log.append("dev_markers_cleared", {"count": count})
	_export_status = ""

func _export_markers() -> void:
	var data: Dictionary = {
		"exported_at": Time.get_unix_time_from_system(),
		"marker_count": _markers.size(),
		"markers": [],
	}
	for marker in _markers:
		if not is_instance_valid(marker):
			continue
		data["markers"].append({
			"id": marker.marker_id,
			"position": {"x": marker.position.x, "y": marker.position.y},
			"area": marker.area_label,
			"type": marker.marker_type,
			"note": "",
		})

	var file: FileAccess = FileAccess.open(EXPORT_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		_export_status = "Exported %d markers -> %s" % [int(data["marker_count"]), EXPORT_PATH]
	else:
		_export_status = "Export failed (could not open %s)" % EXPORT_PATH

func _format_overlay() -> String:
	var player_pos: Vector2 = Vector2.ZERO
	if _player != null and is_instance_valid(_player):
		player_pos = _player.global_position

	var mouse_pos: Vector2 = Vector2.ZERO
	var zoom_level: float = 1.0
	if _camera != null and is_instance_valid(_camera):
		mouse_pos = _camera.get_global_mouse_position()
		zoom_level = _camera.zoom.x

	var lines: Array[String] = [
		"Dev Mode: ON  (F10 to hide)",
		"Tool: %s" % DevToolState.tool_display_name(_state.active_tool),
		"Area: %s" % DevToolState.area_label(player_pos),
		"Player: %d, %d" % [int(player_pos.x), int(player_pos.y)],
		"Mouse: %d, %d" % [int(mouse_pos.x), int(mouse_pos.y)],
		"Zoom: %.2fx" % zoom_level,
		"Markers: %d (last: %d, %d)" % [_markers.size(), int(_last_marker_pos.x), int(_last_marker_pos.y)],
		"Keys: 1 Inspect, 2 Marker, 3 Blocked, 4 Spawn, M Mark, C Clear, E Export",
	]
	if not _export_status.is_empty():
		lines.append(_export_status)
	return "\n".join(lines)
