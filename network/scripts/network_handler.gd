extends Node

const DEFAULT_IP: String = "localhost"
const DEFAULT_PORT: int = 42069

var peer: ENetMultiplayerPeer

func start_server(port: int = DEFAULT_PORT) -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	
	# Force the server host to spawn player ID 1
	var spawner: MultiplayerSpawner = get_tree().current_scene.get_node_or_null("MultiplayerSpawner")
	if spawner:
		spawner.spawn_player(1)

func start_client(ip: String = DEFAULT_IP, port: int = DEFAULT_PORT) -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer
