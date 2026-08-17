extends Node2D
class_name EnemySpawnerLevel4

# LEVEL 4 ENEMY SPAWNER
# Designed for Level 4 with higher difficulty and boss / elite enemy support.

var scout_scene = preload("res://ChiHong/enemies/scout.tscn")
var kb_scout_scene = preload("res://JunZhi/enemies/knockback_scout.tscn")
var mage_scene = preload("res://JunZhi/enemies/mage.tscn")
var archer_scene = preload("res://ChiHong/enemies/archer.tscn")
var monarch_scene = preload("res://JunZhi/enemies/monarch.tscn")

@export var is_boss_room: bool = false
@export var min_enemies: int = 2
@export var max_enemies: int = 4

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
		print("[EnemySpawnerLevel4] Player entered room: ", room_node.name, " | is_boss_room: ", is_boss_room)
		spawn_wave()

func player_pos() -> Vector2:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		return player.global_position
	return Vector2.ZERO

func spawn_wave() -> void:
	lock_doors()
	
	if is_boss_room:
		_spawn_boss_encounter()
	else:
		_spawn_standard_wave()

func _spawn_standard_wave() -> void:
	# Level 4 standard wave: 2-4 tougher enemies
	var count = randi_range(min_enemies, max_enemies)
	for i in range(count):
		# Level 4 weighted probability:
		# 20% Scout, 30% Knockback Scout, 25% Mage, 25% Archer
		var roll = randf()
		var enemy_scene
		
		if roll < 0.20:
			enemy_scene = scout_scene
		elif roll < 0.50:
			enemy_scene = kb_scout_scene
		elif roll < 0.75:
			enemy_scene = mage_scene
		else:
			enemy_scene = archer_scene
			
		var enemy_instance = enemy_scene.instantiate()
		
		# Spawn position within room bounds
		var spawn_x = randf_range(250, 900)
		var spawn_y = randf_range(200, 450)
		enemy_instance.position = Vector2(spawn_x, spawn_y)
		
		room_node.call_deferred("add_child", enemy_instance)
		spawned_enemies.append(enemy_instance)

func _spawn_boss_encounter() -> void:
	# Boss room spawns the Monarch Boss in the center
	var boss_instance = monarch_scene.instantiate()
	boss_instance.position = Vector2(576, 324)
	room_node.call_deferred("add_child", boss_instance)
	spawned_enemies.append(boss_instance)

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
