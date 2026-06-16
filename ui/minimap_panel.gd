extends CanvasLayer

## Top-right minimap (M toggles). A schematic world view drawn with _draw():
## the homestead/landing, town, forest, and the neighborhood plots, plus dots
## for the player, key NPCs/services, and plot ownership. World positions are
## scaled into the map rect from a fixed world bounds, so it stays truthful to
## the real layout without per-frame cost beyond a queue_redraw.

## Fallback world bounds the minimap maps into its rect. The controller normally
## passes the live world bounds via setup(...) so the readout always matches the
## (large, expandable) world; these consts are only used if none are supplied.
const WORLD_MIN := Vector2(-4600, -700)
const WORLD_MAX := Vector2(3900, 2300)

var _world_min: Vector2 = WORLD_MIN
var _world_max: Vector2 = WORLD_MAX

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
func setup(landmarks: Array, plot_centers: Dictionary, world_bounds: Rect2 = Rect2()) -> void:
	_landmarks = landmarks
	_plots.clear()
	for plot_id in plot_centers.keys():
		_plots[plot_id] = {"center": plot_centers[plot_id], "state": "unclaimed"}
	if world_bounds.size.x > 1.0 and world_bounds.size.y > 1.0:
		_world_min = world_bounds.position
		_world_max = world_bounds.end
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
	var nx: float = clampf((world_pos.x - _world_min.x) / maxf(_world_max.x - _world_min.x, 1.0), 0.0, 1.0)
	var ny: float = clampf((world_pos.y - _world_min.y) / maxf(_world_max.y - _world_min.y, 1.0), 0.0, 1.0)
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
