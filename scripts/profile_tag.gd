extends Control

@onready var status: TextureRect = $HBoxContainer/status
@onready var dp: TextureRect = $HBoxContainer/dp
@onready var player_name: Label = $HBoxContainer/player_name
@export var player_id : int
@onready var h_box_container: HBoxContainer = $HBoxContainer
const panel_dark = preload("res://assets/player_tag_panel_dark.tres")
const panel_light = preload("res://assets/player_tag_panel_light.tres")

enum tag {dark, light}

func _ready() -> void:
	status.hide()

func create_profile(player: PlayerProfile, status_dp:Texture2D = null, show_status : bool = false, theme_:tag = tag.light) -> void:
	player_name.text = player.p_name
	dp.texture = GameManager.profile_picture[player.p_dp]
	
	match theme_:
		tag.light:
			add_theme_stylebox_override("panel", panel_light)
		tag.dark:
			add_theme_stylebox_override("panel", panel_dark)
	
	if show_status:
		status.show()

	if status_dp:
		status.show()
		status.texture = status_dp
