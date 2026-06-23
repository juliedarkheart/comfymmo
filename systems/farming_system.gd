extends Node
class_name FarmingSystem

const DEFAULT_CROP_ID: String = "carrot"
const STAGE_EMPTY: String = "empty"
const STAGE_TILLED_SOIL: String = "tilled_soil"
const STAGE_PLANTED_SEED: String = "planted_seed"
const STAGE_CROP_STAGE_1: String = "crop_stage_1"
const STAGE_CROP_STAGE_2: String = "crop_stage_2"
const STAGE_CROP_STAGE_3: String = "crop_stage_3"
const STAGE_PLANTED_DRY: String = "planted_dry"
const STAGE_PLANTED_WATERED: String = "planted_watered"
const STAGE_GROWN: String = "grown"

var _plots: Dictionary = {}

func load_from_data(data: Dictionary) -> void:
	_plots.clear()
	var plot_data_variant: Variant = data.get("plots", {})
	if typeof(plot_data_variant) != TYPE_DICTIONARY:
		return

	var plot_data: Dictionary = plot_data_variant as Dictionary
	for plot_id_variant in plot_data.keys():
		var plot_id: String = String(plot_id_variant)
		var raw_plot_state: Variant = plot_data[plot_id_variant]
		if typeof(raw_plot_state) == TYPE_DICTIONARY:
			_plots[plot_id] = _normalize_plot_state(raw_plot_state as Dictionary)

func export_state() -> Dictionary:
	return {
		"plots": _plots.duplicate(true),
	}

func ensure_plot(plot_id: String) -> void:
	ensure_plot_with_crop(plot_id, DEFAULT_CROP_ID)

func ensure_plot_with_crop(plot_id: String, crop_id: String = DEFAULT_CROP_ID) -> void:
	if plot_id.is_empty() or _plots.has(plot_id):
		if _plots.has(plot_id):
			var existing_plot: Dictionary = get_plot_state(plot_id)
			if String(existing_plot.get("crop_id", "")).is_empty():
				existing_plot["crop_id"] = crop_id
				_plots[plot_id] = existing_plot
		return

	_plots[plot_id] = _create_empty_plot_state(crop_id)

func has_plot(plot_id: String) -> bool:
	return _plots.has(plot_id)

func set_plot_state(plot_id: String, plot_state: Dictionary) -> void:
	if plot_id.is_empty():
		return

	_plots[plot_id] = _normalize_plot_state(plot_state)

func remove_plot(plot_id: String) -> void:
	if plot_id.is_empty():
		return

	_plots.erase(plot_id)

func get_plot_state(plot_id: String) -> Dictionary:
	if plot_id.is_empty() or not _plots.has(plot_id):
		return _create_empty_plot_state()

	return _plots[plot_id] as Dictionary

func get_all_plot_ids() -> Array[String]:
	var ids: Array[String] = []
	for plot_id_variant in _plots.keys():
		ids.append(String(plot_id_variant))
	ids.sort()
	return ids

func get_plot_prompt(plot_id: String) -> String:
	var plot_state: Dictionary = get_plot_state(plot_id)
	var stage: String = String(plot_state.get("stage", STAGE_EMPTY))
	var crop_id: String = String(plot_state.get("crop_id", DEFAULT_CROP_ID))
	var crop_name: String = _crop_display_name(crop_id)
	match stage:
		STAGE_EMPTY:
			return "Select Hoe + F to till"
		STAGE_TILLED_SOIL:
			return "Select Seed Packet + F to plant %s" % crop_name
		STAGE_PLANTED_SEED, STAGE_CROP_STAGE_1, STAGE_CROP_STAGE_2:
			if bool(plot_state.get("watered", false)):
				return "Watered crop. Rest or Grow Crops to advance"
			return "Select Watering Can + F to water"
		STAGE_CROP_STAGE_3:
			return "Press F to harvest %s" % crop_name
		STAGE_PLANTED_DRY:
			return "Select Watering Can + F to water"
		STAGE_PLANTED_WATERED:
			return "Watered crop. Rest or Grow Crops to advance"
		STAGE_GROWN:
			return "Press F to harvest %s" % crop_name
		_:
			return "Press F to inspect plot"

## Legacy helper: still cycles a plot for tests/tools, but player code now calls
## the explicit tool-gated methods below.
func interact_with_plot(plot_id: String) -> Dictionary:
	var plot_state: Dictionary = get_plot_state(plot_id)
	var stage: String = String(plot_state.get("stage", STAGE_EMPTY))
	var crop_id: String = String(plot_state.get("crop_id", DEFAULT_CROP_ID))
	match stage:
		STAGE_EMPTY:
			till_plot(plot_id)
			return {
				"changed": true,
				"action": "till",
			}
		STAGE_TILLED_SOIL:
			plant_seed(plot_id, crop_id)
			return {
				"changed": true,
				"action": "plant",
			}
		STAGE_PLANTED_SEED, STAGE_CROP_STAGE_1, STAGE_CROP_STAGE_2, STAGE_PLANTED_DRY:
			water_plot(plot_id)
			return {
				"changed": true,
				"action": "water",
			}
		STAGE_PLANTED_WATERED:
			grow_plot(plot_id, true)
			return {
				"changed": true,
				"action": "grow",
			}
		STAGE_CROP_STAGE_3, STAGE_GROWN:
			var harvested_plot: Dictionary = harvest_plot(plot_id)
			return {
				"changed": true,
				"action": "harvest",
				"crop_id": String(harvested_plot.get("crop_id", DEFAULT_CROP_ID)),
			}
		_:
			return {
				"changed": false,
				"action": "none",
			}

func can_till(plot_id: String) -> bool:
	if plot_id.is_empty():
		return false

	var plot_state: Dictionary = get_plot_state(plot_id)
	return String(plot_state.get("stage", STAGE_EMPTY)) == STAGE_EMPTY

func till_plot(plot_id: String) -> bool:
	if not can_till(plot_id):
		return false

	var plot_state: Dictionary = get_plot_state(plot_id)
	plot_state["stage"] = STAGE_TILLED_SOIL
	plot_state["watered"] = false
	_plots[plot_id] = plot_state
	return true

func can_plant(plot_id: String, crop_id: String) -> bool:
	if plot_id.is_empty() or crop_id.is_empty():
		return false
	if not ContentRegistry.crops().has(crop_id):
		return false

	var plot_state: Dictionary = get_plot_state(plot_id)
	return String(plot_state.get("stage", STAGE_EMPTY)) == STAGE_TILLED_SOIL

func plant_seed(plot_id: String, crop_id: String) -> bool:
	if not can_plant(plot_id, crop_id):
		return false

	_plots[plot_id] = {
		"crop_id": crop_id,
		"stage": STAGE_PLANTED_SEED,
		"watered": false,
	}
	return true

func can_water(plot_id: String) -> bool:
	if plot_id.is_empty():
		return false

	var plot_state: Dictionary = get_plot_state(plot_id)
	var stage: String = String(plot_state.get("stage", STAGE_EMPTY))
	if bool(plot_state.get("watered", false)):
		return false
	return [
		STAGE_TILLED_SOIL,
		STAGE_PLANTED_SEED,
		STAGE_CROP_STAGE_1,
		STAGE_CROP_STAGE_2,
		STAGE_PLANTED_DRY,
		STAGE_PLANTED_WATERED,
	].has(stage)

func water_plot(plot_id: String) -> bool:
	var plot_state: Dictionary = get_plot_state(plot_id)
	if not can_water(plot_id):
		return false

	plot_state["watered"] = true
	_plots[plot_id] = plot_state
	return true

func grow_plot(plot_id: String, force: bool = false) -> bool:
	var plot_state: Dictionary = get_plot_state(plot_id)
	var stage: String = String(plot_state.get("stage", STAGE_EMPTY))
	if _is_mature_stage(stage) or not _is_growing_stage(stage):
		return false
	if not force and not bool(plot_state.get("watered", false)):
		return false

	plot_state["stage"] = _next_growth_stage(stage)
	plot_state["watered"] = false
	_plots[plot_id] = plot_state
	return true

func advance_all_plots(force: bool = false) -> int:
	var changed_count: int = 0
	for plot_id_variant in _plots.keys():
		if grow_plot(String(plot_id_variant), force):
			changed_count += 1
	return changed_count

func can_harvest(plot_id: String) -> bool:
	if plot_id.is_empty():
		return false
	return _is_mature_stage(String(get_plot_state(plot_id).get("stage", STAGE_EMPTY)))

func harvest_plot(plot_id: String) -> Dictionary:
	var plot_state: Dictionary = get_plot_state(plot_id)
	if not _is_mature_stage(String(plot_state.get("stage", STAGE_EMPTY))):
		return {}

	var harvested_crop_id: String = String(plot_state.get("crop_id", DEFAULT_CROP_ID))
	_plots[plot_id] = {
		"crop_id": harvested_crop_id,
		"stage": STAGE_TILLED_SOIL,
		"watered": false,
	}
	return plot_state

func _normalize_plot_state(plot_state: Dictionary) -> Dictionary:
	var crop_id: String = String(plot_state.get("crop_id", DEFAULT_CROP_ID))
	var stage: String = String(plot_state.get("stage", STAGE_EMPTY))
	if stage.is_empty():
		stage = STAGE_EMPTY
	var watered: bool = bool(plot_state.get("watered", false))
	match stage:
		STAGE_PLANTED_DRY:
			stage = STAGE_PLANTED_SEED
			watered = false
		STAGE_PLANTED_WATERED:
			stage = STAGE_CROP_STAGE_2
			watered = true
		STAGE_GROWN:
			stage = STAGE_CROP_STAGE_3
			watered = false
	if not _is_valid_stage(stage):
		stage = STAGE_EMPTY
		watered = false

	return {
		"crop_id": crop_id,
		"stage": stage,
		"watered": watered,
	}

func _create_empty_plot_state(crop_id: String = DEFAULT_CROP_ID) -> Dictionary:
	return {
		"crop_id": crop_id,
		"stage": STAGE_EMPTY,
		"watered": false,
	}

func _is_valid_stage(stage: String) -> bool:
	return [
		STAGE_EMPTY,
		STAGE_TILLED_SOIL,
		STAGE_PLANTED_SEED,
		STAGE_CROP_STAGE_1,
		STAGE_CROP_STAGE_2,
		STAGE_CROP_STAGE_3,
	].has(stage)

func _is_growing_stage(stage: String) -> bool:
	return [
		STAGE_PLANTED_SEED,
		STAGE_CROP_STAGE_1,
		STAGE_CROP_STAGE_2,
		STAGE_PLANTED_DRY,
		STAGE_PLANTED_WATERED,
	].has(stage)

func _is_mature_stage(stage: String) -> bool:
	return stage == STAGE_CROP_STAGE_3 or stage == STAGE_GROWN

func _next_growth_stage(stage: String) -> String:
	match stage:
		STAGE_PLANTED_SEED, STAGE_CROP_STAGE_1, STAGE_PLANTED_DRY:
			return STAGE_CROP_STAGE_2
		STAGE_CROP_STAGE_2, STAGE_PLANTED_WATERED:
			return STAGE_CROP_STAGE_3
		_:
			return stage

func _crop_display_name(crop_id: String) -> String:
	var crop: Dictionary = ContentRegistry.crops().get(crop_id, {}) as Dictionary
	if crop.is_empty():
		return crop_id.capitalize()
	return String(crop.get("display_name", crop_id.capitalize()))
