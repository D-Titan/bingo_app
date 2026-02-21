class_name PlayerProfile
extends RefCounted

var player_id : int 
var p_name : String 
var p_dp : int

func setup_player(player:Dictionary = {}) -> void:
	if player:
		player_id = player["id"]
		p_name = player["name"]
		p_dp = player["dp"]
	else:
		player_id = GameManager.player_id
		p_name = GameManager.player_name
		p_dp = player_id % len(GameManager.profile_picture) + GameManager.dp_offset

func serial() -> Dictionary:
	var person : Dictionary = {
		"name": p_name,
		"id": player_id,
		"dp": p_dp
	}
	return person
