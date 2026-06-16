extends CanvasModulate
class_name DayNightCycle

## Cozy day/night lighting. A CanvasModulate placed in the world (canvas layer 0)
## tints the overworld through a soft morning -> day -> evening -> night gradient.
## It deliberately never goes dark enough to hurt readability (every channel is
## floored), matching the warm Stardew-like target. UI panels live on their own
## CanvasLayers, so they are never tinted. The clock is a simple real-time loop
## today; `time01`/`set_time01` are exposed so a future persisted world clock can
## drive it. `phase_label()` feeds the HUD.

const DAY_LENGTH_SECONDS: float = 480.0   # 8 real minutes per full in-game day
const MIN_CHANNEL: float = 0.52           # readability floor (never fully dark)

# Keyframes around the day as (time01, tint). 0.0 = deep night, 0.5 = noon.
const KEYS: Array = [
	[0.00, Color(0.58, 0.62, 0.82)],
	[0.22, Color(0.96, 0.80, 0.70)],
	[0.32, Color(1.00, 0.98, 0.93)],
	[0.50, Color(1.00, 1.00, 1.00)],
	[0.70, Color(1.00, 0.84, 0.68)],
	[0.82, Color(0.80, 0.68, 0.74)],
	[1.00, Color(0.58, 0.62, 0.82)],
]

var _time01: float = 0.32   # start mid-morning so first boot is bright
var _paused: bool = false

func _ready() -> void:
	color = tint_for(_time01)

func _process(delta: float) -> void:
	if _paused:
		return
	_time01 = fmod(_time01 + delta / DAY_LENGTH_SECONDS, 1.0)
	color = tint_for(_time01)

func time01() -> float:
	return _time01

func set_time01(value: float) -> void:
	_time01 = clampf(value, 0.0, 1.0)
	color = tint_for(_time01)

func set_paused(paused: bool) -> void:
	_paused = paused

func phase_label() -> String:
	var t: float = _time01
	if t < 0.20: return "Night"
	if t < 0.30: return "Dawn"
	if t < 0.45: return "Morning"
	if t < 0.62: return "Midday"
	if t < 0.78: return "Evening"
	if t < 0.90: return "Dusk"
	return "Night"

## Clock readout like "7:12 am" for the HUD (0.0 == midnight).
func clock_label() -> String:
	var minutes_total: int = int(_time01 * 1440.0) % 1440
	var hour24: int = minutes_total / 60
	var minute: int = minutes_total % 60
	var suffix: String = "am" if hour24 < 12 else "pm"
	var hour12: int = hour24 % 12
	if hour12 == 0:
		hour12 = 12
	return "%d:%02d %s" % [hour12, minute, suffix]

## Interpolate the keyframe gradient, then floor each channel for readability.
static func tint_for(t01: float) -> Color:
	t01 = clampf(t01, 0.0, 1.0)
	var result: Color = (KEYS[KEYS.size() - 1][1] as Color)
	for i in range(KEYS.size() - 1):
		var a: float = float(KEYS[i][0])
		var b: float = float(KEYS[i + 1][0])
		if t01 >= a and t01 <= b:
			var span: float = maxf(b - a, 0.0001)
			result = (KEYS[i][1] as Color).lerp(KEYS[i + 1][1] as Color, (t01 - a) / span)
			break
	return Color(
		maxf(result.r, MIN_CHANNEL),
		maxf(result.g, MIN_CHANNEL),
		maxf(result.b, MIN_CHANNEL),
		1.0
	)
