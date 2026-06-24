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

	# --- 5) Customization default serialize/deserialize ---------------------
	var default_look: Dictionary = CharacterAppearance.default_appearance()
	ok = _expect(not default_look.is_empty() and default_look.has("outfit_color"), "customization default exists") and ok
	# In layered mode, the default appearance may normalize to a different first valid
	# ID (e.g. "hair_01_01" instead of "round_bob"). But all slots must be valid.
	var norm := CharacterAppearance.normalized(default_look)
	ok = _expect(not norm.is_empty(), "default appearance normalizes non-empty") and ok
	for slot in default_look.keys():
		ok = _expect(CharacterAppearanceRegistry.has_option(
			_opt_for_slot(slot), String(norm.get(slot, ""))
		), "normalized slot '%s' is valid" % slot) and ok

	# --- 6) Customization saves + restores through a temp save (no real save) -
	var save := LocalSaveSystem.new()
	get_root().add_child(save)
	save.set_save_path_for_tests(TEMP_SAVE_PATH)
	var custom_look: Dictionary = CharacterAppearance.default_appearance()
	custom_look["outfit_color"] = "berry_red"
	# Use a hair style id valid in the current registry (layered or legacy)
	var hair_ids := CharacterAppearanceRegistry.hair_styles().keys()
	if hair_ids.size() >= 2:
		custom_look["hair_style"] = String(hair_ids[1])  # second style
	save.set_player_appearance(custom_look)
	var save2 := LocalSaveSystem.new()
	get_root().add_child(save2)
	save2.set_save_path_for_tests(TEMP_SAVE_PATH)
	var restored: Dictionary = save2.get_player_appearance()
	ok = _expect(String(restored.get("outfit_color", "")) == "berry_red" \
		and String(restored.get("hair_style", "")) == custom_look["hair_style"], "customization saves + restores") and ok

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
	return {}
