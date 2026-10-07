extends CharacterBody2D

# movement
const SPEED: float = 130.0

# jump
var max_jumps: int = 1
var jumps_left: int = 1
const Jump_VELOCITY: float = -300.0

# player sprite
enum PlayerAnimationState { IDLE, RUN, JUMP }

const ANIMATIONS: Dictionary = {
	PlayerAnimationState.IDLE: "idle",
	PlayerAnimationState.RUN: "run",
	PlayerAnimationState.JUMP: "jump",
}
@export var facing_right: bool = true:
	set(value):
		facing_right = value
		if current_sprite:
			current_sprite.flip_h = not facing_right
			
@export var state: PlayerAnimationState = PlayerAnimationState.IDLE:
	set(value):
		if state == value:
			return
		state = value
		_update_player_visuals()

var current_sprite: AnimatedSprite2D = null

@onready var earth_sprite: AnimatedSprite2D = $EarthAnimatedSprite2D
@onready var fire_sprite: AnimatedSprite2D = $FireAnimatedSprite2D
@onready var water_sprite: AnimatedSprite2D = $WaterAnimatedSprite2D


# projectile shooting
@export var projectile_scene: PackedScene
var can_shoot: bool = true
var fire_rate: float = 1.0
var projectile_offset: float = 35.0

# shielding
var shield: Area2D
@export var shield_offset: Vector2 = Vector2(20.0, 0.0)
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
const MAX_HEALTH: float = 100.0

@export var current_health: float = MAX_HEALTH:
	set(value):
		current_health = clampf(value, 0.0, MAX_HEALTH)
		_update_health_bar()		
		
@onready var health_bar: ProgressBar = $HealthBar


# respawn
var is_dead: bool = false
var default_collision_layer: int


func _enter_tree() -> void:
	set_multiplayer_authority(int(name))


func _ready() -> void:
	default_collision_layer = collision_layer
	health_bar.max_value = MAX_HEALTH
	health_bar.value =current_health
	current_sprite = earth_sprite
	current_sprite.visible = true
	fire_sprite.visible = false
	water_sprite.visible = false
	_setup_shield()


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority() or is_dead:
		return
	if event.is_action_pressed("shoot"):
		var mouse_position: Vector2 = get_global_mouse_position()
		var direction: Vector2 = (mouse_position - global_position).normalized()
		shoot.rpc(direction, multiplayer.get_unique_id())


func _physics_process(delta: float) -> void:
	#sprite_flip()
	if not is_multiplayer_authority() or is_dead:
		return
	player_gravity(delta)
	movement()
	jump()
	update_state()
	move_and_slide()
	
	is_shielding = Input.is_action_pressed("shield")
	var mouse_dir: Vector2 = (get_global_mouse_position() - global_position).normalized()
	shield_rotation = mouse_dir.angle()

	
	
func update_state() -> void:
	if not is_on_floor():
		state = PlayerAnimationState.JUMP
	elif velocity.x == 0.0:
		state = PlayerAnimationState.IDLE
	else:
		state = PlayerAnimationState.RUN


func _update_player_visuals() -> void:
	if current_sprite == null:
		return
	current_sprite.flip_h = facing_right == false
	current_sprite.play(ANIMATIONS[state])


func movement() -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	# facing
	if direction > 0:
		facing_right = true
	elif direction < 0:
		facing_right = false

	# velocity
	if(direction !=0):
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
	
	
func jump() -> void:
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = Jump_VELOCITY
		jumps_left -= 1


func player_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jumps_left = max_jumps


@rpc("call_local", "reliable")		
func shoot(direction: Vector2, shooter_peer_id: int) -> void:
	if not can_shoot:
		return
	_spawn_projectile(direction, shooter_peer_id)

	
func _spawn_projectile(direction: Vector2, shooter_peer_id: int) -> void:
	can_shoot = false
	var projectile: Node2D = projectile_scene.instantiate()
	projectile.set_multiplayer_authority(shooter_peer_id)
	get_tree().current_scene.add_child(projectile, true)
	var spawn_pos: Vector2 = global_position + (direction * projectile_offset)
	projectile.setup(direction, spawn_pos)
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true
	
func _setup_shield() -> void:
	shield = shield_scene.instantiate()
	add_child(shield)
	_apply_shield_state()
	
	
func _apply_shield_state() -> void:
	if shield == null:
		return
	shield.visible = is_shielding
	shield.rotation = shield_rotation
	shield.position = Vector2.RIGHT.rotated(shield_rotation) * shield_offset.length()
	shield.set_deferred("monitorable", is_shielding)
	shield.set_deferred("monitoring", false)
	
	
func get_game() -> Node:
	return get_tree().current_scene.get_node("Game")
	
	
@rpc("any_peer", "call_local", "reliable")	
func take_damage(amount: float) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if sender !=0 and sender !=1:
		return
	if is_dead:
		return
	current_health = max(current_health - amount, 0.0)
	if current_health <= 0.0:
		die.rpc()


func _update_health_bar() -> void:
	if health_bar:
		health_bar.value = current_health
		
		
@rpc("authority", "call_local", "reliable")
func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	current_sprite.visible = false
	health_bar.visible = false
	set_deferred("collision_layer", 0)
	if multiplayer.is_server():
		get_game().respawn_player(name.to_int())
		
		
@rpc("any_peer", "call_local", "reliable")
func respawn(spawn_position: Vector2) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != 1:
		return
	global_position = spawn_position
	velocity = Vector2.ZERO
	current_health = MAX_HEALTH
	health_bar.visible = true
	jumps_left = max_jumps
	collision_layer = default_collision_layer
	current_sprite.visible = true
	is_dead = false
