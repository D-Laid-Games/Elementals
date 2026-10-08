extends Node2D


@onready var players: Node2D = $Players
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
@export var player_scene: PackedScene
var next_slot: int = 0
@export var respawn_time: float = 3.0


func _ready() -> void:
	spawner.spawn_function = _spawn_player


func spawn_player(peer_id: int) -> void:
	if players.has_node(str(peer_id)):
		return
	var spawn_points: Array[Node] = get_tree().get_nodes_in_group("SpawnPoint")
	# sort the spawn points alphabetically so they match across all the clients.
	spawn_points.sort_custom(func(a: Node, b: Node) -> bool: return a.name < b.name)
	# assigning players to the next available spawn point.
	var point: Node2D = spawn_points[next_slot % spawn_points.size()] as Node2D
	next_slot += 1
	spawner.spawn({"id": peer_id, "pos": point.global_position})


func _spawn_player(data: Dictionary) -> Node:
	var player: CharacterBody2D = player_scene.instantiate()
	player.name = str(data["id"])
	player.position = data["pos"]
	return player
	
	
func respawn_player(peer_id: int) -> void:
	await get_tree().create_timer(respawn_time).timeout
	var player: Node = players.get_node_or_null(str(peer_id))
	if player == null:
		return
	player.respawn.rpc(_get_random_spawn_position())
	

func _get_random_spawn_position() -> Vector2:
	var spawn_points: Array[Node] = get_tree().get_nodes_in_group("SpawnPoint")
	var point: Node2D = spawn_points.pick_random() as Node2D
	return point.global_position
	
	
@rpc("any_peer", "call_local", "reliable")
func remove_projectile(proj_name: StringName) -> void:
	var projectile: Area2D = get_tree().current_scene.get_node_or_null(NodePath(proj_name))
	if projectile != null:
		projectile.queue_free()
