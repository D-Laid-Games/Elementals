extends Area2D


@export var damage: float = 25.0


func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return
	if body.has_method("take_damage"):
		body.take_damage.rpc_id(body.get_multiplayer_authority(), damage)
		remove_projectile.rpc()
		return
	elif body.get_parent() and body.get_parent().has_method("take_damage"):
		body.get_parent().take_damage.rpc_id(body.get_multiplayer_authority(), damage)
		remove_projectile.rpc()
		return
	if body is TileMapLayer or body is TileMap or body is StaticBody2D:
		remove_projectile.rpc()


@rpc("call_local", "any_peer", "reliable")
func remove_projectile() -> void:
	queue_free()
