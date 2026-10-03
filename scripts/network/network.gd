extends Node

var enet_peer: ENetMultiplayerPeer
var in_session: bool = false
var is_host: bool = false

var PORT: int = 42069
var IP_Address: String = "localhost"


func start_server() -> void:
	enet_peer = ENetMultiplayerPeer.new()
	if enet_peer.create_server(PORT) != OK:
		return
	is_host = true
	multiplayer.multiplayer_peer = enet_peer
	connect_signals()
	in_session = true
	get_game().spawn_player(1)


func join_server() -> void:
	enet_peer = ENetMultiplayerPeer.new()
	if enet_peer.create_client(IP_Address, PORT) != OK:
		return
	is_host = false
	multiplayer.multiplayer_peer = enet_peer
	connect_signals()
	in_session = true


func connect_signals() -> void:
	if is_host:
		if not multiplayer.peer_connected.is_connected(on_peer_connected):
			multiplayer.peer_connected.connect(on_peer_connected)
		if not multiplayer.peer_disconnected.is_connected(remove_player):
			multiplayer.peer_disconnected.connect(remove_player)
	else:
		if not multiplayer.server_disconnected.is_connected(on_server_disconnected):
			multiplayer.server_disconnected.connect(on_server_disconnected)


func clean_up_signals() -> void:
	if multiplayer.peer_connected.is_connected(on_peer_connected):
		multiplayer.peer_connected.disconnect(on_peer_connected)
	if multiplayer.peer_disconnected.is_connected(remove_player):
		multiplayer.peer_disconnected.disconnect(remove_player)
	if multiplayer.server_disconnected.is_connected(on_server_disconnected):
		multiplayer.server_disconnected.disconnect(on_server_disconnected)


func on_peer_connected(peer_id: int) -> void:
	get_game().spawn_player(peer_id)


func get_game() -> Node:
	return get_tree().current_scene.get_node("Game")


func on_server_disconnected() -> void:
	leave_server()


func remove_player(peer_id: int) -> void:
	var player: Node = get_game().get_node_or_null("Players/" + str(peer_id))
	if player:
		player.queue_free()


func leave_server() -> void:
	if not in_session:
		return
	in_session = false
	clean_up_signals()
	if enet_peer:
		enet_peer.close()
	multiplayer.multiplayer_peer = null
	is_host = false
	get_tree().reload_current_scene()
