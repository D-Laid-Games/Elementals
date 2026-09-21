extends MultiplayerSpawner

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

# NEW: works for host (id 1) and clients alike
func respawn_player(id: int) -> void:
	if not multiplayer.is_server():
		return

	remove_player(id)

	if respawn_delay > 0.0:
		await get_tree().create_timer(respawn_delay).timeout

	spawn_player(id)
