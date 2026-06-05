extends Node
class_name CreatureSystem

var _creatures: Array[Dictionary] = []

func load_from_data(data: Dictionary) -> void:
	_creatures.clear()
	var creature_records: Variant = data.get("creatures", [])
	if typeof(creature_records) != TYPE_ARRAY:
		return

	for creature_record in creature_records:
		if typeof(creature_record) == TYPE_DICTIONARY:
			_creatures.append(creature_record)

func export_state() -> Dictionary:
	return {
		"creatures": _creatures,
	}

func spawn_placeholder_creature(creature_id: String, origin_tile: Vector2i) -> Dictionary:
	var record: Dictionary = {
		"record_id": "%s_%s_%s" % [creature_id, origin_tile.x, origin_tile.y],
		"creature_id": creature_id,
		"tile_x": origin_tile.x,
		"tile_y": origin_tile.y,
		"bond_level": 0,
	}
	_creatures.append(record)
	return record

func get_creatures() -> Array[Dictionary]:
	return _creatures
