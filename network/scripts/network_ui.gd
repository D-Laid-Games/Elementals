extends Control


func _on_server_pressed() -> void:
	$VBoxContainer/Server.release_focus()
	NetworkHandler.start_server()

func _on_client_pressed() -> void:
	$VBoxContainer/Client.release_focus()
	NetworkHandler.start_client()
