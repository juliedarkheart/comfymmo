extends Node2D

@onready var map: HomesteadMap = $Map
@onready var player_spawn_system: PlayerSpawnSystem = $PlayerSpawnSystem

func _ready() -> void:
	player_spawn_system.spawn_player(self, map.get_spawn_position())
