extends CanvasLayer

@onready var button_host: Button = %ButtonHost
@onready var button_join: Button = %ButtonJoin
@onready var button_quit: Button = %ButtonQuit

const PLAYER: PackedScene = preload("uid://dsitnylb8wxef")
const GAME: PackedScene = preload("uid://dxvksof0fy6mi")

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	button_host.pressed.connect(on_host)
	button_join.pressed.connect(on_join)
	button_quit.pressed.connect(on_quit)

	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("UI"):
		if not visible:
			show()
			get_viewport().set_input_as_handled()
		elif visible and get_tree().current_scene.has_node("Game"): 
			hide()
			get_viewport().set_input_as_handled()
	
	
func on_host() -> void:
	add_game()
	Network.start_server()
	hide()
	
	
func on_join() -> void:
	add_game()
	Network.join_server()
	hide()
	
func on_quit() -> void:
	if Network.in_session:
		Network.leave_server()
		show()                  
	else:
		get_tree().quit() 
	

func add_game() -> void:
	var new_game: Node2D = GAME.instantiate()
	get_tree().current_scene.add_child(new_game)
	
