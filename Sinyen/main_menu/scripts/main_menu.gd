extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicManager.play_track(MusicManager.MENU_TRACK)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_start_pressed():
	get_tree().change_scene_to_file("res://Sinyen/levelSelection/scenes/levelSelection.tscn")



func _on_settings_pressed() -> void:
	var packed: PackedScene = load("res://Sinyen/options/scenes/options.tscn") as PackedScene
	if packed == null:
		push_error("MainMenu: failed to load options scene")
		return

	var options: Control = packed.instantiate() as Control
	options.closed.connect(func() -> void: options.queue_free())
	add_child(options)


func _on_exit_pressed():
	get_tree().quit()
