extends Node2D

func _on_player_detector_body_entered(body: Node2D) -> void:
	Events.room_entered.emit(self)
	
func setup_doors(has_up: bool, has_down: bool, has_left: bool, has_right: bool) -> void:
	# --- UP ---
	if has_up:
		$WallUp.queue_free()   # Path exists! Destroy the wall block.
	else:
		$DoorUp.queue_free()   # Dead end! Destroy the teleporter.
		
	# --- DOWN ---
	if has_down:
		$WallDown.queue_free()
	else:
		$DoorDown.queue_free()
		
	# --- LEFT ---
	if has_left:
		$WallLeft.queue_free()
	else:
		$DoorLeft.queue_free()
		
	# --- RIGHT ---
	if has_right:
		$WallRight.queue_free()
	else:
		$DoorRight.queue_free()
