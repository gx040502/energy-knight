extends Node2D

# --- Grid Configuration ---
@export var _dimensions: Vector2i = Vector2i(7, 5)
@export var _start: Vector2i = Vector2i(-1, 0)
@export var _critical_path_length: int = 2
@export var _branches: int = 3
@export var _branch_length: Vector2i = Vector2i(1, 4)

# --- Scene Configuration ---
@export var room_scenes: Array[PackedScene]
@export var boss_room_scene: PackedScene # Optional. Falls back to a random room if null.
@export var room_spacing: Vector2 = Vector2(1152, 648) # Must match your room size in pixels.

@onready var player: CharacterBody2D = $Player
@onready var minimap: Control = $MinimapLayer/Minimap

const SPAWNER_SCRIPT_PATH: String = "res://JunZhi/spawner/enemy_spawner.gd"
const HAZARD_SCRIPT_PATH: String = "res://JunZhi/spawner/hazard_spawner.gd"
const BOSS_SCRIPT_PATH: String = "res://JunZhi/spawner/enemy_spawner_level4.gd"

var dungeon: Array = []
var _branch_candidates: Array[Vector2i] = []
var _critical_path_end: Vector2i = Vector2i(-1, -1)
var _room_cells: Dictionary = {}


func _ready() -> void:
	if room_scenes.is_empty():
		push_error("Level 4: 'room_scenes' is empty. Assign at least one room scene in the Inspector.")
		return

	_initialize_dungeon()
	_place_entrance()
	_generate_critical_path(_start, _critical_path_length, "C")
	_generate_branches()
	_place_boss_room()
	_print_dungeon()

	# Feed the finished grid to the minimap, then connect BEFORE spawning:
	# _spawn_rooms() emits Events.room_entered for the starting room, so the
	# highlight lands on the spawn cell with no special-case code.
	minimap.setup(dungeon, _dimensions)
	Events.room_entered.connect(_on_room_entered)

	_spawn_rooms()
	MusicManager.play_track(MusicManager.LEVEL_TRACK)


func _initialize_dungeon() -> void:
	dungeon.clear()
	for x: int in _dimensions.x:
		dungeon.append([])
		for y: int in _dimensions.y:
			dungeon[x].append(0)


func _print_dungeon() -> void:
	var dungeon_as_string: String = ""
	# Counts forward from 0 so the printout matches Godot's screen orientation.
	for y: int in _dimensions.y:
		for x: int in _dimensions.x:
			if dungeon[x][y]:
				dungeon_as_string += "[" + str(dungeon[x][y]) + "]"
			else:
				dungeon_as_string += "   "
		dungeon_as_string += "\n"
	print(dungeon_as_string)


func _place_entrance() -> void:
	if _start.x < 0 or _start.x >= _dimensions.x:
		_start.x = randi_range(0, _dimensions.x - 1)
	if _start.y < 0 or _start.y >= _dimensions.y:
		_start.y = randi_range(0, _dimensions.y - 1)
	dungeon[_start.x][_start.y] = "S"


func _generate_critical_path(from: Vector2i, length: int, marker: String) -> bool:
	if length == 0:
		return true

	var current: Vector2i = from
	var direction: Vector2i

	match randi_range(0, 3):
		0:
			direction = Vector2i.UP
		1:
			direction = Vector2i.RIGHT
		2:
			direction = Vector2i.DOWN
		3:
			direction = Vector2i.LEFT

	for _i: int in 4:
		if (current.x + direction.x >= 0 and current.x + direction.x < _dimensions.x
		and current.y + direction.y >= 0 and current.y + direction.y < _dimensions.y
		and not dungeon[current.x + direction.x][current.y + direction.y]):
			current += direction
			dungeon[current.x][current.y] = marker

			# The deepest cell of the main path is our boss location.
			# length == 1 means the next recursive call terminates immediately,
			# so this cell can never be backtracked or branched from.
			if marker == "C" and length == 1:
				_critical_path_end = current

			if length > 1:
				_branch_candidates.append(current)

			if _generate_critical_path(current, length - 1, marker):
				return true
			else:
				_branch_candidates.erase(current)
				dungeon[current.x][current.y] = 0
				current -= direction

		direction = Vector2i(direction.y, -direction.x)

	return false


func _generate_branches() -> void:
	var branches_created: int = 0
	var candidate: Vector2i

	while branches_created < _branches and _branch_candidates.size():
		candidate = _branch_candidates[randi_range(0, _branch_candidates.size() - 1)]
		if _generate_critical_path(candidate, randi_range(_branch_length.x, _branch_length.y), str(branches_created + 1)):
			branches_created += 1
		else:
			_branch_candidates.erase(candidate)


# --- BOSS ROOM PLACEMENT ---
# Runs once, after the layout is finalized, so exactly one cell is ever stamped "B".
func _place_boss_room() -> void:
	var boss_cell: Vector2i = _critical_path_end

	# Fallback if the critical path never completed (or _critical_path_length is 0).
	if boss_cell.x < 0 or not dungeon[boss_cell.x][boss_cell.y]:
		boss_cell = _find_furthest_room()

	if boss_cell.x < 0:
		push_warning("Boss room could not be placed: no valid cell found.")
		return

	dungeon[boss_cell.x][boss_cell.y] = "B"


func _find_furthest_room() -> Vector2i:
	var best_cell: Vector2i = Vector2i(-1, -1)
	var best_distance: int = -1

	for x: int in _dimensions.x:
		for y: int in _dimensions.y:
			var cell: Variant = dungeon[x][y]
			if not cell or str(cell) == "S":
				continue
			var distance: int = abs(x - _start.x) + abs(y - _start.y)
			if distance > best_distance:
				best_distance = distance
				best_cell = Vector2i(x, y)

	return best_cell


func _spawn_rooms() -> void:
	for x: int in _dimensions.x:
		for y: int in _dimensions.y:
			var room_type: String = str(dungeon[x][y])
			if room_type == "0":
				continue

			var scene_to_spawn: PackedScene = room_scenes.pick_random()
			if room_type == "B" and boss_room_scene != null:
				scene_to_spawn = boss_room_scene

			if scene_to_spawn == null:
				push_warning("Null room scene at cell (%d, %d) — skipping." % [x, y])
				continue

			var room_instance: Node2D = scene_to_spawn.instantiate()
			var pixel_position: Vector2 = Vector2(x * room_spacing.x, y * room_spacing.y)
			room_instance.position = pixel_position

			# Remember which grid cell this room came from so the minimap can
			# translate an Events.room_entered signal back into a coordinate.
			_room_cells[room_instance] = Vector2i(x, y)

			# Check grid neighbours so the room knows which walls to open.
			# The bounds checks keep us from reading outside the array.
			var has_left: bool = (x > 0) and str(dungeon[x - 1][y]) != "0"
			var has_right: bool = (x < _dimensions.x - 1) and str(dungeon[x + 1][y]) != "0"
			var has_up: bool = (y > 0) and str(dungeon[x][y - 1]) != "0"
			var has_down: bool = (y < _dimensions.y - 1) and str(dungeon[x][y + 1]) != "0"

			room_instance.setup_doors(has_up, has_down, has_left, has_right)

			# Start and boss rooms are excluded from the standard trash wave.
			if room_type == "B":
				var boss_spawner: Node2D = _attach_module(room_instance, BOSS_SCRIPT_PATH)
				if boss_spawner != null:
					boss_spawner.is_boss_room = true
			elif room_type != "S":
				_attach_module(room_instance, SPAWNER_SCRIPT_PATH)
				_attach_module(room_instance, HAZARD_SCRIPT_PATH)

			add_child(room_instance)

			if room_type == "S":
				player.global_position = pixel_position + (room_spacing / 2.0)
				Events.room_entered.emit(room_instance)
				move_child(player, get_child_count() - 1)


func _attach_module(room_instance: Node2D, script_path: String) -> Node2D:
	var module_script: Script = load(script_path)
	if module_script == null:
		push_warning("Could not load module script: " + script_path)
		return null

	var module_node: Node2D = Node2D.new()
	module_node.set_script(module_script)
	room_instance.add_child(module_node)
	return module_node


func _on_room_entered(room: Node2D) -> void:
	if _room_cells.has(room):
		minimap.set_current_cell(_room_cells[room])
