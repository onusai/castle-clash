extends Node

var address
var port

var game_started = false

@onready var UsernameInput = $CanvasLayer/HUD/MainMenu/VBox/Username
@onready var AddressInput = $CanvasLayer/HUD/MainMenu/VBox/IP
@onready var HostButton = $CanvasLayer/HUD/MainMenu/VBox/Host
@onready var JoinButton = $CanvasLayer/HUD/MainMenu/VBox/Join
@onready var StartButton = $CanvasLayer/HUD/MainMenu/VBox/Start
@onready var PingLabel = $CanvasLayer/HUD/GameUI/ping

var default_ip = "localhost:7777"

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	Events.connect("ping_updated", ping_updated)
	if "--server" in OS.get_cmdline_args():
		host_game()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func host_game():
	var peer = ENetMultiplayerPeer.new()
	get_address()
	var error = peer.create_server(port)
	if error != OK:
		print("cannot host: " + str(error))
		return
	
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	
	print("Waiting for players!")
	StartButton.show()

@rpc("authority", "call_local", "reliable")
func start_game():
	
	var scene = preload("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(scene)
	$MenuBG.queue_free();
	$CanvasLayer/HUD/MainMenu.hide()
	$CanvasLayer/HUD/GameUI.show()
	
	for p_id in Game.players:
		Events.emit_signal("spawn_player", p_id)
	
	game_started = true

@rpc("any_peer", "reliable")
func send_player_info(name, id):
	if !Game.players.has(id):
		Game.players[id] = {
			"name": name,
			"id": id,
			"score": 0
		}
	
		if multiplayer.is_server():
			for i in Game.players:
				send_player_info.rpc(Game.players[i].name, i)
		
			if game_started:
				start_game.rpc_id(id)
	
			if CustomLevel.enabled and id != 1:
				load_custom_level_object.rpc_id(id, CustomLevel.enabled)
	
			Events.emit_signal("chat_sent", "[color=yellow]" + name + " has joined[/color]")
			
			
	
		if game_started:
			Events.emit_signal("spawn_player", id)
		

# called on server and client
func peer_connected(id):
	print("player connected: " + str(id))

# called on server and client
func peer_disconnected(id):
	print("player disconnected: " + str(id))
	Events.emit_signal("chat_sent", "[color=yellow]" + Game.players[id].name + " has left[/color]")
	Game.players.erase(id)
	Events.emit_signal("player_quit", id)
	

# called only on clients
func connected_to_server():
	print("Connected to server")
	send_player_info.rpc_id(1, UsernameInput.text, multiplayer.get_unique_id())


# called only on client
func connection_failed():
	print("Couldnt connect")
	
@rpc("authority", "reliable")
func load_custom_level_object(enabled):
	pass

func get_address():
	var ip = AddressInput.text
	if ip == "":
		ip = default_ip
		
	if (":" in ip):
		address = ip.strip_edges().split(":")[0]
		port = int(ip.strip_edges().split(":")[1])
	else:
		address = ip
		port = int(default_ip.strip_edges().split(":")[1])

func _on_host_pressed():
	host_game()
	send_player_info(UsernameInput.text, multiplayer.get_unique_id())
	Game.p_id = multiplayer.get_unique_id()
	_on_start_pressed()
	

func _on_join_pressed():
	get_address()
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)

	multiplayer.set_multiplayer_peer(peer)
	
	Game.p_id = multiplayer.get_unique_id()

func _on_start_pressed():
	start_game.rpc()

var ping_stack = []
func ping_updated(ms):
	ping_stack.append(ms)

func _on_timer_1s_timeout():
	var ping = 0.0
	for ms in ping_stack:
		ping += ms / len(ping_stack)
	PingLabel.text = "ping: " + str(round(ping * 1000)) + "ms" 
	ping_stack = []
