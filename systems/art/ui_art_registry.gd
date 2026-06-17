extends RefCounted
class_name UIArtRegistry

## Optional UI art lookup for local-only Sprout UI assets. Existing panels keep
## using CozyUITheme code-drawn styles unless a local manifest explicitly maps
## a UI id to a licensed file.

const FALLBACK_PATH := "res://art/placeholders/missing.png"
const LOCAL_UI_MANIFEST_PATH := "res://licensed_assets/sprout_lands/sprout_ui_manifest.json"
const LOCAL_UI_ROOT := "res://licensed_assets/sprout_lands/"

## Original, committable Hearthvale generated UI shapes (gap-fill). Resolved as a
## "generated" tier between licensed Sprout UI and the code-drawn cozy theme.
const HEARTHVALE_UI_ROOT := "res://art/generated/hearthvale/ui/"
const DEFAULT_TEXTURE_MARGIN := 8

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
static var _margins: Dictionary = {}

static func reload() -> void:
	_loaded = false
	_active.clear()
	_candidates.clear()
	_margins.clear()
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
	var margin_value: Variant = (parsed as Dictionary).get("margins", {})
	if typeof(margin_value) == TYPE_DICTIONARY:
		_margins = margin_value as Dictionary

static func required_ids() -> Array[String]:
	return REQUIRED_IDS.duplicate()

static func active_count() -> int:
	_ensure_loaded()
	return _active.size()

static func candidate_count() -> int:
	_ensure_loaded()
	return _candidates.size()

## Highest active UI tier: "licensed_ui" when a Sprout UI asset is activated,
## else "cozy_code" (the code-drawn CozyUITheme styles).
static func active_source() -> String:
	return "licensed_ui" if active_count() > 0 else "cozy_code"

static func _resolve_local(value: String) -> String:
	value = value.strip_edges()
	if value.is_empty():
		return ""
	var full_path := value if value.begins_with("res://") else LOCAL_UI_ROOT + value
	return full_path if FileAccess.file_exists(full_path) else ""

## Resolution order: 1. activated licensed Sprout UI -> 2. generated Hearthvale UI
## shape -> 3. generated icon stand-in -> 4. missing placeholder. The cozy
## code-drawn theme is the runtime default and is NOT a file (see CozyUITheme).
static func texture_path(ui_id: String) -> String:
	_ensure_loaded()
	var normalized_id := String(ui_id).strip_edges().to_lower()
	if _active.has(normalized_id):
		var local_path := _resolve_local(String(_active[normalized_id]))
		if not local_path.is_empty():
			return local_path
	var generated := HEARTHVALE_UI_ROOT + normalized_id + ".png"
	if FileAccess.file_exists(generated):
		return generated
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
		return "licensed_modified" if resolved_path.contains("/modified/") else "licensed_ui"
	return "generated"

## True when a licensed Sprout UI texture is active for this id — the only case
## where CozyUITheme swaps its code-drawn box for a nine-patch texture stylebox.
static func has_licensed(ui_id: String) -> bool:
	var path := texture_path(ui_id)
	return source_of(path) in ["licensed_ui", "licensed_modified"]

static func _margin_for(ui_id: String) -> int:
	_ensure_loaded()
	if _margins.has(ui_id):
		return int(_margins[ui_id])
	if _margins.has("_default"):
		return int(_margins["_default"])
	return DEFAULT_TEXTURE_MARGIN

## A nine-patch StyleBoxTexture for an activated licensed Sprout UI id, or null.
## Null means "no licensed art — keep the cozy code-drawn style." content_margin
## keeps text/children off the textured border so labels stay readable.
static func texture_stylebox(ui_id: String, content_margin: int = 10) -> StyleBoxTexture:
	if not has_licensed(ui_id):
		return null
	var tex := load(texture_path(ui_id)) as Texture2D
	if tex == null:
		return null
	var box := StyleBoxTexture.new()
	box.texture = tex
	var margin := _margin_for(ui_id)
	box.set_texture_margin_all(margin)
	box.set_content_margin_all(content_margin)
	return box

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
