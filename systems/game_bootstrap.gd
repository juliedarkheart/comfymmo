extends Node

const WORLD_SYSTEM_PATH := "res://world/world_system.gd"
const MULTIPLAYER_SYSTEM_PATH := "res://multiplayer/multiplayer_service.gd"
const HOMESTEAD_SCENE := preload("res://scenes/world/homestead.tscn")

var world_system: Node
var multiplayer_service: Node
var active_world: Node

func _ready() -> void:
	_bootstrap_services()
	_load_starting_world()
	print("Hearthvale prototype loaded.")

func _bootstrap_services() -> void:
	world_system = _load_service(WORLD_SYSTEM_PATH, "WorldSystem")
	multiplayer_service = _load_service(MULTIPLAYER_SYSTEM_PATH, "MultiplayerService")

func _load_service(script_path: String, node_name: String) -> Node:
	var script := load(script_path)
	var service := Node.new()
	service.name = node_name
	service.set_script(script)
	add_child(service)
	return service

func _load_starting_world() -> void:
	active_world = HOMESTEAD_SCENE.instantiate()
	add_child(active_world)
