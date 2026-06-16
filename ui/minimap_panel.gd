extends CanvasLayer

## Top-right minimap (M toggles). A schematic world view drawn with _draw():
## the homestead/landing, town, forest, and the neighborhood plots, plus dots
## for the player, key NPCs/services, and plot ownership. World positions are
## scaled into the map rect from a fixed world bounds, so it stays truthful to
## the real layout without per-frame cost beyond a queue_redraw.

## World bounds the minimap maps into its rect. Widened west + south so the
## spread-out homestead lots (creekside/brook to the west, orchard/grove to the
## south) all fit on the readout alongside the town and forest to the east.
const WORLD_MIN := Vector2(-1480, -300)
const WORLD_MAX := Vector2(3400, 1820)

var _player_pos: Vector2 = Vector2.ZERO
var _plots: Dictionary = {}            # plot_id -> {rect_center_world, owned_state}
var _landmarks: Array = []             # [{pos, color, label}]
var _admin_debug: bool = false

@onready var _map_rect: Control = $Panel/Margin/MapRect

func _ready() -> void:
	visible = true
	_map_rect.draw.connect(_draw_map)

## Static landmarks + plot centers in world space, supplied once by the
## controller (so the minimap doesn't reach into world systems itself).
func setup(landmarks: Array, plot_centers: Dictionary) -> void:
	_landmarks = landmarks
	for plot_id in plot_centers.keys():
		_plots[plot_id] = {"center": plot_centers[plot_id], "state": "unclaimed"}
	_map_rect.queue_redraw()

func set_player_position(world_pos: Vector2) -> void:
	_player_pos = world_pos
	_map_rect.queue_redraw()

## Update per-plot ownership tint: "unclaimed" / "owned" / "friend" / "other".
func set_plot_states(states: Dictionary) -> void:
	for plot_id in states.keys():
		if _plots.has(plot_id):
			(_plots[plot_id] as Dictionary)["state"] = String(states[plot_id])
	_map_rect.queue_redraw()

func set_admin_debug(enabled: bool) -> void:
	_admin_debug = enabled
	_map_rect.queue_redraw()

func toggle_panel() -> void:
	visible = not visible

func _world_to_map(world_pos: Vector2) -> Vector2:
	var size: Vector2 = _map_rect.size
	var nx: float = clampf((world_pos.x - WORLD_MIN.x) / (WORLD_MAX.x - WORLD_MIN.x), 0.0, 1.0)
	var ny: float = clampf((world_pos.y - WORLD_MIN.y) / (WORLD_MAX.y - WORLD_MIN.y), 0.0, 1.0)
	return Vector2(nx * size.x, ny * size.y)

func _draw_map() -> void:
	var size: Vector2 = _map_rect.size
	_map_rect.draw_rect(Rect2(Vector2.ZERO, size), Color(0.20, 0.26, 0.17, 1.0))
	# Region bands (schematic): town + forest stripes on the right.
	_map_rect.draw_rect(Rect2(_world_to_map(Vector2(1150, -200)), Vector2(18, size.y)), Color(0.42, 0.40, 0.30, 0.5))
	_map_rect.draw_rect(Rect2(_world_to_map(Vector2(2550, -200)), Vector2(size.x, size.y)), Color(0.30, 0.45, 0.30, 0.35))
	# Plot squares, tinted by ownership.
	for plot_id in _plots.keys():
		var plot: Dictionary = _plots[plot_id]
		var center: Vector2 = _world_to_map(plot["center"])
		var color: Color = Color(0.85, 0.78, 0.45, 0.9)
		match String(plot.get("state", "unclaimed")):
			"owned": color = Color(0.45, 0.85, 0.5, 0.95)
			"friend": color = Color(0.5, 0.7, 1.0, 0.95)
			"other": color = Color(0.85, 0.45, 0.45, 0.9)
		_map_rect.draw_rect(Rect2(center - Vector2(4, 4), Vector2(8, 8)), color)
		if _admin_debug:
			_map_rect.draw_rect(Rect2(center - Vector2(5, 5), Vector2(10, 10)), Color(1, 1, 1, 0.6), false, 1.0)
	# Landmark dots (NPCs, services).
	for landmark in _landmarks:
		var lm: Dictionary = landmark
		_map_rect.draw_circle(_world_to_map(lm["pos"]), 3.0, lm.get("color", Color.WHITE))
	# Player marker.
	var p: Vector2 = _world_to_map(_player_pos)
	_map_rect.draw_circle(p, 4.0, Color("#ffe066"))
	_map_rect.draw_circle(p, 4.0, Color(0.2, 0.15, 0.1, 1.0), false, 1.5)
