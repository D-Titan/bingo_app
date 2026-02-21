extends Control

@onready var grid_container: GridContainer = $HBoxContainer/GridContainer
@onready var slot : PackedScene = preload("res://scenes/BingoSlot.tscn")
@onready var play_btn: Button = $HBoxContainer/CenterContainer/VBoxContainer/play
@onready var clear_btn: Button = $HBoxContainer/CenterContainer/VBoxContainer/HBoxContainer2/clear
@onready var undo_btn: Button = $HBoxContainer/CenterContainer/VBoxContainer/HBoxContainer2/undo
@onready var redo_btn: Button = $HBoxContainer/CenterContainer/VBoxContainer/HBoxContainer2/redo
@onready var ready_btn: Button = $HBoxContainer/CenterContainer/VBoxContainer/ready
@onready var jsp: VBoxContainer = $HBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/ScrollContainer/jsp
@onready var profile : PackedScene = preload("res://scenes/profile_tag.tscn")
@onready var create_board_section: VBoxContainer = $HBoxContainer/CenterContainer/VBoxContainer
@onready var current: Control = $"."
@onready var Waiting_players_section: PanelContainer = $HBoxContainer/VBoxContainer/PanelContainer
@onready var back_btn: Button = $HBoxContainer/CenterContainer/VBoxContainer/back_btn

@onready var notification_section : VBoxContainer = $HBoxContainer/VBoxContainer/notification
@onready var toast : PackedScene = preload("res://scenes/toast_notification.tscn")


var jsp_Waiting : Dictionary = {}
var dim : int
var board : Dictionary
var next_val: int = 1 :
	set(val):
		next_val = val
		if next_val > 25:
			state = bs.full
			play_btn.disabled = false
			ready_btn.disabled = false
		else:
			state = bs.partial
			play_btn.disabled = true
			ready_btn.disabled = true
		
		if next_val == 1:
			clear_btn.disabled = true
		else:
			clear_btn.disabled = false

var undo_stack : Array 
var redo_stack : Array
enum bs {partial, full} #board state

var state : bs = bs.partial 

func _ready() -> void:
	notification_section.hide()
	play_btn.disabled = true
	dim = GameManager.grid_size
	clear_btn.disabled = true
	ready_btn.disabled = true
	Waiting_players_section.hide()
	LobbyManager.player_leaved.connect(player_leaved_game)
	if multiplayer.is_server() and not GameManager.is_local():
		multiplayer.multiplayer_peer.refuse_new_connections = false
		ready_btn.hide()
		Waiting_players_section.show()
		create_section()
	elif not GameManager.is_local() :
		play_btn.hide()
		Waiting_players_section.show()
		create_section()
	else:
		ready_btn.hide()
		Waiting_players_section.hide()
		
	LobbyManager.plyr_not_ready.connect(update_jsp)
	LobbyManager.plyr_ready.connect(update_jsp)
	create_board(dim)


func create_board(dimensions : int) -> void:
	grid_container.columns = dimensions
	for i in range(dimensions):
		for j in range(dimensions):
			var tile := slot.instantiate()
			tile.setup(0, Vector2(i,j))
			tile.custom_minimum_size = GameManager.visual[dimensions]
			board[Vector2(i,j)] = tile
			grid_container.add_child(tile)
			if dimensions > 8:
				tile.btn_text.add_theme_font_size_override("font_size", 18)
			tile.interacted.connect(update_text)


func update_text(tile : BingoSlot, next : int = next_val) -> void:
	tile.val = next
	tile.update_without_signal(true)
	undo_stack.push_back(tile)
	redo_stack.clear()
	next_val+=1


func undo() -> void:
	if undo_stack:
		var tile: BingoSlot = undo_stack.pop_back()
		tile.val = 0
		tile.update_without_signal(false)
		next_val -= 1
		redo_stack.push_back(tile)
	else:
		pass

func redo() -> void:
	if redo_stack:
		var tile : BingoSlot = redo_stack.pop_back()
		tile.val = next_val
		tile.update_without_signal(true)
		undo_stack.push_back(tile)
		next_val+=1 
		
	else:
		pass


func autofill() -> void:
	if state == bs.partial:
		autofill_partial()
	else:
		next_val = 1
		autofill_whole()
	undo_stack.clear()
	return


func autofill_partial() -> void:
	var auto : BingoCardData = BingoCardData.new()
	var arr = auto.generate_arr(dim, next_val)
	for i in range(dim):
		for j in range(dim):
			var tile : BingoSlot = board[Vector2(i,j)]
			if  tile.val == 0:
				update_text(tile, arr.pop_back())


func autofill_whole() -> void:
	var auto : BingoCardData = BingoCardData.new()
	var arr = auto.generate_arr(dim, next_val)
	for i in range(dim):
		for j in range(dim):
			var tile : BingoSlot = board[Vector2(i,j)]
			update_text(tile, arr[i*dim + j])
	return


func play() -> void:
	var msg_ : String = "Waiting for players to ready!"
	if multiplayer.is_server() and LobbyManager.players_not_ready == [1] and multiplayer.get_peers().size() != 0:
		LobbyManager.ready_to_play(1)
		rpc("play_game")
	elif GameManager.is_local():
		play_game()
	else:
		if multiplayer.get_peers().size() == 0:
			msg_ = "No players joined the game"
		var t : Control = toast.instantiate()
		notification_section.add_child(t)
		t.msg(msg_, Color.WHITE)
		notification_section.show()
		#t.animation_player.play("blink text")
		await get_tree().create_timer(0.5).timeout
		notification_section.remove_child(t)
		notification_section.hide()

func on_clear() -> void:
	if state == bs.partial:
		for i in undo_stack:
			i.setup(0, i.grid_pos)
	elif state == bs.full:
		for i in board.values():
			i.setup(0,i.grid_pos)
			
	undo_stack.clear()
	redo_stack.clear()
	next_val = 1


@rpc("authority","call_local","reliable")
func play_game():
	var board_arr : Array
	for i in range(dim):
		var row : Array
		for j in range(dim):
			row.append(board[Vector2(i,j)].val)
		board_arr.append(row)
	GameManager.board = board_arr
	get_tree().change_scene_to_file("res://scenes/GameUI.tscn")


func _on_ready_pressed() -> void:
	LobbyManager.rpc("ready_to_play",multiplayer.get_unique_id())
	create_board_section.hide()


func update_jsp(id, status : LobbyManager.ps) -> void:
	match status:
		LobbyManager.ps.ready:
			var tag : Control = jsp_Waiting.get(id, null)
			if tag:
				jsp.remove_child(tag)
		LobbyManager.ps.notReady:
			var tag : Control = jsp_Waiting.get(id,null)
			if not tag:
				tag = profile.instantiate()
				jsp.add_child(tag)
				tag.create_profile(LobbyManager.players.get(id))
				jsp_Waiting[id] = tag

func create_section() -> void:
	for i in LobbyManager.players_not_ready:
		if not jsp_Waiting.get(i,null):
			var tag : Control =  profile.instantiate()
			jsp.add_child(tag)
			tag.create_profile(LobbyManager.players.get(i))
			jsp_Waiting[i] = tag

func player_leaved_game(id:int, _name:String) -> void:
	update_jsp(id, LobbyManager.ps.ready)
	jsp_Waiting.erase(id)
	LobbyManager.players_not_ready.erase(id)

func go_back() -> void:
	if not GameManager.is_local(): 
		if multiplayer.is_server():
			multiplayer.multiplayer_peer.close()
		else:
			multiplayer.multiplayer_peer.disconnect_peer(1)
		multiplayer.multiplayer_peer = null
		LobbyManager.on_leave_clear_Lobby()
	get_tree().change_scene_to_file(GameManager.scene_stack.pop_back())
