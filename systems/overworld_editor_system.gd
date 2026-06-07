extends CanvasLayer
class_name OverworldEditorSystem

## Lightweight, dev-only overlay toggled with F10. It is a read-only inspector for
## now (player/mouse world position, area label, camera zoom) and a seam for future
## world-building/moderation tools. It is hidden and idle when off, never blocks
## gameplay input, and performs no networking or persistence.

var _state: DevToolState = DevToolState.new()
var _player: Node2D
var _camera: Camera2D
var _label: Label

func setup(player: Node2D, camera: Camera2D) -> void:
	_player = player
	_camera = camera

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		var enabled: bool = _state.toggle()
		visible = enabled
		set_process(enabled)
		var viewport: Viewport = get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()

func _process(_delta: float) -> void:
	if not _state.dev_mode_enabled:
		return
	_label.text = _format_overlay()

func _format_overlay() -> String:
	var player_pos: Vector2 = Vector2.ZERO
	if _player != null and is_instance_valid(_player):
		player_pos = _player.global_position

	var mouse_pos: Vector2 = Vector2.ZERO
	var zoom_level: float = 1.0
	if _camera != null and is_instance_valid(_camera):
		mouse_pos = _camera.get_global_mouse_position()
		zoom_level = _camera.zoom.x

	return "DEV MODE  (F10 to hide)\nArea: %s\nPlayer: (%d, %d)\nMouse: (%d, %d)\nZoom: %.2fx\nTool: %s" % [
		DevToolState.area_label(player_pos),
		int(player_pos.x), int(player_pos.y),
		int(mouse_pos.x), int(mouse_pos.y),
		zoom_level,
		_state.active_tool,
	]
