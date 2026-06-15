extends RefCounted
class_name DisplaySettings

## Window/display preferences (F11 fullscreen toggle). Persisted to a tiny
## settings file separate from the game save, so it never touches save data and
## applies before the world loads. The game boots WINDOWED by default so the
## player is never trapped in fullscreen with no way out.

const SETTINGS_PATH := "user://display_settings.cfg"

## Apply the saved window mode (call once at boot, e.g. from the HUD _ready).
static func apply_saved() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	var fullscreen: bool = bool(config.get_value("display", "fullscreen", false))
	_set_fullscreen(fullscreen)

## Flip windowed <-> fullscreen, persist the choice, and return the new state.
static func toggle_fullscreen() -> bool:
	var now_fullscreen: bool = not is_fullscreen()
	_set_fullscreen(now_fullscreen)
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)  # ignore failure; we overwrite
	config.set_value("display", "fullscreen", now_fullscreen)
	config.save(SETTINGS_PATH)
	return now_fullscreen

static func is_fullscreen() -> bool:
	var mode: int = DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

static func _set_fullscreen(fullscreen: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
