extends Control

@onready var save = preload("save.gd").new()


# Called when the node enters the scene tree for the first time.
func _ready():
	
	$VBoxContainer/FullscreenToggleButton.grab_focus()
	
	save.load_data()
	#set fullscreen optoin
	if save.fullscreen_on():
		$VBoxContainer/FullscreenToggleButton.set_pressed(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_fullscreen_toggle_button_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		save.set_fullscreen_on(false)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		save.set_fullscreen_on(true)


func _on_back_button_pressed():
	save.save_data()
	get_tree().change_scene_to_file("res://menu.tscn")
