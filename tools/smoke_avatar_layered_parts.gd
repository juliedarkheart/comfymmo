extends SceneTree

## Headless smoke for the LAYERED avatar parts system: the curated manifest loads, layered mode
## is enabled (verified), the Julie default + every starter part resolves to a texture, the shared
## 16x32 frame geometry is correct, and the render signature reflects part choices. Clean-checkout
## safe: when the manifest/pack is absent, layered_ready() is false and the asserts adapt.
##
##   Godot --headless --path . --script res://tools/smoke_avatar_layered_parts.gd

func _initialize() -> void:
	var ok: bool = true
	CharacterPartLibrary.reload()

	var available := CharacterPartLibrary.is_available()
	print("  INFO  is_available = %s, layered_ready = %s" % [available, CharacterPartLibrary.layered_ready()])

	if not available:
		ok = _expect(not CharacterPartLibrary.layered_ready(), "layered_ready false when manifest absent (clean checkout)") and ok
		_report(ok); return

	# --- Manifest present: layered mode is enabled (layout verified) ----------
	ok = _expect(CharacterPartLibrary.layered_ready(), "layered_ready() true (layout verified + body texture loads)") and ok

	# --- Starter categories populated ----------------------------------------
	for cat in ["bodies", "hairstyles", "outfits", "accessories", "eyes"]:
		ok = _expect(CharacterPartLibrary.part_ids_for_category(cat).size() >= 1, "%s part ids present" % cat) and ok

	# --- Full dev wardrobe coverage: every compatible ADULT asset is scanned in ----
	# (the library scans the actual Character_Generator folders, so the dev wardrobe exposes ALL
	# usable adult assets — the manifest is only the clean-checkout fallback).
	ok = _expect(CharacterPartLibrary.part_ids_for_category("bodies").size() >= 8,
		"all adult bodies exposed (%d)" % CharacterPartLibrary.part_ids_for_category("bodies").size()) and ok
	ok = _expect(CharacterPartLibrary.part_ids_for_category("eyes").size() >= 7,
		"all adult eyes exposed (%d)" % CharacterPartLibrary.part_ids_for_category("eyes").size()) and ok
	ok = _expect(CharacterPartLibrary.style_bases_for_category("hairstyles").size() >= 28,
		"all adult hair base styles exposed (%d)" % CharacterPartLibrary.style_bases_for_category("hairstyles").size()) and ok
	ok = _expect(CharacterPartLibrary.style_bases_for_category("outfits").size() >= 30,
		"all adult outfit base styles exposed (%d)" % CharacterPartLibrary.style_bases_for_category("outfits").size()) and ok
	ok = _expect(CharacterPartLibrary.part_ids_for_category("accessories").size() >= 40,
		"all adult accessories exposed + None (%d)" % CharacterPartLibrary.part_ids_for_category("accessories").size()) and ok
	# Hair/outfit color variants are exposed per style base.
	ok = _expect(CharacterPartLibrary.colors_for_style_base("hair_22").size() >= 4,
		"hair colour variants exposed for a style (%d)" % CharacterPartLibrary.colors_for_style_base("hair_22").size()) and ok

	# --- Release-gating metadata present on every adult part ------------------
	var meta_sample := CharacterPartLibrary.dev_metadata_for_part("hair_22_01")
	for meta_key in ["dev_available", "release_default_available", "unlock_status", "release_unlock_source", "tone_tag", "avatar_type", "layout_status"]:
		ok = _expect(meta_sample.has(meta_key), "adult part metadata has '%s'" % meta_key) and ok
	ok = _expect(String(meta_sample.get("avatar_type", "")) == "adult" and String(meta_sample.get("layout_status", "")) == "compatible_layout",
		"adult part is tagged adult/compatible") and ok

	# --- Kid assets inventoried but DEFERRED (incompatible layout) ------------
	var kid_status := CharacterPartLibrary.kid_asset_status()
	ok = _expect(not kid_status.is_empty(), "kid assets inventoried (deferred)") and ok
	for bucket in kid_status.keys():
		for item in (kid_status[bucket] as Array):
			var km: Dictionary = (item as Dictionary).get("metadata", {}) as Dictionary
			ok = _expect(String(km.get("layout_status", "")) == "incompatible_layout" and not bool(km.get("dev_available", true)),
				"kid asset deferred (incompatible_layout, not dev_available)") and ok
			break  # one sample per bucket is enough

	# --- Every enabled starter part resolves to a texture (or null file for acc_none) ---
	var checked := 0
	for cat in ["bodies", "hairstyles", "outfits", "accessories", "eyes"]:
		for pid in CharacterPartLibrary.part_ids_for_category(cat):
			var entry := CharacterPartLibrary.part_entry(String(pid))
			var file_v: Variant = entry.get("file", "")
			if file_v == null:
				continue  # acc_none has no file (intentional)
			var file := String(file_v)
			if file.is_empty():
				continue
			if CharacterPartLibrary.resolve_texture(file) == null:
				ok = _expect(false, "dev wardrobe entry '%s' points to a MISSING texture (%s)" % [pid, file]) and ok
			checked += 1
	ok = _expect(checked >= 300, "resolved the full dev wardrobe with no missing textures (%d parts)" % checked) and ok

	# --- Julie default resolves to a coherent (non-empty) layer set ----------
	var julie := CharacterAppearance.default_appearance()
	ok = _expect(String(julie.get("hair_style", "")) == "hair_22" and String(julie.get("hair_color", "")) == "01"
		and String(julie.get("outfit_style", "")) == "outfit_14" and String(julie.get("outfit_color", "")) == "01",
		"Julie default uses the approved curated parts") and ok
	var sig := CharacterPartLibrary.render_signature(julie)
	var layer_count := sig.split("|").size()
	ok = _expect(layer_count >= 4, "Julie default composites >=4 layers (body+eyes+outfit+hair+acc) = %d" % layer_count) and ok

	# --- Accessory None removes the accessory layer --------------------------
	var none_look := julie.duplicate(); none_look["accessory"] = "none"
	ok = _expect(CharacterPartLibrary.render_signature(none_look).split("|").size() == layer_count - 1,
		"accessory None drops exactly one layer") and ok

	# --- Shared 16x32 frame geometry (front/down is distinct from side) -------
	var idle_down := CharacterAnimationRegistry.generator_idle_rect("down")
	ok = _expect(idle_down == Rect2i(48, 0, 16, 32), "idle-down/front cell is col3,row0 16x32") and ok
	var idle_up := CharacterAnimationRegistry.generator_idle_rect("up")
	ok = _expect(idle_up == Rect2i(16, 0, 16, 32), "idle-up cell is (1,0) 16x32") and ok
	var idle_side := CharacterAnimationRegistry.generator_idle_rect("side")
	ok = _expect(idle_side == Rect2i(0, 0, 16, 32) and idle_side != idle_down,
		"idle-side is distinct from idle-down/front") and ok
	var walk_down := CharacterAnimationRegistry.generator_walk_frames("down")
	ok = _expect(walk_down.size() >= 6 and (walk_down[0] as Rect2i) == Rect2i(288, 32, 16, 32),
		"down walk has reviewed front-facing 6-frame band") and ok

	# --- Reload idempotent ---------------------------------------------------
	CharacterPartLibrary.reload()
	ok = _expect(CharacterPartLibrary.layered_ready() == true, "reload preserves layered_ready") and ok

	_report(ok)

func _report(ok: bool) -> void:
	if ok:
		print("PASS: smoke_avatar_layered_parts")
	else:
		printerr("FAIL: smoke_avatar_layered_parts")
	quit(0 if ok else 1)

func _expect(condition: bool, label: String) -> bool:
	if condition:
		print("  OK  %s" % label)
	else:
		printerr("  FAIL  %s" % label)
	return condition
