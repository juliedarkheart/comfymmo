extends RefCounted
class_name UIArtRegistry

## Optional UI art lookup for local-only Sprout UI assets. Existing panels keep
## using CozyUITheme code-drawn styles unless a local manifest explicitly maps
## a UI id to a licensed file.

const FALLBACK_PATH := "res://art/placeholders/missing.png"
const LOCAL_UI_MANIFEST_PATH := "res://licensed_assets/sprout_lands/sprout_ui_manifest.json"
const LOCAL_UI_ROOT := "res://licensed_assets/sprout_lands/"

const REQUIRED_IDS: Array[String] = [
	"panel",
	"button",
	"button_hover",
	"slot",
	"slot_selected",
	"close",
	"check",
	"cursor",
	"dialog_panel",
	"inventory_panel",
	"system_menu_panel",
	"build_menu_panel",
]

const GENERATED_ICON_FALLBACKS := {
	"close": "delete",
	"check": "build_tool",
}

static var _loaded := false
static var _active: Dictionary = {}
static var _candidates: Dictionary = {}

static func reload() -> void:
	_loaded = false
	_active.clear()
	_candidates.clear()
	_ensure_loaded()

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(LOCAL_UI_MANIFEST_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LOCAL_UI_MANIFEST_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var active_value: Variant = (parsed as Dictionary).get("active", {})
	if typeof(active_value) == TYPE_DICTIONARY:
		_active = active_value as Dictionary
	var candidate_value: Variant = (parsed as Dictionary).get("candidates", {})
	if typeof(candidate_value) == TYPE_DICTIONARY:
		_candidates = candidate_value as Dictionary

static func required_ids() -> Array[String]:
	return REQUIRED_IDS.duplicate()

static func active_count() -> int:
	_ensure_loaded()
	return _active.size()

static func candidate_count() -> int:
	_ensure_loaded()
	return _candidates.size()

static func active_source() -> String:
	return "licensed_ui" if active_count() > 0 else "cozy_code"

static func _resolve_local(value: String) -> String:
	value = value.strip_edges()
	if value.is_empty():
		return ""
	var full_path := value if value.begins_with("res://") else LOCAL_UI_ROOT + value
	return full_path if FileAccess.file_exists(full_path) else ""

static func texture_path(ui_id: String) -> String:
	_ensure_loaded()
	var normalized_id := String(ui_id).strip_edges().to_lower()
	if _active.has(normalized_id):
		var local_path := _resolve_local(String(_active[normalized_id]))
		if not local_path.is_empty():
			return local_path
	if GENERATED_ICON_FALLBACKS.has(normalized_id):
		var object_path := ObjectArtRegistry.texture_path(String(GENERATED_ICON_FALLBACKS[normalized_id]))
		if ObjectArtRegistry.source_of(object_path) != "missing":
			return object_path
	return FALLBACK_PATH

static func texture(ui_id: String) -> Texture2D:
	return load(texture_path(ui_id)) as Texture2D

static func source_of(resolved_path: String) -> String:
	if resolved_path == FALLBACK_PATH:
		return "missing"
	if resolved_path.begins_with("res://licensed_assets/"):
		return "licensed_ui"
	return "generated"

static func candidate_paths(ui_id: String) -> Array[String]:
	_ensure_loaded()
	var normalized_id := String(ui_id).strip_edges().to_lower()
	var result: Array[String] = []
	var raw: Variant = _candidates.get(normalized_id, [])
	if raw is Array:
		for entry in raw:
			var local_path := _resolve_local(String(entry))
			if not local_path.is_empty():
				result.append(local_path)
	elif raw is String:
		var single_path := _resolve_local(String(raw))
		if not single_path.is_empty():
			result.append(single_path)
	return result
