extends MultiplayerSpawner

@export var network_player: PackedScene
@export var spawn_point: NodePath

func _ready() -> void:
	# Network signals for tracking peer connections
	multiplayer.peer_connected.connect(spawn_player)
	multiplayer.peer_disconnected.connect(remove_player)

func spawn_player(id: int) -> void:
	# GUARD: Only the server handles spawning nodes
	if not multiplayer.is_server():
		return
		
	var target_parent: Node = get_node_or_null(spawn_path)
	if not target_parent:
		return

	# GUARD: Prevent duplicate spawning if player node already exists
	if target_parent.has_node(str(id)):
		return

	# Instantiate and assign authority name
	var player: Node2D = network_player.instantiate() as Node2D
	player.name = str(id)
	
	# Add child using scene replication (add_child must happen before position assignment)
	target_parent.add_child(player, true)

	# Set initial world position based on Marker2D
	if spawn_point:
		var marker: Node2D = get_node_or_null(spawn_point) as Node2D
		if marker:
			player.global_position = marker.global_position

func remove_player(id: int) -> void:
	# GUARD: Only server despawns players
	if not multiplayer.is_server():
		return

	var target_parent: Node = get_node_or_null(spawn_path)
	if target_parent and target_parent.has_node(str(id)):
		target_parent.get_node(str(id)).queue_free()
