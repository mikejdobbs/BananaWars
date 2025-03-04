extends CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()

func update_player_life(life):
	$HPBar.set_value_no_signal(life)
	
func show_game_over():
	show_message("Game Over")
	
func update_kill_score(score):
	$KillScore.text = str(score)
	
func update_death_score(score):
	$DeathScore.text = str(score)


func _on_message_timer_timeout():
	$Message.hide()
