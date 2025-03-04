extends Node

const SAVEFILE = "user://options.save"

var game_data = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	load_data()
	
func load_data():
	if not FileAccess.file_exists(SAVEFILE):
		game_data = {
			'fullscreen_on':false
		}
		save_data()
	else:
		var file = FileAccess.open(SAVEFILE,FileAccess.READ)
		game_data = file.get_var()

func fullscreen_on():
	return game_data['fullscreen_on']
	
func set_fullscreen_on(value):
	game_data['fullscreen_on'] = value
	
func save_data():
	var file = FileAccess.open(SAVEFILE,FileAccess.WRITE)
	file.store_var(game_data)
