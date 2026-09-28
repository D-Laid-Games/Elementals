extends CharacterBody2D

# movement
const SPEED: float = 130.0

# jump
var max_jumps: int = 1
var jumps_left: int = 1
const Jump_VELOCITY: float = -300.0

# sprite logic
var facing_right: bool = true
var current_sprite: AnimatedSprite2D = null
@onready var earth_sprite: AnimatedSprite2D = $EarthAnimatedSprite2D
@onready var fire_sprite: AnimatedSprite2D = $FireAnimatedSprite2D
@onready var water_sprite: AnimatedSprite2D = $WaterAnimatedSprite2D

func _ready() -> void:
	current_sprite = earth_sprite
	fire_sprite.visible = false
	water_sprite.visible = false
	
func _physics_process(delta: float) -> void:
	player_gravity(delta)
	movement()
	sprite_flip()
	jump()

	move_and_slide()

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

	# animation
	correct_animation()

func sprite_flip() -> void:
	if facing_right == true:
		current_sprite.flip_h = false
	else:
		current_sprite.flip_h = true

func correct_animation() -> void:
	if is_on_floor():
		current_sprite.play("idle" if velocity.x == 0 else "run")
	else:
		current_sprite.play("jump")
			

func jump() -> void:
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = Jump_VELOCITY
		jumps_left -= 1


func player_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jumps_left = max_jumps
