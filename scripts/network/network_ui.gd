extends Control

@onready var ip_edit: LineEdit = $VBoxContainer/IP
@onready var port_edit: LineEdit = $VBoxContainer/Port

func _on_server_pressed() -> void:
	$VBoxContainer/Server.release_focus()
	var port: int = _get_port()
	NetworkHandler.start_server(port)

func _on_client_pressed() -> void:
	$VBoxContainer/Client.release_focus()
	var ip: String = ip_edit.text if ip_edit.text != "" else NetworkHandler.DEFAULT_IP
	var port: int = _get_port()
	NetworkHandler.start_client(ip, port)

func _get_port() -> int:
	if port_edit.text.is_valid_int():
		return port_edit.text.to_int()
	return NetworkHandler.DEFAULT_PORT
