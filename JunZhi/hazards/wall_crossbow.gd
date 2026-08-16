extends Node2D
class_name WallCrossbow

# --- WALL-MOUNTED CROSSBOW (Milestone 2 - Khor Jun Zhi) ---
# Place this node in a room scene, set the `direction` export, and it will
# fire a CrossbowBolt every `fire_interval` seconds.
# Bolt damage and speed are also configurable via the inspector.

@export var fire_interval: float = 2.5
@export var direction: Vector2 = Vector2.RIGHT   # Must be a cardinal or diagonal direction
@export var bolt_speed: float = 400.0
@export var bolt_damage: float = 15.0
@export var bolt_lifetime: float = 2.0           # Auto-destroy distance limit

var bolt_scene: PackedScene = preload("res://JunZhi/hazards/crossbow_bolt.tscn")

@onready var fire_timer: Timer = $FireTimer


func _ready() -> void:
	fire_timer.wait_time = fire_interval
	fire_timer.timeout.connect(_fire_bolt)
	fire_timer.start()
	# Rotate the crossbow visual so it always points in the fire direction
	rotation = direction.angle()


func _fire_bolt() -> void:
	var bolt: CrossbowBolt = bolt_scene.instantiate() as CrossbowBolt
	bolt.bolt_direction = direction.normalized()
	bolt.bolt_speed = bolt_speed
	bolt.bolt_damage = bolt_damage

	# Add to the scene tree FIRST so global_position has a valid parent
	# transform. Setting it before add_child makes Godot store the
	# world-space value as a local position, putting the bolt off-screen.
	get_parent().add_child(bolt)
	bolt.global_position = global_position + direction.normalized() * 60.0

	# Auto-destroy bolt after lifetime (acts as a range limiter)
	var life_timer := get_tree().create_timer(bolt_lifetime)
	life_timer.timeout.connect(func() -> void:
		if is_instance_valid(bolt):
			bolt.queue_free()
	)
