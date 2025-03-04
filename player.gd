extends CharacterBody2D
signal hit(player_id,life)
signal killed(player_id, killed_by_id)
signal respawned(player_id)

@export var speed = 400 # How fast the player will move (pixels/sec).
@export var banana_turrent_speed = 2 # How fast the turrent will move (pixels/sec).
@export var Banana_scene: PackedScene
@export var banana_distance_from_point = 8000
@export var life = 100
@export var kill_score = 0
@export var death_score = 0
@export var SPAWN_RANDOM = 800.0

var is_computer = false

var banana_rotation_around_point = 0
var ready_to_fire = true
var ready_to_think = true

const  rotate_range = deg_to_rad(360)

var screen_size # Size of the game window.

# Set by the authority, synchronized on spawn.
@export var player := 1 :
	set(id):
		#ignore id of 0 or less, this is computer controlled
		if id >= 0:
			player = id
			# Give authority over the player input to the appropriate peer.
			$PlayerInput.set_multiplayer_authority(id)

# Player synchronized input.
@onready var input = $PlayerInput

# Called when the node enters the scene tree for the first time.
func _ready():
	print(multiplayer.get_unique_id(),":_player_ready")
	
	screen_size = get_viewport_rect().size
	
	if player == multiplayer.get_unique_id():
		$Camera2D.enabled = true
	else:
		$Camera2D.enabled = false

	start()

func shoot():
	# We only need to spawn players on the server.
	if  multiplayer.is_server():
		if (life > 0) and ready_to_fire:
			var b = Banana_scene.instantiate()
			b.player = player
			b.transform = $BananaTurrentShape2D.global_transform
			var bananas = get_node("/root/Menu/Level/main/Bananas")
			bananas.add_child(b,true)
			ready_to_fire = false

func random_location():
	# Randomize character position.
	var pos := Vector2.from_angle(randf() * 2 * PI)
	position = Vector2(clamp(pos.x * SPAWN_RANDOM * randf(),10,2000), clamp(pos.y * SPAWN_RANDOM * randf(),10,2000) )
	print("Position:",position)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
func _physics_process(delta):

	if  multiplayer.is_server() and is_computer:
		ai_process(delta)
	
	$AnimatedSprite2D.pause()
	
	if (life > 0): #the dead don't move
		velocity = input.direction.normalized() * speed
		if velocity.length() > 0:
			$AnimatedSprite2D.play("default")

		var collision_info = move_and_collide(velocity * delta)

		#if collision_info:
			##move away until the colision is over
			#velocity =   10 * collision_info.get_normal()
			#move_and_collide(velocity * delta)

		#move_and_slide()
		#for i in get_slide_collision_count():
			#var collision = get_slide_collision(i)
	
	
		#move turent
		if  input.rotatingcc:
			banana_rotation_around_point += -banana_turrent_speed * delta		
			$BananaTurrentShape2D.global_position = global_position
			$BananaTurrentShape2D.global_position += Vector2(cos(banana_rotation_around_point), sin(banana_rotation_around_point)) * banana_distance_from_point
			
			#aim cannon away
			$BananaTurrentShape2D.rotate( $BananaTurrentShape2D.get_angle_to(global_position) + 3.14)
			input.rotatingcc = false

		if input.rotatingc:
			banana_rotation_around_point += banana_turrent_speed * delta
			$BananaTurrentShape2D.global_position = global_position
			$BananaTurrentShape2D.global_position += Vector2(cos(banana_rotation_around_point), sin(banana_rotation_around_point)) * banana_distance_from_point

			#aim cannon away
			$BananaTurrentShape2D.rotate( $BananaTurrentShape2D.get_angle_to(global_position) + 3.14)
			input.rotatingc = false
		
		
		if input.firing:
			shoot()
			input.firing = false


func start():
	$CollisionShape2D.disabled = false
	life = 100
	show()

#func _on_area_2d_area_entered(area):
		#for group in area.get_groups():
			#print(group)

func _on_area_2d_area_shape_entered(area_rid, area, area_shape_index, local_shape_index):
	#print(multiplayer.get_unique_id(),":_on_area_2d_area_shape_entered")
	if life > 0: #my own banana doesn't hurt me and bullets don't hurt the dead
		var bodies = $PlayerArea2D.get_overlapping_areas()
		
		for body in bodies:
			if body.is_in_group("bullet") and (body.player != player):
				hit.emit(self.player,life)
				life -= body.damage
				$HPBar.set_value_no_signal(life)
			
				if life < 1:
					killed.emit(self.player,body.player)
					life = 0
					$AnimatedSprite2D.play("dead")
					$RespawnTimer.start()
					#TODO add death scene


func _on_reload_timer_timeout():
	ready_to_fire = true

func _on_respawn_timer_timeout():
	#print(multiplayer.get_unique_id(),":_on_respawn_timer_timeout")
	life = 100
	death_score += 1
	$HPBar.set_value_no_signal(life)
	random_location()
	$AnimatedSprite2D.set_animation("default")
	respawned.emit(self.player)


#COMPUTER AI
#func aimAngle(target, bulletSpeed) {
	#var rCrossV = target.x * target.vy - target.y * target.vx;
	#var magR = Math.sqrt(target.x*target.x + target.y*target.y);
	#var angleAdjust = Math.asin(rCrossV / (bulletSpeed * magR));
#
	#return angleAdjust + Math.atan2(target.y, target.x);
#}

func ai_process(delta):
	#https://www.reddit.com/r/gamedev/comments/16ceki/comment/c7vbu2j/
	
	if ready_to_think:
		ready_to_think = false
		
		#get nearest player
		var targetted_players = get_tree().get_nodes_in_group("players")
		var targetted_player = targetted_players[0]
		var targetted_player_distance = abs(global_position -  targetted_player.global_position)
		for x in targetted_players:
			if x.life == 0:
				#print("Skipping ",x.player," as they done dead")
				continue #don't target the dead
				
			var x_targetted_player_distance = abs(global_position -  x.global_position)
			if  (x != self) and (x_targetted_player_distance < targetted_player_distance):
				targetted_player = x
				targetted_player_distance = x_targetted_player_distance
			
		
		input.direction = (targetted_player.position - position).normalized()
		
		#move turrent
		#calculate angle need to shoot
		#var rotation_current = fmod($BananaTurrentShape2D.rotation_degrees, 2 * PI)
		var rotation_current = $BananaTurrentShape2D.global_rotation
		#var rotation_needed = atan2((global_position.x - targetted_player.global_position.x),(global_position.y - targetted_player.global_position.y) )
		var rotation_needed = get_angle_to(targetted_player.global_position)

		#print( "global_position", global_position," targeted_player.global_position", targetted_player.global_position,"rotation_needed:", rotation_needed," rotation_current:",rotation_current)

		if abs(rotation_needed - rotation_current) < PI/32:
			#print ("Lockon!")
			input.firing = true
		else:
			if rotation_needed > rotation_current:
				input.rotatingc = true
				input.rotatingcc = false
			else:
				input.rotatingcc = true
				input.rotatingc = false
		

func _on_think_timer_timeout():
	ready_to_think = true
