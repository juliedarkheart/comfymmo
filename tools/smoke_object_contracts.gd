extends SceneTree

## Headless smoke test for the object-contract pass: every visible/playable object has a clear
## contract (category + collision + interaction), physical props build a collider, interactive
## props have a prompt+action (no silent/fake F), and placed crate/sign/fence serialize and
## restore their object id (collision + interaction are rebuilt from it on load).
##
## SAVE SAFETY: uses a dedicated temporary test save path and deletes it. It never reads,
## writes, or restores the real player save. Run:
##   Godot --headless --path . --script res://tools/smoke_object_contracts.gd

const TEMP_SAVE_PATH: String = "user://object_contracts_smoke_test.json"

func _initialize() -> void:
	var ok: bool = true
	_remove_temp_save()

	# --- 1) Known contracts exist with the right shape ------------------------
	ok = _expect(AssetWorldMetadata.object_category("object.crate") == AssetWorldMetadata.CATEGORY_STORAGE \
		and AssetWorldMetadata.is_blocking("object.crate") \
		and AssetWorldMetadata.interaction_enabled("object.crate"), "crate contract: storage + blocks + interactable") and ok
	ok = _expect(AssetWorldMetadata.interaction_response("object.crate") != "", "crate has a response (no silent F)") and ok
	ok = _expect(AssetWorldMetadata.object_category("object.sign") == AssetWorldMetadata.CATEGORY_SIGN \
		and AssetWorldMetadata.interaction_enabled("object.sign"), "sign contract: sign + interactable") and ok
	ok = _expect(AssetWorldMetadata.object_category("object.fence_horizontal") == AssetWorldMetadata.CATEGORY_FENCE \
		and AssetWorldMetadata.is_blocking("object.fence_horizontal"), "fence contract: fence + blocks") and ok

	# --- 2) Physical props carry collision shapes to build from ---------------
	for solid_id in ["object.crate", "object.barn", "object.tree", "object.fence_horizontal"]:
		ok = _expect(AssetWorldMetadata.has_asset_collision_shapes(solid_id), "physical '%s' has collision shapes" % solid_id) and ok

	# --- 3) No fake prompts: every interactive contract has a prompt; every toast
	#        interaction has a response; decor is intentionally non-interactive. --
	for cid in AssetWorldMetadata.interactable_ids():
		ok = _expect(AssetWorldMetadata.interaction_prompt(cid) != "", "interactive '%s' has a prompt" % cid) and ok
		if AssetWorldMetadata.has_toast_interaction(cid):
			ok = _expect(AssetWorldMetadata.interaction_response(cid) != "", "toast '%s' has a response" % cid) and ok
	ok = _expect(not AssetWorldMetadata.interaction_enabled("object.tree_small") \
		and not AssetWorldMetadata.is_blocking("object.tree_small"), "decor tree_small: no prompt, pass-through") and ok
	ok = _expect(not AssetWorldMetadata.is_blocking("object.flower"), "decor flower stays pass-through") and ok

	# --- 4) Placed-object collision is rebuildable from the contract ----------
	var tile_size := Vector2i(32, 32)
	var crate_body := StaticBody2D.new()
	get_root().add_child(crate_body)
	var crate_status: String = PlacedObjectCollision.apply_to_placed(crate_body, "object.crate", Vector2i(1, 1), tile_size)
	ok = _expect(crate_status == "metadata_blocking" and crate_body.get_child_count() > 0, "placed crate builds a blocking collider") and ok
	var flower_body := StaticBody2D.new()
	get_root().add_child(flower_body)
	var flower_status: String = PlacedObjectCollision.apply_to_placed(flower_body, "object.flower", Vector2i(1, 1), tile_size)
	ok = _expect(flower_status == "metadata_none", "placed decor flower stays non-blocking") and ok

	# --- 5) Placeable -> asset contract bridge --------------------------------
	ok = _expect(AssetWorldMetadata.asset_id_for_placeable("crate") == "object.crate" \
		and AssetWorldMetadata.asset_id_for_placeable("signpost") == "object.sign" \
		and AssetWorldMetadata.asset_id_for_placeable("fence_segment") == "object.fence_horizontal", "placeable->asset bridge maps crate/sign/fence") and ok

	# --- 6) Placed crate/sign/fence serialize + restore their object id -------
	var placed: Array[Dictionary] = [
		{"record_id": "crate_9001", "object_id": "crate", "tile_x": 8, "tile_y": 13},
		{"record_id": "sign_9002", "object_id": "signpost", "tile_x": 9, "tile_y": 13},
		{"record_id": "fence_9003", "object_id": "fence_segment", "tile_x": 10, "tile_y": 13},
	]
	var save := LocalSaveSystem.new()
	get_root().add_child(save)
	save.set_save_path_for_tests(TEMP_SAVE_PATH)
	save.set_region_placed_objects(save.DEFAULT_REGION_ID, placed)
	# Reload through a FRESH save instance on the same temp path = true disk roundtrip.
	var save2 := LocalSaveSystem.new()
	get_root().add_child(save2)
	save2.set_save_path_for_tests(TEMP_SAVE_PATH)
	var reloaded: Array[Dictionary] = save2.get_region_placed_objects(save2.DEFAULT_REGION_ID)
	ok = _expect(reloaded.size() == 3, "save/load: all 3 placed objects persist") and ok
	var by_id := {}
	for record in reloaded:
		by_id[String(record.get("object_id", ""))] = record
	ok = _expect(by_id.has("crate") and by_id.has("signpost") and by_id.has("fence_segment"), "save/load: crate/sign/fence object ids restored") and ok
	# Collision + interaction metadata are derived from object_id on load, so a restored
	# record is enough to rebuild both.
	var crate_asset: String = AssetWorldMetadata.asset_id_for_placeable("crate")
	ok = _expect(AssetWorldMetadata.is_blocking(crate_asset) and AssetWorldMetadata.has_toast_interaction(crate_asset), "save/load: crate collision + interaction rebuildable from id") and ok

	_remove_temp_save()

	# --- 7) Buildable objects have player-facing names and prompts ------------
	var buildable_ids: Array = ["crate", "signpost", "fence_segment", "well", "workbench", "mailbox"]
	for bid in buildable_ids:
		var asset_id: String = AssetWorldMetadata.asset_id_for_placeable(bid)
		if asset_id.is_empty():
			continue
		var entry: Dictionary = ContentRegistry.placeables().get(bid, {}) as Dictionary
		var name_text: String = String(entry.get("display_name", ""))
		ok = _expect(not name_text.is_empty(), "buildable '%s' has a display name" % bid) and ok
		ok = _expect(not name_text.contains("admin"), "buildable '%s' name has no debug language" % bid) and ok
		if AssetWorldMetadata.interaction_enabled(asset_id):
			var prompt: String = AssetWorldMetadata.interaction_prompt(asset_id)
			ok = _expect(not prompt.is_empty(), "interactive buildable '%s' has a prompt" % bid) and ok
			ok = _expect(not prompt.contains("admin"), "buildable '%s' prompt has no debug language" % bid) and ok

	print("SMOKE object contracts: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)

func _expect(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond

func _remove_temp_save() -> void:
	if FileAccess.file_exists(TEMP_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SAVE_PATH))
