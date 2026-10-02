extends CanvasLayer

@onready var button_host: Button = %ButtonHost
@onready var button_join: Button = %ButtonJoin
@onready var button_quit: Button = %ButtonQuit

const PLAYER: PackedScene = preload("uid://dsitnylb8wxef")
const GAME: PackedScene = preload("uid://dxvksof0fy6mi")

func _ready() -> void:
	button_host.pressed.connect(on_host)
	button_join.pressed.connect(on_join)
	button_quit.pressed.connect(func() -> void: get_tree().quit())


func on_host() -> void:
	add_game()
	Network.start_server()
	hide()
	
	
func on_join() -> void:
	add_game()
	Network.join_server()
	hide()


func add_game() -> void:
	var new_game: Node2D = GAME.instantiate()
	get_tree().current_scene.add_child(new_game)
	
