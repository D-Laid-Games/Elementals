extends CharacterBody2D

enum Element { FIRE, WATER, EARTH }

# --- EXPORTED NETWORKED PROPERTIES ---
@export var current_element: Element = Element.FIRE:
	set(value):
		current_element = value
		if is_node_ready():
			_update_element_visuals()

@export var facing_left: bool = false:
	set(value):
		facing_left = value
		if is_node_ready() and current_sprite:
			current_sprite.flip_h = value

@export var is_shielding: bool = false:
	set(value):
		is_shielding = value
		if is_node_ready() and shield:
			shield.visible = value
			# Safe check for multiplayer tree state
			if is_inside_tree() and multiplayer:
				shield.monitoring = value if multiplayer.is_server() else false

@export var shield_rotation: float = 0.0:
	set(value):
		shield_rotation = value
		if is_node_ready() and shield:
			shield.rotation = value
			shield.position = Vector2.RIGHT.rotated(value) * shield_offset.length()
			


# --- STATS & CONFIG ---
const SPEED: float = 130.0
const JUMP_VELOCITY: float = -300.0
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectile.tscn")
const SHIELD_SCENE: PackedScene = preload("res://scenes/shield.tscn")

@export var max_health: float = 10.0
@export var fire_rate: float = 1.0
@export var shield_offset: Vector2 = Vector2(20.0, 0.0)

@export_group("Shield Textures")
@export var fire_shield_tex: Texture2D = preload("res://assets/fireShield.png")
@export var water_shield_tex: Texture2D = preload("res://assets/waterShield.png")
@export var earth_shield_tex: Texture2D = preload("res://assets/earthShield.png")

@export_group("Movement & Roll")
@export var roll_speed: float = 800.0
@export var roll_duration: float = 0.10
@export var roll_cooldown: float = 0.8

# --- NODE REFERENCES ---
@onready var fire_sprite: AnimatedSprite2D = $FireAnimatedSprite2D
@onready var water_sprite: AnimatedSprite2D = $WaterAnimatedSprite2D
@onready var earth_sprite: AnimatedSprite2D = $EarthAnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

# --- LOCAL STATE ---
var current_health: float
var can_shoot: bool = true
var is_rolling: bool = false
var can_roll: bool = true
var is_invincible: bool = false
var roll_direction: float = 0.0
var max_jumps: int = 1
var jumps_left: int = 1
var has_water_double_jumped: bool = false
var current_sprite: AnimatedSprite2D
var shield: Area2D


# ==============================================================================
# LIFECYCLE & INITIALIZATION
# ==============================================================================
func _enter_tree() -> void:
	if name.is_valid_int():
		set_multiplayer_authority(name.to_int())
		
func _ready() -> void:
	# 2. Local Setup
	current_health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

	# 3. Instantiate Shield Node
	shield = SHIELD_SCENE.instantiate() as Area2D
	shield.position = shield_offset
	shield.visible = false
	shield.monitoring = false
	add_child(shield)

	# 4. Set Initial Visuals
	_update_element_visuals()

# ==============================================================================
# INPUT & MOVEMENT (AUTHORITY ONLY)
# ==============================================================================

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if event.is_echo():
		return

	if event.is_action_pressed("fire_stance"):
		current_element = Element.FIRE
	elif event.is_action_pressed("water_stance"):
		current_element = Element.WATER
	elif event.is_action_pressed("earth_stance"):
		current_element = Element.EARTH

	if event.is_action_pressed("shoot"):
		shoot()

	if event.is_action_pressed("ability_button") and current_element == Element.FIRE and can_roll and not is_rolling:
		perform_roll()

func _physics_process(delta: float) -> void:
	# 1. GUARD: Exit immediately if this node belongs to a remote peer
	if not is_multiplayer_authority():
		return

	# 2. ROLL EXECUTION
	if is_rolling:
		velocity.x = roll_direction * roll_speed
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return

	# 3. MOVEMENT SPEED (EARTH DASH)
	var current_speed: float = SPEED
	if Input.is_action_pressed("ability_button") and current_element == Element.EARTH:
		current_speed = SPEED * 2.0

	# 4. SHIELD TOGGLE & AIMING
	# Inside _physics_process(delta) in player.gd:
	is_shielding = Input.is_action_pressed("shield")
	var mouse_dir: Vector2 = (get_global_mouse_position() - global_position).normalized()
	
	# Setting this variable triggers the setter locally AND replicates to server/clients
	shield_rotation = mouse_dir.angle()

	# 5. GRAVITY & JUMP RESET
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		max_jumps = 2 if current_element == Element.WATER else 1
		jumps_left = max_jumps
		has_water_double_jumped = false

	# 6. HORIZONTAL INPUT & FACING
	var direction: float = Input.get_axis("move_left", "move_right")
	if direction > 0:
		facing_left = false
	elif direction < 0:
		facing_left = true

	# 7. ANIMATIONS
	if is_on_floor():
		current_sprite.play("idle" if direction == 0 else "run")
	else:
		current_sprite.play("jump")

	# 8. JUMP EXECUTION
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1
		if not is_on_floor():
			has_water_double_jumped = true

	# 9. APPLY VELOCITY
	if direction != 0:
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)

	move_and_slide()

#@rpc("any_peer", "call_remote", "unreliable")
#func sync_shield_transform(pos: Vector2, rot: float) -> void:
	#if shield:
		#shield.position = pos
		#shield.rotation = rot

# ==============================================================================
# ACTIONS & MECHANICS
# ==============================================================================

func perform_roll() -> void:
	is_rolling = true
	can_roll = false
	is_invincible = true
	roll_direction = -1.0 if facing_left else 1.0

	await get_tree().create_timer(roll_duration).timeout
	is_rolling = false
	is_invincible = false

	await get_tree().create_timer(roll_cooldown).timeout
	can_roll = true

		
func shoot() -> void:
	if not can_shoot:
		return

	# 1. Calculate direction on the local player's machine
	var mouse_pos: Vector2 = get_global_mouse_position()
	var dir: Vector2 = (mouse_pos - global_position).normalized()

	# 2. If client, send the calculated direction to the server
	if not multiplayer.is_server():
		rpc_id(1, "request_shoot", dir)
		return

	# 3. If host/server, fire directly using local direction
	_spawn_projectile(dir)

@rpc("any_peer", "call_local", "reliable")
func request_shoot(dir: Vector2) -> void:
	if multiplayer.is_server() and can_shoot:
		# Use the direction passed from the client instead of get_global_mouse_position()
		_spawn_projectile(dir)

func _spawn_projectile(dir: Vector2) -> void:
	can_shoot = false
	var projectile: Node2D = PROJECTILE_SCENE.instantiate() as Node2D
	
	projectile.global_position = global_position + (dir * 35.0)
	projectile.rotation = dir.angle()
	
	if "element" in projectile:
		projectile.element = current_element

	get_tree().current_scene.add_child(projectile, true)
	
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

# ==============================================================================
# COMBAT & HEALTH (SERVER AUTHORITATIVE)
# ==============================================================================

func take_damage(amount: float) -> void:
	if not multiplayer.is_server():
		return

	current_health = clamp(current_health - amount, 0.0, max_health)
	rpc("sync_health", current_health)

	if current_health <= 0.0:
		rpc("die")

@rpc("any_peer", "call_local", "reliable")
func sync_health(new_health: float) -> void:
	current_health = new_health
	if health_bar:
		health_bar.value = current_health

@rpc("any_peer", "call_local", "reliable")
func die() -> void:
	current_health = max_health
	if health_bar:
		health_bar.value = max_health
	if is_multiplayer_authority():
		global_position = Vector2(600, -200) # Reset position safely

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

func _update_element_visuals() -> void:
	max_jumps = 2 if current_element == Element.WATER else 1
	
	if fire_sprite: fire_sprite.visible = false
	if water_sprite: water_sprite.visible = false
	if earth_sprite: earth_sprite.visible = false

	match current_element:
		Element.FIRE: current_sprite = fire_sprite
		Element.WATER: current_sprite = water_sprite
		Element.EARTH: current_sprite = earth_sprite

	if current_sprite:
		current_sprite.visible = true
		current_sprite.flip_h = facing_left

	if shield:
		var shield_sprite: Sprite2D = shield.get_node_or_null("Shield") as Sprite2D
		if not shield_sprite:
			shield_sprite = shield.get_node_or_null("Sprite2D") as Sprite2D
			
		if shield_sprite:
			match current_element:
				Element.FIRE: shield_sprite.texture = fire_shield_tex
				Element.WATER: shield_sprite.texture = water_shield_tex
				Element.EARTH: shield_sprite.texture = earth_shield_tex
