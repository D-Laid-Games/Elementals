extends Node

var loadouts_by_peer: Dictionary[int, Dictionary]


func get_count(peer_id: int, powerup: String) -> int:
	var counts: Dictionary = loadouts_by_peer.get(peer_id, {})
	return int(counts.get(powerup, 0))


func try_grant_power_up(peer_id: int, powerup: String) -> int:
	if not loadouts_by_peer.has(peer_id):
		loadouts_by_peer[peer_id] = {}
		
	var count: int = get_count(peer_id, powerup)
	if count >= 3:
		return 0
	else:
		var peer_loadout: Dictionary = loadouts_by_peer.get(peer_id, {})
		peer_loadout[powerup] = count + 1
		return count + 1


func get_loadout(peer_id: int) -> Dictionary:
	var peer_loadout: Dictionary = loadouts_by_peer.get(peer_id, {})
	return peer_loadout.duplicate()
