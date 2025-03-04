extends Node

signal new_server(ip: String, message: String)
var socket := PacketPeerUDP.new()
const lan_broadcast_port := 42355
var found_servers: Array[String] = []

const PORT = 4433


func check_packets() -> void:
	while socket.get_available_packet_count() > 0:
		var serverip := socket.get_packet_ip()
		var port := socket.get_packet_port()
		var bytes := socket.get_packet()
		var message := bytes.get_string_from_ascii()
		

		if serverip != '':
			if not serverip in found_servers:
				new_server.emit(serverip, message)
				found_servers.append(serverip)
				var i = $UI/VBoxContainer/LocalServerList.add_item(serverip,null,true) 
				#print("Added %d as %s" % [i,serverip] )



# Called when the node enters the scene tree for the first time.
func _ready():
	#TODO: Fix as this is null for some reason
	#$VBoxContainer/StartButton.grab_focus()

	var save = preload("save.gd").new()
	save.load_data()
	#set fullscreen optoin
	if save.fullscreen_on():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

		# Start paused
	#get_tree().paused = true
	# You can save bandwith by disabling server relay and peer notifications.
	multiplayer.server_relay = false

	# Automatically start the server in headless mode.
	if DisplayServer.get_name() == "headless":
		print("Automatically starting dedicated server")
		_on_host_button_pressed.call_deferred()
	else:	
		#look for local server broadcasts
		var bind_err := socket.bind(lan_broadcast_port)
		if bind_err == OK:
			var timer := Timer.new()
			timer.autostart = true
			add_child(timer)
			timer.timeout.connect(check_packets)
		else:
			push_warning("Couldn't bind lan broadcast listener")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

		


func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://main.tscn")


func _on_quit_button_pressed():
	get_tree().quit()


func _on_options_button_pressed():
	get_tree().change_scene_to_file("res://options.tscn")


func _on_host_button_pressed():
	if not global.hosting:
		global.hosting = true
			# Start as server
		var peer = ENetMultiplayerPeer.new()

		peer.create_server(PORT)
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
			OS.alert("Failed to start multiplayer server")
			return
		multiplayer.multiplayer_peer = peer
	start_game()
	#get_tree().change_scene_to_file("res://main.tscn")
	print(multiplayer.get_unique_id(),":_on_host_button_pressed")



func _on_connect_button_pressed():
	global.hosting = false
		# Start as client
	var txt : String = $UI/VBoxContainer/Remote.text
	if txt == "":
		OS.alert("Need a remote to connect to.")
		return
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(txt, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client")
		return
	multiplayer.multiplayer_peer = peer
	start_game()
	#get_tree().change_scene_to_file("res://main.tscn")
	print(multiplayer.get_unique_id(),":_on_connect_button_pressed")


func start_game():
	# Hide the UI and unpause to start the game.
	$UI.hide()
	get_tree().paused = false
	# Only change level on the server.
	# Clients will instantiate the level via the spawner.
	if multiplayer.is_server():
		change_level.call_deferred(load("res://main.tscn"))
		
		#send unicast


# Call this function deferred and only on the main authority (server).
func change_level(scene: PackedScene):
	# Remove old level if any.
	var level = $Level
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
	# Add new level.
	level.add_child(scene.instantiate())


func _on_local_server_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	$UI/VBoxContainer/Remote.text = $UI/VBoxContainer/LocalServerList.get_item_text(index)
	_on_connect_button_pressed()
