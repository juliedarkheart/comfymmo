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

func _ready() -> void:
	visible = false
	$Dim/Panel/Rows/ResumeButton.pressed.connect(_request_close)
	$Dim/Panel/Rows/FullscreenButton.pressed.connect(_on_fullscreen)
	$Dim/Panel/Rows/QuitButton.pressed.connect(_on_quit)
	$Dim/Panel/Rows/CloseButton.pressed.connect(_request_close)

func open() -> void:
	visible = true
	_refresh_mode_label()

func close() -> void:
	visible = false

func is_open() -> bool:
	return visible

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
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

func _on_quit() -> void:
	get_tree().quit()

func _refresh_mode_label() -> void:
	if _mode_label != null:
		_mode_label.text = "Window: %s   (F11 also toggles)" % ("Fullscreen" if DisplaySettings.is_fullscreen() else "Windowed")
