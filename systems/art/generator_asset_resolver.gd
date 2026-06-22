extends RefCounted
class_name GeneratorAssetResolver

## Optional, fully-local resolver for the LimeZu generator outputs (derivative +
## inspired). Reads the two gitignored manifests if present and maps a generator
## asset id -> output res:// path.
##
## SAFE-BY-DEFAULT: when the manifests (or the PNGs) are absent — e.g. a clean
## checkout without the licensed packs / generator runs — EVERY lookup returns ""
## so nothing the player sees ever depends on these local dev/review outputs.
##
## Priority (per pass spec): local LimeZu DERIVATIVE (licensed pixels) is preferred
## over the Hearthvale-INSPIRED original output for the same id. Callers consult
## this only as a fallback tier, after their reviewed/mapped assets.

const DERIVATIVE_MANIFEST := "res://licensed_assets/limezu/generator_manifests/limezu_derivative_manifest.json"
const INSPIRED_MANIFEST := "res://licensed_assets/limezu/generator_manifests/limezu_inspired_manifest.json"

static var _loaded: bool = false
static var _derivative: Dictionary = {}
static var _inspired: Dictionary = {}

static func reload() -> void:
	_loaded = false
	_derivative.clear()
	_inspired.clear()
	_ensure_loaded()

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_derivative = _load_entries(DERIVATIVE_MANIFEST)
	_inspired = _load_entries(INSPIRED_MANIFEST)

static func _load_entries(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var entries: Variant = (parsed as Dictionary).get("entries", {})
	return entries as Dictionary if typeof(entries) == TYPE_DICTIONARY else {}

static func _path_from(entries: Dictionary, asset_id: String) -> String:
	if not entries.has(asset_id):
		return ""
	var entry: Variant = entries[asset_id]
	if typeof(entry) != TYPE_DICTIONARY:
		return ""
	var rel: String = String((entry as Dictionary).get("output_path", "")).strip_edges()
	if rel.is_empty():
		return ""
	var full: String = rel if rel.begins_with("res://") else "res://" + rel
	return full if FileAccess.file_exists(full) else ""

static func derivative_path(asset_id: String) -> String:
	_ensure_loaded()
	return _path_from(_derivative, String(asset_id).strip_edges())

static func inspired_path(asset_id: String) -> String:
	_ensure_loaded()
	return _path_from(_inspired, String(asset_id).strip_edges())

## Derivative first, then inspired; "" when neither resolves (always safe).
static func resolve(asset_id: String) -> String:
	var derivative: String = derivative_path(asset_id)
	if not derivative.is_empty():
		return derivative
	return inspired_path(asset_id)

static func source_tier(asset_id: String) -> String:
	if not derivative_path(asset_id).is_empty():
		return "limezu_derivative"
	if not inspired_path(asset_id).is_empty():
		return "hearthvale_inspired"
	return "missing"

static func available() -> bool:
	_ensure_loaded()
	return not _derivative.is_empty() or not _inspired.is_empty()

static func derivative_count() -> int:
	_ensure_loaded()
	return _derivative.size()

static func inspired_count() -> int:
	_ensure_loaded()
	return _inspired.size()
