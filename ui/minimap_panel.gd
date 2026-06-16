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
	CozyUITheme.apply_hud_panel($Panel)
	CozyUITheme.apply_secondary_label($Panel/Margin/Title, 12, true)
	_map_rect.draw.connect(_draw_map)

## Static landmarks + plot centers in world space, supplied once by the
## controller (so the minimap doesn't reach into world systems itself).
func setup(landmarks: Array, plot_centers: Dictionary, world_bounds: Rect2 = Rect2()) -> void:
	_landmarks = landmarks
	_plots.clear()
	for plot_id in plot_centers.keys():
		var raw: Variant = plot_centers[plot_id]
		if raw is Dictionary:
			_plots[plot_id] = {
				"center": (raw as Dictionary).get("center", Vector2.ZERO),
				"state": "unclaimed",
				"biome": String((raw as Dictionary).get("biome", "meadow")),
			}
		else:
			_plots[plot_id] = {"center": raw, "state": "unclaimed", "biome": "meadow"}
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

func _clamped_rect(rect: Rect2) -> Rect2:
	return rect.intersection(Rect2(Vector2.ZERO, _map_rect.size))

func _draw_map() -> void:
	var size: Vector2 = _map_rect.size
	_map_rect.draw_rect(Rect2(Vector2.ZERO, size), Color("#d7c58f"))
	_map_rect.draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), Color("#7da964"))
	# Region bands (schematic): town + forest stripes on the right.
	var town_band: Rect2 = _clamped_rect(Rect2(_world_to_map(Vector2(1150, -200)), Vector2(18, size.y)))
	if town_band.size.x > 0.0 and town_band.size.y > 0.0:
		var town_color: Color = BiomeRegistry.minimap_tint("town")
		town_color.a = 0.55
		_map_rect.draw_rect(town_band, town_color)
	var forest_band: Rect2 = _clamped_rect(Rect2(_world_to_map(Vector2(2550, -200)), Vector2(size.x, size.y)))
	if forest_band.size.x > 0.0 and forest_band.size.y > 0.0:
		var forest_color: Color = BiomeRegistry.minimap_tint("forest")
		forest_color.a = 0.45
		_map_rect.draw_rect(forest_band, forest_color)
	# Plot squares, tinted by ownership.
	for plot_id in _plots.keys():
		var plot: Dictionary = _plots[plot_id]
		var center: Vector2 = _world_to_map(plot["center"])
		var color: Color = BiomeRegistry.minimap_tint(String(plot.get("biome", "meadow")))
		color.a = 0.92
		var border: Color = Color("#fff0a8")
		match String(plot.get("state", "unclaimed")):
			"owned": border = Color("#f8de9a")
			"friend": border = Color("#9fc4e8")
			"other": border = Color("#d98473")
		var plot_rect := Rect2(center - Vector2(5, 5), Vector2(10, 10))
		_map_rect.draw_rect(plot_rect, color)
		_map_rect.draw_rect(plot_rect, border, false, 1.5)
		if _admin_debug:
			_map_rect.draw_rect(Rect2(center - Vector2(6, 6), Vector2(12, 12)), Color(1, 1, 1, 0.6), false, 1.0)
	# Landmark dots (NPCs, services).
	for landmark in _landmarks:
		var lm: Dictionary = landmark
		_map_rect.draw_circle(_world_to_map(lm["pos"]), 3.0, lm.get("color", Color.WHITE))
	# Player marker.
	var p: Vector2 = _world_to_map(_player_pos)
	_map_rect.draw_circle(p, 5.0, Color("#3e2e23"))
	_map_rect.draw_circle(p, 3.6, Color("#ffe066"))
	_map_rect.draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), Color("#4a3420"), false, 2.0)
