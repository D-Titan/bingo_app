extends Panel
@onready var grid: OptionButton = $CenterContainer/VBoxContainer2/GridSize
@onready var line_edit: LineEdit = $CenterContainer/VBoxContainer2/LineEdit
@onready var spin_box: SpinBox = $CenterContainer/VBoxContainer2/HBoxContainer/SpinBox

func _ready() -> void:
	if LobbyManager.server:
		LobbyManager.server.close()
	LobbyManager.server = null


func back() -> void:
	get_tree().change_scene_to_file(GameManager.scene_stack.pop_back()) 


func host() -> void:
	var numbers : LineEdit = spin_box.get_line_edit()
	var num : int = convert(numbers.text,TYPE_INT)
	GameManager.grid_size = grid.get_item_id(grid.selected)
	GameManager.gmode = GameManager.gtype.multiplayer
	GameManager.player_name = line_edit.text
	#print("hosting game")
	LobbyManager.host_game(num)
	GameManager.scene_stack.append("res://scenes/host_panel.tscn")
	get_tree().change_scene_to_file("res://scenes/create_board.tscn")
