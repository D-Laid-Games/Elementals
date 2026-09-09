#extends Area2D
#
#@export var speed: float = 600.0
#
#var direction: Vector2 = Vector2.ZERO
#
#func _physics_process(delta: float) -> void:
	## Move the projectile forward in its current direction
	#position += direction * speed * delta

#func _on_body_entered(_body: Node2D) -> void:
	# Add logic here to damage enemies (e.g., if body.is_in_group("enemies"): body.take_damage())
	#queue_free() # Destroy bullet on impact


extends Node2D

@export var speed: float = 800.0
@export var projectile_gravity: float = 1000.0
var element: int = 0

var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Calculate initial launch velocity using direction and speed
	velocity = transform.x * speed

func _physics_process(delta: float) -> void:
	# Apply gravity over time to pull the projectile down
	velocity.y += projectile_gravity * delta
	
	# Move projectile
	position += velocity * delta
	
	# Rotate the sprite so it points in the direction it is currently falling
	rotation = velocity.angle()

func _on_body_entered(_body: Node2D) -> void:
	queue_free()
