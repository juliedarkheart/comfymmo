extends Node

const WORLD_SYSTEM_PATH := "res://world/world_system.gd"
const MULTIPLAYER_SYSTEM_PATH := "res://multiplayer/multiplayer_service.gd"
const WORLD_REGION_MANAGER_PATH := "res://systems/world_region_manager.gd"

var world_system: Node
var multiplayer_service: Node
var world_region_manager: Node

func _ready() -> void:
	_bootstrap_services()
	_load_starting_world()
	print("Hearthvale prototype loaded.")

func _bootstrap_services() -> void:
	world_system = _load_service(WORLD_SYSTEM_PATH, "WorldSystem")
	multiplayer_service = _load_service(MULTIPLAYER_SYSTEM_PATH, "MultiplayerService")
	world_region_manager = _load_service(WORLD_REGION_MANAGER_PATH, "WorldRegionManager")

func _load_service(script_path: String, node_name: String) -> Node:
	var script: Script = load(script_path) as Script
	var service: Node = Node.new()
	service.name = node_name
	service.set_script(script)
	add_child(service)
	return service

func _load_starting_world() -> void:
	return
