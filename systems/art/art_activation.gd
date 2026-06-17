extends RefCounted
class_name ArtActivation

## Manifest-driven activation for non-generated art. Two manifests, checked in
## priority order so a clean checkout (no licensed assets) still works:
##
##   1. LOCAL LICENSED  — res://licensed_assets/sprout_lands/sprout_active_manifest.json
##      Premium / non-redistributable packs (Sprout Lands by Cup Nooble). This
##      file AND the assets it points at are gitignored; absent on a clean clone.
##      Values are relative to the pack's normalized/ folder (or a full res://).
##   2. REDISTRIBUTABLE — res://art/active_art_manifest.json (tracked)
##      CC0/CC-BY derivatives under art/generated/from_external/active/...
##
## Full resolution order (in the registries): licensed -> redistributable ->
## generated placeholder -> missing.png. A derivative is only used when listed in
## a manifest — never just because a file exists. Empty/absent manifests => the
## cozy generated placeholders, which is the safe default.

const REDIST_MANIFEST_PATH := "res://art/active_art_manifest.json"
const LICENSED_MANIFEST_PATH := "res://licensed_assets/sprout_lands/sprout_active_manifest.json"
const LICENSED_NORMALIZED_ROOT := "res://licensed_assets/sprout_lands/normalized/"
const ART_ROOT := "res://art/"

static var _redist: Dictionary = {}
static var _licensed: Dictionary = {}
static var _loaded: bool = false

static func _load_active_map(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		var active: Variant = (parsed as Dictionary).get("active", {})
		if typeof(active) == TYPE_DICTIONARY:
			return active as Dictionary
	return {}

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_redist = _load_active_map(REDIST_MANIFEST_PATH)
	_licensed = _load_active_map(LICENSED_MANIFEST_PATH)

static func reload() -> void:
	_loaded = false
	_ensure_loaded()

## Redistributable (tracked) activated entries.
static func active_count() -> int:
	_ensure_loaded()
	return _redist.size()

## Local licensed (gitignored) activated entries. 0 on a clean checkout.
static func licensed_count() -> int:
	_ensure_loaded()
	return _licensed.size()

static func _resolve_value(value: String, licensed: bool) -> String:
	value = value.strip_edges()
	if value.is_empty():
		return ""
	var full: String
	if value.begins_with("res://"):
		full = value
	elif licensed:
		full = LICENSED_NORMALIZED_ROOT + value
	else:
		full = ART_ROOT + value
	return full if FileAccess.file_exists(full) else ""

## Activated override (full res:// path) for a mapped generated art path, or "".
## Local licensed assets win over redistributable ones. Fails safe (missing file
## or un-activated id -> "").
static func override_for(mapped_path: String, allow_licensed: bool = true) -> String:
	_ensure_loaded()
	if not mapped_path.begins_with(ART_ROOT):
		return ""
	var rel: String = mapped_path.substr(ART_ROOT.length())
	if allow_licensed and _licensed.has(rel):
		var licensed_path: String = _resolve_value(String(_licensed[rel]), true)
		if not licensed_path.is_empty():
			return licensed_path
	if _redist.has(rel):
		var redist_path: String = _resolve_value(String(_redist[rel]), false)
		if not redist_path.is_empty():
			return redist_path
	return ""
