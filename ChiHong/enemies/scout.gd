extends EnemyBase
class_name ScoutEnemy


@export var damage: float = 20.0
@export var attack_range: float = 80.0
@export var attack_cooldown: float = 1.0

var is_attacking: bool = false
var telegraph_ratio: float = 0.0
var can_attack: bool = true

# --- State Machine ---
enum State { IDLE, CHASE, TELEGRAPH, ATTACK, COOLDOWN }
var current_state = State.IDLE

@onready var telegraph_timer = $Telegraph
@onready var cooldown_timer = $Cooldown
@onready var attack_area = $AttackArea

func _ready() -> void:
	super._ready() # Runs EnemyBase ready to find the player
	
	# Connect Area signals programmatically
	$DetectionArea.body_entered.connect(_on_detection_area_body_entered)
	$DetectionArea.body_exited.connect(_on_detection_area_body_exited)
	$AttackArea.body_entered.connect(_on_attack_area_body_entered)
	
	# Connect Timer signals
	telegraph_timer.timeout.connect(_on_telegraph_timeout)
	cooldown_timer.timeout.connect(_on_cooldown_timeout)
	
	# Sync our timers with the exported variables
	cooldown_timer.wait_time = attack_cooldown


func _physics_process(delta: float) -> void:
	if is_dead: return 
	
	var target_velocity = Vector2.ZERO
	
	match current_state:
		State.IDLE:
			sprite.play("idle")

		State.CHASE:
			if player != null:
				var direction = global_position.direction_to(player.global_position)
				target_velocity = direction * speed 
				
				sprite.play("walk")
				if direction.x > 0:
					sprite.flip_h = false
				elif direction.x < 0:
					sprite.flip_h = true
			else:
				current_state = State.IDLE

		State.TELEGRAPH:
			sprite.play("idle")
			is_attacking = true
			telegraph_ratio = 1.0 - (telegraph_timer.time_left / telegraph_timer.wait_time)
			queue_redraw() 

		State.ATTACK:
			pass 

		State.COOLDOWN:
			is_attacking = false
			telegraph_ratio = 0.0
			queue_redraw()
			if sprite.animation != "attack" or not sprite.is_playing():
				sprite.play("idle")

	# Smoothly apply knockback friction
	velocity = velocity.move_toward(target_velocity, 800.0 * delta)
	move_and_slide()


# --- PASS DAMAGE TO ENEMY BASE ---
func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> void:
	super.take_damage(amount, knockback)


# --- DETECTION AREA (Chasing) ---
func _on_detection_area_body_entered(body) -> void:
	if body.is_in_group("player"):
		if current_state == State.IDLE:
			current_state = State.CHASE

func _on_detection_area_body_exited(body) -> void:
	if body == player:
		if current_state == State.CHASE:
			current_state = State.IDLE


# --- ATTACK AREA (Telegraph & Attack) ---
func _on_attack_area_body_entered(body) -> void:
	if body == player and current_state == State.CHASE and can_attack:
		start_telegraph()


func start_telegraph() -> void:
	current_state = State.TELEGRAPH
	telegraph_timer.start()


func _on_telegraph_timeout() -> void:
	current_state = State.ATTACK
	sprite.play("attack")
	execute_attack()
	
	can_attack = false
	current_state = State.COOLDOWN
	cooldown_timer.start()


func execute_attack() -> void:
	is_attacking = false
	telegraph_ratio = 0.0
	
	if player and not is_dead:
		var dist = (player.global_position - global_position).length()
		if dist <= attack_range:
			if player.has_method("take_damage"):
				var knockback_dir = (player.global_position - global_position).normalized()
				player.take_damage(damage, knockback_dir * 200.0)


func _on_cooldown_timeout() -> void:
	can_attack = true
	if player != null and not is_dead:
		if attack_area.overlaps_body(player):
			start_telegraph()
		else:
			current_state = State.CHASE
	else:
		current_state = State.IDLE
