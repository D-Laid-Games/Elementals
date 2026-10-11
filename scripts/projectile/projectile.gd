extends Area2D

@export var speed: float = 800.0
@export var projectile_gravity: float = 1000.0
var velocity: Vector2 = Vector2.ZERO
@export var damage: float = 25.0
var shooter_id: int = 0
var self_hit_grace: float = 0.15
var player_element: int

const TEXTURES: Array[Texture2D] = [
	preload("res://assets/projectile/fireBall.png"),
	preload("res://assets/projectile/waterBall.png"),
	preload("res://assets/projectile/earthBall.png"),
]
@onready var projectile_sprite: Sprite2D = $Sprite2D


func setup(direction: Vector2, start_position: Vector2, p_player_element: int, p_shooter_id: int) -> void:
	global_position = start_position
	rotation = direction.angle()
	velocity = direction * speed
	player_element = p_player_element
	shooter_id = p_shooter_id
	_update_projectile_texture(p_player_element)
	get_tree().create_timer(5.0).timeout.connect(queue_free)
	
	
func _physics_process(delta: float) -> void:
	self_hit_grace = maxf(self_hit_grace - delta, 0.0)
	velocity.y += projectile_gravity * delta
	position += velocity * delta
	rotation = velocity.angle()

func _is_ignored_self_hit(target: Player) -> bool:
	return self_hit_grace > 0.0 and target.get_multiplayer_authority() == shooter_id
	
	
func _update_projectile_texture(element: int) -> void:
	if element >=0 and element < TEXTURES.size():
		projectile_sprite.texture = TEXTURES[element]
		

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if _is_ignored_self_hit(body):
			return
		if multiplayer.is_server():
			body.apply_damage(damage)
	_remove()

		
func _on_area_entered(area: Area2D) -> void:
	if not area is Shield:
		return
	var shield: Shield = area
	if not shield.get_is_shielding():
		return
	var target: Player = shield.player as Player
	if _is_ignored_self_hit(target):
		return  
	if multiplayer.is_server():
		var shield_element: int = shield.get_current_shield_element()
		if is_element_blocked(shield_element, player_element):
			pass  # fully blocked, no damage
		elif is_element_double_damage(shield_element, player_element):
			target.apply_damage(damage * 2.0)
		else:
			target.apply_damage(damage)
	_remove()

				
func is_element_blocked(shield_element: int, projectile_element: int) -> bool:
	match shield_element:
		Enums.Element.WATER: return projectile_element == Enums.Element.FIRE
		Enums.Element.EARTH: return projectile_element == Enums.Element.WATER
		Enums.Element.FIRE:  return projectile_element == Enums.Element.EARTH
	return false
	
	
func is_element_double_damage(shield_element: int, projectile_element: int) -> bool:
	return shield_element == projectile_element
	
	
func _remove() -> void:
	if is_queued_for_deletion():
		return
	$CollisionShape2D.set_deferred("disabled", true)
	queue_free()
