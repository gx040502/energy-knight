extends EnemyBase
class_name ArcherEnemy

@export var shoot_range: float = 350.0
@export var dash_trigger_range: float = 120.0 # Distance to back away/dash
@export var dash_speed: float = 400.0

# Preload your Arrow scene
var arrow_scene = preload("res://ChiHong/enemies/arrow.tscn")

var is_dashing: bool = false
var can_shoot: bool = true
var can_dash: bool = true # Controls dash cooldown

@onready var ray_cast: RayCast2D = $RayCast2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var muzzle: Marker2D = $Muzzle

func _ready() -> void:
	super._ready() 
	max_health = 15.0
	current_health = max_health
	
	if shoot_timer:
		shoot_timer.timeout.connect(func(): can_shoot = true)

func _physics_process(_delta: float) -> void:
	if is_dead: return # Stop processing if dead
	if not player: return

	# 1. Update Line-of-Sight using RayCast2D
	ray_cast.target_position = to_local(player.global_position)
	var collider = ray_cast.get_collider()
	var has_los = (collider == player) # True if nothing is blocking view

	var distance_to_player = global_position.distance_to(player.global_position)

	if has_los:
		# 2. Proximity check for Dashing away if player gets too close (and dash is off cooldown)
		if distance_to_player < dash_trigger_range and not is_dashing and can_dash:
			dash_away_from_player()
		
		# 3. Proximity check for Projectile Shooting (Stop and shoot when in range!)
		elif distance_to_player <= shoot_range:
			velocity = Vector2.ZERO # Stop moving completely to shoot/idle
			if sprite:
				sprite.play("idle")
			if can_shoot:
				shoot_projectile()
		else:
			# Only move closer if completely out of shoot range
			var direction = global_position.direction_to(player.global_position)
			velocity = direction * speed
			if sprite:
				sprite.play("walk")
				sprite.flip_h = direction.x < 0
	else:
		# Line of sight broken (e.g., behind a wall)
		velocity = Vector2.ZERO
		if sprite:
			sprite.play("idle")

	move_and_slide()

func shoot_projectile() -> void:
	can_shoot = false
	shoot_timer.start()
	
	if sprite:
		sprite.play("attack")
		
	if player:
		var arrow = arrow_scene.instantiate()
		
		# Pass the archer reference to the arrow so it ignores it completely
		arrow.shooter = self
		
		if muzzle:
			arrow.global_position = muzzle.global_position
		else:
			arrow.global_position = global_position 
		
		var dir = global_position.direction_to(player.global_position)
		arrow.direction = dir
		arrow.rotation = dir.angle()
		
		get_tree().current_scene.add_child(arrow)

func dash_away_from_player() -> void:
	is_dashing = true
	can_dash = false # Put dash on cooldown immediately
	
	var escape_dir = (global_position - player.global_position).normalized()
	if escape_dir == Vector2.ZERO:
		escape_dir = Vector2.RIGHT
		
	if sprite:
		sprite.play("dash")
	
	# Safe speed and duration for the dash
	var dash_time = 0.15
	var elapsed = 0.0
	while elapsed < dash_time:
		if is_dead: break
		velocity = escape_dir * 500.0 
		move_and_slide()
		elapsed += get_physics_process_delta_time()
		await get_tree().process_frame
		
	is_dashing = false
	
	# Dash Cooldown Timer (e.g., 2.0 seconds before they can dash again)
	var dash_cooldown_timer = get_tree().create_timer(1.0)
	dash_cooldown_timer.timeout.connect(func():
		can_dash = true
	)
	
# --- PASS DAMAGE TO ENEMY BASE ---
func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	super.take_damage(amount, knockback)
