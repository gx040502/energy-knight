extends EnemyBase
class_name ScoutEnemy

var attack_range: float = 65.0
var attack_cooldown: float = 1.2
var telegraphed_time: float = 0.6
var damage: float = 10.0

var is_attacking: bool = false
var can_attack: bool = true
var telegraph_ratio: float = 0.0

func _ready() -> void:
	super._ready()
	speed = 120.0
	max_health = 30.0 # Standard 30 health (since player health is 100)
	current_health = max_health

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			return
			
	var to_player = player.global_position - global_position
	var dist = to_player.length()
	
	# Flip sprite based on direction
	if sprite:
		if to_player.x < 0:
			sprite.flip_h = true
		elif to_player.x > 0:
			sprite.flip_h = false

	# Knockback dampening
	velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)

	if not is_attacking:
		if dist <= attack_range and can_attack:
			start_attack()
		else:
			# Chase
			var dir = to_player.normalized()
			velocity = velocity.move_toward(dir * speed, 600.0 * delta)
			if sprite:
				sprite.play("walk")
	else:
		# Stopped while attacking
		if sprite:
			sprite.play("idle")
			
	move_and_slide()

func start_attack() -> void:
	is_attacking = true
	can_attack = false
	velocity = Vector2.ZERO
	telegraph_ratio = 0.0
	
	# Animate the warning circle
	var tween = create_tween()
	tween.tween_property(self, "telegraph_ratio", 1.0, telegraphed_time)
	
	var telegraph_timer = get_tree().create_timer(telegraphed_time)
	telegraph_timer.timeout.connect(execute_attack)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if is_attacking and telegraph_ratio > 0.0:
		# Draw telegraphed warning area
		draw_circle(Vector2.ZERO, attack_range * telegraph_ratio, Color(1, 0, 0, 0.3))
		draw_arc(Vector2.ZERO, attack_range, 0, 360, 32, Color(1, 0, 0, 0.6), 1.5)

func execute_attack() -> void:
	if is_dead:
		return
		
	is_attacking = false
	telegraph_ratio = 0.0
	
	# Check if player is in range at the moment of strike
	if player:
		var dist = (player.global_position - global_position).length()
		if dist <= attack_range + 10.0:
			# Deal damage and apply a small knockback
			var dir = (player.global_position - global_position).normalized()
			player.take_damage(damage, dir * 250.0)
			
	# Cooldown
	var cooldown_timer = get_tree().create_timer(attack_cooldown)
	cooldown_timer.timeout.connect(func():
		can_attack = true
	)
