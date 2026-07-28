extends Node2D
class_name EnemySpawner

var scout_scene = preload("res://ChiHong/enemies/scout.tscn")
var kb_scout_scene = preload("res://JunZhi/enemies/knockback_scout.tscn")

var spawned_enemies: Array = []
var barriers: Array = []
var has_spawned: bool = false
var room_node: Node2D = null

func _ready() -> void:
	room_node = get_parent()
	Events.room_entered.connect(_on_room_entered)

func _on_room_entered(room: Node2D) -> void:
	if room == room_node and not has_spawned:
		has_spawned = true
		spawn_wave()

func player_pos() -> Vector2:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		return player.global_position
	return Vector2.ZERO

func spawn_wave() -> void:
	lock_doors()
	
	# Spawn 1-3 random enemies
	var count = randi_range(1, 3)
	for i in range(count):
		# 70% Scout, 30% Knockback Scout
		var is_kb = randf() < 0.35
		var enemy_instance = (kb_scout_scene if is_kb else scout_scene).instantiate()
		
		# Pick a random spawn position within room inner bounds
		var spawn_x = randf_range(250, 900)
		var spawn_y = randf_range(200, 450)
		enemy_instance.position = Vector2(spawn_x, spawn_y)
		
		room_node.call_deferred("add_child", enemy_instance)
		spawned_enemies.append(enemy_instance)

func lock_doors() -> void:
	# Check active doors in room
	var doors = {
		"DoorUp": Vector2(576, 87),
		"DoorDown": Vector2(576, 564),
		"DoorLeft": Vector2(93, 324),
		"DoorRight": Vector2(1064, 324)
	}
	var door_sizes = {
		"DoorUp": Vector2(142, 120),
		"DoorDown": Vector2(142, 120),
		"DoorLeft": Vector2(120, 140),
		"DoorRight": Vector2(120, 140)
	}
	
	for door_name in doors.keys():
		var door_node = room_node.get_node_or_null(door_name)
		if is_instance_valid(door_node):
			# Spawn a barrier at the door position
			var barrier = create_barrier(doors[door_name], door_sizes[door_name])
			room_node.call_deferred("add_child", barrier)
			barriers.append(barrier)
			print("Barrier created for ", door_name)

func create_barrier(pos: Vector2, size: Vector2) -> StaticBody2D:
	var barrier = StaticBody2D.new()
	barrier.collision_layer = 2 # Wall/Obstacle layer
	barrier.position = pos
	
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	barrier.add_child(col)
	
	# Add a visual glowing red/orange shield
	var rect = ColorRect.new()
	rect.color = Color(0.9, 0.2, 0.2, 0.5) # Semitransparent red
	rect.size = size
	rect.position = -size / 2.0
	barrier.add_child(rect)
	
	return barrier

func _process(_delta: float) -> void:
	if not has_spawned:
		return
		
	# Clean up list of enemies
	var active_enemies = []
	for enemy in spawned_enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			active_enemies.append(enemy)
	spawned_enemies = active_enemies
	
	# If all enemies are dead, unlock the doors
	if spawned_enemies.size() == 0:
		unlock_doors()
		queue_free() # Remove the spawner

func unlock_doors() -> void:
	for barrier in barriers:
		if is_instance_valid(barrier):
			barrier.queue_free()
	barriers.clear()
