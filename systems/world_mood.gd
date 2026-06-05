extends RefCounted
class_name WorldMood

## Tiny stateless utility describing the world's mood / time-of-day phases.
## No real time, no automatic advancement — phases are cycled manually and the
## current phase lives in the save under `world.global_flags.current_mood`.

const MORNING: String = "morning"
const AFTERNOON: String = "afternoon"
const DUSK: String = "dusk"
const DEFAULT_MOOD: String = MORNING
const ORDER: Array[String] = [MORNING, AFTERNOON, DUSK]

static func normalize(mood_id: String) -> String:
	return mood_id if ORDER.has(mood_id) else DEFAULT_MOOD

static func next_mood(mood_id: String) -> String:
	var index: int = ORDER.find(normalize(mood_id))
	return ORDER[(index + 1) % ORDER.size()]

## Resting at dusk wraps to the next day's morning; resting earlier only advances
## the phase. Used by the homestead rest interaction to decide day progression.
static func rest_increments_day(mood_id: String) -> bool:
	return normalize(mood_id) == DUSK

static func display_name(mood_id: String) -> String:
	match normalize(mood_id):
		AFTERNOON:
			return "Afternoon"
		DUSK:
			return "Dusk"
		_:
			return "Morning"

## Subtle, cozy full-screen tint. Afternoon is intentionally clear (alpha 0).
## Alphas stay low so HUD panels and world art remain readable.
static func tint_color(mood_id: String) -> Color:
	match normalize(mood_id):
		MORNING:
			return Color(1.0, 0.84, 0.55, 0.10)
		DUSK:
			return Color(0.70, 0.48, 0.62, 0.14)
		_:
			return Color(1.0, 1.0, 1.0, 0.0)
