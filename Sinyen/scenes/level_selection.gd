extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	


func _on_level_1_button_pressed():
	get_tree().change_scene_to_file("res://GyapXun/levels/scenes/level1.tscn")



func _on_level_2_button_pressed():
	get_tree().change_scene_to_file("res://Sinyen/scenes/level_1.tscn")
	


func _on_level_3_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Sinyen/scenes/level_1.tscn")



func _on_level_4_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Sinyen/scenes/level_1.tscn")



func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Sinyen/main_menu.tscn")
