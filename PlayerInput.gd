extends MultiplayerSynchronizer

# Set via RPC to simulate is_action_just_pressed.
@export var firing := false
@export var rotatingcc := false
@export var rotatingc := false

# Synchronized property.
@export var direction := Vector2()

# Called when the node enters the scene tree for the first time.
func _ready():
	# Only process for the local player
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())


@rpc("call_local")
func fire():
	firing = true

@rpc("call_local")
func rotatecc():
	rotatingcc = true

@rpc("call_local")
func rotatec():
	rotatingc = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	direction = Input.get_vector("player1_left", "player1_right", "player1_up", "player1_down")
	
	if Input.is_action_pressed("player1_rotatecc"):
		rotatecc.rpc()

	if Input.is_action_pressed("player1_rotatec"):
		rotatec.rpc()
	
	if Input.is_action_just_pressed("player1_shoot"):
		fire.rpc()
