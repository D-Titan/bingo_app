class_name GameUI
extends Control

const PANEL_STYLE = preload("res://assets/panel_style.tres")
@onready var bingoslot : PackedScene = preload("res://scenes/BingoSlot.tscn")
@onready var grid_container : GridContainer = $HBoxContainer/BingoGrid
var grid : Array
@export var card_size : int
@onready var toast : PackedScene = preload("res://scenes/toast_notification.tscn")
@onready var current: GameUI = $"."
const btn_disabled_filled = preload("res://assets/buttons/btn_disabled_filled_88.png")
#@onready var turn_label: Label = $HBoxContainer/multiplayer_sidebar/VBoxContainer/turn/label
@onready var multiplayer_turn: PanelContainer = $HBoxContainer/multiplayer_sidebar/VBoxContainer/turn
const turn_profile_tag = preload("res://scenes/profile_tag.tscn")
var turn_profile : Control
@onready var turn_panel: VBoxContainer = $HBoxContainer/multiplayer_sidebar/VBoxContainer/turn/VBoxContainer
@onready var lines_formed_value: Label = $HBoxContainer/multiplayer_sidebar/VBoxContainer/lines/HBoxContainer/value
@onready var home_page = preload("res://scenes/home_page.tscn")
@onready var in_game_notification: PanelContainer = $HBoxContainer/multiplayer_sidebar/VBoxContainer/in_game_notification
@onready var notification_label: Label = $HBoxContainer/multiplayer_sidebar/VBoxContainer/in_game_notification/Label
@onready var notification_animation_player: AnimationPlayer = $HBoxContainer/multiplayer_sidebar/VBoxContainer/in_game_notification/Label/AnimationPlayer
@onready var local_game_win: PanelContainer = $PanelContainer
@onready var play_again_local: Button = $PanelContainer/CenterContainer/VBoxContainer/play_again


var plyr_leaved : Array = []
enum gamestate {player_turn, synchronize}

var player_score : Dictionary

var curr_state: gamestate

var score_check : Array = LobbyManager.players.keys():
	set(arr):
		score_check = arr
		if not score_check and not GameManager.is_local():
			curr_state = gamestate.player_turn
			call_update_turn()

var scene_loaded: Array :
	set(arr):
		scene_loaded = arr
		if not scene_loaded and multiplayer.is_server():
			call_update_turn()
var bingo_complete: PackedInt64Array
var slot_map : Dictionary
var board_map : Dictionary

var p_turn_list : PackedInt64Array 
var p_turn : int 
var t_players : int
var game_call : int

func _ready() -> void:
	GameManager.scene_stack.clear()
	card_size = GameManager.grid_size
	grid_container.columns = card_size
	grid = GameManager.board
	curr_state = gamestate.player_turn
	in_game_notification.hide()
	local_game_win.hide()
	LobbyManager.player_leaved.connect(player_leaved_game)
	
	if  GameManager.is_local():
		multiplayer_turn.hide()
	else:
		turn_profile = turn_profile_tag.instantiate()
		turn_panel.add_child(turn_profile)
		turn_profile.anchors_preset = Control.PRESET_BOTTOM_WIDE
		
	if multiplayer.is_server() and not GameManager.is_local():
		multiplayer.multiplayer_peer.refuse_new_connections = true
		scene_loaded = LobbyManager.players.keys()
		p_turn_list = LobbyManager.players.keys()
		t_players = len(p_turn_list)
		game_call = 0
		scene_loaded.erase(1)
	lines_formed_value.text = "0"
	create_board()
	
	if not multiplayer.is_server():
		rpc_id(1, "update_scene_loaded", multiplayer.get_unique_id())
	

@rpc("any_peer","call_remote","reliable")
func update_scene_loaded(id: int) -> void:
	scene_loaded.erase(id)
	scene_loaded = scene_loaded


func create_board() -> void:
	for i in range(card_size):
		for j in range(card_size):
			var slot: BingoSlot = bingoslot.instantiate()
			slot.interacted.connect(on_slot_clicked)
			grid_container.add_child(slot)
			slot.setup(grid[i][j], Vector2(i,j))
			slot.custom_minimum_size = GameManager.visual[card_size]
			if card_size > 8:
				slot.btn_text.add_theme_font_size_override("font_size", 18)
			slot_map[Vector2(i,j)] = slot
			board_map[slot.val] = slot

func call_update_turn() -> void:
	if curr_state == gamestate.player_turn:
		if not bingo_complete:
			score_check = LobbyManager.players.keys()
			var p_turn_id : int = p_turn_list[game_call % t_players]
			game_call += 1
			while(p_turn_id in plyr_leaved):
				p_turn_id = p_turn_list[game_call % t_players]
				game_call += 1
			rpc("update_turn", p_turn_id)
		else:
			rpc("save_score", player_score)
	else: return

@rpc("authority","call_local","reliable")
func update_turn(_id : int):
	p_turn = _id
	if not GameManager.is_local():
		turn_profile.create_profile(LobbyManager.players.get(_id))
	if p_turn == GameManager.player_id:
		Input.vibrate_handheld()

func on_slot_clicked(slot:BingoSlot) -> void:
	if p_turn == GameManager.player_id and not GameManager.is_local():
		rpc_id(1,"request_select_slot", slot.val,GameManager.player_id)
	elif GameManager.is_local():
		select_slot(slot.val)
	else:
		revert_slot_by_val(slot.val, "Not Your Turn!")

@rpc("any_peer","call_local","reliable")
func request_select_slot(val : int, id : int) -> void:
	if p_turn == id and curr_state == gamestate.player_turn:
		rpc("select_slot", val)
		curr_state = gamestate.synchronize
	else:
		rpc_id(id, "revert_slot_by_val",val, "Not Your Turn!")

@rpc("any_peer","call_local","reliable")
func select_slot(val) -> void:
	var slot : BingoSlot = board_map[val]
	slot.update_without_signal(true)
	update_score(slot)

@rpc("any_peer","call_local","reliable")
func revert_slot_by_val(val:int, msg: String ='') -> void:
	board_map[val].update_without_signal(false)
	if msg:
		show_notification("Not your Turn!", true)

var lines: int = 0:
	set(value):
		lines = value
		lines_formed_value.text = str(lines)

var painted : Dictionary

func update_score(slot : BingoSlot) -> void:
	var row : Dictionary
	var col : Dictionary
	var diag : Dictionary
	var diag2: Dictionary
	#Check if line is formed
	var i : int = int(slot.grid_pos.x)
	var j : int = int(slot.grid_pos.y)
	var clicked_row : int = 0
	var clicked_col : int = 0
	var clicked_diag : int = 0
	var clicked_diag2 : int = 0
	
	for k in range(card_size):
		#checking in row
		var button : BingoSlot 
		button = slot_map[Vector2(i,k)]
		
		if button.button_pressed:
			clicked_row += 1
			if not painted.has(Vector2(i,k)): 
				row[Vector2(i,k)] = button
			
		#checking in col
		button = slot_map[Vector2(k,j)]
		if button.button_pressed:
			clicked_col += 1
			if not painted.has(Vector2(k,j)): 
				col[Vector2(k,j)] = button
		#checking in diag 1
		if i==j:
			button = slot_map[Vector2(k,k)]
			if button.button_pressed:
				clicked_diag +=1
				if not painted.has(Vector2(k,k)): 
					diag[Vector2(k,k)] = button

		#checking in diag 2
		if i+j == card_size -1:
			button = slot_map[Vector2(k, card_size-1-k)]
			if button.button_pressed:
				clicked_diag2 += 1
				if not painted.has(Vector2(k,card_size-1-k)): 
					diag2[Vector2(k,card_size-1-k)] = button

	if clicked_row == card_size:
		lines+=1
		for key in row:
			row[key].texture_disabled = btn_disabled_filled
			painted[key] = row[key]
			
	if clicked_col == card_size:
		lines+=1
		for key in col:
			col[key].texture_disabled = btn_disabled_filled
			painted[key] = col[key]
			
	if clicked_diag == card_size:
		lines +=1
		for key in diag:
			diag[key].texture_disabled = btn_disabled_filled
			painted[key] = diag[key]
			
	if clicked_diag2 == card_size:
		lines+=1
		for key in diag2:
			diag2[key].texture_disabled = btn_disabled_filled
			painted[key] = diag2[key]
	
	if GameManager.is_local():
		if lines == card_size:
			local_play_again()
	else:
		if multiplayer.is_server():
			check_score(1, lines)
		else:
			rpc_id(1, "check_score", multiplayer.get_unique_id(), lines)

@rpc("any_peer","call_remote","reliable")
func check_score(id:int, score : int)-> void:
	if score >= card_size:
		bingo_complete.append(id)

	score_check.erase(id)
	player_score[id] = score
	score_check = score_check

@rpc("authority","call_local","reliable")
func save_score(score : Dictionary) -> void:
	LobbyManager.player_score = score
	#change scene to leaderboard
	get_tree().change_scene_to_file("res://scenes/leader_board.tscn")


func player_leaved_game(id: int, name_:String) -> void:
	plyr_leaved.append(id)
	show_notification("%s Left Game!" % name_)
	if multiplayer.is_server():
		if curr_state == gamestate.player_turn and p_turn == id:
			call_update_turn()
		else:
			score_check.erase(id)
		scene_loaded.erase(id)
		scene_loaded = scene_loaded

func show_notification(msg:String , animation: bool = false) -> void:
	notification_label.text = msg
	in_game_notification.show()
	if animation:
		notification_animation_player.play("blink text")
	await get_tree().create_timer(1).timeout
	in_game_notification.hide()
	
func local_play_again()-> void:
	local_game_win.show()
	play_again_local.pressed.connect(func ():
		get_tree().change_scene_to_file("res://scenes/home_page.tscn")
		)
	
