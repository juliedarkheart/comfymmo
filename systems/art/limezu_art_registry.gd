extends RefCounted
class_name LimeZuArtRegistry

## LimeZu licensed art provider (preferred live visual provider when available).
##
## LimeZu (Modern Farm/UI/Exteriors/Interiors/Office, Fungus Cave, RPG-Arsenal) is
## the preferred local visual ecosystem for this branch. This registry resolves
## LOGICAL ids (e.g. "terrain.grass", "ui.panel") to local LimeZu derivatives through a
## gitignored activation manifest, exactly like Sprout's ArtActivation but keyed by
## logical id and kept fully separate from the optional Sprout comparison provider.
##
## All LimeZu media stays local-only under gitignored licensed_assets/limezu/. A clean
## checkout with no LimeZu pack must NOT crash: every lookup fails safe, and live boot
## falls back to committed generated/procedural visuals. Generate/refresh the local
## manifest + candidates with: python tools/art/limezu_integrate.py --all

const PROVIDER_ID := "limezu"
const LIMEZU_ROOT := "res://licensed_assets/limezu/"
const ACTIVE_MANIFEST_PATH := "res://licensed_assets/limezu/limezu_active_manifest.json"
const FALLBACK_PATH := "res://art/placeholders/missing.png"

const READINESS_FULL_LIVE_SLICE := "full_live_slice_ready"
const READINESS_PARTIAL_USABLE := "partial_usable"
const READINESS_EXTRACTED_PACKS_PRESENT := "extracted_packs_present"
const READINESS_ABSENT := "absent"

const PACK_IDS: Array[String] = [
	"modern_farm",
	"modern_ui",
	"modern_exteriors",
	"modern_interiors",
	"modern_office",
	"fungus_cave",
	"rpg_arsenal",
]

const LIVE_REQUIRED_IDS: Array[String] = [
	"terrain.grass",
	"terrain.dirt_path",
	"terrain.tilled_soil",
	"object.barn",
	"object.tree",
	"object.fence_horizontal",
	"crop.carrot",
	"animal.chicken",
	"character.farmer_idle",
	"ui.panel",
	"ui.slot",
]

const RAW_PACK_FALLBACKS := {
	"terrain.dirt_path": {
		"path": "modern_exteriors/extracted/modernexteriors-win/Modern_Exteriors_16x16/ME_Theme_Sorter_16x16/1_Terrains_and_Fences_Singles_16x16/ME_Singles_Terrains_and_Fences_16x16_Props_Dirt_18.png",
	},
	"terrain.tilled_soil": {
		"path": "modern_farm/extracted/16x16/Single_Files_16x16/0_Complete_Tileset_Singles_16x16/Soil_Wet_1_16x16.png",
	},
	"object.barn": {
		"path": "modern_farm/extracted/16x16/Single_Files_16x16/0_Complete_Tileset_Singles_16x16/Barn_Small_16x16.png",
	},
	"object.tree": {
		"path": "modern_farm/extracted/16x16/Single_Files_16x16/0_Complete_Tileset_Singles_16x16/Fruit_Tree_Apple_Ripe_16x16.png",
	},
	"object.tree_small": {
		"path": "modern_farm/extracted/16x16/Single_Files_16x16/0_Complete_Tileset_Singles_16x16/Fruit_Tree_Small_Apple_16x16.png",
	},
	"object.fence_horizontal": {
		"path": "modern_farm/extracted/16x16/Single_Files_16x16/0_Complete_Tileset_Singles_16x16/Wooden_Fence_Type_1_Brown_1_16x16.png",
	},
	"object.fence_vertical": {
		"path": "modern_farm/extracted/16x16/Single_Files_16x16/0_Complete_Tileset_Singles_16x16/Wooden_Fence_Type_1_Brown_3_16x16.png",
	},
	"object.fence_post": {
		"path": "modern_farm/extracted/16x16/Single_Files_16x16/0_Complete_Tileset_Singles_16x16/Wooden_Fence_Type_1_Brown_5_16x16.png",
	},
	"object.flower": {
		"path": "modern_farm/extracted/16x16/Single_Files_16x16/0_Complete_Tileset_Singles_16x16/Grass_Tufts_Flowers_16x16_1.png",
	},
	"object.flower2": {
		"path": "modern_farm/extracted/16x16/Single_Files_16x16/0_Complete_Tileset_Singles_16x16/Grass_Tufts_Flowers_16x16_5.png",
	},
	"object.flower3": {
		"path": "modern_farm/extracted/16x16/Single_Files_16x16/0_Complete_Tileset_Singles_16x16/Grass_Tufts_Flowers_16x16_9.png",
	},
	"object.crate": {
		"path": "modern_farm/extracted/16x16/Single_Files_16x16/0_Complete_Tileset_Singles_16x16/Crate_Brown_Apples_16x16.png",
	},
	"object.sign": {
		"path": "modern_farm/extracted/16x16/Single_Files_16x16/Props_and_Buildings_16x16/Sign_1_16x16.png",
	},
	"crop.carrot": {
		"path": "modern_farm/extracted/16x16/Single_Files_16x16/0_Complete_Tileset_Singles_16x16/Crop_Carrot_Ripe_1_16x16.png",
	},
	"crop.carrot_stage1": {
		"path": "modern_farm/extracted/16x16/Single_Files_16x16/0_Complete_Tileset_Singles_16x16/Crop_Carrot_Stage_1_16x16.png",
	},
	"animal.chicken": {
		"path": "modern_farm/extracted/16x16/Animals_16x16/Chickens_and_Roosters/Chicken_Brown_16x16.png",
		"rect": [0, 0, 16, 16],
	},
	"animal.cow": {
		"path": "modern_farm/extracted/16x16/Animals_16x16/Cows/Cow_16x16.png",
		"rect": [0, 0, 48, 48],
	},
	"character.farmer_idle": {
		"path": "modern_farm/extracted/16x16/Characters_16x16/Farmer_1_16x16.png",
		"rect": [16, 32, 16, 32],
	},
	"icon.carrot": {
		"path": "modern_farm/extracted/Icons/Icons_16x16/Icons_16x16_Singles/Icons_16x16_Crops_ Carrot.png",
	},
	"icon.wood": {
		"path": "modern_farm/extracted/Icons/Icons_16x16/Icons_16x16_Singles/Icons_16x16_Resources_Trunk_1.png",
	},
}

static var _loaded := false
static var _active: Dictionary = {}

static func reload() -> void:
	_loaded = false
	_active.clear()
	_ensure_loaded()

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(ACTIVE_MANIFEST_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ACTIVE_MANIFEST_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var active_value: Variant = (parsed as Dictionary).get("active", {})
	if typeof(active_value) == TYPE_DICTIONARY:
		_active = active_value as Dictionary

static func pack_ids() -> Array[String]:
	return PACK_IDS.duplicate()

static func _resolve_local(value: String) -> String:
	value = value.strip_edges()
	if value.is_empty():
		return ""
	var full := value if value.begins_with("res://") else LIMEZU_ROOT + value
	return full if FileAccess.file_exists(full) else ""

static func _resolve_raw_fallback(logical_id: String) -> String:
	var nid := normalize_id(logical_id)
	if not RAW_PACK_FALLBACKS.has(nid):
		return ""
	var entry: Dictionary = RAW_PACK_FALLBACKS[nid] as Dictionary
	return _resolve_local(String(entry.get("path", "")))

static func _source_rect(logical_id: String) -> Rect2i:
	var nid := normalize_id(logical_id)
	if not RAW_PACK_FALLBACKS.has(nid):
		return Rect2i()
	var entry: Dictionary = RAW_PACK_FALLBACKS[nid] as Dictionary
	var raw: Variant = entry.get("rect", [])
	if raw is Array and (raw as Array).size() == 4:
		return Rect2i(
			int((raw as Array)[0]),
			int((raw as Array)[1]),
			int((raw as Array)[2]),
			int((raw as Array)[3])
		)
	return Rect2i()

static func normalize_id(logical_id: String) -> String:
	return String(logical_id).strip_edges().to_lower()

static func _prefers_raw_pack_frame(logical_id: String) -> bool:
	return normalize_id(logical_id).begins_with("character.")

## Resolved res:// path for a logical id, or the missing placeholder if not mapped /
## the mapped file is absent. Always returns a loadable path.
static func texture_path(logical_id: String) -> String:
	_ensure_loaded()
	var nid := normalize_id(logical_id)
	if _active.has(nid):
		var local := _resolve_local(String(_active[nid]))
		if not local.is_empty():
			return local
	# Reviewed, hand-curated raw LimeZu single-file mapping (RAW_PACK_FALLBACKS) wins
	# over the unreviewed local generator slices for EVERY id. The generator
	# derivative cells are semantically random (they were the cause of the giant
	# fence-post scatter when they out-ranked the curated single files), so they may
	# only fill ids that have NO reviewed mapping.
	var raw := _resolve_raw_fallback(nid)
	if not raw.is_empty():
		return raw
	# Optional local generator outputs (derivative > inspired) only as a last resort
	# before missing. Returns "" — and is skipped — when the manifests/PNGs are absent
	# (clean checkout), so the live game never depends on these dev/review outputs.
	var generated := GeneratorAssetResolver.resolve(nid)
	if not generated.is_empty():
		return generated
	return FALLBACK_PATH

static func has_asset(logical_id: String) -> bool:
	_ensure_loaded()
	var nid := normalize_id(logical_id)
	if _active.has(nid) and not _resolve_local(String(_active[nid])).is_empty():
		return true
	if not _resolve_raw_fallback(nid).is_empty():
		return true
	if not GeneratorAssetResolver.resolve(nid).is_empty():
		return true
	return false

static func resolve_texture(logical_id: String) -> Texture2D:
	var path := texture_path(logical_id)
	var use_resource_loader := not (path.begins_with(LIMEZU_ROOT) and (path.contains("/generator_outputs/") or path.contains("/extracted/")))
	var tex: Texture2D = load(path) as Texture2D if use_resource_loader else null
	if tex != null:
		tex.set_meta("source_path", path)
		return tex
	var image := Image.new()
	var image_path := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	if image.load(image_path) != OK or image.is_empty():
		return null
	var rect := _source_rect(logical_id)
	if rect.size.x > 0 and rect.size.y > 0:
		var cropped := Image.create_empty(rect.size.x, rect.size.y, false, image.get_format())
		cropped.blit_rect(image, rect, Vector2i.ZERO)
		image = cropped
	tex = ImageTexture.create_from_image(image)
	if tex != null:
		tex.set_meta("source_path", path)
	return tex

## Source tier for an id: "missing", "limezu_generated_local" (output from a LimeZu
## generator, kept under generator_outputs/ or normalized/generated_candidates/), or
## "limezu" (sliced/copied from a shipped pack).
static func resolve_source_tier(logical_id: String) -> String:
	if not has_asset(logical_id):
		return "missing"
	var path := texture_path(logical_id)
	if path.contains("/generator_outputs/") or path.contains("/generated_candidates/"):
		return "limezu_generated_local"
	if path.contains("/extracted/"):
		return "limezu_extracted"
	return PROVIDER_ID

## Active ids whose art came from a LimeZu generator (reported separately from the
## sliced pack ids). Empty until generator outputs are reviewed + mapped.
static func list_generated_ids() -> Array[String]:
	var out: Array[String] = []
	for id in list_active_ids():
		if resolve_source_tier(String(id)) == "limezu_generated_local":
			out.append(String(id))
	out.sort()
	return out

## Logical ids that currently resolve to a real local LimeZu file.
static func list_active_ids() -> Array[String]:
	_ensure_loaded()
	var ids: Array[String] = []
	for key in _active.keys():
		if has_asset(String(key)):
			ids.append(String(key))
	ids.sort()
	return ids

static func list_resolved_live_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in LIVE_REQUIRED_IDS:
		if has_asset(id):
			ids.append(id)
	ids.sort()
	return ids

## Active ids grouped by their category prefix (the part before the first ".").
static func list_active_ids_by_category() -> Dictionary:
	var by_cat: Dictionary = {}
	for id in list_active_ids():
		var cat := id.get_slice(".", 0)
		if not by_cat.has(cat):
			by_cat[cat] = []
		(by_cat[cat] as Array).append(id)
	return by_cat

## How many of the given logical ids resolve to a real local LimeZu file.
static func resolved_count(ids: Array) -> int:
	var n := 0
	for id in ids:
		if has_asset(String(id)):
			n += 1
	return n

## The subset of the given logical ids that do NOT resolve (for honest reporting).
static func missing_ids(ids: Array) -> Array[String]:
	var out: Array[String] = []
	for id in ids:
		if not has_asset(String(id)):
			out.append(String(id))
	return out

static func live_required_ids() -> Array[String]:
	return LIVE_REQUIRED_IDS.duplicate()

static func live_missing_ids() -> Array[String]:
	return missing_ids(LIVE_REQUIRED_IDS)

static func live_ready() -> bool:
	return live_missing_ids().is_empty()

static func direct_live_missing_ids() -> Array[String]:
	var out: Array[String] = []
	_ensure_loaded()
	for id in LIVE_REQUIRED_IDS:
		var nid := normalize_id(id)
		if not (_active.has(nid) and not _resolve_local(String(_active[nid])).is_empty()):
			out.append(nid)
	return out

static func full_live_slice_ready() -> bool:
	return direct_live_missing_ids().is_empty()

static func local_inputs_present() -> bool:
	if FileAccess.file_exists(ACTIVE_MANIFEST_PATH) or GeneratorAssetResolver.available():
		return true
	for pack_id in PACK_IDS:
		if pack_present(pack_id):
			return true
	return false

static func readiness() -> Dictionary:
	var direct_missing := direct_live_missing_ids()
	var missing_any := live_missing_ids()
	var packs_present := []
	for pack_id in PACK_IDS:
		if pack_present(pack_id):
			packs_present.append(pack_id)
	var tier := READINESS_ABSENT
	if direct_missing.is_empty():
		tier = READINESS_FULL_LIVE_SLICE
	elif missing_any.is_empty() or resolved_count(LIVE_REQUIRED_IDS) >= 7:
		tier = READINESS_PARTIAL_USABLE
	elif not packs_present.is_empty() or GeneratorAssetResolver.available() or FileAccess.file_exists(ACTIVE_MANIFEST_PATH):
		tier = READINESS_EXTRACTED_PACKS_PRESENT
	return {
		"tier": tier,
		"full_live_slice_ready": tier == READINESS_FULL_LIVE_SLICE,
		"partial_usable": tier == READINESS_PARTIAL_USABLE,
		"usable_for_live": tier == READINESS_FULL_LIVE_SLICE or tier == READINESS_PARTIAL_USABLE,
		"direct_missing_ids": direct_missing,
		"missing_ids": missing_any,
		"resolved_live_ids": list_resolved_live_ids(),
		"resolved_live_count": resolved_count(LIVE_REQUIRED_IDS),
		"required_live_count": LIVE_REQUIRED_IDS.size(),
		"generator_available": GeneratorAssetResolver.available(),
		"packs_present": packs_present,
	}

static func readiness_tier() -> String:
	return String(readiness().get("tier", READINESS_ABSENT))

static func is_usable_for_live() -> bool:
	return bool(readiness().get("usable_for_live", false))

## Candidate source files per logical id, aggregated from each pack's local
## manifests/candidates.json (written by limezu_integrate.py). Best-effort review aid.
static func list_candidates() -> Array:
	var out: Array = []
	for pack_id in PACK_IDS:
		var path := LIMEZU_ROOT + pack_id + "/manifests/candidates.json"
		if not FileAccess.file_exists(path):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var cands: Variant = (parsed as Dictionary).get("candidates", {})
		if typeof(cands) == TYPE_DICTIONARY:
			for logical_id in (cands as Dictionary).keys():
				out.append({"pack": pack_id, "id": String(logical_id), "sources": (cands as Dictionary)[logical_id]})
	return out

## True when the manifest resolves enough core ids for the live LimeZu world slice.
## A UI-only manifest is useful for menus, but must not enable the world renderer.
static func is_available() -> bool:
	_ensure_loaded()
	return full_live_slice_ready()

## True when a pack's extracted/ folder exists locally (raw pack present).
static func pack_present(pack_id: String) -> bool:
	return DirAccess.open(LIMEZU_ROOT + pack_id + "/extracted") != null

## Human-readable reason the spike cannot show real LimeZu art yet, or "" if it can.
static func missing_reason() -> String:
	_ensure_loaded()
	var status := readiness()
	var tier := String(status.get("tier", READINESS_ABSENT))
	if tier == READINESS_PARTIAL_USABLE:
		return "LimeZu full live slices are incomplete; using partial LimeZu local outputs. Missing direct ids: %s" % ", ".join(status.get("direct_missing_ids", []) as Array)
	if tier == READINESS_EXTRACTED_PACKS_PRESENT:
		return "LimeZu packs/local outputs are present but not enough usable live ids resolve yet. Missing ids: %s" % ", ".join(status.get("missing_ids", []) as Array)
	if not FileAccess.file_exists(ACTIVE_MANIFEST_PATH):
		return "LimeZu activation manifest not found. Run: python tools/art/limezu_integrate.py --all"
	var missing_live_ids: Array[String] = live_missing_ids()
	if not missing_live_ids.is_empty():
		return "LimeZu manifest is partial; missing live slice ids: %s" % ", ".join(missing_live_ids)
	if list_active_ids().is_empty():
		return "LimeZu manifest has no resolvable assets yet — review the contact sheets in licensed_assets/limezu/**/contact_sheets and map logical ids in limezu_active_manifest.json."
	return ""
