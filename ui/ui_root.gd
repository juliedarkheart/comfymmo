extends CanvasLayer

## Placeholder root for screen-level UI composition.

signal screen_requested(screen_id: String)

func request_screen(screen_id: String) -> void:
	screen_requested.emit(screen_id)

