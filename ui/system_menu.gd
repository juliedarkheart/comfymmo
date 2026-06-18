extends CanvasLayer

## System / pause menu (Esc when no other panel is open). Gives the player a
## real, visible way to control the window and quit — Resume, Toggle
## Fullscreen/Windowed, Quit to Desktop, Close — so they never have to Alt+F4.
## The in-game Quit button calls get_tree().quit() and works even in a
## borderless window that hides the OS controls. Esc or Resume closes it.
##
## The controller owns open/close (so it can pause movement/interactions); this
## scene just draws the menu and reports when it should close.

signal close_requested()

@onready var _mode_label: Label = $Dim/Panel/Rows/ModeLabel
@onready var _settings_box: VBoxContainer = $Dim/Panel/Rows/SettingsBox
@onready var _vsync_button: Button = $Dim/Panel/Rows/SettingsBox/VsyncButton

func _ready() -> void:
	visible = false
	_apply_style()
	$Dim/Panel/Rows/ResumeButton.pressed.connect(_request_close)
	$Dim/Panel/Rows/FullscreenButton.pressed.connect(_on_fullscreen)
	$Dim/Panel/Rows/SettingsButton.pressed.connect(_on_settings)
	$Dim/Panel/Rows/QuitButton.pressed.connect(_on_quit)
	$Dim/Panel/Rows/CloseButton.pressed.connect(_request_close)
	_vsync_button.pressed.connect(_on_vsync)
	_refresh_vsync_label()

func _apply_style() -> void:
	CozyUITheme.apply_panel($Dim/Panel)
	CozyUITheme.apply_heading_label($Dim/Panel/Rows/Title, 24)
	CozyUITheme.apply_secondary_label(_mode_label, 13)
	CozyUITheme.apply_secondary_label($Dim/Panel/Rows/SettingsBox/DisplayInfo, 11)
	for button_variant in $Dim/Panel/Rows.find_children("*", "Button", true, false):
		CozyUITheme.apply_button(button_variant as Button)
	CozyUITheme.apply_danger_button($Dim/Panel/Rows/QuitButton)
	CozyUITheme.apply_close_button($Dim/Panel/Rows/CloseButton)

func open() -> void:
	visible = true
	_refresh_vsync_label()
	_refresh_mode_label()

func close() -> void:
	visible = false

func is_open() -> bool:
	return visible

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.echo:
		return
	if (
		event.is_action_pressed("toggle_system_menu")
		or event.is_action_pressed("cancel_action")
	):
		_request_close()
		var viewport: Viewport = get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()

func _request_close() -> void:
	visible = false
	close_requested.emit()

func _on_fullscreen() -> void:
	DisplaySettings.toggle_fullscreen()
	_refresh_mode_label()

## Settings / Display: reveal the small display settings box (V-Sync + reminders).
func _on_settings() -> void:
	if _settings_box != null:
		_settings_box.visible = not _settings_box.visible

func _on_vsync() -> void:
	var enabled: bool = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_DISABLED if enabled else DisplayServer.VSYNC_ENABLED
	)
	_refresh_vsync_label()

func _refresh_vsync_label() -> void:
	if _vsync_button == null:
		return
	var on: bool = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	_vsync_button.text = "V-Sync: %s" % ("On" if on else "Off")

func _on_quit() -> void:
	get_tree().quit()

func _refresh_mode_label() -> void:
	if _mode_label != null:
		_mode_label.text = "Window: %s (F11)" % (
			"Fullscreen" if DisplaySettings.is_fullscreen() else "Windowed (bordered)"
		)
