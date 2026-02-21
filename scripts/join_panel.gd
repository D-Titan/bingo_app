extends Panel

@onready var line_edit: LineEdit = $VBoxContainer2/VBoxContainer/LineEdit
@onready var item_list: ItemList = $VBoxContainer2/Panel/VBoxContainer/ItemList
@onready var host_label: Label = $VBoxContainer2/Panel/VBoxContainer/Label

var hosts : Dictionary = {}
var client_broadcaster : PacketPeerUDP
var b_timer : Timer
var join_ip : String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	client_broadcaster = PacketPeerUDP.new()
	client_broadcaster.set_broadcast_enabled(true)
	client_broadcaster.bind(0)
	b_timer = Timer.new()
	add_child(b_timer)
	b_timer.wait_time = 3
	b_timer.timeout.connect(broadcast_p)
	b_timer.start()
	broadcast_p()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if client_broadcaster.get_available_packet_count() > 0:
		var msg : String = client_broadcaster.get_packet().get_string_from_ascii()
		var load_msg  = JSON.new()
		var host_ip : String = client_broadcaster.get_packet_ip()
		load_msg.parse(msg)
		var host_info = load_msg.get_data()
		if not hosts.get(host_ip, null):
			hosts[host_ip] = host_info
			add_to_host_list(host_ip)

func broadcast_p() -> void:
	var buffer = LobbyManager.REQUEST.to_ascii_buffer()
	client_broadcaster.set_dest_address(LobbyManager.BROADCAST_ADD, LobbyManager.BROADCAST_PORT)
	client_broadcaster.put_packet(buffer)
	#print("Client: requested for hosts")

func add_to_host_list(ip: String) -> void:
	var _name: String = hosts[ip].get("name")
	item_list.add_item("  "+_name, GameManager.profile_picture[(15 + len(hosts))% len(GameManager.profile_picture)], true)
	item_list.set_item_metadata(item_list.get_item_count() -1 , ip)
	host_label.text = "Select host to join"
	

func join() -> void:
	GameManager.gmode = GameManager.gtype.multiplayer
	GameManager.player_name = line_edit.text
	if join_ip:
		GameManager.scene_stack.append("res://scenes/join_panel.tscn")
		LobbyManager.join_game(join_ip, hosts[join_ip].get("port"))


func _on_item_list_item_selected(index: int) -> void:
	join_ip = item_list.get_item_metadata(index)

func back() -> void:
	get_tree().change_scene_to_file(GameManager.scene_stack.pop_back()) 
