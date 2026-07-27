extends CharacterBody2D
class_name EnemyBase

@export var max_health: float = 20.0
@onready var current_health: float = max_health

@export var speed: float = 100.0

var is_dead: bool = false
var player: CharacterBody2D = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	current_health = max_health
	# Find player automatically
	player = get_tree().get_first_node_in_group("player")
	if not player:
		# Fallback search if not in group
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]

func take_damage(amount: float, knockback: Vector2) -> void:
	if is_dead:
		return
	
	current_health -= amount
	velocity += knockback
	
	# Visual flash red
	if sprite:
		sprite.modulate = Color(2, 0.5, 0.5, 1) # Over-bright red flash
		var timer = get_tree().create_timer(0.15)
		timer.timeout.connect(func():
			if is_instance_valid(sprite):
				sprite.modulate = Color(1, 1, 1, 1)
		)
		
	if current_health <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	# Play a small death animation or just queue_free
	queue_free()
