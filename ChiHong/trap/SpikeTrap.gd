extends Area2D

@export var damage: float = 10.0
@export var damage_cooldown: float = 1.0 # Time between damage ticks if standing on it

var can_deal_damage: bool = true
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D # Optional if you have animations

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and can_deal_damage:
		apply_damage(body)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Reset or stop ticking if needed
		pass

func apply_damage(target: Node2D) -> void:
	if target.has_method("take_damage"):
		var knockback_dir = (target.global_position - global_position).normalized()
		target.take_damage(damage, knockback_dir * 100.0)
		
	can_deal_damage = false
	if animated_sprite:
		animated_sprite.play("spike_active") # Play stab animation if you have one
		
	# Cooldown timer before spikes can hurt again
	var timer = get_tree().create_timer(damage_cooldown)
	timer.timeout.connect(func():
		can_deal_damage = true
		if animated_sprite:
			animated_sprite.play("spike_idle")
		
		# If player is still standing on it, damage them again immediately
		for body in get_overlapping_bodies():
			if body.is_in_group("player"):
				apply_damage(body)
				break
)
