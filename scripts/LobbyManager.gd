extends Node

var peer : ENetMultiplayerPeer
const PORT = 31415
const BROADCAST_PORT : int = 31416
const BROADCAST_ADD: String = "255.255.255.255"
const REQUEST : String = "ARE_YOU_BINGO_HOST?"
var server : PacketPeerUDP

var players : Dictionary 

var players_not_ready : Array

enum ps {ready,notReady}

signal plyr_ready(id:int, stat:ps)
signal plyr_not_ready(id :int, stat:ps)
signal player_leaved(id:int, name: String)

var is_host : bool = false
var player_score : Dictionary

func _process(delta: float) -> void:
	if is_host:
		if server.get_available_packet_count()>0:
			var packet := server.get_packet()
			if packet.get_string_from_ascii() == REQUEST:
				#print("Host: request heard")
				server.set_dest_address(server.get_packet_ip(),server.get_packet_port())
				var info : Dictionary = {
					"name": GameManager.player_name + "'s game",
					"port": PORT,
					"pid": multiplayer.get_unique_id()
				}
				server.put_packet(JSON.stringify(info).to_ascii_buffer())



func _ready() -> void:
	multiplayer.peer_connected.connect(_on_joined_game)
	multiplayer.server_disconnected.connect(_host_left)
	multiplayer.connected_to_server.connect(_on_connected_to_server)

func host_game(clients : int = 2) -> void:
	peer = ENetMultiplayerPeer.new()
	var status = peer.create_server(PORT, clients)

	#if status != OK:
		#print("error hosting game! try again later")
		#return
		
	multiplayer.multiplayer_peer = peer
	GameManager.player_id = 1
	is_host = true
	
	var p := PlayerProfile.new()
	p.setup_player()
	p.p_name += " (Host)"
	players[1] = p
	not_ready(1)
	multiplayer.peer_disconnected.connect(_on_game_leaved)
	
	server = PacketPeerUDP.new()
	server.bind(BROADCAST_PORT)
	server.set_broadcast_enabled(true)
	
	#print("Waiting for players...")


func join_game(ip : String = "127.0.0.1", port : int = PORT ) -> void:
	peer = ENetMultiplayerPeer.new()
	var status = peer.create_client(ip, port)
	if status != OK:
		#print("Error joining the game! try again later")
		return
	multiplayer.multiplayer_peer = peer
	#print("Connecting to host....")


func _on_connected_to_server() -> void:
	GameManager.player_id = multiplayer.get_unique_id()
	var person : Dictionary ={
		"name": GameManager.player_name,
		"id": GameManager.player_id,
		"dp" :GameManager.player_id % len(GameManager.profile_picture)
	} 
	rpc("setup_profile_info", person)


@rpc("authority", "call_remote", "reliable")
func go_to_create_board(g_size:int):
	GameManager.grid_size = g_size
	get_tree().change_scene_to_file("res://scenes/create_board.tscn")


@rpc("any_peer", "call_remote", "reliable")
func player_info_synced(id) -> void:
		rpc_id(id, "go_to_create_board", GameManager.grid_size)

func _on_joined_game(id : int):
	if multiplayer.is_server():
		rpc_id(id, "sync_player_info", serial_player_dictionary(players), players_not_ready)


@rpc("any_peer","call_remote","reliable")
func setup_profile_info(person : Dictionary) -> void:
	#print("player ", multiplayer.get_unique_id(),person)
	var p := PlayerProfile.new()
	p.setup_player(person)
	if person.id == multiplayer.get_unique_id():
		p.p_name += " (You)"
	players[p.player_id] = p
	if multiplayer.is_server():
		rpc("setup_profile_info", person)
		rpc("not_ready", p.player_id)


@rpc("any_peer","call_local","reliable")
func not_ready(id: int):
	players_not_ready.append(id)
	plyr_not_ready.emit(id, ps.notReady)

@rpc("any_peer","call_local","reliable")
func ready_to_play(id : int):
	players_not_ready.erase(id)
	plyr_ready.emit(id, ps.ready)

func serial_player_dictionary(players_list:Dictionary) -> Dictionary:
	var players_dictionary : Dictionary
	for i in players_list.values():
		players_dictionary[i.player_id] = i.serial()
	return players_dictionary

@rpc("authority","call_remote","reliable")
func sync_player_info(players_list:Dictionary, waiting_list : Array):
	for person in players_list.values(): 
		var p = PlayerProfile.new()
		p.setup_player(person)
		players[p.player_id] = p
	players_not_ready = waiting_list
	rpc_id(1, "player_info_synced",multiplayer.get_unique_id())

@rpc("authority","call_local","reliable")
func clean_LobbyManager(id : int, name_: String) -> void:
	#print(multiplayer.get_unique_id(), ": player %d leaved from me"%id)
	players.erase(id)
	players_not_ready.erase(id)
	player_score.erase(id)
	player_leaved.emit(id, name_)

func on_leave_clear_Lobby() -> void:
	players.clear()
	players_not_ready.clear()
	player_score.clear()
	is_host = false

func _on_game_leaved(id : int):
	rpc("clean_LobbyManager", id, players[id].p_name)
	
func _host_left() -> void:
	get_tree().change_scene_to_file("res://scenes/host_left.tscn")
