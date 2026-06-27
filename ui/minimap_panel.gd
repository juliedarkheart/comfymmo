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
var _landmarks: Array = []             # feature dictionaries: dots, rects, tile strips
var _admin_debug: bool = false
# Truth mode (LimeZu live): draw ONLY the real live features the controller supplies +
# the player. The schematic town/forest bands and broad-overworld plot squares are phantom
# in the curated slice, so they are suppressed unless admin/debug is on.
var _truth_mode: bool = false

@onready var _map_rect: Control = $Panel/Margin/MapRect

func _ready() -> void:
	visible = true
	CozyUITheme.apply_hud_panel($Panel)
	CozyUITheme.apply_secondary_label($Panel/Margin/Title, 12, true)
	_map_rect.draw.connect(_draw_map)

## Static landmarks + plot centers in world space, supplied once by the
## controller (so the minimap doesn't reach into world systems itself).
func setup(landmarks: Array, plot_centers: Dictionary, world_bounds: Rect2 = Rect2()) -> void:
	_landmarks = landmarks.duplicate(true)
	_landmarks.sort_custom(Callable(self, "_feature_priority_less"))
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

func _feature_priority_less(a: Variant, b: Variant) -> bool:
	var a_dict: Dictionary = a if a is Dictionary else {}
	var b_dict: Dictionary = b if b is Dictionary else {}
	return int(a_dict.get("priority", 0)) < int(b_dict.get("priority", 0))

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

## Truth mode: in the live LimeZu slice, suppress the phantom town/forest bands + broad-
## overworld plot squares and draw only the supplied real features + the player.
func set_truth_mode(enabled: bool) -> void:
	_truth_mode = enabled
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

func _world_rect_to_map(rect: Rect2) -> Rect2:
	var a: Vector2 = _world_to_map(rect.position)
	var b: Vector2 = _world_to_map(rect.end)
	var pos: Vector2 = a.min(b)
	var end: Vector2 = a.max(b)
	return _clamped_rect(Rect2(pos, end - pos))

func _feature_color(feature: Dictionary, fallback: Color = Color.WHITE) -> Color:
	var raw: Variant = feature.get("color", fallback)
	if raw is Color:
		return raw as Color
	if raw is String:
		return Color(String(raw))
	return fallback

func _draw_feature_rect(feature: Dictionary, fill_color: Color, border_color: Color, min_px: Vector2 = Vector2(3, 3)) -> void:
	var rect: Rect2 = feature.get("rect_world", Rect2()) as Rect2
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var map_rect: Rect2 = _world_rect_to_map(rect)
	if map_rect.size.x <= 0.0 or map_rect.size.y <= 0.0:
		return
	if map_rect.size.x < min_px.x:
		map_rect.position.x -= (min_px.x - map_rect.size.x) * 0.5
		map_rect.size.x = min_px.x
	if map_rect.size.y < min_px.y:
		map_rect.position.y -= (min_px.y - map_rect.size.y) * 0.5
		map_rect.size.y = min_px.y
	map_rect = _clamped_rect(map_rect)
	_map_rect.draw_rect(map_rect, fill_color)
	_map_rect.draw_rect(map_rect, border_color, false, 1.25)

func _draw_feature_tile_rects(feature: Dictionary, fill_color: Color, border_color: Color) -> void:
	var rects: Array = feature.get("tile_rects_world", []) as Array
	for rect_variant in rects:
		var rect: Rect2 = rect_variant as Rect2
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		var map_rect: Rect2 = _world_rect_to_map(rect)
		if map_rect.size.x <= 0.0 or map_rect.size.y <= 0.0:
			continue
		map_rect.size = map_rect.size.max(Vector2(2, 2))
		_map_rect.draw_rect(map_rect, fill_color)
		_map_rect.draw_rect(map_rect, border_color, false, 0.75)

func _draw_feature_dot(feature: Dictionary, radius: float, color: Color, border_color: Color = Color.TRANSPARENT) -> void:
	if not feature.has("pos"):
		return
	var center: Vector2 = _world_to_map(feature["pos"] as Vector2)
	if border_color.a > 0.0:
		_map_rect.draw_circle(center, radius + 1.1, border_color)
	_map_rect.draw_circle(center, radius, color)

func _draw_feature(feature: Dictionary) -> void:
	var kind: String = String(feature.get("kind", "dot"))
	var color: Color = _feature_color(feature, Color.WHITE)
	var fill := color
	fill.a = float(feature.get("alpha", fill.a))
	var border := color.lightened(0.25)
	border.a = maxf(fill.a, 0.85)
	match kind:
		"building_footprint":
			fill.a = minf(fill.a, 0.72)
			_draw_feature_rect(feature, fill, border, Vector2(6, 5))
		"farm_patch":
			fill.a = minf(fill.a, 0.78)
			_draw_feature_rect(feature, fill, border, Vector2(5, 5))
		"path_shape":
			fill.a = minf(fill.a, 0.62)
			_draw_feature_tile_rects(feature, fill, border.darkened(0.12))
		"fence_line":
			fill.a = minf(fill.a, 0.78)
			_draw_feature_tile_rects(feature, fill, border)
		"tree_dot":
			_draw_feature_dot(feature, 2.0, color, Color(0.1, 0.18, 0.09, 0.45))
		"npc_dot":
			_draw_feature_dot(feature, 3.2, color, Color("#3e2e23"))
		"sign_dot":
			_draw_feature_dot(feature, 2.6, color, Color("#4a3420"))
		"placed_object_dot":
			_draw_feature_dot(feature, 2.4, color, Color("#4a3420"))
		_:
			_draw_feature_dot(feature, 3.0, color)

func _draw_map() -> void:
	var size: Vector2 = _map_rect.size
	_map_rect.draw_rect(Rect2(Vector2.ZERO, size), Color("#d7c58f"))
	_map_rect.draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), Color("#5e8a4c"))
	# Schematic bands + broad-overworld plot squares are phantom in the curated LimeZu slice;
	# only draw them outside truth mode (or in admin/debug, where the old plan is useful).
	var show_schematic: bool = (not _truth_mode) or _admin_debug
	if show_schematic:
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
	# Plot squares, tinted by ownership (phantom in the slice -> schematic/debug only).
	for plot_id in (_plots.keys() if show_schematic else []):
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
	# Truth-mode features are real live objects/terrain supplied by the controller/map.
	for landmark in _landmarks:
		var lm: Dictionary = landmark
		_draw_feature(lm)
	# Player marker.
	var p: Vector2 = _world_to_map(_player_pos)
	_map_rect.draw_circle(p, 5.0, Color("#3e2e23"))
	_map_rect.draw_circle(p, 4.0, Color("#ffe066"))
	_map_rect.draw_circle(p, 4.8, Color(1, 0.88, 0.4, 0.25))
	_map_rect.draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), Color("#4a3420"), false, 2.0)
