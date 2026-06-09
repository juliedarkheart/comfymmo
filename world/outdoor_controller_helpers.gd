extends RefCounted
class_name OutdoorControllerHelpers

## Small, stateless helpers shared by outdoor area controllers. These factor the
## mechanical "call a HUD method if it exists" pattern and the mood/day HUD
## application out of the controllers, so the logic is reusable by a future
## `OutdoorAreaController` base without depending on HomesteadController.
##
## Behaviour must stay identical to the inline versions the controllers used.

## Calls `method` on `node` with `args` only if the node exists and exposes it. This
## mirrors the defensive `if hud.has_method(...)` pattern used throughout the HUD
## wiring, so controllers never hard-depend on a specific HUD implementation.
static func call_if_has(node: Object, method: String, args: Array = []) -> void:
	if node != null and node.has_method(method):
		node.callv(method, args)

static func apply_mood(hud: Object, mood_id: String) -> void:
	call_if_has(hud, "set_mood", [mood_id])

static func apply_day(hud: Object, day_count: int) -> void:
	call_if_has(hud, "set_day", [day_count])

## Advances the global mood one phase, persists it, and refreshes the HUD tint/line.
## Returns the new mood id. (Day count is unaffected — only resting advances the day.)
static func cycle_mood(save_system: LocalSaveSystem, hud: Object) -> String:
	var next_mood: String = WorldMood.next_mood(save_system.get_current_mood())
	save_system.set_current_mood(next_mood)
	apply_mood(hud, next_mood)
	return next_mood
