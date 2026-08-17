extends EnemyBase
class_name MonarchBoss

# The Monarch cycles between two phases:
#   SHIELDED   – Fully immune to damage. Shield pulses blue. Lasts shield_duration seconds.
#   VULNERABLE – Shield drops. Monarch chases and attacks. Lasts vulnerable_duration seconds.
# At half HP (spawn_hp_threshold), it spawns two Scout minions once.
# The _draw() method draws the shield glow and the attack telegraph ring.

const SPEED: float = 110.0
const SHIELD_SPEED: float = 70.0

@export var attack_range: float = 100.0
@export var shield_duration: float = 5.0
@export var vulnerable_duration: float = 3.5
@export var spawn_hp_threshold: float = 50.0

var shield_up: bool = true
var has_spawned_minions: bool = false
var is_attacking: bool = false
var telegraph_ratio: float = 0.0    # 0..1 fed by tween for _draw()
var phase_timer: float = 0.0
var can_attack: bool = true

var scout_scene: PackedScene = preload("res://ChiHong/enemies/scout.tscn")

enum State { SHIELDED, VULNERABLE, TELEGRAPH, ATTACK, COOLDOWN }
var current_state: State = State.SHIELDED


func _ready() -> void:
	super._ready()
	max_health = 100.0
	current_health = max_health
	# Golden tint + larger scale to signal "boss"
	sprite.modulate = Color(1.0, 0.85, 0.2, 1.0)
	phase_timer = shield_duration


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	match current_state:

		State.SHIELDED:
			shield_up = true
			phase_timer -= delta
			queue_redraw()
			# Re-fetch player if null
			if player == null:
				player = get_tree().get_first_node_in_group("player")
			# Chase player while shielded (cannot attack)
			if player != null:
				var dir := global_position.direction_to(player.global_position)
				velocity = dir * SHIELD_SPEED
				sprite.play("walk")
				sprite.flip_h = dir.x < 0
			else:
				velocity = Vector2.ZERO
				sprite.play("idle")
			if phase_timer <= 0.0:
				# Drop the shield
				current_state = State.VULNERABLE
				shield_up = false
				phase_timer = vulnerable_duration

		State.VULNERABLE:
			shield_up = false
			queue_redraw()
			phase_timer -= delta
			# Re-fetch player if reference was lost at spawn time
			if player == null:
				player = get_tree().get_first_node_in_group("player")
			if player != null:
				var dist := global_position.distance_to(player.global_position)
				if dist > attack_range:
					var dir := global_position.direction_to(player.global_position)
					velocity = dir * SPEED
					sprite.play("walk")
					sprite.flip_h = dir.x < 0
				else:
					velocity = Vector2.ZERO
					sprite.play("idle")
					if can_attack:
						_start_telegraph()
			else:
				velocity = Vector2.ZERO
			# Vulnerable window expired – raise shield again
			if phase_timer <= 0.0:
				velocity = Vector2.ZERO
				current_state = State.SHIELDED
				shield_up = true
				phase_timer = shield_duration

		State.TELEGRAPH:
			velocity = Vector2.ZERO
			is_attacking = true
			queue_redraw()

		State.ATTACK:
			velocity = Vector2.ZERO

		State.COOLDOWN:
			velocity = Vector2.ZERO
			is_attacking = false
			telegraph_ratio = 0.0
			queue_redraw()

	move_and_slide()


# TELEGRAPHED ATTACK
func _start_telegraph() -> void:
	can_attack = false
	current_state = State.TELEGRAPH
	# Tween telegraph_ratio 0→1 over 0.7 s, then execute
	var tween := create_tween()
	tween.tween_property(self, "telegraph_ratio", 1.0, 0.7)
	tween.tween_callback(_execute_attack)


func _execute_attack() -> void:
	is_attacking = false
	telegraph_ratio = 0.0
	queue_redraw()
	current_state = State.ATTACK

	if player and not is_dead:
		var dist: float = (player.global_position - global_position).length()
		if dist <= attack_range + 25.0 and player.has_method("take_damage"):
			var dir := (player.global_position - global_position).normalized()
			if dir == Vector2.ZERO:
				dir = Vector2.RIGHT
			player.take_damage(25.0, dir * 550.0)

	current_state = State.COOLDOWN
	var cooldown := get_tree().create_timer(1.8)
	cooldown.timeout.connect(func() -> void:
		can_attack = true
		if not is_dead and current_state == State.COOLDOWN:
			# Resume vulnerable phase with at least 0.5 s remaining
			current_state = State.VULNERABLE
			phase_timer = max(phase_timer, 0.5)
	)


# DAMAGE + SHIELD LOGIC
func take_damage(amount: float, knockback: Vector2) -> void:
	if shield_up:
		# Shield is up – absorb hit, flash blue to communicate immunity
		sprite.modulate = Color(0.3, 0.5, 2.0, 1.0)
		var t := get_tree().create_timer(0.12)
		t.timeout.connect(func() -> void:
			if is_instance_valid(sprite):
				sprite.modulate = Color(1.0, 0.85, 0.2, 1.0)
		)
		return

	super.take_damage(amount, knockback)

	# First time HP drops to or below threshold: spawn minions
	if not has_spawned_minions and current_health <= spawn_hp_threshold and current_health > 0.0:
		has_spawned_minions = true
		_spawn_minions()


func _spawn_minions() -> void:
	for _i in range(2):
		var scout: Node2D = scout_scene.instantiate()
		var offset := Vector2(randf_range(-130.0, 130.0), randf_range(-90.0, 90.0))
		# Add to same parent as the boss (the room node) so global_position is valid
		var spawn_pos := global_position + offset
		get_parent().call_deferred("add_child", scout)
		scout.set_deferred("global_position", spawn_pos)
		print("[Monarch] Spawning minion at ", spawn_pos)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	queue_free()


# _draw()  – shield glow (SHIELDED) + telegraph ring (TELEGRAPH)
func _draw() -> void:
	# Pulsing blue shield ring
	if shield_up:
		var pulse: float = abs(sin(Time.get_ticks_msec() * 0.005))
		draw_circle(Vector2.ZERO, 52.0, Color(0.3, 0.55, 1.0, 0.20 + 0.12 * pulse))
		draw_arc(Vector2.ZERO, 52.0, 0.0, TAU, 48, Color(0.4, 0.7, 1.0, 0.7 + 0.3 * pulse), 3.0)

	# Orange telegraph ring expanding to attack_range
	if is_attacking and telegraph_ratio > 0.0:
		draw_circle(Vector2.ZERO, attack_range * telegraph_ratio, Color(1.0, 0.5, 0.0, 0.28))
		draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 32, Color(1.0, 0.6, 0.1, 0.9), 2.5)
