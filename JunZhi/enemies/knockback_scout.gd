extends EnemyBase
class_name KnockbackScoutEnemy

const SPEED = 140.0
@export var attack_range: float = 60.0
@export var attack_cooldown: float = 1.0

var is_attacking: bool = false
var telegraph_ratio: float = 0.0
var can_attack: bool = true
var can_move: bool = true

func _ready() -> void:
	super._ready()
	max_health = 30.0
	current_health = max_health

func _physics_process(delta: float) -> void:
	if is_dead: return

	if player != null and can_move:
		var distance = global_position.distance_to(player.global_position)
		var direction = global_position.direction_to(player.global_position)

		# Chase if outside attack range, stop and attack if inside
		if distance > attack_range:
			velocity = direction * SPEED
			if sprite:
				sprite.play("walk")
				sprite.flip_h = direction.x < 0
		else:
			velocity = Vector2.ZERO
			if can_attack:
				trigger_knockback_attack()
	else:
		velocity = Vector2.ZERO
		if sprite:
			sprite.play("idle")

	move_and_slide()

func trigger_knockback_attack() -> void:
	can_attack = false
	can_move = false # Stop moving to wind up
	is_attacking = true
	
	if sprite:
		sprite.play("attack")

	# Telegraph wind-up duration (0.5 seconds)
	var telegraph_tween = create_tween()
	telegraph_tween.tween_property(self, "telegraph_ratio", 1.0, 0.5)
	
	# Force the warning circle to redraw every frame while the tween is playing
	while telegraph_tween.is_running():
		queue_redraw()
		await get_tree().process_frame
	
	# Execute the Knockback Attack
	if player and not is_dead:
		var dist = (player.global_position - global_position).length()
		if dist <= attack_range + 20.0:
			if player.has_method("take_damage"):
				var dir = (player.global_position - global_position).normalized()
				if dir == Vector2.ZERO:
					dir = Vector2.RIGHT
				player.take_damage(0.0, dir * 1600.0) # Massive knockback push

	is_attacking = false
	telegraph_ratio = 0.0
	queue_redraw() # Clear the circle when done
	can_move = true # Resume movement

	# Cooldown before next attack
	var cooldown = get_tree().create_timer(attack_cooldown)
	cooldown.timeout.connect(func():
		can_attack = true
	)

func _draw() -> void:
	if is_attacking and telegraph_ratio > 0.0:
		# Draws the warning circle around the knockback scout
		draw_circle(Vector2.ZERO, attack_range * telegraph_ratio, Color(1, 0.5, 0, 0.35))
		draw_arc(Vector2.ZERO, attack_range, 0, TAU, 32, Color(1, 0.5, 0, 0.7), 1.5)
