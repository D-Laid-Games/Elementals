extends Area2D

@export var speed: float = 800.0
@export var projectile_gravity: float = 1000.0
var velocity: Vector2 = Vector2.ZERO
@export var damage: float = 25.0

enum Element { FIRE, WATER, EARTH }
var player_element: int

const TEXTURES: Array[Texture2D] = [
	preload("res://assets/projectile/fireBall.png"),
	preload("res://assets/projectile/waterBall.png"),
	preload("res://assets/projectile/earthBall.png"),
]
@onready var projectile_sprite: Sprite2D = $Sprite2D


func setup(direction: Vector2, start_position: Vector2, p_player_element: int) -> void:
	global_position = start_position
	rotation = direction.angle()
	velocity = direction * speed
	_update_projectile_texture(p_player_element)
	player_element = p_player_element
	
	
func _physics_process(delta: float) -> void:
	velocity.y += projectile_gravity * delta
	position += velocity * delta
	rotation = velocity.angle()
	
	
func _update_projectile_texture(element: int) -> void:
	if element >=0 and element < TEXTURES.size():
		projectile_sprite.texture = TEXTURES[element]
		

		
func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return
	if body is Player:
		body.take_damage.rpc_id(body.get_multiplayer_authority(), damage)
	_remove()

		
func _on_area_entered(area: Area2D) -> void:
	if not multiplayer.is_server():
		return
	if area is Shield:
		var shield: Shield = area
		if shield.get_is_shielding():
			var target_player: Player = shield.player
			var shield_element: int = shield.get_current_shield_element()
			if is_element_blocked(shield_element, player_element):
				target_player.take_damage.rpc_id(target_player.get_multiplayer_authority(), 0.0)
			elif is_element_double_damage(shield_element, player_element):
				target_player.take_damage.rpc_id(target_player.get_multiplayer_authority(), damage * 2.0)
			else: 
				target_player.take_damage.rpc_id(target_player.get_multiplayer_authority(), damage)
			_remove()
				
			
func is_element_blocked(shield_element: int, projectile_element: int) -> bool:
	match shield_element:
		Element.WATER: return projectile_element == Element.FIRE
		Element.EARTH: return projectile_element == Element.WATER
		Element.FIRE:  return projectile_element == Element.EARTH
	return false
	
	
func is_element_double_damage(shield_element: int, projectile_element: int) -> bool:
	return shield_element == projectile_element
	
	
func _remove() -> void:
	if is_queued_for_deletion():
		return
	$CollisionShape2D.set_deferred("disabled", true)
	var game_node: Node = get_tree().current_scene.get_node_or_null("Game")
	if game_node != null:
		game_node.remove_projectile.rpc(name)
	else:
		queue_free()
