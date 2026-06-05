extends Node
class_name CombatSystem

var active_encounter_id: String = ""

func request_combat(encounter_id: String, _context: Dictionary = {}) -> bool:
	if encounter_id.is_empty():
		return false

	active_encounter_id = encounter_id
	return false

func end_combat() -> void:
	active_encounter_id = ""
