extends Node2D
class_name HazardSpawner

# --- HAZARD SPAWNER (Milestone 2 - Khor Jun Zhi) ---
# Works like EnemySpawner: add this node as a child of a room scene.
# When the player enters the room, it randomly mounts WallCrossbows on
# 1-2 walls. Each wall has a fixed mount strip derived from dungeon_room.tscn.
#
# Usage: instance hazard_spawner.tscn into a room, done.

var crossbow_scene: PackedScene = preload("res://JunZhi/hazards/wall_crossbow.tscn")

@export var spawn_chance: float = 0.65   # Probability crossbows appear at all
@export var max_crossbows: int = 2       # Max walls that get a crossbow (1..max)

var has_spawned: bool = false
var room_node: Node2D = null

# ---------------------------------------------------------------------------
# WALL SLOT TABLE  (positions in the room's LOCAL coordinate space)
#
# Only top and bottom walls are used:
#   • DoorUp   is centred at x ≈ 577, gap ≈ 142 px wide  → avoid x 490–660
#   • DoorDown is centred at x ≈ 584, gap ≈ 141 px wide  → avoid x 490–660
# Vertical (left/right) walls are skipped – the door gap takes up most of
# the available strip height and would cause crossbows to block passages.
# ---------------------------------------------------------------------------
const WALL_SLOTS: Array = [
	# Top wall – fire downward, LEFT of door gap
	{ "pos_min": Vector2(220, 130), "pos_max": Vector2(470, 130), "dir": Vector2( 0,  1) },
	# Top wall – fire downward, RIGHT of door gap
	{ "pos_min": Vector2(680, 130), "pos_max": Vector2(940, 130), "dir": Vector2( 0,  1) },
	# Bottom wall – fire upward, LEFT of door gap
	{ "pos_min": Vector2(220, 540), "pos_max": Vector2(470, 540), "dir": Vector2( 0, -1) },
	# Bottom wall – fire upward, RIGHT of door gap
	{ "pos_min": Vector2(680, 540), "pos_max": Vector2(940, 540), "dir": Vector2( 0, -1) },
]


func _ready() -> void:
	room_node = get_parent()
	Events.room_entered.connect(_on_room_entered)


func _on_room_entered(room: Node2D) -> void:
	if room == room_node and not has_spawned:
		has_spawned = true
		if randf() < spawn_chance:
			spawn_crossbows()


func spawn_crossbows() -> void:
	# Shuffle the slot list so we never pick the same walls every time
	var slots: Array = WALL_SLOTS.duplicate()
	slots.shuffle()

	var count: int = randi_range(1, max_crossbows)
	count = mini(count, slots.size())

	for i in range(count):
		var slot: Dictionary = slots[i]
		# Random position between pos_min and pos_max
		var local_pos := Vector2(
			randf_range(slot["pos_min"].x, slot["pos_max"].x),
			randf_range(slot["pos_min"].y, slot["pos_max"].y)
		)
		var crossbow: WallCrossbow = crossbow_scene.instantiate() as WallCrossbow
		crossbow.direction = slot["dir"]
		crossbow.position = local_pos   # Local to room_node
		room_node.call_deferred("add_child", crossbow)
