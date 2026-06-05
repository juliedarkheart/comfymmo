extends Node
class_name WorldRegionManager

const HOMESTEAD_REGION_SCENE := preload("res://scenes/world/regions/homestead/homestead_region.tscn")
const VILLAGE_SQUARE_REGION_SCENE := preload("res://scenes/world/regions/village_square/village_square_region.tscn")
const FOREST_EDGE_REGION_SCENE := preload("res://scenes/world/regions/forest_edge/forest_edge_region.tscn")
const TRANSITION_COOLDOWN_MSEC: int = 400

var save_system: LocalSaveSystem
var _region_definitions: Dictionary = {}
var _active_region: BaseRegionController
var _region_root: Node
var _transition_cooldown_until_msec: int = 0
var _last_transition_from_region_id: String = ""
var _last_transition_to_region_id: String = ""

func _ready() -> void:
	save_system = LocalSaveSystem.new()
	save_system.name = "LocalSaveSystem"
	add_child(save_system)

	_region_root = Node.new()
	_region_root.name = "RegionRoot"
	add_child(_region_root)

	_register_default_regions()
	_load_starting_region()

func transition_to_region(region_id: String, spawn_id: String = "default") -> void:
	var now_msec: int = Time.get_ticks_msec()
	var source_region_id: String = ""
	if _active_region != null and is_instance_valid(_active_region):
		source_region_id = _active_region.get_region_id()

	if (
		now_msec < _transition_cooldown_until_msec
		and source_region_id == _last_transition_to_region_id
		and region_id == _last_transition_from_region_id
	):
		return

	if not _region_definitions.has(region_id):
		push_warning("Unknown region id: %s" % region_id)
		return

	save_system.set_current_region_id(region_id)

	if _active_region != null and is_instance_valid(_active_region):
		_region_root.remove_child(_active_region)
		_active_region.queue_free()

	_load_region(region_id, spawn_id)
	_last_transition_from_region_id = source_region_id
	_last_transition_to_region_id = region_id
	_transition_cooldown_until_msec = now_msec + TRANSITION_COOLDOWN_MSEC

func _load_starting_region() -> void:
	var starting_region_id: String = save_system.get_current_region_id()
	if not _region_definitions.has(starting_region_id):
		starting_region_id = "homestead"

	_load_region(starting_region_id, "default")

func _load_region(region_id: String, spawn_id: String) -> void:
	var region_definition: RegionDefinition = _region_definitions[region_id] as RegionDefinition
	if region_definition == null or region_definition.scene == null:
		return

	var region: BaseRegionController = region_definition.scene.instantiate() as BaseRegionController
	region.set_region_id(region_definition.region_id)
	region.set_entry_spawn_id(spawn_id)
	region.region_transition_requested.connect(_on_region_transition_requested)
	_region_root.add_child(region)
	_active_region = region

func _on_region_transition_requested(target_region_id: String, target_spawn_id: String) -> void:
	transition_to_region(target_region_id, target_spawn_id)

func _register_default_regions() -> void:
	_register_region("homestead", "Homestead", HOMESTEAD_REGION_SCENE)
	_register_region("village_square", "Village Square", VILLAGE_SQUARE_REGION_SCENE)
	_register_region("forest_edge", "Forest Edge", FOREST_EDGE_REGION_SCENE)

func _register_region(region_id: String, display_name: String, scene: PackedScene) -> void:
	var region_definition: RegionDefinition = RegionDefinition.new()
	region_definition.region_id = region_id
	region_definition.display_name = display_name
	region_definition.scene = scene
	_region_definitions[region_id] = region_definition
