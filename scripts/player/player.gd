extends CharacterBody2D
class_name Player

# movement
const BASE_SPEED: float = 130.0
var speed: float = BASE_SPEED

# jump
const BASE_MAX_JUMPS: int = 1
const BASE_JUMPS_LEFT: int = BASE_MAX_JUMPS
const JUMP_VELOCITY: float = -300.0
var max_jumps: int = BASE_MAX_JUMPS
var jumps_left: int = BASE_JUMPS_LEFT

# roll
const BASE_ROLL_SPEED: float = 800
const BASE_ROLL_DURATION: float = 0.10
const BASE_ROLL_COOLDOWN: float = 0.8
var roll_speed: float = BASE_ROLL_SPEED
var roll_duration: float = BASE_ROLL_DURATION
var roll_cooldown: float = BASE_ROLL_COOLDOWN
var can_roll: bool = true
var roll_direction: float = 0.0
var is_rolling: bool = false

# player sprite
const ANIMATIONS: Dictionary = {
	Enums.PlayerAnimationState.IDLE: "idle",
	Enums.PlayerAnimationState.RUN: "run",
	Enums.PlayerAnimationState.JUMP: "jump",
}

@export var facing_right: bool = true:
	set(value):
		facing_right = value
		if current_sprite:
			current_sprite.flip_h = not facing_right
			
@export var state: Enums.PlayerAnimationState = Enums.PlayerAnimationState.IDLE:
	set(value):
		if state == value:
			return
		state = value
		_update_player_visuals()

var current_sprite: AnimatedSprite2D = null

@onready var earth_sprite: AnimatedSprite2D = $EarthAnimatedSprite2D
@onready var fire_sprite: AnimatedSprite2D = $FireAnimatedSprite2D
@onready var water_sprite: AnimatedSprite2D = $WaterAnimatedSprite2D


@export var current_element: Enums.Element = Enums.Element.FIRE:
	set(value):
		current_element = value
		if is_node_ready():
			_update_element_visuals()
			_update_shield_element()
			_movement_ability()


# projectile shooting
const BASE_FIRE_RATE: float = 1.0
const BASE_PROJECTILE_OFFSET: float = 25.0
var fire_rate: float = BASE_FIRE_RATE
var projectile_offset: float = BASE_PROJECTILE_OFFSET
@export var projectile_scene: PackedScene
var can_shoot: bool = true
var shot_counter: int = 0

# shielding
var shield: Area2D
const BASE_SHIELD_OFFSET: Vector2 = Vector2(20.0, 0.0)
@export var shield_offset: Vector2 = BASE_SHIELD_OFFSET
@export var shield_scene: PackedScene

@export var is_shielding: bool = false:
	set(value):
		is_shielding = value
		_apply_shield_state()

@export var shield_rotation: float = 0.0:
	set(value):
		shield_rotation = value
		_apply_shield_state()

# health
const BASE_MAX_HEALTH: float = 100.0

@export var current_health: float = BASE_MAX_HEALTH:
	set(value):
		current_health = clampf(value, 0.0, BASE_MAX_HEALTH)
		_update_health_bar()		
		
@onready var health_bar: ProgressBar = $HealthBar


# respawn
var is_dead: bool = false
var default_collision_layer: int


func _enter_tree() -> void:
	set_multiplayer_authority(int(name))


func _ready() -> void:
	default_collision_layer = collision_layer
	health_bar.max_value = BASE_MAX_HEALTH
	health_bar.value = current_health
	_update_element_visuals()
	_setup_shield()


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority() or is_dead:
		return
	if event.is_action_pressed("fire_stance"):
		current_element = Enums.Element.FIRE
	elif event.is_action_pressed("water_stance"):
		current_element = Enums.Element.WATER
	elif event.is_action_pressed("earth_stance"):
		current_element = Enums.Element.EARTH
	_activate_shot(event)

		
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority() or is_dead:
		return
	_physics_movement_ability()
	# movement needs to be disabled during the roll because godot resets the player movement to the base movement speed per frame. 
	if not is_rolling:
		_player_gravity(delta)	
		_movement()	
	_jump()
	_update_state()
	move_and_slide()
	_activate_shield()

	
func _update_state() -> void:
	if not is_on_floor():
		state = Enums.PlayerAnimationState.JUMP
	elif velocity.x == 0.0:
		state = Enums.PlayerAnimationState.IDLE
	else:
		state = Enums.PlayerAnimationState.RUN


func _update_player_visuals() -> void:
	if current_sprite == null:
		return
	current_sprite.flip_h = facing_right == false
	current_sprite.play(ANIMATIONS[state])


func _movement() -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	# facing
	if direction > 0:
		facing_right = true
	elif direction < 0:
		facing_right = false
	# velocity
	if(direction !=0):
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
	
	
func _jump() -> void:
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1
	
		
func _physics_movement_ability() -> void:
	# earth speedup
	if Input.is_action_pressed("ability_button") and current_element == Enums.Element.EARTH:
		speed = BASE_SPEED * 2.0
	else:
		speed = BASE_SPEED
	# fire roll	
	if Input.is_action_just_pressed("ability_button") and current_element == Enums.Element.FIRE:
		_execute_roll()
	

func _execute_roll() -> void:
	can_roll = false
	is_rolling = true
	roll_direction = 1.0 if facing_right else -1.0
	velocity.x = roll_direction * roll_speed
	velocity.y = 0.0
	await get_tree().create_timer(roll_duration).timeout
	is_rolling = false
	await get_tree().create_timer(roll_cooldown).timeout
	can_roll = true


func _movement_ability() -> void:
	if current_element == Enums.Element.WATER:
		max_jumps = 2
	else:
		max_jumps = BASE_MAX_JUMPS 
		jumps_left -= 1
		
	
func _player_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jumps_left = max_jumps


@rpc("authority", "call_local", "reliable")
func setup_shot(spawn_position: Vector2, direction: Vector2, element: int) -> void:
	shot_counter += 1
	var shooter_id: int = get_multiplayer_authority()
	var projectile: Area2D = projectile_scene.instantiate()
	projectile.name = "Proj_%d_%d" % [shooter_id, shot_counter]
	get_tree().current_scene.add_child(projectile)
	projectile.setup(direction, spawn_position, element, shooter_id)
	
	
func _activate_shot(event: InputEvent) -> void:
	if event.is_action_pressed("shoot") and can_shoot == true:
		can_shoot = false
		var direction: Vector2 = (get_global_mouse_position() - global_position).normalized()
		var spawn_position: Vector2 = global_position + direction * projectile_offset
		setup_shot.rpc(spawn_position, direction, current_element)
		await get_tree().create_timer(fire_rate).timeout
		can_shoot = true
	
	
func _setup_shield() -> void:
	shield = shield_scene.instantiate()
	add_child(shield)
	_apply_shield_state()
	_update_shield_element()
	
	
func _activate_shield() -> void:
	is_shielding = Input.is_action_pressed("shield")
	var mouse_dir: Vector2 = (get_global_mouse_position() - global_position).normalized()
	shield_rotation = mouse_dir.angle()
	
	
func _apply_shield_state() -> void:
	if shield == null:
		return
	shield.visible = is_shielding
	shield.rotation = shield_rotation
	shield.position = Vector2.RIGHT.rotated(shield_rotation) * shield_offset.length()
	shield.set_deferred("monitorable", is_shielding)
	shield.set_deferred("monitoring", false)


func _update_shield_element() -> void:
	if shield != null:
		shield.update_shield_texture()
	

func apply_damage(amount: float) -> void:
	if not multiplayer.is_server() or is_dead:
		return
	var new_health: float = maxf(current_health - amount, 0.0)
	set_health.rpc(new_health)
	if new_health <= 0.0:
		die.rpc()
		get_game().respawn_player(name.to_int())


func _is_from_server() -> bool:
	var sender: int = multiplayer.get_remote_sender_id()
	return sender == 0 or sender == 1


@rpc("any_peer", "call_local", "reliable")
func set_health(value: float) -> void:
	if not _is_from_server():
		return
	current_health = value


func _update_health_bar() -> void:
	if health_bar:
		health_bar.value = current_health
		
		
@rpc("any_peer", "call_local", "reliable")
func die() -> void:
	if not _is_from_server() or is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	current_sprite.visible = false
	health_bar.visible = false
	shield.visible = false
	set_deferred("collision_layer", 0)
		
		
@rpc("any_peer", "call_local", "reliable")
func respawn(spawn_position: Vector2) -> void:
	if not _is_from_server():
		return
	global_position = spawn_position
	velocity = Vector2.ZERO
	current_health = BASE_MAX_HEALTH
	health_bar.visible = true
	jumps_left = max_jumps
	collision_layer = default_collision_layer
	current_sprite.visible = true
	is_dead = false
	
	
func _update_element_visuals() -> void:
	if fire_sprite: fire_sprite.visible = false
	if water_sprite: water_sprite.visible = false
	if earth_sprite: earth_sprite.visible = false
	match current_element:
		Enums.Element.FIRE: current_sprite = fire_sprite
		Enums.Element.WATER: current_sprite = water_sprite
		Enums.Element.EARTH: current_sprite = earth_sprite
	if current_sprite:
		current_sprite.visible = true
		current_sprite.flip_h = not facing_right
		current_sprite.play(ANIMATIONS[state]) 
		
		
func get_element() -> int:
	return current_element 
	
	
func get_game() -> Node:
	return get_tree().current_scene.get_node("Game")
