extends Node
class_name PlayerPowerUps

signal loadout_changed(powerup: String)

@onready var player: CharacterBody2D = get_parent()

var owned_counts: Dictionary


func _enter_tree() -> void:
	set_multiplayer_authority(1)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug") and player.is_multiplayer_authority():
		if not multiplayer.is_server():
			rpc_id(1, "request_grant_power_up", "bulwark")
		else:
			request_grant_power_up("bulwark")


func _set_power_up_count(id: String, count: int) -> void:
	owned_counts[id] = count
	loadout_changed.emit(id)


@rpc("any_peer", "reliable")
func request_grant_power_up(powerup: String) -> void:
	if not multiplayer.is_server():
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id != 0 and sender_id != player.name.to_int():
		return
	
	var count: int = MatchState.try_grant_power_up(player.name.to_int(), powerup)
	if count > 0:
		_set_power_up_count(powerup, count)
		rpc("receive_power_up_count", powerup, owned_counts[powerup])


func power_up_count(powerup: String) -> int:
	var count: int = 0
	if owned_counts.has(powerup):
		count = owned_counts[powerup]
	return count


@rpc("authority", "call_remote", "reliable")
func receive_power_up_count(powerup: String, count: int) -> void:
	_set_power_up_count(powerup, count)


func get_shield_length_multiplier() -> float:
	var shield_length_multiplier: float = 1.0
	var count: int = power_up_count("bulwark")
	if count > 0:
		shield_length_multiplier = 1 + 0.2 * count
	return shield_length_multiplier


func get_shield_turn_speed() -> int:
	var shield_rotation_speed: int = 0
	var count: int = power_up_count("bulwark")
	if count > 0:
		shield_rotation_speed = 700 - 100 * count
	return shield_rotation_speed


func restore_loadout(loadout: Dictionary) -> void:
	for powerup: String in loadout:
		_set_power_up_count(powerup, loadout[powerup])


@rpc("authority", "call_remote", "reliable")
func receive_peer_loadout(loadout: Dictionary) -> void:
	restore_loadout(loadout)
