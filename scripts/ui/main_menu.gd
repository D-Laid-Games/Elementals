extends CanvasLayer


@onready var button_host: Button = %ButtonHost
@onready var button_join: Button = %ButtonJoin
@onready var button_quit: Button = %ButtonQuit

@export var game: PackedScene


func _ready() -> void:
	button_host.pressed.connect(on_host)
	button_join.pressed.connect(on_join)
	button_quit.pressed.connect(on_quit)

	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("UI"):
		if not visible:
			show()
			get_viewport().set_input_as_handled()
		elif visible == true:
			hide()
			get_viewport().set_input_as_handled()
	
	
func on_host() -> void:
	if !Network.in_session:
		_add_game()
		Network.start_server()
		hide()
	
	
func on_join() -> void:
	_add_game()
	Network.join_server()
	hide()
	
	
func on_quit() -> void:
	if Network.in_session:
		Network.leave_server()
		show()                  
	else:
		get_tree().quit() 
	

func _add_game() -> void:
	var new_game: Node2D = game.instantiate()
	get_tree().current_scene.add_child(new_game)
	
