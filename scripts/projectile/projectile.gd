extends Node2D


@export var speed: float = 800.0
@export var projectile_gravity: float = 1000.0
var velocity: Vector2 = Vector2.ZERO


func setup(direction: Vector2, start_position: Vector2) -> void:
	global_position = start_position
	rotation = direction.angle()
	velocity = direction * speed
	
	
func _physics_process(delta: float) -> void:
	velocity.y += projectile_gravity * delta
	position += velocity * delta
	rotation = velocity.angle()
