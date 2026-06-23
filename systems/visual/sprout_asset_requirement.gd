extends RefCounted
class_name SproutAssetRequirement

## Optional Sprout readiness report for reference/fallback visuals.
##
## The cozy top-down presentation is designed around the licensed Sprout Lands pack
## (Cup Nooble) which lives local-only under gitignored licensed_assets/. It is no
## longer required for runtime boot: missing/corrupt Sprout should only reduce visual
## quality or reference coverage, while LimeZu/generated/procedural fallbacks keep the
## game playable. See systems/visual/live_visual_policy.gd and docs/world_art_direction.md.

## Kept as a discoverable policy flag for validation and reports.
const REQUIRED := false

const LICENSED_MANIFEST_PATH := "res://licensed_assets/sprout_lands/sprout_active_manifest.json"
const UI_MANIFEST_PATH := "res://licensed_assets/sprout_lands/sprout_ui_manifest.json"

## Representative ids that MUST resolve to a Sprout source (licensed /
## licensed_modified / licensed_ui) once the pack is installed AND activated, so the
## check fails if the manifests are present but point at the wrong/missing files.
const REQUIRED_TERRAIN_IDS: Array[String] = ["meadow", "water", "creek"]
const REQUIRED_OBJECT_IDS: Array[String] = [
	ContentIds.PLACEABLE_WORKBENCH,
	ContentIds.PLACEABLE_SIGNPOST,
]
const REQUIRED_UI_IDS: Array[String] = ["panel", "button", "slot"]

static func _manifest_active(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var active: Variant = (parsed as Dictionary).get("active", {})
	return active as Dictionary if typeof(active) == TYPE_DICTIONARY else {}

## Full check. Reloads the activation registries first so a freshly installed (or
## removed) pack is reflected immediately, then returns:
##   { ok: bool, missing: Array[String], summary: String }
static func check() -> Dictionary:
	ArtActivation.reload()
	UIArtRegistry.reload()
	var missing: Array[String] = []

	# 1. The two local manifests must exist.
	if not FileAccess.file_exists(LICENSED_MANIFEST_PATH):
		missing.append("Sprout activation manifest (sprout_active_manifest.json)")
	if not FileAccess.file_exists(UI_MANIFEST_PATH):
		missing.append("Sprout UI manifest (sprout_ui_manifest.json)")

	# 2. Every file a present manifest maps must actually exist on disk.
	for key_variant in _manifest_active(LICENSED_MANIFEST_PATH).keys():
		var rel: String = String(_manifest_active(LICENSED_MANIFEST_PATH)[key_variant]).strip_edges()
		if rel.is_empty():
			continue
		var full: String = rel if rel.begins_with("res://") else ArtActivation.LICENSED_NORMALIZED_ROOT + rel
		if not FileAccess.file_exists(full):
			missing.append("Sprout asset file: %s" % full)
	for ui_key_variant in _manifest_active(UI_MANIFEST_PATH).keys():
		var ui_rel: String = String(_manifest_active(UI_MANIFEST_PATH)[ui_key_variant]).strip_edges()
		if ui_rel.is_empty():
			continue
		var ui_full: String = ui_rel if ui_rel.begins_with("res://") else UIArtRegistry.LOCAL_UI_ROOT + ui_rel
		if not FileAccess.file_exists(ui_full):
			missing.append("Sprout UI file: %s" % ui_full)

	# 3. The pack must actually WIN through the registries — being present is not
	#    enough; a representative terrain/object/UI id has to resolve to Sprout.
	for terrain_id in REQUIRED_TERRAIN_IDS:
		var terrain_src: String = TerrainArtRegistry.source_of(
			TerrainArtRegistry.texture_path(terrain_id, WorldProjection.MODE_SPROUT_TOPDOWN, true)
		)
		if terrain_src != "licensed" and terrain_src != "licensed_modified":
			missing.append("Active Sprout terrain '%s' (resolved: %s)" % [terrain_id, terrain_src])
	for object_id in REQUIRED_OBJECT_IDS:
		var object_src: String = ObjectArtRegistry.source_of(ObjectArtRegistry.texture_path(object_id, true))
		if object_src != "licensed" and object_src != "licensed_modified":
			missing.append("Active Sprout object '%s' (resolved: %s)" % [object_id, object_src])
	for ui_id in REQUIRED_UI_IDS:
		if not UIArtRegistry.has_licensed(ui_id, true):
			missing.append("Active Sprout UI '%s'" % ui_id)

	var ok: bool = missing.is_empty()
	return {
		"ok": ok,
		"missing": missing,
		"summary": "Sprout assets installed and active" if ok
			else "Missing %d optional Sprout asset(s); using other visual fallbacks" % missing.size(),
	}

static func is_satisfied() -> bool:
	return bool(check()["ok"])

## True when the pack appears installed at all (manifest present). Lets validation
## stay green on a clean CI checkout (no pack) while still proving the gate is wired.
static func pack_present() -> bool:
	return FileAccess.file_exists(LICENSED_MANIFEST_PATH)

static func describe_missing() -> String:
	var result: Dictionary = check()
	if bool(result["ok"]):
		return "All optional Sprout assets are installed and active."
	var lines: Array[String] = []
	for item in result["missing"] as Array:
		lines.append("· %s" % String(item))
	return "\n".join(lines)
