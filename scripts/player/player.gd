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

func _enter_tree() -> void:
	set_multiplayer_authority(int(name))


func _ready() -> void:
	add_to_group("Player")
	current_sprite = earth_sprite
	current_sprite.visible = true;
	fire_sprite.visible = false
	water_sprite.visible = false
	
	
func _physics_process(delta: float) -> void:
	#sprite_flip()
	if not is_multiplayer_authority():
		return
	player_gravity(delta)
	movement()
	jump()
	update_state()
	move_and_slide()
	
	
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
