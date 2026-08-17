extends Node2D
class_name HazardSpawner

# --- HAZARD SPAWNER ---
var crossbow_scene: PackedScene = preload("res://JunZhi/hazards/wall_crossbow.tscn")
var spike_scene: PackedScene = preload("res://ChiHong/trap/SpikeTrap.tscn")       # Update with your actual path
var bomb_scene: PackedScene = preload("res://ChiHong/trap/ProximityBomb.tscn") # Update with your actual path

@export var spawn_chance: float = 0.75    # Probability hazards appear
@export var max_crossbows: int = 2        # Max wall crossbows
@export var max_floor_hazards: int = 3    # Max floor traps/bombs (spike traps or bombs)

var has_spawned: bool = false
var room_node: Node2D = null

# Wall slot positions (same as before)
const WALL_SLOTS: Array = [
	{ "pos_min": Vector2(220, 130), "pos_max": Vector2(470, 130), "dir": Vector2( 0,  1) },
	{ "pos_min": Vector2(680, 130), "pos_max": Vector2(940, 130), "dir": Vector2( 0,  1) },
	{ "pos_min": Vector2(220, 540), "pos_max": Vector2(470, 540), "dir": Vector2( 0, -1) },
	{ "pos_min": Vector2(680, 540), "pos_max": Vector2(940, 540), "dir": Vector2( 0, -1) },
]

func _ready() -> void:
	room_node = get_parent()
	Events.room_entered.connect(_on_room_entered)

func _on_room_entered(room: Node2D) -> void:
	if room == room_node and not has_spawned:
		has_spawned = true
		if randf() < spawn_chance:
			spawn_hazards()

func spawn_hazards() -> void:
	# 1. Spawn Wall Crossbows
	var slots: Array = WALL_SLOTS.duplicate()
	slots.shuffle()
	var crossbow_count: int = randi_range(1, max_crossbows)
	crossbow_count = mini(crossbow_count, slots.size())

	for i in range(crossbow_count):
		var slot: Dictionary = slots[i]
		var local_pos := Vector2(
			randf_range(slot["pos_min"].x, slot["pos_max"].x),
			randf_range(slot["pos_min"].y, slot["pos_max"].y)
		)
		var crossbow: WallCrossbow = crossbow_scene.instantiate() as WallCrossbow
		crossbow.direction = slot["dir"]
		crossbow.position = local_pos
		room_node.call_deferred("add_child", crossbow)

	# 2. Randomly Spawn Floor Hazards (Spike Traps or Proximity Bombs)
	var floor_hazard_count: int = randi_range(1, max_floor_hazards)
	for i in range(floor_hazard_count):
		var hazard_scene = spike_scene if randf() < 0.5 else bomb_scene
		var hazard_instance = hazard_scene.instantiate()
		
		# Pick a random safe floor position inside the room bounds (avoiding center/doors)
		var floor_pos := Vector2(
			randf_range(280, 880),
			randf_range(220, 480)
		)
		
		hazard_instance.position = floor_pos
		room_node.call_deferred("add_child", hazard_instance)
