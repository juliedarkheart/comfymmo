extends Node
class_name RegionTransitionSystem

signal transition_requested(target_region_id: String, target_spawn_id: String)

func request_transition(target_region_id: String, target_spawn_id: String = "default") -> void:
	if target_region_id.is_empty():
		return

	transition_requested.emit(target_region_id, target_spawn_id)
