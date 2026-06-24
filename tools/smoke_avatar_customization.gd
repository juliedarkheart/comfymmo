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
		# --- Julie default is the curated layered look (not forced masculine) ---
		ok = _expect(String(default_look.get("body_presentation", "")) == "feminine",
			"Julie default body_presentation = feminine (not masculine)") and ok
		ok = _expect(String(default_look.get("hair_style", "")) == "hair_22_04", "Julie default hair = hair_22_04") and ok
		ok = _expect(String(default_look.get("outfit_style", "")) == "outfit_14_03", "Julie default outfit = outfit_14_03") and ok
		ok = _expect(String(default_look.get("accessory", "")) == "acc_ladybug_01", "Julie default accessory = ladybug") and ok

		var base_sig := CharacterPartLibrary.render_signature(default_look)
		ok = _expect(not base_sig.is_empty() and base_sig.split("|").size() >= 4,
			"Julie default render signature has >=4 layers (%s)" % base_sig) and ok

		# --- Each editable field CHANGES the rendered layer signature ----------
		var body_look := default_look.duplicate(); body_look["body_presentation"] = "masculine"
		ok = _expect(CharacterPartLibrary.render_signature(body_look) != base_sig, "body change alters render signature") and ok

		var hair_look := default_look.duplicate(); hair_look["hair_style"] = "hair_28_01"
		ok = _expect(CharacterPartLibrary.render_signature(hair_look) != base_sig, "hair change alters render signature") and ok

		var outfit_look := default_look.duplicate(); outfit_look["outfit_style"] = "outfit_05_01"
		ok = _expect(CharacterPartLibrary.render_signature(outfit_look) != base_sig, "outfit change alters render signature") and ok

		var acc_look := default_look.duplicate(); acc_look["accessory"] = "acc_beanie_01"
		ok = _expect(CharacterPartLibrary.render_signature(acc_look) != base_sig, "accessory change alters render signature") and ok

		# --- Accessory None removes the accessory layer -----------------------
		var none_look := default_look.duplicate(); none_look["accessory"] = "none"
		var none_sig := CharacterPartLibrary.render_signature(none_look)
		ok = _expect(none_sig != base_sig and none_sig.split("|").size() == base_sig.split("|").size() - 1,
			"accessory None removes the accessory layer") and ok

		# --- Layered part textures resolve ------------------------------------
		var body_pid := CharacterPartLibrary.presentation_body("feminine")
		ok = _expect(CharacterPartLibrary.resolve_texture(String(CharacterPartLibrary.part_entry(body_pid).get("file", ""))) != null,
			"Julie body texture resolves") and ok
		ok = _expect(CharacterPartLibrary.resolve_texture(String(CharacterPartLibrary.part_entry("hair_22_04").get("file", ""))) != null,
			"Julie hair texture resolves") and ok
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
	var custom_look: Dictionary = CharacterAppearance.default_appearance()
	custom_look["body_presentation"] = "masculine"
	if layered:
		custom_look["hair_style"] = "hair_28_01"
		custom_look["outfit_style"] = "outfit_05_01"
		custom_look["accessory"] = "acc_beanie_01"
	save.set_player_appearance(custom_look)
	var save2 := LocalSaveSystem.new()
	get_root().add_child(save2)
	save2.set_save_path_for_tests(TEMP_SAVE_PATH)
	var restored: Dictionary = save2.get_player_appearance()
	ok = _expect(String(restored.get("body_presentation", "")) == "masculine", "save/load preserves body_presentation") and ok
	if layered:
		ok = _expect(String(restored.get("hair_style", "")) == "hair_28_01" \
			and String(restored.get("outfit_style", "")) == "outfit_05_01" \
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
