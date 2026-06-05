extends Node
class_name FarmingSystem

const DEFAULT_CROP_ID: String = "carrot"
const STAGE_EMPTY: String = "empty"
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
		"plots": _plots,
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

func get_plot_prompt(plot_id: String) -> String:
	var plot_state: Dictionary = get_plot_state(plot_id)
	var stage: String = String(plot_state.get("stage", STAGE_EMPTY))
	var crop_id: String = String(plot_state.get("crop_id", DEFAULT_CROP_ID))
	match stage:
		STAGE_EMPTY:
			return "Press F to plant %s" % crop_id
		STAGE_PLANTED_DRY:
			return "Press F to water crop"
		STAGE_PLANTED_WATERED:
			return "Press F to tend crop"
		STAGE_GROWN:
			return "Press F to harvest %s" % crop_id
		_:
			return "Press F to inspect plot"

func interact_with_plot(plot_id: String) -> Dictionary:
	var plot_state: Dictionary = get_plot_state(plot_id)
	var stage: String = String(plot_state.get("stage", STAGE_EMPTY))
	var crop_id: String = String(plot_state.get("crop_id", DEFAULT_CROP_ID))
	match stage:
		STAGE_EMPTY:
			plant_seed(plot_id, crop_id)
			return {
				"changed": true,
				"action": "plant",
			}
		STAGE_PLANTED_DRY:
			water_plot(plot_id)
			return {
				"changed": true,
				"action": "water",
			}
		STAGE_PLANTED_WATERED:
			grow_plot(plot_id)
			return {
				"changed": true,
				"action": "grow",
			}
		STAGE_GROWN:
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

func can_plant(plot_id: String, crop_id: String) -> bool:
	if plot_id.is_empty() or crop_id.is_empty():
		return false

	var plot_state: Dictionary = get_plot_state(plot_id)
	return String(plot_state.get("stage", STAGE_EMPTY)) == STAGE_EMPTY

func plant_seed(plot_id: String, crop_id: String) -> bool:
	if not can_plant(plot_id, crop_id):
		return false

	_plots[plot_id] = {
		"crop_id": crop_id,
		"stage": STAGE_PLANTED_DRY,
	}
	return true

func water_plot(plot_id: String) -> bool:
	var plot_state: Dictionary = get_plot_state(plot_id)
	if String(plot_state.get("stage", STAGE_EMPTY)) != STAGE_PLANTED_DRY:
		return false

	plot_state["stage"] = STAGE_PLANTED_WATERED
	_plots[plot_id] = plot_state
	return true

func grow_plot(plot_id: String) -> bool:
	var plot_state: Dictionary = get_plot_state(plot_id)
	if String(plot_state.get("stage", STAGE_EMPTY)) != STAGE_PLANTED_WATERED:
		return false

	plot_state["stage"] = STAGE_GROWN
	_plots[plot_id] = plot_state
	return true

func harvest_plot(plot_id: String) -> Dictionary:
	var plot_state: Dictionary = get_plot_state(plot_id)
	if String(plot_state.get("stage", STAGE_EMPTY)) != STAGE_GROWN:
		return {}

	var harvested_crop_id: String = String(plot_state.get("crop_id", DEFAULT_CROP_ID))
	_plots[plot_id] = _create_empty_plot_state(harvested_crop_id)
	return plot_state

func _normalize_plot_state(plot_state: Dictionary) -> Dictionary:
	var crop_id: String = String(plot_state.get("crop_id", DEFAULT_CROP_ID))
	var stage: String = String(plot_state.get("stage", STAGE_EMPTY))
	if stage.is_empty():
		stage = STAGE_EMPTY

	return {
		"crop_id": crop_id,
		"stage": stage,
	}

func _create_empty_plot_state(crop_id: String = DEFAULT_CROP_ID) -> Dictionary:
	return {
		"crop_id": crop_id,
		"stage": STAGE_EMPTY,
	}
