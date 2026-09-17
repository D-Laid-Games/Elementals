extends Node2D

@export var speed: float = 800.0
@export var projectile_gravity: float = 1000.0
@export var element: int = 0:
	set(value):
		element = value
		if is_node_ready():
			_update_texture()
			

var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Calculate initial launch velocity using direction and speed
	velocity = transform.x * speed
	_update_texture()
	
	
func _update_texture() -> void:
	var proj_sprite: Sprite2D = get_node_or_null("Damagezone/Projectile") as Sprite2D
	if proj_sprite:
		match element:
			0: proj_sprite.texture = preload("res://assets/fireBall.png")
			1: proj_sprite.texture = preload("res://assets/waterBall.png")
			2: proj_sprite.texture = preload("res://assets/earthBall.png")

func _physics_process(delta: float) -> void:
	# Apply gravity over time to pull the projectile down
	velocity.y += projectile_gravity * delta
	
	# Move projectile
	position += velocity * delta
	
	# Rotate the sprite so it points in the direction it is currently falling
	rotation = velocity.angle()

func _on_body_entered(_body: Node2D) -> void:
	if multiplayer.is_server():
		queue_free()
		
