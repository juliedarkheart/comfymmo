extends RefCounted
class_name GeneratorCharacterRegistry

## LimeZu GENERATOR character/portrait provider (local-only, fallback-safe).
##
## The LimeZu **Farmer Generator** and **Character Generator 2.0** are GUI tools
## (installers live under `licensed_assets/limezu/*/original/`). They cannot run
## headlessly, so this registry never generates art itself — it reads a LOCAL,
## gitignored manifest written by `tools/art/limezu_generator_catalog.py` after the
## user exports sheets/portraits into `licensed_assets/limezu/generator_outputs/`.
##
## It resolves a CHARACTER ID to a portrait crop and/or sprite-sheet `Texture2D`. A clean
## checkout (no outputs, no manifest) must NOT crash: every lookup fails safe to null so
## callers can show a framed placeholder instead. All generated media stays local-only
## under gitignored `licensed_assets/limezu/`; only this code + the schema/docs are
## commit-safe. See docs/limezu_generator_workflow.md.

const LIMEZU_ROOT := "res://licensed_assets/limezu/"
const MANIFEST_PATH := "res://licensed_assets/limezu/generator_manifests/limezu_generator_manifest.json"

static var _loaded := false
static var _characters: Dictionary = {}
static var _portrait_cache: Dictionary = {}

static func reload() -> void:
	_loaded = false
	_characters.clear()
	_portrait_cache.clear()
	_ensure_loaded()

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var chars: Variant = (parsed as Dictionary).get("characters", {})
	if typeof(chars) == TYPE_DICTIONARY:
		_characters = chars as Dictionary

## True when at least one generator character is cataloged locally. False on a clean
## checkout, so callers fall back to placeholders.
static func is_available() -> bool:
	_ensure_loaded()
	return not _characters.is_empty()

static func has_character(character_id: String) -> bool:
	_ensure_loaded()
	return _characters.has(character_id)

static func list_characters() -> Array[String]:
	_ensure_loaded()
	var ids: Array[String] = []
	for key in _characters.keys():
		ids.append(String(key))
	ids.sort()
	return ids

static func _entry(character_id: String) -> Dictionary:
	_ensure_loaded()
	var value: Variant = _characters.get(character_id, {})
	return value as Dictionary if typeof(value) == TYPE_DICTIONARY else {}

static func _resolve_path(rel: String) -> String:
	rel = rel.strip_edges()
	if rel.is_empty():
		return ""
	var full := rel if rel.begins_with("res://") else LIMEZU_ROOT + rel
	return full if FileAccess.file_exists(full) else ""

## Portrait Texture2D (cropped to portrait_rect) for a character, or null when no entry /
## file / valid rect exists. Cached. Callers should treat null as "use placeholder frame".
static func portrait_texture(character_id: String) -> Texture2D:
	_ensure_loaded()
	if _portrait_cache.has(character_id):
		return _portrait_cache[character_id]
	var result: Texture2D = null
	var entry := _entry(character_id)
	var path := _resolve_path(String(entry.get("portrait_sheet", "")))
	if not path.is_empty():
		var sheet: Texture2D = load(path) as Texture2D
		if sheet != null:
			var rect_arr: Array = entry.get("portrait_rect", [])
			if rect_arr.size() == 4 and int(rect_arr[2]) > 0 and int(rect_arr[3]) > 0:
				var atlas := AtlasTexture.new()
				atlas.atlas = sheet
				atlas.region = Rect2(int(rect_arr[0]), int(rect_arr[1]), int(rect_arr[2]), int(rect_arr[3]))
				result = atlas
			else:
				result = sheet
	_portrait_cache[character_id] = result
	return result

## Sprite-sheet Texture2D for a character (full sheet; callers slice frames via the
## manifest's idle/walk rects), or null when unavailable.
static func sprite_sheet_texture(character_id: String) -> Texture2D:
	var entry := _entry(character_id)
	var path := _resolve_path(String(entry.get("sprite_sheet", "")))
	return load(path) as Texture2D if not path.is_empty() else null

static func idle_frame_rect(character_id: String) -> Rect2i:
	var entry := _entry(character_id)
	var arr: Array = entry.get("idle_frame_rect", [])
	if arr.size() == 4:
		return Rect2i(int(arr[0]), int(arr[1]), int(arr[2]), int(arr[3]))
	return Rect2i()

static func missing_reason() -> String:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return "No generator manifest yet — run the LimeZu generators (GUI) then tools/art/limezu_generator_catalog.py. See docs/limezu_generator_workflow.md."
	_ensure_loaded()
	if _characters.is_empty():
		return "Generator manifest present but empty — drop exported sheets into licensed_assets/limezu/generator_outputs/ and re-run the catalog."
	return ""

# --- ORIGINAL Hearthvale generated assets (procedural, local-only, gitignored) ----------
# Detection only: these PNGs are local/gitignored until a commit policy exists, so a clean
# checkout has none and everything below fails safe to 0/empty (never crashes the boot).
const HEARTHVALE_GENERATED_DIR := "res://licensed_assets/limezu/generator_outputs/hearthvale_generated/"

## Count of local original Hearthvale generated PNGs across category subfolders. 0 on a clean
## checkout. Gameplay must NOT depend on this — it is for preview/catalog/tooling only.
static func generated_local_count() -> int:
	var dir: DirAccess = DirAccess.open(HEARTHVALE_GENERATED_DIR)
	if dir == null:
		return 0
	var total: int = 0
	for sub in dir.get_directories():
		if sub == "review":
			continue
		var sub_dir: DirAccess = DirAccess.open(HEARTHVALE_GENERATED_DIR + sub)
		if sub_dir == null:
			continue
		for f in sub_dir.get_files():
			if f.to_lower().ends_with(".png"):
				total += 1
	return total

static func has_generated_local_assets() -> bool:
	return generated_local_count() > 0
