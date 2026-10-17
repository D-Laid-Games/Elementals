extends MultiplayerSpawner

var stop_acknowledged: Dictionary[int, bool] = {}

@export var network_player: PackedScene
@export var spawn_point: NodePath
@export var respawn_delay: float = 2.0


func _ready() -> void:
	multiplayer.peer_connected.connect(spawn_player)
	multiplayer.peer_disconnected.connect(remove_player)

func spawn_player(id: int) -> void:
	if not multiplayer.is_server():
		return

	var target_parent: Node = get_node_or_null(spawn_path)
	if not target_parent:
		return

	if target_parent.has_node(str(id)):
		return

	var player: Node2D = network_player.instantiate() as Node2D
	player.name = str(id)
	target_parent.add_child(player, true)
	
	var powerups: PlayerPowerUps = player.get_node("PlayerPowerUps") as PlayerPowerUps
	powerups.restore_loadout(MatchState.get_loadout(id))

	if spawn_point:
		var marker: Node2D = get_node_or_null(spawn_point) as Node2D
		if marker:
			player.global_position = marker.global_position

func remove_player(id: int) -> void:
	if not multiplayer.is_server():
		return

	var target_parent: Node = get_node_or_null(spawn_path)
	if target_parent and target_parent.has_node(str(id)):
		target_parent.get_node(str(id)).queue_free()

#func respawn_player(id: int) -> void:
	#if not multiplayer.is_server():
		#return
#
	#remove_player(id)
#
	#if respawn_delay > 0.0:
		#await get_tree().create_timer(respawn_delay).timeout
#
	#spawn_player(id)
func respawn_player(id: int) -> void:
	if not multiplayer.is_server():
		return

	# The host owns peer 1, so it does not need a network acknowledgement.
	if id != 1 and multiplayer.get_peers().has(id):
		stop_acknowledged[id] = false
		rpc_id(id, "prepare_player_despawn", id)

		var timeout_at: int = Time.get_ticks_msec() + 1000
		while not stop_acknowledged[id] \
				and multiplayer.get_peers().has(id) \
				and Time.get_ticks_msec() < timeout_at:
			await get_tree().process_frame

		var received_ack: bool = stop_acknowledged[id]
		stop_acknowledged.erase(id)

		if not received_ack:
			push_warning("Client did not acknowledge stopping Player %d synchronizer" % id)

		# Give updates already in transit a short time to arrive.
		await get_tree().create_timer(0.15).timeout

	if id != 1 and not multiplayer.get_peers().has(id):
		return

	remove_player(id)

	if respawn_delay > 0.0:
		await get_tree().create_timer(respawn_delay).timeout

	if id == 1 or multiplayer.get_peers().has(id):
		spawn_player(id)

func _on_spawned(node: Node) -> void:
	var player: CharacterBody2D = node if node.has_node("PlayerPowerUps") else null
	if player:
		var player_id: int = player.name.to_int()
		rpc_id(1, "request_player_loadout", player_id)


@rpc("any_peer", "call_remote", "reliable")
func request_player_loadout(player_id: int) -> void:
	if not multiplayer.is_server():
		return
	
	var loadout: Dictionary = MatchState.get_loadout(player_id)
	var requester_id: int = multiplayer.get_remote_sender_id()
	var target_parent: Node = get_node_or_null(spawn_path)
	var player: CharacterBody2D = target_parent.get_node(str(player_id))
	var powerups: PlayerPowerUps = player.get_node("PlayerPowerUps") as PlayerPowerUps
	powerups.rpc_id(requester_id, "receive_peer_loadout", loadout)

@rpc("authority", "call_remote", "reliable")
func prepare_player_despawn(player_id: int) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	if player_id != multiplayer.get_unique_id():
		return

	var target_parent: Node = get_node_or_null(spawn_path)
	if target_parent:
		var player: Node = target_parent.get_node_or_null(str(player_id))
		if player:
			player.set("is_dead", true)

			var synchronizer: MultiplayerSynchronizer = \
					player.get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer
			if synchronizer:
				synchronizer.root_path = NodePath()

	rpc_id(1, "acknowledge_player_despawn", player_id)


@rpc("any_peer", "call_remote", "reliable")
func acknowledge_player_despawn(player_id: int) -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != player_id:
		return

	if stop_acknowledged.has(player_id):
		stop_acknowledged[player_id] = true
