extends SceneTree

## READ-ONLY catalog of installed LimeZu animation sheets (animation/terrain pass, Task 1).
## Scans the licensed packs for character / animal / crop / environment / UI animation sheets,
## records frame size, rows/cols, frame count, likely directions, source pack/path, and whether
## the sheet is wired for runtime NOW (vs cataloged for a future reviewed pass). Writes an
## ADDITIVE, gitignored manifest — it never moves, copies, or modifies any source asset.
##
##   Godot --headless --path . --script res://tools/audit_limezu_animations.gd

const LIMEZU_ROOT := "res://licensed_assets/limezu/"
const MANIFEST_OUT := "res://licensed_assets/limezu/generator_manifests/limezu_animation_manifest.json"

# (relative dir under LIMEZU_ROOT, category) scan roots. Focused on the actual animation
# asset folders (characters + animals). Environment/UI animation sheets are rare in these packs
# and intentionally NOT deep-scanned here (the extracted exteriors tree is tens of thousands of
# static tiles) — they remain a documented future-review item.
const SCAN_ROOTS := [
	["modern_farm/extracted/16x16/Characters_16x16", "character"],
	["modern_farm/extracted/16x16/Animals_16x16", "animal"],
]
# Sheets already wired for live runtime (CharacterAnimationRegistry idle/walk facing).
const RUNTIME_WIRED := ["Farmer_1_16x16.png", "Farmer_2_16x16.png", "Body_2_16x16.png"]

func _init() -> void:
	var entries: Array = []
	for root_pair in SCAN_ROOTS:
		_scan_dir(LIMEZU_ROOT + String(root_pair[0]), String(root_pair[1]), entries, 0)
	entries.sort_custom(func(a, b): return String(a["name"]) < String(b["name"]))

	var by_cat: Dictionary = {}
	var usable: int = 0
	for e in entries:
		by_cat[e["category"]] = int(by_cat.get(e["category"], 0)) + 1
		if e["usable_now"]:
			usable += 1

	print("\n========== LIMEZU ANIMATION CATALOG ==========")
	print("sheets found=%d  by_category=%s  runtime-usable-now=%d" % [entries.size(), str(by_cat), usable])
	print("-- usable now (idle/walk wired) --")
	for e in entries:
		if e["usable_now"]:
			print("  %-26s %-9s frames=%-4s %s" % [e["name"], e["category"], str(e["frame_count"]), e["dimensions"]])
	print("-- cataloged for future review (action atlases / unreviewed) --  [first 18]")
	var shown: int = 0
	for e in entries:
		if not e["usable_now"] and shown < 18:
			print("  %-40s %-9s frames=%-4s %s" % [e["name"], e["category"], str(e["frame_count"]), e["dimensions"]])
			shown += 1

	var manifest := {
		"schema": "limezu_animation_manifest_v1",
		"generated_by": "tools/audit_limezu_animations.gd",
		"commit_policy": "local_gitignored_output",
		"note": "Read-only catalog. Source assets are never moved/modified. Runtime currently wires only the base character idle/walk facing; action atlases are cataloged for later.",
		"counts": {"total": entries.size(), "by_category": by_cat, "usable_now": usable},
		"entries": entries,
	}
	var ok := _write_manifest(manifest)
	print("manifest: %s (%s)" % [MANIFEST_OUT, "written" if ok else "FAILED to write"])
	print("AUDIT limezu animations: %s" % ("PASS" if not entries.is_empty() and ok else "REVIEW"))
	quit(0 if (not entries.is_empty() and ok) else 1)

func _scan_dir(dir_path: String, category: String, entries: Array, depth: int) -> void:
	if depth > 4:
		return
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.begins_with("."):
			name = dir.get_next()
			continue
		var full := dir_path + "/" + name
		if dir.current_is_dir():
			_scan_dir(full, category, entries, depth + 1)
		elif name.to_lower().ends_with(".png") and not name.begins_with("00_"):
			var e := _describe_sheet(full, name, category)
			if not e.is_empty():
				entries.append(e)
		name = dir.get_next()
	dir.list_dir_end()

func _describe_sheet(full_path: String, name: String, category: String) -> Dictionary:
	var img := Image.new()
	var abs := ProjectSettings.globalize_path(full_path)
	if img.load(abs) != OK or img.is_empty():
		return {}
	var w := img.get_width()
	var h := img.get_height()
	var frame_count := _parse_frame_count(name)
	# Heuristic frame size: 16x32 for characters (humanoid 2-tall), else best guess from name/size.
	var fw := 16
	var fh := 32 if category == "character" else (16 if h % 16 == 0 else h)
	if category == "animal":
		fh = 16 if h <= 64 else (48 if h % 48 == 0 else h)
	var directions := _likely_directions(name, category)
	var usable := RUNTIME_WIRED.has(name)
	return {
		"name": name,
		"path": full_path,
		"category": category,
		"pack": full_path.replace(LIMEZU_ROOT, "").split("/")[0],
		"dimensions": "%dx%d" % [w, h],
		"width": w, "height": h,
		"frame_size_guess": "%dx%d" % [fw, fh],
		"frame_count": frame_count,
		"likely_directions": directions,
		"likely_animation": _likely_animation(name),
		"usable_now": usable,
		"review_required": not usable,
	}

func _parse_frame_count(name: String) -> int:
	var re := RegEx.new()
	re.compile("(\\d+)_frames")
	var m := re.search(name)
	return int(m.get_string(1)) if m != null else 0

func _likely_animation(name: String) -> String:
	var n := name.to_lower()
	for key in ["chopping", "dig", "fishing", "harvesting", "watering", "walk", "run", "idle"]:
		if n.contains(key):
			return key
	return "base/idle+walk" if name.to_lower().contains("16x16") else "unknown"

func _likely_directions(name: String, category: String) -> Array:
	if category == "character":
		return ["down", "up", "left", "right"]
	return ["idle"]

func _write_manifest(manifest: Dictionary) -> bool:
	var f := FileAccess.open(MANIFEST_OUT, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	return true
