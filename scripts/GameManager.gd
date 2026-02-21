extends Node
const ICON = preload("res://icon.svg")
var grid_size : int = 5
var dp_offset : int = 15

var visual : Dictionary[int,Vector2] = {
	5: Vector2(72,72),
	6: Vector2(72,72),
	7: Vector2(72,72),
	8: Vector2(72,72),
	9: Vector2(64,64),
	10: Vector2(60,60)
}

var board : Array

enum gtype {local, multiplayer}

var gmode: gtype = gtype.local

var player_name : String = 'Admin' 

var player_not_ready : Array

var profile_picture : Array[Texture2D] = [
	preload("res://assets/profiles/avatar_1.png"), preload("res://assets/profiles/avatar_2.png"), preload("res://assets/profiles/avatar_3.png"), preload("res://assets/profiles/avatar_4.png"), preload("res://assets/profiles/avatar_5.png"), preload("res://assets/profiles/avatar_6.png"), preload("res://assets/profiles/avatar_7.png"), preload("res://assets/profiles/avatar_8.png"), preload("res://assets/profiles/avatar_9.png"), preload("res://assets/profiles/avatar_10.png"), preload("res://assets/profiles/avatar_11.png"), preload("res://assets/profiles/avatar_12.png"), preload("res://assets/profiles/avatar_13.png"), preload("res://assets/profiles/avatar_14.png"), preload("res://assets/profiles/avatar_15.png"), preload("res://assets/profiles/avatar_16.png"), preload("res://assets/profiles/avatar_17.png"), preload("res://assets/profiles/avatar_18.png"), preload("res://assets/profiles/avatar_19.png")
]

var scene_stack : Array[String]

func is_local() -> bool:
	if gmode == gtype.local:
		return true
	else:
		return false
		
var player_id : int 
