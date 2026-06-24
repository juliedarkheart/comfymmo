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

## Runtime logical-id bridge. The generator manifests are recipe-oriented
## (`crate_variant`, `carrot_stage_3`, etc.) while live renderers ask for LimeZu
## logical ids (`object.crate`, `crop.carrot`). Keep this mapping source-only and
## local-output-safe; it does not create or commit any generated PNGs.
const LOGICAL_ID_ALIASES := {
	"terrain.grass": ["mossy_path_tile", "flower_border_tile", "path_tile_variant"],
	"terrain.dirt_path": ["dirt_path_variant", "soft_path_tile", "mossy_path_tile"],
	"terrain.stone_path": ["stone_path_variant", "path_tile_variant"],
	"terrain.tilled_soil": ["tilled_soil_variant", "dry_soil_variant"],
	"object.crate": ["crate_variant", "berry_crate"],
	"object.sign": ["sign_variant", "family_notice_sign", "heart_sign"],
	"object.fence_horizontal": ["fence_variant", "ribbon_fence"],
	"object.fence_vertical": ["fence_variant", "ribbon_fence"],
	"object.fence_post": ["fence_variant", "ribbon_fence"],
	"object.flower": ["flower_patch_variant", "flower_wagon", "garden_charm_stake"],
	"object.flower2": ["flower_patch_variant", "flower_wagon", "garden_charm_stake"],
	"object.flower3": ["flower_patch_variant", "flower_wagon", "garden_charm_stake"],
	"object.tree_small": ["shrub_variant", "flower_patch_variant"],
	"object.workbench": ["workbench_variant", "cozy_workbench"],
	"crop.carrot": ["carrot_stage_3", "carrot_crop_icon"],
	"crop.carrot_stage1": ["carrot_stage_1"],
	"crop.carrot_stage_1": ["carrot_stage_1"],
	"crop.carrot_stage_2": ["carrot_stage_2"],
	"crop.carrot_stage_3": ["carrot_stage_3"],
	"ui.panel": ["panel_variant_dark", "hearth_panel_dark"],
	"ui.inventory_panel": ["panel_variant_light", "hearth_panel_soft"],
	"ui.dialogue": ["panel_variant_light", "hearth_panel_soft"],
	"ui.tooltip": ["panel_variant_light", "hearth_panel_soft"],
	"ui.slot": ["slot_variant", "cozy_slot"],
	"ui.slot_selected": ["slot_selected_variant", "cozy_slot_selected"],
	"ui.button": ["button_variant", "cozy_button"],
	"ui.button_hover": ["button_hover_variant", "cozy_button_hover"],
	"ui.button_pressed": ["button_hover_variant", "cozy_button_hover"],
	"ui.tab": ["tab_variant", "cozy_button"],
	"ui.close": ["close_button_variant", "tiny_close_button"],
	"ui.close_hover": ["close_button_variant", "tiny_close_button"],
	# Semantic HUD status icons (LimeZu-INSPIRED, drawn by category) — a day/calendar
	# and a comfort/heart token. Used so the HUD never falls back to an empty UI slot.
	"icon.day": ["family_calendar_icon", "village_note_icon"],
	"icon.comfort": ["comfort_token_icon", "creature_treat_icon"],
}

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

static func _candidate_ids(asset_id: String) -> Array[String]:
	var normalized := String(asset_id).strip_edges().to_lower()
	var ids: Array[String] = [normalized]
	if LOGICAL_ID_ALIASES.has(normalized):
		for alias in LOGICAL_ID_ALIASES[normalized]:
			ids.append(String(alias))
	return ids

## Derivative first, then inspired; "" when neither resolves (always safe).
static func resolve(asset_id: String) -> String:
	for id in _candidate_ids(asset_id):
		var derivative: String = derivative_path(id)
		if not derivative.is_empty():
			return derivative
	for id in _candidate_ids(asset_id):
		var inspired: String = inspired_path(id)
		if not inspired.is_empty():
			return inspired
	return ""

static func source_tier(asset_id: String) -> String:
	for id in _candidate_ids(asset_id):
		if not derivative_path(id).is_empty():
			return "limezu_derivative"
	for id in _candidate_ids(asset_id):
		if not inspired_path(id).is_empty():
			return "limezu_inspired"
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
