extends Area2D

@export var explosion_damage: float = 25.0
@export var fuse_time: float = 0.2
@export var explosion_radius: float = 80.0

var is_triggered: bool = false
var is_exploding: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var trigger_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if sprite:
		sprite.play("idle")
	collision_mask = 0xFFFFFFFF

func _on_body_entered(body: Node2D) -> void:
	if is_triggered or is_exploding:
		return
		
	if body.is_in_group("player"):
		start_fuse()

func start_fuse() -> void:
	is_triggered = true
	
	if trigger_shape:
		trigger_shape.set_deferred("disabled", true)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(2, 0.5, 0.5, 1), fuse_time)
	
	# Use a clean await timeout instead of a lambda connection
	await get_tree().create_timer(fuse_time).timeout
	if not is_exploding:
		explode()

func explode() -> void:
	if is_exploding:
		return
	is_exploding = true

	# Deal damage via physics space query
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	var shape = CircleShape2D.new()
	shape.radius = explosion_radius
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 0xFFFFFFFF
	
	for result in space_state.intersect_shape(query):
		var collider = result.collider
		if collider and collider.has_method("take_damage"):
			var dir = (collider.global_position - global_position).normalized()
			if dir == Vector2.ZERO:
				dir = Vector2.UP
			collider.take_damage(explosion_damage, dir * 400.0)

	# Play explosion animation safely
	if sprite:
		sprite.play("explosion")
		await sprite.animation_finished

	queue_free()
