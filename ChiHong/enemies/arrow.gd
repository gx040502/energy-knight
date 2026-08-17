extends Area2D

@export var speed: float = 400.0
@export var damage: float = 1.0

var direction: Vector2 = Vector2.ZERO
var shooter: Node2D = null # Holds reference to who fired it

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Auto-destroy the arrow after 5 seconds if it misses everything
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	# Ignore the specific shooter, any enemy, or self so it doesn't destroy itself on spawn!
	if body == shooter or body.is_in_group("enemy") or body == self:
		return

	# If it hits the player
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			var knockback_dir = direction.normalized()
			body.take_damage(damage, knockback_dir * 150.0)
		queue_free()
		
	else:
		# If it hits a wall or obstacle, destroy it
		queue_free()
