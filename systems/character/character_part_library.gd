extends RefCounted
class_name CharacterPartLibrary

## Loads the local curated avatar parts manifest and provides texture access
## for layered character rendering. Falls back safely when the manifest or
## textures are absent (clean checkout).

const MANIFEST_PATH := "res://licensed_assets/limezu/generator_manifests/hearthvale_curated_avatar_parts_manifest.json"
const CG_ROOT := "res://licensed_assets/limezu/modern_interiors/extracted/moderninteriors-win/2_Characters/Character_Generator/"

const LAYER_ORDER := ["body", "eyes", "outfit", "hair", "accessory"]
const DEFAULT_GRID := 56  # columns in the shared sprite sheet grid (16x16 cells)

## SAFETY GATE: enabled after a composited visual review confirmed the layers align to the
## same 16x32 frame grid (Julie default preview + starter contact sheets). The earlier
## "misaligned" reading was a compositor bug; the body's extra 31px right margin is harmless.
## layered_ready() still does a live sanity check (manifest flag + a body texture actually loads),
## so a clean checkout or a broken manifest safely falls back to the full-body sprite.
const LAYOUT_VERIFIED := true

enum Direction { DOWN, LEFT, RIGHT, UP }

# Cached manifest data
static var _loaded := false
static var _manifest: Dictionary = {}
static var _dev_parts: Dictionary = {}
static var _part_index: Dictionary = {}
static var _kid_parts: Dictionary = {}
static var _texture_cache: Dictionary = {}

## True when the curated manifest exists and has usable parts.
static func is_available() -> bool:
	_ensure_loaded()
	return not _manifest.is_empty()

## The manifest data (empty dict when absent).
static func manifest() -> Dictionary:
	_ensure_loaded()
	return _manifest.duplicate(true)

## True when layered rendering is usable: the const gate is on, the manifest is present and marks
## the layout verified, AND a body texture actually loads (so a clean checkout / broken manifest
## safely falls back to the full-body sprite).
static func layered_ready() -> bool:
	if not LAYOUT_VERIFIED:
		return false
	_ensure_loaded()
	if _manifest.is_empty():
		return false
	var starter := _manifest.get("starter_set", {}) as Dictionary
	if not (starter.has("bodies") and starter.has("hairstyles") and starter.has("outfits")):
		return false
	if not bool((_manifest.get("layout_verification", {}) as Dictionary).get("verified", false)):
		return false
	var body_ids := part_ids_for_category("bodies")
	if body_ids.is_empty():
		return false
	return resolve_texture(String(part_entry(String(body_ids[0])).get("file", ""))) != null

## Body part id for a presentation (feminine/neutral/masculine) from the curated map.
static func presentation_body(presentation: String) -> String:
	_ensure_loaded()
	var m: Dictionary = _manifest.get("presentation_body_map", {}) as Dictionary
	return String(m.get(String(presentation), "body_01"))

## The curated Julie default appearance (part ids), or empty when no manifest.
static func julie_default() -> Dictionary:
	_ensure_loaded()
	var out: Dictionary = (_manifest.get("julie_default", {}) as Dictionary).duplicate(true)
	_sync_split_fields(out)
	return out

## A stable render signature of the LAYER files an appearance resolves to — changes whenever any
## visible part (body/eyes/outfit/hair/accessory) changes, so smoke/validation can prove the
## editor actually alters the avatar. "acc_none"/none accessory contributes no layer.
static func render_signature(appearance: Dictionary) -> String:
	var bp := String(appearance.get("body_presentation", "body_01"))
	# Map legacy names (feminine/neutral/masculine) via the manifest, pass direct IDs through
	if bp == "feminine" or bp == "masculine" or bp == "neutral":
		bp = presentation_body(bp)
	var ids: Array = [
		bp,
		String(appearance.get("eyes", "eyes_02")),
		resolve_combined_part_id("outfit", String(appearance.get("outfit_style", "")), String(appearance.get("outfit_color", ""))),
		resolve_combined_part_id("hair", String(appearance.get("hair_style", "")), String(appearance.get("hair_color", ""))),
		String(appearance.get("accessory", "none")),
	]
	var parts: Array = []
	for pid in ids:
		var p := String(pid)
		if p.is_empty() or p == "none" or p == "acc_none":
			continue
		var f := String(part_entry(p).get("file", ""))
		if not f.is_empty():
			parts.append(f.get_file())
	return "|".join(parts)

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
	var items: Array = (_dev_parts.get(category, []) as Array)
	var out: Array = []
	for item in items:
		out.append(String((item as Dictionary).get("part_id", "")))
	return out

## Full entry for a part id, or empty dict.
static func part_entry(part_id: String) -> Dictionary:
	_ensure_loaded()
	var item: Dictionary = _part_index.get(String(part_id), {}) as Dictionary
	if not item.is_empty():
		return item.duplicate(true)
	return {}

## Layer category for a part id ("body"/"hair"/"outfit"/"accessory"/"eyes"), or "".
static func category_for(part_id: String) -> String:
	_ensure_loaded()
	return String(part_entry(part_id).get("category", ""))

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

## --- Combined ID helpers (hair_22_04 → style=22, color=04) ---

## Splits a combined part ID like "hair_22_04" into [base, style, color].
## Returns [] if the ID doesn't match the expected pattern.
static func split_id(part_id: String) -> Array:
	var s := String(part_id)
	var parts := s.split("_")
	if parts.size() < 3:
		return []
	# Expected: prefix_number_number (e.g. hair_22_04)
	if not parts[-1].is_valid_int() or not parts[-2].is_valid_int():
		return []
	var color := parts[-1]
	var style := parts[-2]
	var base := "_".join(parts.slice(0, -2))  # "hair", "outfit", "acc_beanie", etc.
	return [base, style, color]

## Builds a combined part ID from base + style + color (e.g. "hair", "22", "04" → "hair_22_04")
static func join_id(base: String, style: String, color: String) -> String:
	return "%s_%s_%s" % [base, style, color]

## Returns a unique list of style bases for a category (e.g. "hair" for hair IDs).
## For hair: returns ["hair_01", "hair_02", ...]
static func style_bases_for_category(category: String) -> Array:
	_ensure_loaded()
	var ids := part_ids_for_category(category)
	var bases: Dictionary = {}
	for raw in ids:
		var pid := String(raw)
		var split := split_id(pid)
		if split.size() == 3:
			bases["%s_%s" % [split[0], split[1]]] = true
	return bases.keys()

## Returns available color suffixes for a style base (e.g. ["01","02","03"] for "hair_22").
static func colors_for_style_base(style_base: String) -> Array:
	_ensure_loaded()
	var cat := ""
	if style_base.begins_with("hair"): cat = "hairstyles"
	elif style_base.begins_with("outfit"): cat = "outfits"
	elif style_base.begins_with("acc"): cat = "accessories"
	else: return []
	
	var out: Array = []
	for raw in part_ids_for_category(cat):
		var pid := String(raw)
		if pid.begins_with(style_base + "_"):
			var split := split_id(pid)
			if split.size() == 3:
				out.append(split[2])
	out.sort()
	return out

static func resolve_combined_part_id(slot_prefix: String, style_or_part_id: String, color_suffix: String = "") -> String:
	var current := String(style_or_part_id)
	if current.is_empty():
		return ""
	var split := split_id(current)
	if split.size() == 3:
		if color_suffix.is_empty() or String(split[2]) == color_suffix:
			return current
		current = "%s_%s" % [split[0], split[1]]
	var colors := colors_for_style_base(current)
	if colors.is_empty():
		return current
	var chosen := String(color_suffix)
	if not colors.has(chosen):
		chosen = _nearest_suffix(chosen, colors)
	return "%s_%s" % [current, chosen]

static func valid_color_for_style(style_base: String, requested_color: String) -> String:
	var colors := colors_for_style_base(style_base)
	if colors.is_empty():
		return ""
	return _nearest_suffix(requested_color, colors)

static func split_base_from_part_id(part_id: String) -> String:
	var split := split_id(part_id)
	if split.size() == 3:
		return "%s_%s" % [split[0], split[1]]
	return String(part_id)

static func dev_metadata_for_part(part_id: String) -> Dictionary:
	var entry := part_entry(part_id)
	if entry.has("metadata"):
		return (entry["metadata"] as Dictionary).duplicate(true)
	return {}

static func kid_asset_status() -> Dictionary:
	_ensure_loaded()
	return _kid_parts.duplicate(true)

## --- Friendly display labels (user-facing F9 names) ---

static func hair_style_label(style_base: String) -> String:
	var parts := style_base.split("_")
	if parts.size() >= 2 and parts[-1].is_valid_int():
		return "Hair %d" % int(parts[-1])
	return style_base.capitalize()

static func outfit_style_label(style_base: String) -> String:
	var parts := style_base.split("_")
	if parts.size() >= 2 and parts[-1].is_valid_int():
		return "Outfit %d" % int(parts[-1])
	return style_base.capitalize()

static func color_label(suffix: String) -> String:
	if suffix.is_valid_int():
		return "Color %s" % suffix
	return suffix.capitalize()

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(MANIFEST_PATH):
		_manifest = {}
	else:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
		if typeof(parsed) == TYPE_DICTIONARY:
			_manifest = parsed as Dictionary
	_scan_dev_parts()

static func reload() -> void:
	_loaded = false
	_manifest.clear()
	_dev_parts.clear()
	_part_index.clear()
	_kid_parts.clear()
	_texture_cache.clear()
	_ensure_loaded()

static func _sync_split_fields(data: Dictionary) -> void:
	for slot in ["hair", "outfit"]:
		var key := "%s_style" % slot
		var color_key := "%s_color" % slot
		var combined := String(data.get(key, ""))
		var split := split_id(combined)
		if split.size() == 3:
			data[key] = "%s_%s" % [split[0], split[1]]
			data[color_key] = String(split[2])

static func _scan_dev_parts() -> void:
	_dev_parts = {"bodies": [], "eyes": [], "hairstyles": [], "outfits": [], "accessories": []}
	_part_index.clear()
	_scan_category("bodies", "Bodies/16x16", "Body_", "body")
	_scan_category("eyes", "Eyes/16x16", "Eyes_", "eyes")
	_scan_category("hairstyles", "Hairstyles/16x16", "Hairstyle_", "hair")
	_scan_category("outfits", "Outfits/16x16", "Outfit_", "outfit")
	_scan_accessories()
	_scan_kid_assets()
	if (_dev_parts["bodies"] as Array).is_empty():
		_load_manifest_starter_fallback()
	for cat in _dev_parts.keys():
		(_dev_parts[cat] as Array).sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return String(a.get("part_id", "")) < String(b.get("part_id", "")))

static func _scan_category(category: String, rel_dir: String, file_prefix: String, id_prefix: String) -> void:
	var dir := DirAccess.open(ProjectSettings.globalize_path(CG_ROOT + rel_dir))
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".png") and file_name.begins_with(file_prefix):
			var stem := file_name.get_basename()
			var suffix := stem.trim_prefix(file_prefix)
			var part_id := "%s_%s" % [id_prefix, suffix.to_lower()]
			var label := _label_for_part(id_prefix, suffix)
			_add_part(category, part_id, "%s/%s" % [rel_dir, file_name], label, _metadata_for_file(category, file_name))
		file_name = dir.get_next()
	dir.list_dir_end()

static func _scan_accessories() -> void:
	_add_part("accessories", "acc_none", "", "None", _metadata_for_file("accessories", "none"))
	var rel_dir := "Accessories/16x16"
	var dir := DirAccess.open(ProjectSettings.globalize_path(CG_ROOT + rel_dir))
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".png") and file_name.begins_with("Accessory_"):
			var stem := file_name.get_basename().trim_prefix("Accessory_")
			var bits := stem.split("_")
			if bits.size() >= 3:
				var variant := String(bits[bits.size() - 1])
				var name_bits := bits.slice(1, bits.size() - 1)
				var name := "_".join(name_bits)
				var part_id := "acc_%s_%s" % [name.to_lower(), variant.to_lower()]
				var label := "%s %s" % [name.capitalize().replace("_", " "), variant]
				_add_part("accessories", part_id, "%s/%s" % [rel_dir, file_name], label, _metadata_for_file("accessories", file_name))
		file_name = dir.get_next()
	dir.list_dir_end()

static func _add_part(category: String, part_id: String, file_path: String, label: String, metadata: Dictionary) -> void:
	if _part_index.has(part_id):
		return
	var entry := {
		"part_id": part_id,
		"file": file_path,
		"enabled_for_editor": true,
		"label": label,
		"display_name": label,
		"category": category,
		"metadata": metadata,
	}
	if category == "bodies":
		entry["skin_tone_label"] = label
	(_dev_parts[category] as Array).append(entry)
	_part_index[part_id] = entry

static func _metadata_for_file(category: String, file_name: String) -> Dictionary:
	var lower := String(file_name).to_lower()
	var tone := "cozy"
	if lower.contains("police") or lower.contains("sheriff") or lower.contains("detective"):
		tone = "authority"
	elif lower.contains("zombie") or lower.contains("horror") or lower.contains("skull") or lower.contains("bat"):
		tone = "spooky"
	elif lower.contains("medical") or lower.contains("doctor") or lower.contains("nurse"):
		tone = "medical"
	elif lower.contains("christmas") or lower.contains("party") or lower.contains("pumpkin"):
		tone = "seasonal"
	elif lower.contains("dino") or lower.contains("wizard") or lower.contains("crown"):
		tone = "fantasy"
	elif category == "outfits":
		tone = "casual"
	elif category == "accessories":
		tone = "accessory"
	return {
		"unlock_status": "dev_unlocked",
		"release_unlock_source": "unknown",
		"tone_tag": tone,
		"release_default_available": false,
		"dev_available": true,
		"avatar_type": "adult",
		"layout_status": "compatible_layout",
	}

static func _scan_kid_assets() -> void:
	_kid_parts = {}
	for rel_dir in ["Bodies_kids/16x16", "Eyes_kids/16x16", "Hairstyles_kids/16x16", "Outfits_kids/16x16"]:
		var dir := DirAccess.open(ProjectSettings.globalize_path(CG_ROOT + rel_dir))
		var files: Array = []
		if dir != null:
			dir.list_dir_begin()
			var file_name := dir.get_next()
			while not file_name.is_empty():
				if not dir.current_is_dir() and file_name.ends_with(".png"):
					files.append({
						"file": "%s/%s" % [rel_dir, file_name],
						"metadata": {
							"unlock_status": "incompatible_layout",
							"release_unlock_source": "unknown",
							"tone_tag": "kid",
							"release_default_available": false,
							"dev_available": false,
							"avatar_type": "kid",
							"layout_status": "incompatible_layout",
						}
					})
				file_name = dir.get_next()
			dir.list_dir_end()
		_kid_parts[rel_dir] = files

static func _load_manifest_starter_fallback() -> void:
	var starter := _manifest.get("starter_set", {}) as Dictionary
	for category in starter.keys():
		if not _dev_parts.has(category):
			continue
		for raw in starter.get(category, []):
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var item := (raw as Dictionary).duplicate(true)
			var part_id := String(item.get("part_id", ""))
			if part_id.is_empty() or _part_index.has(part_id):
				continue
			item["category"] = category
			if not item.has("metadata"):
				item["metadata"] = _metadata_for_file(category, String(item.get("file", "")))
			(_dev_parts[category] as Array).append(item)
			_part_index[part_id] = item

static func _label_for_part(id_prefix: String, suffix: String) -> String:
	var parts := suffix.split("_")
	if id_prefix == "body":
		return "Skin %s" % suffix
	if id_prefix == "eyes":
		return "Eyes %s" % suffix
	if id_prefix == "hair" and parts.size() >= 2:
		return "Hair %d" % int(parts[0])
	if id_prefix == "outfit" and parts.size() >= 2:
		return "Outfit %d" % int(parts[0])
	return "%s %s" % [id_prefix.capitalize(), suffix]

static func _nearest_suffix(requested: String, options: Array) -> String:
	if options.is_empty():
		return ""
	var r := String(requested)
	if options.has(r):
		return r
	if r.is_valid_int():
		var target := int(r)
		var best := String(options[0])
		var best_dist := 999999
		for raw in options:
			var opt := String(raw)
			if not opt.is_valid_int():
				continue
			var dist := absi(int(opt) - target)
			if dist < best_dist:
				best = opt
				best_dist = dist
		return best
	return String(options[0])
