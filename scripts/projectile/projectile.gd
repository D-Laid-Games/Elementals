extends Node2D


@export var speed: float = 800.0
@export var projectile_gravity: float = 1000.0
var velocity: Vector2 = Vector2.ZERO

const TEXTURES: Array[Texture2D] = [
	preload("res://assets/projectile/fireBall.png"),
	preload("res://assets/projectile/waterBall.png"),
	preload("res://assets/projectile/earthBall.png"),
]
@onready var projectile_sprite: Sprite2D = $DamageZone/Projectile

func setup(direction: Vector2, start_position: Vector2, new_element: int) -> void:
	global_position = start_position
	rotation = direction.angle()
	velocity = direction * speed
	_update_projectile_texture(new_element)
	
	
func _physics_process(delta: float) -> void:
	velocity.y += projectile_gravity * delta
	position += velocity * delta
	rotation = velocity.angle()
	
	
func _update_projectile_texture(element: int) -> void:
	if element >=0 and element < TEXTURES.size():
		projectile_sprite.texture = TEXTURES[element]
