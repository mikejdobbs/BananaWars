extends Node

@export var mob_scene: PackedScene
@export var min_players = 3
@export var max_players = 8
var score

#broadcast server
var socket := PacketPeerUDP.new()
const lan_broadcast_port := 42355
@export var broadcast_message: String = "BananaWarsServer"

func broadcast() -> void:
	var packet := broadcast_message.to_ascii_buffer()
	socket.put_packet(packet)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	print(multiplayer.get_unique_id(),":_main_ready")

	randomize()
	$StartSound.play()
	
	
	# We only need to spawn players on the server.
	if not multiplayer.is_server():
		#show the ready message and play!
		$HUD.show_message("Get Ready") 
		return

	#server only
	#broadcast
	socket.set_broadcast_enabled(true)
	var err := socket.set_dest_address("255.255.255.255", lan_broadcast_port)
	assert(err == OK, "Couldn't set broadcasting")

	var timer := Timer.new()
	timer.autostart = true
	timer.wait_time = 1.5
	add_child(timer)
	timer.timeout.connect(broadcast)

	# Spawn already connected players
	for id in multiplayer.get_peers():
		add_player(id)

	# Spawn the local player unless this is a dedicated server export.
	if not OS.has_feature("dedicated_server"):
		add_player(1)
	new_game()


func game_over():
	$DeathSound.play()
	$DeathTimer.start()
	$HUD.show_message("Game Over")
	
func new_game():
	#TODO:DELETE $HUD.update_score(score)
	$HUD.show_message("Get Ready")
	#get_tree().call_group("mobs", "queue_free")
	$Music.play()
	$HUD.update_player_life(100)

	# Add computers to count up to max_players
	
	print($Players.get_child_count()," total players")
	while $Players.get_child_count() < min_players:
		add_player(0)

func _on_mob_hit(player,bullet):
	pass	

func _on_mob_killed():
	$MobDeathSound.play()


func _input(event):
	#process all keyboard events
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://menu.tscn")


func _on_death_timer_timeout():
	get_tree().change_scene_to_file("res://menu.tscn")

func physics_process(delta):
	pass

#called by signaql when a player is hit.  This only happens on the server as only the server has connections to this server. 
func _on_player_hit(player_id,life):
	_on_player_hit_rpc.rpc(player_id,life)
	
@rpc("authority", "call_local", "reliable", 0)
func _on_player_hit_rpc(player_id,life):
	#only the server can call this function
	#the following is run on all comptuers
	#print(multiplayer.get_unique_id(),":_on_player_hit")
	$PlayerHitSound.play()
	#print(multiplayer.get_unique_id(),":recived _on_player_hit")
	
	
	#update life on the player who got hit
	if player_id == multiplayer.get_unique_id():
		$HUD.update_player_life(life)
	#send rpc to udpate cliens

#func update_player_life(player_id) :

func _on_player_killed(player_id,killed_by):
	#add kill to killed_by
	var character = $Players.get_node(str(killed_by))
	character.kill_score += 1

	_on_player_killed_rpc.rpc(player_id,killed_by)

@rpc("authority", "call_local", "reliable", 0)
func _on_player_killed_rpc(player_id,killed_by):
	$DeathSound.play()
	
	if player_id == multiplayer.get_unique_id():
		var character = $Players.get_node(str(player_id))
		$HUD.show_message("You have died!")
		$HUD.update_death_score(character.death_score)

	if killed_by == multiplayer.get_unique_id():
		var killed_by_character = $Players.get_node(str(killed_by))
		$HUD.update_kill_score(killed_by_character.kill_score)
		##game_over()
		#$HUD.update_player_life(0)

func _on_player_respawned(player_id):
	if player_id == multiplayer.get_unique_id():
		$HUD.show_message("You are back!")
		$HUD.update_player_life(100)


	
	
func add_player(id: int):
	#re-assign computer nodes to negatives
	var is_computer = false
	if (id == 0):
		is_computer = true
		while $Players.has_node(str(id)):
			id += 1
	
	print("Adding Player ID:", id)
	
	var character = preload("res://player.tscn").instantiate()
	character.is_computer = is_computer
	#mob.hit.connect(_on_mob_hit)
	character.hit.connect(_on_player_hit)
	character.killed.connect(_on_player_killed)
	character.respawned.connect(_on_player_respawned)
	
	# Set player id.
	character.player = id
	character.name = str(id)
	character.random_location()
	$Players.add_child(character, true)


func del_player(id: int):
	if not $Players.has_node(str(id)):
		return
	$Players.get_node(str(id)).queue_free()

func add_banana(banana):
	$Bananas.add_child(banana, false)
	
