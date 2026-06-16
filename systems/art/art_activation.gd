extends RefCounted
class_name ArtActivation

## Manifest-driven activation for external art. Imported/normalized derivatives are
## NOT used in-game just because a file exists — they must be explicitly listed in
## `art/active_art_manifest.json`. This guarantees no blind full-pack replacement:
## an unreviewed pack sits in art/external/ + art/review/ until a human adds it to
## the manifest. The art registries consult this before falling back to the
## generated placeholder, then to missing.png.
##
## Manifest shape (keys are paths relative to res://art/, values point at the
## activated derivative, also relative to res://art/ or a full res:// path):
##
##   { "version": 1, "active": {
##       "ui/icons/wood.png": "generated/from_external/active/ui/icons/wood.png"
##   } }
##
## An empty `active` map (the shipped default) means everything uses the cozy
## generated placeholders — the safe state.

const MANIFEST_PATH := "res://art/active_art_manifest.json"
const ART_ROOT := "res://art/"

static var _cache: Dictionary = {}
static var _loaded: bool = false

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_cache = {}
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var file: FileAccess = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		var active: Variant = (parsed as Dictionary).get("active", {})
		if typeof(active) == TYPE_DICTIONARY:
			_cache = active as Dictionary

## Force a reload (e.g. after editing the manifest in the editor).
static func reload() -> void:
	_loaded = false
	_ensure_loaded()

## How many art ids are currently activated from external derivatives.
static func active_count() -> int:
	_ensure_loaded()
	return _cache.size()

## The activated override (full res:// path) for a mapped generated art path, or
## "" if that id is not activated or the derivative file is missing. Fails safe.
static func override_for(mapped_path: String) -> String:
	_ensure_loaded()
	if not mapped_path.begins_with(ART_ROOT):
		return ""
	var rel: String = mapped_path.substr(ART_ROOT.length())
	if not _cache.has(rel):
		return ""
	var value: String = String(_cache[rel]).strip_edges()
	if value.is_empty():
		return ""
	var full: String = value if value.begins_with("res://") else ART_ROOT + value
	return full if FileAccess.file_exists(full) else ""
