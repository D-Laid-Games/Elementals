extends Area2D
class_name Shield

@onready var player: CharacterBody2D = get_parent() as CharacterBody2D

const TEXTURES: Array[Texture2D] = [
	preload("res://assets/shield/fireShield.png"),
	preload("res://assets/shield/waterShield.png"),
	preload("res://assets/shield/earthShield.png"),
]

@onready var shield_sprite: Sprite2D = $Shield 


func update_shield_texture() -> void:
	var element: int  = player.current_element
	if element >= 0 and element < TEXTURES.size():
		shield_sprite.texture = TEXTURES[element]
	
func get_current_shield_element() -> int:
	return player.current_element

func get_is_shielding() -> bool:
	return player.is_shielding
