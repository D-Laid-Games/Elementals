extends Area2D
class_name Shield

@onready var player: CharacterBody2D = get_parent() as CharacterBody2D

var current_element: int

const TEXTURES: Array[Texture2D] = [
	preload("res://assets/shield/fireShield.png"),
	preload("res://assets/shield/waterShield.png"),
	preload("res://assets/shield/earthShield.png"),
]

@onready var shield_sprite: Sprite2D = $Shield 


func update_shield_texture(element: int) -> void:
	current_element = element
	if element >= 0 and element < TEXTURES.size():
		shield_sprite.texture = TEXTURES[element]
	
	
func get_element() -> int:
	#return player.current_element
	return current_element

func is_active() -> bool:
	return player.is_shielding
