extends RefCounted
class_name CharacterPartLibrary

## Loads the local curated avatar parts manifest and provides texture access
## for layered character rendering. Falls back safely when the manifest or
## textures are absent (clean checkout).

const MANIFEST_PATH := "res://licensed_assets/limezu/generator_manifests/hearthvale_curated_avatar_parts_manifest.json"
const CG_ROOT := "res://licensed_assets/limezu/modern_interiors/extracted/moderninteriors-win/2_Characters/Character_Generator/"

const LAYER_ORDER := ["body", "eyes", "outfit", "hair", "accessory"]
const DEFAULT_GRID := 56  # columns in the shared sprite sheet grid (16x16 cells)

## SAFETY GATE: Set to true ONLY after Julie visually verifies the per-layer grid
## offsets match. Currently disabled because bodies are 927px (non-aligned grid)
## while hair/outfit/accessory are 896px, and per-layer idle-row positions differ.
const LAYOUT_VERIFIED := false

enum Direction { DOWN, LEFT, RIGHT, UP }

# Cached manifest data
static var _loaded := false
static var _manifest: Dictionary = {}
static var _texture_cache: Dictionary = {}

## True when the curated manifest exists and has usable parts.
static func is_available() -> bool:
	_ensure_loaded()
	return not _manifest.is_empty()

## The manifest data (empty dict when absent).
static func manifest() -> Dictionary:
	_ensure_loaded()
	return _manifest.duplicate(true)

## True when layered rendering is usable (manifest present AND layout verified).
static func layered_ready() -> bool:
	if not LAYOUT_VERIFIED:
		return false
	_ensure_loaded()
	if _manifest.is_empty():
		return false
	var starter := _manifest.get("starter_set", {}) as Dictionary
	return starter.has("bodies") and starter.has("hairstyles") and starter.has("outfits")

## True when the manifest exists but layout isn't verified yet (for editor labeling).
static func needs_layout_review() -> bool:
	_ensure_loaded()
	if _manifest.is_empty():
		return false
	var starter := _manifest.get("starter_set", {}) as Dictionary
	return starter.has("bodies") and starter.has("hairstyles") and starter.has("outfits")

## List of part ids for a given layer category (empty array when absent).
static func part_ids_for_category(category: String) -> Array:
	_ensure_loaded()
	var starter := _manifest.get("starter_set", {}) as Dictionary
	var items: Array = starter.get(category, []) as Array
	var out: Array = []
	for item in items:
		out.append(String((item as Dictionary).get("part_id", "")))
	return out

## Full entry for a part id, or empty dict.
static func part_entry(part_id: String) -> Dictionary:
	_ensure_loaded()
	var starter: Dictionary = _manifest.get("starter_set", {}) as Dictionary
	for category in starter.keys():
		var items = starter[category]
		if typeof(items) != TYPE_ARRAY:
			continue
		for i in range(items.size()):
			var item: Dictionary = items[i] as Dictionary
			if String(item.get("part_id", "")) == part_id:
				return item.duplicate(true)
	return {}

## Layer category for a part id ("body"/"hair"/"outfit"/"accessory"/"eyes"), or "".
static func category_for(part_id: String) -> String:
	_ensure_loaded()
	var starter: Dictionary = _manifest.get("starter_set", {}) as Dictionary
	for cat in starter.keys():
		var items = starter[cat]
		if typeof(items) != TYPE_ARRAY:
			continue
		for i in range(items.size()):
			var item: Dictionary = items[i] as Dictionary
			if String(item.get("part_id", "")) == part_id:
				return cat
	return ""

## Standard grid X offset for a direction band (0-based column index).
static func direction_grid_col(direction: int) -> int:
	match direction:
		Direction.DOWN:  return 0
		Direction.LEFT:  return 14
		Direction.RIGHT: return 28
		Direction.UP:    return 42
	return 0

## Standard grid row for idle frame in a direction.
static func idle_grid_row(direction: int) -> int:
	match direction:
		Direction.DOWN:  return 1
		Direction.LEFT:  return 3
		Direction.RIGHT: return 5
		Direction.UP:    return 7
	return 1

## The 16x16 region rect for a frame at (col, row) in the shared grid.
static func grid_rect(col: int, row: int) -> Rect2i:
	return Rect2i(col * 16, row * 16, 16, 16)

## Resolves the full sprite sheet texture for a part file path (null if absent).
static func resolve_texture(file_path: String) -> Texture2D:
	if file_path.is_empty():
		return null
	var cached: Variant = _texture_cache.get(file_path, null)
	if cached != null and is_instance_valid(cached):
		return cached as Texture2D
	var res_path := CG_ROOT + file_path
	if not FileAccess.file_exists(res_path):
		return null
	# Load via Image for gitignored paths
	var image := Image.new()
	var global := ProjectSettings.globalize_path(res_path)
	if image.load(global) != OK or image.is_empty():
		return null
	var tex := ImageTexture.create_from_image(image)
	if tex != null:
		_texture_cache[file_path] = tex
	return tex

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		_manifest = parsed as Dictionary

static func reload() -> void:
	_loaded = false
	_manifest.clear()
	_texture_cache.clear()
	_ensure_loaded()
