extends SceneTree

## Headless smoke test for character identity + the customization foundation: named actors load
## distinct visual profiles (no farmer clone), the player/Rowan signatures differ, NPC signatures
## are not all identical, and the player customization serializes/restores and falls back safely.
##
## SAVE SAFETY: uses a dedicated temporary test save path and deletes it. It never reads, writes,
## or restores the real player save. Run:
##   Godot --headless --path . --script res://tools/smoke_character_identity.gd

const TEMP_SAVE_PATH: String = "user://character_identity_smoke_test.json"

func _initialize() -> void:
	var ok: bool = true
	_remove_temp_save()
	CharacterProfileRegistry.clear_player_appearance()

	# --- 1) Required profiles load ------------------------------------------
	for actor_id in CharacterProfileRegistry.required_profile_ids():
		var profile: Dictionary = CharacterProfileRegistry.profile_for(actor_id)
		ok = _expect(CharacterProfileRegistry.has(actor_id) and not profile.is_empty() \
			and not String(profile.get("sheet", "")).is_empty(), "profile loads: %s" % actor_id) and ok

	# --- 2) Player and Rowan are distinct -----------------------------------
	ok = _expect(CharacterProfileRegistry.signature("player") != CharacterProfileRegistry.signature("rowan"),
		"player and Rowan signatures differ") and ok
	ok = _expect(CharacterProfileRegistry.sheet_id("player") != CharacterProfileRegistry.sheet_id("rowan"),
		"player and Rowan use different base sheets") and ok

	# --- 3) Named NPCs are not all identical --------------------------------
	var npc_sigs := {}
	for npc_id in ["rowan", "maribel_tock", "bram_nettle", "land_clerk"]:
		npc_sigs[CharacterProfileRegistry.signature(npc_id)] = true
	ok = _expect(npc_sigs.size() >= 3, "named NPCs have varied signatures (%d distinct)" % npc_sigs.size()) and ok

	# --- 4) All required signatures unique ----------------------------------
	var all_sigs := {}
	for req_id in CharacterProfileRegistry.required_profile_ids():
		all_sigs[CharacterProfileRegistry.signature(req_id)] = true
	ok = _expect(all_sigs.size() == CharacterProfileRegistry.required_profile_ids().size(),
		"all required actor signatures are unique") and ok

	# Named NPCs must use a CLOTHED base sheet — never the bare Body_2 (that rendered Hazel as a
	# naked pink figure in live play).
	for clothed_npc in ["rowan", "maribel_tock", "bram_nettle", "land_clerk", "generic_villager_1", "generic_villager_2"]:
		ok = _expect(CharacterProfileRegistry.sheet_id(clothed_npc) != "character.body2_idle",
			"NPC '%s' uses a clothed sheet (not the bare Body_2)" % clothed_npc) and ok

	# Clean-checkout body-presentation fallback must never resolve to the bare Body_2 for ANY
	# presentation option — the full-body fallback sprites are the clothed Farmer sheets.
	for presentation_id in CharacterAppearanceRegistry.body_presentations().keys():
		ok = _expect(CharacterAppearanceRegistry.body_presentation_sheet(String(presentation_id)) != "character.body2_idle",
			"body presentation '%s' falls back to a clothed sheet (not bare Body_2)" % String(presentation_id)) and ok
	ok = _expect(CharacterAppearanceRegistry.body_presentation_sheet("feminine") != "character.body2_idle",
		"feminine fallback presentation is clothed (not the bare Body_2)") and ok
	# A player who saved a feminine body_presentation in clean-checkout mode must render clothed.
	CharacterProfileRegistry.apply_player_appearance({"body_presentation": "feminine", "outfit_color": "rose"})
	ok = _expect(CharacterProfileRegistry.sheet_id("player") != "character.body2_idle",
		"player feminine fallback presentation is clothed (not bare Body_2)") and ok
	CharacterProfileRegistry.clear_player_appearance()

	# --- 5) Customization default serialize/deserialize ---------------------
	var default_look: Dictionary = CharacterAppearance.default_appearance()
	ok = _expect(not default_look.is_empty() and default_look.has("outfit_color"), "customization default exists") and ok
	# In layered mode, the default appearance may normalize to a different first valid
	# ID (e.g. "hair_01_01" instead of "round_bob"). But all slots must be valid.
	var norm := CharacterAppearance.normalized(default_look)
	ok = _expect(not norm.is_empty(), "default appearance normalizes non-empty") and ok
	for slot in default_look.keys():
		if slot == "hair_color":
			ok = _expect(CharacterPartLibrary.colors_for_style_base(String(norm.get("hair_style", ""))).has(String(norm.get(slot, ""))),
				"normalized slot '%s' is valid" % slot) and ok
		elif slot == "outfit_color":
			ok = _expect(CharacterPartLibrary.colors_for_style_base(String(norm.get("outfit_style", ""))).has(String(norm.get(slot, ""))),
				"normalized slot '%s' is valid" % slot) and ok
		else:
			ok = _expect(CharacterAppearanceRegistry.has_option(
				_opt_for_slot(slot), String(norm.get(slot, ""))
			), "normalized slot '%s' is valid" % slot) and ok

	# --- 6) Customization saves + restores through a temp save (no real save) -
	var save := LocalSaveSystem.new()
	get_root().add_child(save)
	save.set_save_path_for_tests(TEMP_SAVE_PATH)
	var custom_look: Dictionary = CharacterAppearance.default_appearance()
	# Use a hair style id valid in the current registry (layered or legacy)
	var hair_ids := CharacterAppearanceRegistry.hair_styles().keys()
	if hair_ids.size() >= 2:
		custom_look["hair_style"] = String(hair_ids[1])  # second style
		custom_look["hair_color"] = CharacterPartLibrary.valid_color_for_style(String(custom_look["hair_style"]), "07")
	var outfit_ids := CharacterAppearanceRegistry.outfit_styles().keys()
	if outfit_ids.size() >= 2:
		custom_look["outfit_style"] = String(outfit_ids[1])
		custom_look["outfit_color"] = CharacterPartLibrary.valid_color_for_style(String(custom_look["outfit_style"]), "04")
	var body_ids := CharacterAppearanceRegistry.body_presentations().keys()
	if body_ids.size() >= 2:
		custom_look["body_presentation"] = String(body_ids[1])
	save.set_player_appearance(custom_look)
	var save2 := LocalSaveSystem.new()
	get_root().add_child(save2)
	save2.set_save_path_for_tests(TEMP_SAVE_PATH)
	var restored: Dictionary = save2.get_player_appearance()
	ok = _expect(String(restored.get("hair_style", "")) == custom_look["hair_style"] \
		and String(restored.get("hair_color", "")) == custom_look["hair_color"] \
		and String(restored.get("outfit_style", "")) == custom_look["outfit_style"] \
		and String(restored.get("outfit_color", "")) == custom_look["outfit_color"], "customization saves + restores") and ok

	# --- 7) Customization drives the player profile, then reverts cleanly ----
	var base_player_sig: String = CharacterProfileRegistry.signature("player")
	CharacterProfileRegistry.apply_player_appearance(custom_look)
	var custom_player_sig: String = CharacterProfileRegistry.signature("player")
	ok = _expect(custom_player_sig != base_player_sig, "applied customization changes the player palette") and ok
	ok = _expect(CharacterProfileRegistry.signature("player") != CharacterProfileRegistry.signature("rowan"),
		"customized player is still distinct from Rowan") and ok
	CharacterProfileRegistry.clear_player_appearance()
	ok = _expect(CharacterProfileRegistry.signature("player") == base_player_sig, "clearing customization reverts to default Julie") and ok

	# --- 8) Missing customization falls back to default ---------------------
	var empty_save := LocalSaveSystem.new()
	get_root().add_child(empty_save)
	empty_save.set_save_path_for_tests("user://character_identity_missing_test.json")
	if FileAccess.file_exists("user://character_identity_missing_test.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://character_identity_missing_test.json"))
	ok = _expect(empty_save.get_player_appearance() == CharacterAppearance.default_appearance(),
		"missing customization falls back to default") and ok

	# --- 9) Nameplate sits clearly above the avatar with UI-consistent styling ---
	var dummy := Node2D.new()
	get_root().add_child(dummy)
	var plate: Node2D = Nameplate.attach(dummy, "Test Name", "", Color("#bfe0ff"))
	ok = _expect(plate != null and plate.get_child_count() >= 1, "nameplate attaches with a name label") and ok
	if plate != null:
		# Avatar is ~64px tall (feet at 0); the plate must sit clearly above the head/hat.
		ok = _expect(plate.position.y <= -70.0, "nameplate sits clearly above the avatar (y=%.0f, not cutting into head)" % plate.position.y) and ok
		var name_lbl := plate.get_child(0) as Label
		ok = _expect(name_lbl != null and name_lbl.text == "Test Name", "nameplate label carries the character name") and ok
		ok = _expect(name_lbl != null and name_lbl.has_theme_font_size_override("font_size") \
			and name_lbl.has_theme_constant_override("outline_size"), "nameplate label uses UI-consistent font + outline styling") and ok
	dummy.queue_free()

	_remove_temp_save()
	print("SMOKE character identity: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)

func _expect(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond

func _remove_temp_save() -> void:
	if FileAccess.file_exists(TEMP_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SAVE_PATH))

func _opt_for_slot(slot: String) -> Dictionary:
	match slot:
		"body_presentation": return CharacterAppearanceRegistry.body_presentations()
		"body_style": return CharacterAppearanceRegistry.body_styles()
		"skin_tone": return CharacterAppearanceRegistry.skin_tones()
		"hair_style": return CharacterAppearanceRegistry.hair_styles()
		"hair_color": return CharacterAppearanceRegistry.palette()
		"outfit_style": return CharacterAppearanceRegistry.outfit_styles()
		"outfit_color": return CharacterAppearanceRegistry.palette()
		"accessory": return CharacterAppearanceRegistry.accessories()
		"face_style": return CharacterAppearanceRegistry.face_styles()
		"eyes": return CharacterAppearanceRegistry.eyes()
	return {}
