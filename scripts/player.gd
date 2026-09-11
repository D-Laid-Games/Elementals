extends CharacterBody2D

enum Element { FIRE, WATER, EARTH }
var current_element: Element = 0 as Element

const SPEED: float = 130.0
const JUMP_VELOCITY: float = -300.0
# 1. Preload your projectile scene (make sure this path matches where you saved projectile.tscn)
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectile.tscn")
const SHIELD_SCENE: PackedScene = preload("res://scenes/shield.tscn")

@export var fire_rate: float = 1.0 # Delay in seconds between shots
@export var shield_offset: Vector2 = Vector2(20.0, 0.0)

@export_group("Shield Textures")
@export var fire_shield_tex: Texture2D = preload("res://assets/fireShield.png")
@export var water_shield_tex: Texture2D = preload("res://assets/waterShield.png")
@export var earth_shield_tex: Texture2D = preload("res://assets/earthShield.png")

@export_group("Projectile Textures")
@export var fire_ball_tex: Texture2D = preload("res://assets/fireBall.png")
@export var water_ball_tex: Texture2D = preload("res://assets/waterBall.png")
@export var earth_ball_tex: Texture2D = preload("res://assets/earthBall.png")

var can_shoot: bool = true
var shield: Area2D

# Onready references to your scene tree nodes
@onready var fire_sprite: AnimatedSprite2D = $FireAnimatedSprite2D
@onready var water_sprite: AnimatedSprite2D = $WaterAnimatedSprite2D
@onready var earth_sprite: AnimatedSprite2D = $EarthAnimatedSprite2D

var current_sprite: AnimatedSprite2D

@export var max_health: float = 10.0
var current_health: float

@onready var health_bar: ProgressBar = $HealthBar

@export var max_jumps: int
var jumps_left: int


@export var roll_speed: float = 400.0
@export var roll_duration: float = 0.10
@export var roll_cooldown: float = 0.8

var is_rolling: bool = false
var can_roll: bool = true
var is_invincible: bool = false
var roll_direction: float = 0.0

func _ready() -> void:
	current_health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	# Spawn the shield as a child node so it follows player movement
	shield = SHIELD_SCENE.instantiate() as Area2D
	shield.position = shield_offset
	shield.visible = false
	shield.monitoring = false # Disables collision checks while hidden
	add_child(shield)
	
	# Pick a random element (0: FIRE, 1: WATER, 2: EARTH)
	var random_element: Element = (randi() % 3) as Element
	set_element(random_element)
	

func take_damage(amount: float) -> void:
	current_health -= amount
	current_health = clamp(current_health, 0.0, max_health)
	
	if health_bar:
		health_bar.value = current_health
		
	if current_health <= 0.0:
		die()
		

func die() -> void:
	# Trigger scene reload or death logic
	Engine.time_scale = 0.5
	if has_node("CollisionShape2D"):
		$CollisionShape2D.queue_free()
	
	await get_tree().create_timer(0.5).timeout
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.is_action_pressed("fire_stance"):
			set_element(Element.FIRE)
		elif event.is_action_pressed("water_stance"):
			set_element(Element.WATER)
		elif event.is_action_pressed("earth_stance"):
			set_element(Element.EARTH)

	if event.is_action_pressed("shoot") and not event.is_echo():
		shoot()
		
	# Inside _unhandled_input(event: InputEvent) in player.gd
	if event.is_action_pressed("ability_button") and not event.is_echo():
		if current_element == Element.FIRE and can_roll and not is_rolling:
			perform_roll()

func perform_roll() -> void:
	is_rolling = true
	can_roll = false
	is_invincible = true
	
	# Lock the direction at the start of the roll
	roll_direction = -1.0 if current_sprite.flip_h else 1.0
	

	# Wait out roll duration
	await get_tree().create_timer(roll_duration).timeout
	is_rolling = false
	is_invincible = false

	# Wait out cooldown
	await get_tree().create_timer(roll_cooldown).timeout
	can_roll = true


func set_element(new_element: Element) -> void:
	current_element = new_element
	
	max_jumps = 2 if current_element == Element.WATER else 1
	
	if not is_on_floor():
		if current_element == Element.WATER:
			# Give access to the 2nd jump if it hasn't been used yet
			jumps_left = max(jumps_left, 1)
		else:
			# Instantly revoke mid-air jumps for non-Water stances
			jumps_left = 0
	else:
		jumps_left = max_jumps
	
	var last_flip_h: bool = false
	if current_sprite:
		last_flip_h = current_sprite.flip_h

	fire_sprite.visible = false
	water_sprite.visible = false
	earth_sprite.visible = false
	
	match current_element:
		Element.FIRE:
			current_sprite = fire_sprite
		Element.WATER:
			current_sprite = water_sprite
		Element.EARTH:
			current_sprite = earth_sprite
			
	current_sprite.visible = true
	current_sprite.flip_h = last_flip_h

	# SWAP SHIELD TEXTURE
	if shield:
		var shield_sprite: Sprite2D = shield.get_node_or_null("Shield") as Sprite2D
		if shield_sprite:
			match current_element:
				Element.FIRE:
					shield_sprite.texture = fire_shield_tex
				Element.WATER:
					shield_sprite.texture = water_shield_tex
				Element.EARTH:
					shield_sprite.texture = earth_shield_tex

	
func shoot() -> void:
	if not can_shoot:
		return
		
	can_shoot = false
	var projectile: Node2D = PROJECTILE_SCENE.instantiate() as Node2D
	projectile.element = current_element
	
	# SWAP PROJECTILE TEXTURE
	var proj_sprite: Sprite2D = projectile.get_node_or_null("Damagezone/Projectile") as Sprite2D
	if proj_sprite:
		match current_element:
			Element.FIRE:
				proj_sprite.texture = fire_ball_tex
			Element.WATER:
				proj_sprite.texture = water_ball_tex
			Element.EARTH:
				proj_sprite.texture = earth_ball_tex

	var mouse_pos: Vector2 = get_global_mouse_position()
	var dir: Vector2 = (mouse_pos - global_position).normalized()
	
	projectile.global_position = global_position + (dir * 35.0)
	projectile.rotation = dir.angle()
	
	get_tree().current_scene.add_child(projectile)
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

func _physics_process(delta: float) -> void:
	if is_rolling:
		velocity.x = roll_direction * roll_speed
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return # Bypasses all standard input handling during the roll
	
	var current_speed: float = SPEED
	
	if Input.is_action_pressed("ability_button") and current_element == Element.EARTH:
		current_speed = SPEED * 2
		
	# Toggle Shield with Right Click (MOUSE_BUTTON_RIGHT)
	var is_shielding: bool = Input.is_action_pressed("shield")
	shield.visible = is_shielding
	shield.monitoring = is_shielding

	# Optional: Rotate shield position toward mouse position
	var mouse_dir: Vector2 = (get_global_mouse_position() - global_position).normalized()
	shield.position = mouse_dir * shield_offset.length()
	shield.rotation = mouse_dir.angle()
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta


	var direction: float = Input.get_axis("move_left", "move_right")
	
	if is_on_floor():
		max_jumps = 2 if current_element == Element.WATER else 1
		jumps_left = max_jumps
		if direction == 0:
			current_sprite.play("idle")
		else:
			current_sprite.play("run")    
	else:
		current_sprite.play("jump")
	
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1

	# Flip the sprite
	if direction > 0:
		current_sprite.flip_h = false
	elif direction < 0:
		current_sprite.flip_h = true
			
	if direction:
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)

	move_and_slide()
	
	
	
