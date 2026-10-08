#extends Area2D
#
#
#@export var damage: float = 25.0
#
#
#func _on_body_entered(body: Node2D) -> void:
	#if not multiplayer.is_server():
		#return
	#if body.has_method("take_damage"):
		#body.take_damage.rpc_id(body.get_multiplayer_authority(), damage)
		#_remove()
		#return
	#elif body.get_parent() and body.get_parent().has_method("take_damage"):
		#body.get_parent().take_damage.rpc_id(body.get_multiplayer_authority(), damage)
		#_remove()
		#return
	#if body is TileMapLayer or body is TileMap or body is StaticBody2D:
		#_remove()
#
#
#func _on_area_entered(area: Area2D) -> void:
	#if not multiplayer.is_server():
		#return
	#
	#if area is Area2D:
		#_remove()
#
#
#func _remove() -> void:
	#var proj: Node = get_parent()
	#if proj.is_queued_for_deletion():
		#return
	#get_tree().current_scene.get_node("Game").remove_projectile.rpc(proj.name)
	#
	#
