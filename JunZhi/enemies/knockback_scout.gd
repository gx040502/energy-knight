extends ScoutEnemy
class_name KnockbackScoutEnemy

func _ready() -> void:
	super._ready()
	speed = 140.0 # Slightly faster to force player to react!
	max_health = 30.0
	current_health = max_health
	damage = 0.0 # Deals NO damage directly

func _draw() -> void:
	if is_attacking and telegraph_ratio > 0.0:
		# Draw telegraphed warning area in Orange/Yellow
		draw_circle(Vector2.ZERO, attack_range * telegraph_ratio, Color(1, 0.5, 0, 0.35))
		draw_arc(Vector2.ZERO, attack_range, 0, 360, 32, Color(1, 0.5, 0, 0.7), 1.5)

func execute_attack() -> void:
	if is_dead:
		return
		
	is_attacking = false
	telegraph_ratio = 0.0
	
	if player:
		var dist = (player.global_position - global_position).length()
		if dist <= attack_range + 10.0:
			# Apply MASSIVE knockback (1600 force) to push player away
			var dir = (player.global_position - global_position).normalized()
			if dir == Vector2.ZERO:
				dir = Vector2.RIGHT
			player.take_damage(0.0, dir * 1600.0)
			
	# Cooldown
	var cooldown_timer = get_tree().create_timer(attack_cooldown)
	cooldown_timer.timeout.connect(func():
		can_attack = true
	)
