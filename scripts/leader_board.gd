extends Control
@onready var leader_board: VBoxContainer = $ScrollContainer/VBoxContainer

var score : Dictionary = LobbyManager.player_score
var score_sorted:Dictionary[int, Array] = {}
@onready var profile : PackedScene = preload("res://scenes/profile_tag.tscn")
const crown = preload("res://assets/buttons/crown_88.png")
@onready var btn_play_again: Button = $HBoxContainer/play_again
@onready var play_again_panel: Panel = $Panel
@onready var new_grid_size: OptionButton = $Panel/CenterContainer/VBoxContainer/GridSize


func _ready() -> void:
	play_again_panel.hide()
	
	for id in score:
		if score_sorted.has(score[id]):
			score_sorted[score[id]].append(id)
		else:
			score_sorted[score[id]] = []
			score_sorted[score[id]].append(id)
		
	print(score_sorted)
	create_leaderboard()

func create_leaderboard():

	for s in range(GameManager.grid_size*2+2, 0, -1):
		for id in score_sorted.get(s,[]): 
			var player = LobbyManager.players[id]
			var p : Control = profile.instantiate()
			var spacer : Control = Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			leader_board.add_child(p)
			if s >= GameManager.grid_size:
				p.create_profile(player, crown, true, p.tag.dark)
			else:
				p.create_profile(player, null, true, p.tag.dark)
				
			p.h_box_container.add_child(spacer)
			var l : Label = Label.new()
			p.h_box_container.add_child(l)
			l.text = " Total Lines: %d  " % s
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
	LobbyManager.player_score.clear()

@rpc("authority","call_local","reliable")
func flush_LobbyManager(grid_size : int) -> void:
	GameManager.grid_size = grid_size
	LobbyManager.players_not_ready = LobbyManager.players.keys()
	get_tree().change_scene_to_file("res://scenes/create_board.tscn")

func play_again() -> void:
	if multiplayer.is_server() and not GameManager.is_local():
		play_again_panel.show()
	else:
		btn_play_again.text = "Waiting for host"
		btn_play_again.disabled = true

func quit_game() -> void:
	if not GameManager.is_local(): 
		if multiplayer.is_server():
			multiplayer.multiplayer_peer.close()
		else:
			multiplayer.multiplayer_peer.disconnect_peer(1)
		multiplayer.multiplayer_peer = null
		
		LobbyManager.on_leave_clear_Lobby()
	get_tree().quit()


func home() -> void:
	if not GameManager.is_local(): 
		if multiplayer.is_server():
			multiplayer.multiplayer_peer.close()
		else:
			multiplayer.multiplayer_peer.disconnect_peer(1)
		multiplayer.multiplayer_peer = null
		
		LobbyManager.on_leave_clear_Lobby()
	#clean all arrays and game data stored so far
	
	get_tree().change_scene_to_file("res://scenes/home_page.tscn")


func play() -> void:
	play_again_panel.show()
	rpc("flush_LobbyManager", new_grid_size.get_item_id(new_grid_size.selected))
