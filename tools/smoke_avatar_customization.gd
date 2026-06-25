extends SceneTree

## Headless smoke for REAL layered avatar customization: changing body/hair/outfit/accessory
## changes the rendered LAYER signature (CharacterPartLibrary.render_signature), accessory None
## removes the accessory layer, the curated Julie default loads, save/load round-trips, and player
## changes never touch Rowan/Hazel. Falls back to full-body-fallback assertions on a clean checkout.
## Never mutates the real player save (temp path only).
##
##   Godot --headless --path . --script res://tools/smoke_avatar_customization.gd

const TEMP_SAVE_PATH: String = "user://avatar_customization_smoke_test.json"

func _initialize() -> void:
	var ok: bool = true
	_remove_temp_save()
	CharacterPartLibrary.reload()
	CharacterProfileRegistry.clear_player_appearance()

	var layered := CharacterPartLibrary.layered_ready()
	print("  INFO  layered_ready = %s" % layered)

	# --- Default appearance loads --------------------------------------------
	var default_look: Dictionary = CharacterAppearance.default_appearance()
	ok = _expect(default_look.has("body_presentation"), "default appearance has body_presentation") and ok

	if layered:
		# --- Julie default is the curated layered look ------------------------
		var julie_def := CharacterPartLibrary.julie_default()
		var def_body := String(julie_def.get("body_presentation", ""))
		var def_hair := String(julie_def.get("hair_style", ""))
		var def_hair_color := String(julie_def.get("hair_color", ""))
		var def_outfit := String(julie_def.get("outfit_style", ""))
		var def_outfit_color := String(julie_def.get("outfit_color", ""))
		var def_acc := String(julie_def.get("accessory", ""))

		ok = _expect(not def_body.is_empty(), "Julie default body set") and ok
		ok = _expect(def_hair == "hair_22" and def_hair_color == "01", "Julie default split hair set (%s/%s)" % [def_hair, def_hair_color]) and ok
		ok = _expect(def_outfit == "outfit_14" and def_outfit_color == "01", "Julie default split outfit set (%s/%s)" % [def_outfit, def_outfit_color]) and ok
		ok = _expect(not def_acc.is_empty(), "Julie default accessory set (%s)" % def_acc) and ok

		var base_sig := CharacterPartLibrary.render_signature(julie_def)
		ok = _expect(not base_sig.is_empty() and base_sig.split("|").size() >= 4,
			"Julie default render signature has >=4 layers (%s)" % base_sig) and ok

		# --- Each editable field CHANGES the rendered layer signature ----------
		var body_ids := CharacterAppearanceRegistry.body_presentations().keys()
		if body_ids.size() >= 2:
			var alt_body := String(body_ids[min(1, body_ids.size() - 1)])
			var body_look := julie_def.duplicate(); body_look["body_presentation"] = alt_body
			ok = _expect(CharacterPartLibrary.render_signature(body_look) != base_sig, "body change alters render signature") and ok

		var hair_bases := CharacterPartLibrary.style_bases_for_category("hairstyles")
		ok = _expect(hair_bases.size() >= 20, "Hair Style exposes many dev-unlocked bases (%d)" % hair_bases.size()) and ok
		if hair_bases.size() >= 2:
			var alt_hair := String(hair_bases[min(1, hair_bases.size() - 1)])
			var hair_look := julie_def.duplicate(); hair_look["hair_style"] = alt_hair
			ok = _expect(CharacterPartLibrary.render_signature(hair_look) != base_sig, "hair change alters render signature") and ok
		var hair_colors := CharacterPartLibrary.colors_for_style_base(def_hair)
		ok = _expect(hair_colors.size() >= 2, "Hair Color exposes real variants for %s (%d)" % [def_hair, hair_colors.size()]) and ok
		if hair_colors.size() >= 2:
			var hair_color_look := julie_def.duplicate()
			hair_color_look["hair_color"] = String(hair_colors[1])
			ok = _expect(CharacterPartLibrary.render_signature(hair_color_look) != base_sig, "hair color changes render signature") and ok

		var outfit_bases := CharacterPartLibrary.style_bases_for_category("outfits")
		ok = _expect(outfit_bases.size() >= 20, "Outfit exposes many dev-unlocked bases (%d)" % outfit_bases.size()) and ok
		if outfit_bases.size() >= 2:
			var alt_outfit := String(outfit_bases[min(2, outfit_bases.size() - 1)])
			var outfit_look := julie_def.duplicate(); outfit_look["outfit_style"] = alt_outfit
			ok = _expect(CharacterPartLibrary.render_signature(outfit_look) != base_sig, "outfit change alters render signature") and ok
		var outfit_colors := CharacterPartLibrary.colors_for_style_base(def_outfit)
		ok = _expect(outfit_colors.size() >= 2, "Outfit Color exposes real variants for %s (%d)" % [def_outfit, outfit_colors.size()]) and ok
		if outfit_colors.size() >= 2:
			var outfit_color_look := julie_def.duplicate()
			outfit_color_look["outfit_color"] = String(outfit_colors[1])
			ok = _expect(CharacterPartLibrary.render_signature(outfit_color_look) != base_sig, "outfit color changes render signature") and ok

		var acc_ids := CharacterPartLibrary.part_ids_for_category("accessories")
		ok = _expect(acc_ids.size() >= 40 and acc_ids.has("acc_none"), "Accessory exposes dev-unlocked options plus None (%d)" % acc_ids.size()) and ok
		var alt_acc := "acc_beanie_01"
		for pid in acc_ids:
			if pid != "acc_none" and pid != def_acc:
				alt_acc = pid; break
		var acc_look := julie_def.duplicate(); acc_look["accessory"] = alt_acc
		ok = _expect(CharacterPartLibrary.render_signature(acc_look) != base_sig, "accessory change alters render signature") and ok

		# --- Accessory None removes the accessory layer -----------------------
		var none_look := julie_def.duplicate(); none_look["accessory"] = "none"
		var none_sig := CharacterPartLibrary.render_signature(none_look)
		ok = _expect(none_sig != base_sig and none_sig.split("|").size() == base_sig.split("|").size() - 1,
			"accessory None removes the accessory layer") and ok

		# --- Layered part textures resolve ------------------------------------
		var body_entry := CharacterPartLibrary.part_entry(def_body)
		var body_file := String(body_entry.get("file", ""))
		ok = _expect(not body_file.is_empty() and CharacterPartLibrary.resolve_texture(body_file) != null,
			"Julie body texture resolves") and ok
		var hair_entry := CharacterPartLibrary.part_entry(CharacterPartLibrary.resolve_combined_part_id("hair", def_hair, def_hair_color))
		var hair_file := String(hair_entry.get("file", ""))
		ok = _expect(not hair_file.is_empty() and CharacterPartLibrary.resolve_texture(hair_file) != null,
			"Julie hair texture resolves") and ok
		var kid_status := CharacterPartLibrary.kid_asset_status()
		ok = _expect(not kid_status.is_empty(), "kid assets are inventoried for deferred metadata") and ok
		for bucket in kid_status.keys():
			var kid_items: Array = kid_status[bucket] as Array
			if not kid_items.is_empty():
				var meta: Dictionary = (kid_items[0] as Dictionary).get("metadata", {}) as Dictionary
				ok = _expect(String(meta.get("layout_status", "")) == "incompatible_layout", "kid bucket %s is deferred as incompatible_layout" % bucket) and ok
	else:
		# Clean-checkout fallback: full-body presentation presets + palette still work.
		ok = _expect(CharacterAppearanceRegistry.body_presentations().has("feminine"), "feminine presentation exists (fallback)") and ok
		var n := CharacterAppearance.default_appearance(); n["body_presentation"] = "neutral"
		var m := CharacterAppearance.default_appearance(); m["body_presentation"] = "masculine"
		CharacterProfileRegistry.apply_player_appearance(n); var nsig := CharacterProfileRegistry.signature("player")
		CharacterProfileRegistry.apply_player_appearance(m)
		ok = _expect(CharacterProfileRegistry.signature("player") != nsig, "presentation changes fallback sheet signature") and ok

	# --- Save/load preserves the selected appearance -------------------------
	var save := LocalSaveSystem.new()
	get_root().add_child(save)
	save.set_save_path_for_tests(TEMP_SAVE_PATH)
	var custom_look := CharacterAppearance.default_appearance()
	if layered:
		var body_ids2 := CharacterAppearanceRegistry.body_presentations().keys()
		if body_ids2.size() >= 2:
			custom_look["body_presentation"] = String(body_ids2[min(1, body_ids2.size() - 1)])
		var hair_ids2 := CharacterPartLibrary.style_bases_for_category("hairstyles")
		if hair_ids2.size() >= 2:
			custom_look["hair_style"] = String(hair_ids2[min(1, hair_ids2.size() - 1)])
			custom_look["hair_color"] = CharacterPartLibrary.valid_color_for_style(String(custom_look["hair_style"]), "07")
		var outfit_ids2 := CharacterPartLibrary.style_bases_for_category("outfits")
		if outfit_ids2.size() >= 2:
			custom_look["outfit_style"] = String(outfit_ids2[min(2, outfit_ids2.size() - 1)])
			custom_look["outfit_color"] = CharacterPartLibrary.valid_color_for_style(String(custom_look["outfit_style"]), "10")
		custom_look["accessory"] = "acc_beanie_01"
	else:
		custom_look["body_presentation"] = "masculine"
	save.set_player_appearance(custom_look)
	var save2 := LocalSaveSystem.new()
	get_root().add_child(save2)
	save2.set_save_path_for_tests(TEMP_SAVE_PATH)
	var restored: Dictionary = save2.get_player_appearance()
	ok = _expect(restored.has("body_presentation"), "save/load preserves body_presentation") and ok
	if layered:
		ok = _expect(String(restored.get("hair_style", "")) == String(custom_look.get("hair_style", ""))
			and String(restored.get("hair_color", "")) == String(custom_look.get("hair_color", ""))
			and String(restored.get("outfit_style", "")) == String(custom_look.get("outfit_style", ""))
			and String(restored.get("outfit_color", "")) == String(custom_look.get("outfit_color", ""))
			and String(restored.get("accessory", "")) == "acc_beanie_01", "save/load preserves hair/outfit/accessory") and ok

	# --- Player customization does NOT change Rowan/Hazel --------------------
	var rowan_before := CharacterProfileRegistry.signature("rowan")
	var hazel_before := CharacterProfileRegistry.signature("land_clerk")
	CharacterProfileRegistry.apply_player_appearance(custom_look)
	ok = _expect(CharacterProfileRegistry.signature("rowan") == rowan_before, "Rowan unchanged by player customization") and ok
	ok = _expect(CharacterProfileRegistry.signature("land_clerk") == hazel_before, "Hazel unchanged by player customization") and ok
	CharacterProfileRegistry.clear_player_appearance()

	# --- Downward animation frames exist (>=2, 16x32) -----------------------
	var down_gen := CharacterAnimationRegistry.generator_walk_frames("down")
	ok = _expect(down_gen.size() >= 2 and (down_gen[0] as Rect2i).size == Vector2i(16, 32),
		"layered down walk has >=2 16x32 frames (%d)" % down_gen.size()) and ok

	_remove_temp_save()
	ok = _expect(not FileAccess.file_exists(TEMP_SAVE_PATH), "temp save cleaned up (no real save mutation)") and ok

	if ok:
		print("PASS: smoke_avatar_customization")
	else:
		printerr("FAIL: smoke_avatar_customization")
	quit(0 if ok else 1)

func _expect(condition: bool, label: String) -> bool:
	if condition:
		print("  OK  %s" % label)
	else:
		printerr("  FAIL  %s" % label)
	return condition

func _remove_temp_save() -> void:
	if FileAccess.file_exists(TEMP_SAVE_PATH):
		DirAccess.remove_absolute(TEMP_SAVE_PATH)
