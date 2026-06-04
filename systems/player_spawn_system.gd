extends Node
class_name PlayerSpawnSystem

const PLAYER_SCENE := preload("res://scenes/avatar/player_avatar.tscn")

func spawn_player(parent: Node, spawn_position: Vector2) -> AvatarController:
	var player := PLAYER_SCENE.instantiate() as AvatarController
	player.position = spawn_position
	parent.add_child(player)
	return player
