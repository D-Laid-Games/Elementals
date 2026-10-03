extends Node2D

@onready var players: Node2D = $Players
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
var next_slot: int = 0


func _ready() -> void:
	spawner.spawn_function = _spawn_player


func spawn_player(peer_id: int) -> void:
	if players.has_node(str(peer_id)):
		return
	var points: Array[Node] = get_tree().get_nodes_in_group("SpawnPoint")
	points.sort_custom(func(a: Node, b: Node) -> bool: return a.name < b.name)
	var point: Node2D = points[next_slot % points.size()] as Node2D
	next_slot += 1
	spawner.spawn({"id": peer_id, "pos": point.global_position})


func _spawn_player(data: Dictionary) -> Node:
	var player: CharacterBody2D = preload("uid://dsitnylb8wxef").instantiate()
	player.name = str(data["id"])
	player.position = data["pos"]
	return player
