extends RefCounted
class_name WorldProjection

## Visual projection helper. Gameplay still owns the logical tile grid; this
## helper only describes how a tile should be drawn/picked in a visual mode.

const MODE_ISO_64X32 := "iso_64x32"
const MODE_SPROUT_TOPDOWN := "sprout_topdown"
const MODE_TOPDOWN_16 := "topdown_16"
const MODE_TOPDOWN_32 := "topdown_32"

const DEFAULT_MODE := MODE_SPROUT_TOPDOWN
const LEGACY_MODE := MODE_ISO_64X32

static func supported_modes() -> Array[String]:
	return [MODE_ISO_64X32, MODE_SPROUT_TOPDOWN, MODE_TOPDOWN_16, MODE_TOPDOWN_32]

static func normalize_mode(mode: String) -> String:
	var normalized := String(mode).strip_edges().to_lower()
	if supported_modes().has(normalized):
		return normalized
	return DEFAULT_MODE

static func is_sprout_compatible(mode: String) -> bool:
	return normalize_mode(mode) in [MODE_SPROUT_TOPDOWN, MODE_TOPDOWN_16, MODE_TOPDOWN_32]

static func is_legacy_mode(mode: String) -> bool:
	return normalize_mode(mode) == MODE_ISO_64X32

static func is_primary_mode(mode: String) -> bool:
	return normalize_mode(mode) == DEFAULT_MODE

static func tile_size(mode: String = DEFAULT_MODE) -> Vector2i:
	match normalize_mode(mode):
		MODE_TOPDOWN_16:
			return Vector2i(16, 16)
		MODE_SPROUT_TOPDOWN, MODE_TOPDOWN_32:
			return Vector2i(32, 32)
		_:
			return Vector2i(64, 32)

static func sprite_canvas_size(mode: String = DEFAULT_MODE) -> Vector2i:
	match normalize_mode(mode):
		MODE_TOPDOWN_16:
			return Vector2i(16, 16)
		MODE_SPROUT_TOPDOWN, MODE_TOPDOWN_32:
			return Vector2i(32, 32)
		_:
			return Vector2i(64, 48)

static func tile_to_world(tile: Vector2i, mode: String = DEFAULT_MODE) -> Vector2:
	var safe_mode := normalize_mode(mode)
	var size := tile_size(safe_mode)
	if safe_mode == MODE_ISO_64X32:
		return IsoMapHelpers.grid_to_world(tile, size.x, size.y)
	return Vector2(tile.x * size.x, tile.y * size.y)

static func world_to_tile(position: Vector2, mode: String = DEFAULT_MODE) -> Vector2i:
	var safe_mode := normalize_mode(mode)
	var size := tile_size(safe_mode)
	if safe_mode == MODE_ISO_64X32:
		return IsoMapHelpers.world_to_grid(position, size.x, size.y)
	return Vector2i(roundi(position.x / float(size.x)), roundi(position.y / float(size.y)))

static func screen_to_tile(position: Vector2, mode: String = DEFAULT_MODE) -> Vector2i:
	return world_to_tile(position, mode)

static func tile_to_screen(tile: Vector2i, mode: String = DEFAULT_MODE) -> Vector2:
	return tile_to_world(tile, mode)

static func sprite_scale(mode: String = DEFAULT_MODE) -> Vector2:
	match normalize_mode(mode):
		MODE_SPROUT_TOPDOWN, MODE_TOPDOWN_16:
			return Vector2.ONE
		MODE_TOPDOWN_32:
			return Vector2.ONE
		_:
			return Vector2.ONE

static func pivot_anchor(mode: String = DEFAULT_MODE) -> Vector2:
	if is_sprout_compatible(mode):
		return Vector2(0.5, 0.5)
	return Vector2(0.5, 0.5)

static func y_sort_origin(mode: String = DEFAULT_MODE) -> float:
	if is_sprout_compatible(mode):
		return float(tile_size(mode).y) * 0.5
	return 0.0

static func z_index_for_tile(tile: Vector2i, mode: String = DEFAULT_MODE) -> int:
	if is_sprout_compatible(mode):
		return tile.y
	return tile.x + tile.y

static func tile_polygon(mode: String = DEFAULT_MODE, inset: float = 0.0) -> PackedVector2Array:
	var safe_mode := normalize_mode(mode)
	var size := tile_size(safe_mode)
	if safe_mode == MODE_ISO_64X32:
		var iso_w: int = maxi(2, int(size.x - inset * 2.0))
		var iso_h: int = maxi(2, int(size.y - inset * 2.0))
		return IsoMapHelpers.tile_diamond(iso_w, iso_h)
	var hx: float = maxf(float(size.x) * 0.5 - inset, 1.0)
	var hy: float = maxf(float(size.y) * 0.5 - inset, 1.0)
	return PackedVector2Array([
		Vector2(-hx, -hy),
		Vector2(hx, -hy),
		Vector2(hx, hy),
		Vector2(-hx, hy),
	])

static func visual_hints(mode: String = DEFAULT_MODE) -> Dictionary:
	var safe_mode := normalize_mode(mode)
	return {
		"mode": safe_mode,
		"primary": is_primary_mode(safe_mode),
		"legacy": is_legacy_mode(safe_mode),
		"tile_size": tile_size(safe_mode),
		"sprite_canvas_size": sprite_canvas_size(safe_mode),
		"sprite_scale": sprite_scale(safe_mode),
		"pivot_anchor": pivot_anchor(safe_mode),
		"y_sort_origin": y_sort_origin(safe_mode),
		"sprout_compatible": is_sprout_compatible(safe_mode),
	}
