extends Node
class_name DungeonSystem

var combat_system: CombatSystem
var _dungeon_registry: Dictionary = {
	"rooted_cellar": {
		"id": "rooted_cellar",
		"display_name": "Rooted Cellar",
		"status": "placeholder",
	}
}
var _active_dungeon_id: String = ""

func configure(target_combat_system: CombatSystem) -> void:
	combat_system = target_combat_system

func get_available_dungeons() -> Array[Dictionary]:
	var dungeons: Array[Dictionary] = []
	for dungeon_id in _dungeon_registry.keys():
		dungeons.append(_dungeon_registry[dungeon_id] as Dictionary)
	return dungeons

func enter_dungeon(dungeon_id: String) -> bool:
	if not _dungeon_registry.has(dungeon_id):
		return false

	_active_dungeon_id = dungeon_id
	return false

func leave_dungeon() -> void:
	_active_dungeon_id = ""
