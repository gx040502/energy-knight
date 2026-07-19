extends Node2D
@export var _dimensions : Vector2i = Vector2i(7,5)
@export var _start : Vector2i = Vector2i(-1,0)
@export var _critical_path_length : int =2
@export var _branches : int =3
@export var _branch_length : Vector2i = Vector2i(1,4)
@export var room_scenes : Array[PackedScene]
@export var room_spacing : Vector2 = Vector2(1152, 648) # Change this to your exact room size in pixels!
@onready var player: CharacterBody2D = $Player

var dungeon :Array
var _branch_candidates : Array[Vector2i]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_initialize_dungeon()
	_place_entrance()
	_generate_critical_path(_start, _critical_path_length, "C")
	_generate_branches()
	_print_dungeon()
	_spawn_rooms()

func _initialize_dungeon() -> void:
	for x in _dimensions.x:
		dungeon.append([])
		for y in _dimensions.y:
			dungeon[x].append(0)

func _print_dungeon() -> void:
	var dungeon_as_string : String = ""
	# Changed this loop to count forward from 0 so it matches Godot's screen!
	for y in _dimensions.y: 
		for x in _dimensions.x:
			if dungeon[x][y]:
				dungeon_as_string += "[" + str(dungeon[x][y]) + "]"
			else:
				dungeon_as_string += "   "
		dungeon_as_string += '\n'
	print(dungeon_as_string)
	
func _place_entrance() -> void:
	if _start.x <0 or _start.x >= _dimensions.x:
		_start.x = randi_range(0, _dimensions.x -1)
	if _start.y <0 or _start.y >= _dimensions.y:
		_start.y = randi_range(0, _dimensions.y -1)
	dungeon[_start.x][_start.y] = "S"
	pass
	
func _generate_critical_path(from : Vector2i, length :int, marker:String) -> bool:
	if length ==0:
		return true
	var current :Vector2i = from
	var direction :Vector2i
	match randi_range(0,3):
		0:
			direction = Vector2i.UP
		1:
			direction = Vector2i.RIGHT
		2: 
			direction = Vector2i.DOWN
		3: 
			direction = Vector2i.LEFT
	for i in 4:
		if (current.x + direction.x >=0 and current.x + direction.x < _dimensions.x and
		current.y + direction.y >=0 and current.y + direction.y < _dimensions.y and 
		not dungeon[current.x + direction.x][current.y+direction.y]):
			current += direction
			dungeon [current.x][current.y]= marker
			if length >1:
				_branch_candidates.append(current)
			if _generate_critical_path(current, length -1, marker):
				return true
			else:
				_branch_candidates.erase(current)
				dungeon[current.x][current.y]=0
				current -= direction
		direction = Vector2(direction.y, -direction.x)
	return false

func _generate_branches()-> void:
	var branches_created: int =0
	var candidate: Vector2i
	while branches_created < _branches and _branch_candidates.size():
		candidate = _branch_candidates[randi_range(0, _branch_candidates.size() -1)]
		if _generate_critical_path(candidate, randi_range(_branch_length.x, _branch_length.y), str(branches_created+1)):
			branches_created +=1
		else:
			_branch_candidates.erase(candidate)
			
func _spawn_rooms() -> void:
	for x in _dimensions.x:
		for y in _dimensions.y:
			
			var room_type = str(dungeon[x][y]) # Store the letter/number for easy checking
			
			if room_type != "0":
				var random_scene = room_scenes.pick_random()
				var room_instance = random_scene.instantiate()
				var pixel_position = Vector2(x * room_spacing.x, y * room_spacing.y)
				room_instance.position = pixel_position
				
				# --- NEW CODE: Check the Grid Neighbors ---
				# We use "and" to make sure we don't look outside the edges of the array and crash the game!
				var has_left = (x > 0) and str(dungeon[x-1][y]) != "0"
				var has_right = (x < _dimensions.x - 1) and str(dungeon[x+1][y]) != "0"
				var has_up = (y > 0) and str(dungeon[x][y-1]) != "0" 
				var has_down = (y < _dimensions.y - 1) and str(dungeon[x][y+1]) != "0"
				
				# Send the findings directly to the room we just created
				room_instance.setup_doors(has_up, has_down, has_left, has_right)
				
				# ------------------------------------------
				
				# Spawn enemies in non-starting rooms
				if room_type != "S":
					var spawner_script = load("res://JunZhi/spawner/enemy_spawner.gd")
					var spawner_node = Node2D.new()
					spawner_node.set_script(spawner_script)
					room_instance.add_child(spawner_node)
				
				add_child(room_instance)
				
				if room_type == "S":
					player.global_position = pixel_position + (room_spacing / 2.0)
					Events.room_entered.emit(room_instance)
					move_child(player, get_child_count() - 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
