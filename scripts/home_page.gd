extends Control
@onready var play_panel: Panel = $Panel
@onready var grid_size: OptionButton = $Panel/CenterContainer/VBoxContainer/GridSize
@onready var play_btn: Button = $Panel/CenterContainer/VBoxContainer/play_btn


func _ready() -> void:
	GameManager.scene_stack.clear()
	GameManager.gmode = GameManager.gtype.local
	play_panel.hide()
	if LobbyManager.server:
		LobbyManager.server.close()
	LobbyManager.server = null


func _on_play_pressed() -> void:
	play_panel.show()
	
func _on_host_pressed() -> void:
	GameManager.scene_stack.push_back("res://scenes/home_page.tscn")
	get_tree().change_scene_to_file("res://scenes/host_panel.tscn")
	

func _on_join_pressed() -> void:
	GameManager.scene_stack.push_back("res://scenes/home_page.tscn")
	get_tree().change_scene_to_file("res://scenes/join_panel.tscn")


func play() -> void:
	GameManager.scene_stack.push_back("res://scenes/home_page.tscn")
	GameManager.grid_size = grid_size.get_item_id(grid_size.selected)
	get_tree().change_scene_to_file("res://scenes/create_board.tscn")


func quit() -> void:
	get_tree().quit()

func back() -> void:
	play_panel.hide()
