extends CharacterBody2D

const SPEED: float = 130.0
const JUMP_VELOCITY: float = -300.0
# 1. Preload your projectile scene (make sure this path matches where you saved projectile.tscn)
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectile.tscn")
const SHIELD_SCENE: PackedScene = preload("res://scenes/shield.tscn")

@export var fire_rate: float = 1.0 # Delay in seconds between shots
@export var shield_offset: Vector2 = Vector2(30.0, 0.0)

var can_shoot: bool = true
var shield: Area2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Spawn the shield as a child node so it follows player movement
	shield = SHIELD_SCENE.instantiate() as Area2D
	shield.position = shield_offset
	shield.visible = false
	shield.monitoring = false # Disables collision checks while hidden
	add_child(shield)

func _unhandled_input(event: InputEvent) -> void:
	# 2. Listen for Left Mouse Click
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
	#if Input.is_action_just_pressed("shoot"):
	if event.is_action_pressed("shoot") and not event.is_echo():
		shoot()

func shoot() -> void:
	# Explicitly typed variables to clear Godot's strict type warnings
	if not can_shoot:
		return
		
	can_shoot = false
	var projectile: Node2D = PROJECTILE_SCENE.instantiate() as Node2D
	
	
	# Aim directly toward mouse
	var mouse_pos: Vector2 = get_global_mouse_position()
	var dir: Vector2 = (mouse_pos - global_position).normalized()
	
	#spawn projectile
	projectile.global_position = global_position + (dir * 35.0)
	projectile.rotation = dir.angle()
	
	# Add projectile to the main scene level
	get_tree().current_scene.add_child(projectile)
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

func _physics_process(delta: float) -> void:
	
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

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	var direction: float = Input.get_axis("move_left", "move_right")
	
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")    
	else:
		animated_sprite.play("jump")

	# Flip the sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
			
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	move_and_slide()
