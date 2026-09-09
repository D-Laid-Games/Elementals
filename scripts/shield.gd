extends Area2D

func _ready() -> void:
	# Connect the signal so it triggers whenever another Area2D enters the shield
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
		# Destroy the parent projectile node
		if area.get_parent():
			area.get_parent().queue_free()
		else:
			area.queue_free()
