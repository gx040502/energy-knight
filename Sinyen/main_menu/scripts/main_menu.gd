extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_start_pressed():
	get_tree().change_scene_to_file("res://Sinyen/levelSelection/scenes/levelSelection.tscn")



func _on_settings_pressed():
	get_tree().change_scene_to_file("res://Sinyen/options/scenes/options.tscn")


func _on_exit_pressed():
	get_tree().quit()
