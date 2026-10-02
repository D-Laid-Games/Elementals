extends Node

const PLAYER: PackedScene = preload("uid://dsitnylb8wxef")

var enet_peer: ENetMultiplayerPeer
var in_session: bool = false

var PORT: int = 42069
var IP_Address: String = "localhost"

func start_server() -> void:
	enet_peer = ENetMultiplayerPeer.new()
	if enet_peer.create_server(PORT) != OK:
		return
	multiplayer.multiplayer_peer = enet_peer
	connect_signals()
	in_session = true
	add_player(1)


func join_server() -> void:
	enet_peer = ENetMultiplayerPeer.new()
	if enet_peer.create_client(IP_Address, PORT) != OK:
		return
	multiplayer.multiplayer_peer = enet_peer
	connect_signals()
	in_session = true


func connect_signals() -> void:
	if not multiplayer.peer_connected.is_connected(add_player):
		multiplayer.peer_connected.connect(add_player)
	if not multiplayer.peer_disconnected.is_connected(remove_player):
		multiplayer.peer_disconnected.connect(remove_player)
	if not multiplayer.connected_to_server.is_connected(on_connected_to_server):
		multiplayer.connected_to_server.connect(on_connected_to_server)
	if not multiplayer.server_disconnected.is_connected(on_server_disconnected):
		multiplayer.server_disconnected.connect(on_server_disconnected)


func clean_up_signals() -> void:
	if multiplayer.peer_connected.is_connected(add_player):
		multiplayer.peer_connected.disconnect(add_player)
	if multiplayer.peer_disconnected.is_connected(remove_player):
		multiplayer.peer_disconnected.disconnect(remove_player)
	if multiplayer.connected_to_server.is_connected(on_connected_to_server):
		multiplayer.connected_to_server.disconnect(on_connected_to_server)
	if multiplayer.server_disconnected.is_connected(on_server_disconnected):
		multiplayer.server_disconnected.disconnect(on_server_disconnected)


func on_connected_to_server() -> void:
	add_player(multiplayer.get_unique_id())


# Client only: when the hosts kills the session, clients also go down
func on_server_disconnected() -> void:
	leave_server()


func add_player(peer_id: int) -> void:
	var scene: Node = get_tree().current_scene
	if scene.has_node(str(peer_id)):
		return
	var new_player: CharacterBody2D = PLAYER.instantiate()
	new_player.name = str(peer_id)
	new_player.position = get_spawn_position(peer_id)
	scene.add_child(new_player, true)
	
	
func get_spawn_position(peer_id: int) -> Vector2:
	var spawn_points: Array[Node] = get_tree().get_nodes_in_group("SpawnPoint")
	if spawn_points.is_empty():
		return Vector2.ZERO
	spawn_points.sort_custom(func(a:Node, b:Node) -> bool: return a.name < b.name)	
	var point: Node2D = spawn_points[peer_id % spawn_points.size()]
	return point.global_position


func remove_player(peer_id: int) -> void:
	var player: Node = get_tree().current_scene.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()


# Works for both roles:
# - client: disconnects from the host
# - host: closing the peer disconnects every client, which triggers
#   on_server_disconnected on their side
func leave_server() -> void:
	if not in_session:
		return
	in_session = false
	clean_up_signals()
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	get_tree().reload_current_scene()
