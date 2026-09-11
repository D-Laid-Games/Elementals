extends Area2D

@export var damage: float = 5.0

func _on_body_entered(body: Node2D) -> void:
	# Call take_damage on the player if available
	if body.has_method("take_damage"):
		body.take_damage(damage)
	elif body.get_parent() and body.get_parent().has_method("take_damage"):
		body.get_parent().take_damage(damage)
