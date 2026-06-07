extends RefCounted
class_name DevToolState

## Local-only developer tool state. Holds whether dev mode is active and which tool
## is selected, ready for future world-building tools (terrain paint, landmark
## placement, blocked-area definition, wilderness inspection, spawned-content
## debugging, build-moderation review). It has no gameplay effect while disabled and
## performs no networking or persistence.

const TOOL_INSPECT := "inspect"
const TOOL_MARKER := "marker"
const TOOL_BLOCKED_NOTE := "blocked_note"
const TOOL_SPAWN_NOTE := "spawn_note"
# Reserved future tool ids (not implemented yet):
const TOOL_TERRAIN_PAINT := "terrain_paint"
const TOOL_PLACE_LANDMARK := "place_landmark"
const TOOL_DEFINE_BLOCKED := "define_blocked"
const TOOL_WILDERNESS_INSPECT := "wilderness_inspect"
const TOOL_BUILD_MODERATION := "build_moderation"

var dev_mode_enabled: bool = false
var active_tool: String = TOOL_INSPECT

func toggle() -> bool:
	dev_mode_enabled = not dev_mode_enabled
	return dev_mode_enabled

static func tool_display_name(tool_id: String) -> String:
	match tool_id:
		TOOL_INSPECT:
			return "Inspect"
		TOOL_MARKER:
			return "Marker"
		TOOL_BLOCKED_NOTE:
			return "Blocked Note"
		TOOL_SPAWN_NOTE:
			return "Spawn Note"
		_:
			return tool_id.capitalize()

## Approximate area label from a world position, matching the overworld layout
## (homestead at the origin, village near x=1500, forest near x=3000).
static func area_label(world_pos: Vector2) -> String:
	var x: float = world_pos.x
	if x >= -760.0 and x < 760.0:
		return "Homestead"
	if x >= 1150.0 and x < 2050.0:
		return "Village Square"
	if x >= 2550.0 and x < 3760.0:
		return "Forest Edge"
	return "Wilderness/Unknown"
