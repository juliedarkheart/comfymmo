extends SceneTree

## Headless smoke test for the playable homestead loop: till -> plant -> grow ->
## harvest -> inventory -> placed object -> save/load roundtrip. It exercises the
## underlying systems directly (no input simulation, no licensed assets needed).
##
## SAVE SAFETY: it uses a dedicated temporary test save path, then deletes that
## file. It does not read, write, move, or restore the real player save. Run:
##   Godot --headless --path . --script res://tools/smoke_homestead_loop.gd

const TEMP_SAVE_PATH: String = "user://homestead_loop_smoke_test.json"

func _initialize() -> void:
	var ok: bool = true
	_remove_temp_save()

	# --- Farming data loop (no file) -----------------------------------------
	var fs := FarmingSystem.new()
	get_root().add_child(fs)
	fs.ensure_plot_with_crop("smoke_plot", "carrot")
	ok = _expect(fs.get_plot_state("smoke_plot").get("stage") == FarmingSystem.STAGE_EMPTY, "plot starts empty") and ok
	ok = _expect(fs.till_plot("smoke_plot") and fs.get_plot_state("smoke_plot").get("stage") == FarmingSystem.STAGE_TILLED_SOIL, "hoe -> tilled_soil") and ok
	ok = _expect(fs.plant_seed("smoke_plot", "carrot") and fs.get_plot_state("smoke_plot").get("stage") == FarmingSystem.STAGE_PLANTED_SEED, "plant -> planted_seed") and ok
	fs.grow_plot("smoke_plot", true)
	ok = _expect(fs.get_plot_state("smoke_plot").get("stage") == FarmingSystem.STAGE_CROP_STAGE_2, "grow -> crop_stage_2") and ok
	fs.grow_plot("smoke_plot", true)
	ok = _expect(fs.can_harvest("smoke_plot"), "grow -> harvestable") and ok
	# Capture the mature state so save/load proves crop-stage persistence; harvest after.
	var farm_state: Dictionary = fs.export_state()
	var harvested: Dictionary = fs.harvest_plot("smoke_plot")
	ok = _expect(not harvested.is_empty() and String(harvested.get("crop_id")) == "carrot", "harvest returns carrot") and ok
	ok = _expect(fs.get_plot_state("smoke_plot").get("stage") == FarmingSystem.STAGE_TILLED_SOIL, "after harvest -> tilled_soil (no double-harvest)") and ok

	# --- Inventory: harvested crop increases ---------------------------------
	var inv := InventorySystem.new()
	get_root().add_child(inv)
	inv.add_item("carrot", 1)
	inv.add_item("carrot", 1)
	ok = _expect(inv.get_quantity("carrot") == 2, "inventory carrot count = 2") and ok
	ok = _expect(inv.remove_item("carrot", 1) and inv.get_quantity("carrot") == 1, "seed/crop decrement works") and ok
	var inv_state: Dictionary = inv.export_state()

	# --- Placed object record (the format BuildingPlacementSystem persists) ---
	var placed: Array[Dictionary] = [{"record_id": "crate_0001", "object_id": "crate", "tile_x": 8, "tile_y": 13}]

	# --- Save/load roundtrip through a temporary smoke-test save path ---------
	var save := LocalSaveSystem.new()
	get_root().add_child(save)
	save.set_save_path_for_tests(TEMP_SAVE_PATH)
	save.set_region_farming(save.DEFAULT_REGION_ID, farm_state)
	save.set_region_placed_objects(save.DEFAULT_REGION_ID, placed)
	var write_data: Dictionary = save.load_save_data()
	var player_section: Dictionary = write_data.get("player", {}) as Dictionary
	player_section["inventory"] = inv_state
	write_data["player"] = player_section
	save.save_save_data(write_data)

	# Reload fresh and verify everything stuck.
	var reloaded: Dictionary = save.load_save_data()
	var loaded_farm: Dictionary = save.get_region_farming(save.DEFAULT_REGION_ID)
	var loaded_placed: Array[Dictionary] = save.get_region_placed_objects(save.DEFAULT_REGION_ID)

	var fs2 := FarmingSystem.new()
	get_root().add_child(fs2)
	fs2.load_from_data(loaded_farm)
	ok = _expect(fs2.can_harvest("smoke_plot"), "save/load: crop still harvestable") and ok

	var inv2 := InventorySystem.new()
	get_root().add_child(inv2)
	inv2.load_from_data((reloaded.get("player", {}) as Dictionary).get("inventory", {}))
	ok = _expect(inv2.get_quantity("carrot") == 1, "save/load: inventory carrot persists") and ok

	ok = _expect(loaded_placed.size() == 1 and String(loaded_placed[0].get("object_id")) == "crate", "save/load: placed crate persists") and ok

	# --- remove the temporary test save (never mutate real player data) -------
	_remove_temp_save()

	print("SMOKE homestead loop: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)

func _expect(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond

func _remove_temp_save() -> void:
	if FileAccess.file_exists(TEMP_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SAVE_PATH))
