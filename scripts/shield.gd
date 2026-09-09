extends Area2D

enum Element { FIRE, WATER, EARTH }

@onready var player: CharacterBody2D = get_parent() as CharacterBody2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	# Retrieve the root projectile node
	var projectile: Node2D = area.get_parent() as Node2D
	if not projectile:
		projectile = area
		
	# Ensure the object has an elemental variable to read
	if not "element" in projectile or not player:
		return

	var incoming_element: int = projectile.element
	var shield_element: int = player.current_element


	# Check counter matrix using the helper function
	if is_element_blocked(shield_element, incoming_element):
		projectile.queue_free()
			
func is_element_blocked(shield_elem: int, proj_elem: int) -> bool:
	match shield_elem:
		Element.WATER:
			return proj_elem == Element.FIRE
		Element.EARTH:
			return proj_elem == Element.WATER
		Element.FIRE:
			return proj_elem == Element.EARTH
	return false
