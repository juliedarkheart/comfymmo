extends Node
class_name SurvivalSystem

signal survival_changed()

const DEFAULT_STATS: Dictionary = {
	"energy": 100.0,
	"hunger": 100.0,
	"comfort": 50.0,
}

var _stats: Dictionary = DEFAULT_STATS.duplicate(true)

func load_from_data(data: Dictionary) -> void:
	_stats = DEFAULT_STATS.duplicate(true)
	for stat_name in DEFAULT_STATS.keys():
		if data.has(stat_name):
			_stats[String(stat_name)] = clampf(float(data[stat_name]), 0.0, 100.0)

func export_state() -> Dictionary:
	return _stats

func get_stat(stat_name: String) -> float:
	return float(_stats.get(stat_name, 0.0))

func set_stat(stat_name: String, value: float) -> void:
	_stats[stat_name] = clampf(value, 0.0, 100.0)
	survival_changed.emit()

func add_to_stat(stat_name: String, amount: float) -> void:
	set_stat(stat_name, get_stat(stat_name) + amount)
