extends CharacterBody2D

@onready var player_anim = $AnimatedSprite2D
@onready var dash_timer = $Timer 
@onready var energy_bar: TextureProgressBar = $Hud/%EnergyBar #milestone2
@onready var health_bar = $Hud/%HPBar

@onready var footsteps_sfx: AudioStreamPlayer = $FootstepsSFX
@onready var footstep_timer: Timer = $FootstepTimer
@onready var dash_sfx: AudioStreamPlayer = $DashSFX
@onready var melee_attack_sfx: AudioStreamPlayer = $MeleeAttackSFX
@onready var explosion_blast_sfx: AudioStreamPlayer = $ExplosionBlastSFX
@onready var take_damage_sfx: AudioStreamPlayer = $TakeDamageSFX
@onready var stamina_debuff_sfx: AudioStreamPlayer = $StaminaDebuffSFX
@onready var spell_cast_sfx: AudioStreamPlayer = $SpellCastSFX

# --- FOOTSTEP AUDIO ---
const STEP_L: AudioStream = preload("res://GyapXun/sfx/walk/sfx_step_rock_l.wav")
const STEP_R: AudioStream = preload("res://GyapXun/sfx/walk/sfx_step_rock_l.wav")

const STEP_INTERVAL_WALK: float = 0.45
const STEP_INTERVAL_SPRINT: float = 0.28
const STEP_INTERVAL_DEBUFF: float = 0.60
const STEP_PITCH_SPRINT: float = 1.10
const STEP_PITCH_VARIANCE: float = 0.05
const STEP_VOLUME_SPRINT_DB: float = 2.5

var _step_use_left: bool = true
var _step_is_sprinting: bool = false

# Movement Speeds
const WALK_SPEED = 300.0
const SPRINT_SPEED = 500.0
const DASH_SPEED = 1000.0

# Dash State
var is_dashing = false
var dash_direction = Vector2.ZERO

# --- NEW STAMINA SYSTEM ---
var max_stamina = 100.0
var current_stamina = 100.0

# --- STAMINA DEBUFF --- milestone2
const EXHAUSTION_THRESHOLD: float = 0.0
const RECOVERY_THRESHOLD: float = 55.0
const DEBUFF_SPEED_MULT: float = 0.55

var is_stamina_debuffed: bool = false

# --- ENERGY BAR WARNING ---
const WARNING_TINT: Color = Color(1.0, 0.3, 0.3, 1.0)
const WARNING_BLINK_TIME: float = 0.35

var _energy_warning_tween: Tween = null

var dash_cost = 25.0       # Costs 25 stamina instantly
var sprint_cost = 30.0     # Drains 30 stamina per second
var stamina_regen = 15.0   # Recovers 15 stamina per second

# --- NEW HEALTH SYSTEM ---
var max_health = 100.0
var current_health = 100.0 # Reset to 100 max health
var health_regen = 1.0   # Recovers exactly 1 HP per second

# --- KNOCKBACK SYSTEM ---
var knockback_velocity = Vector2.ZERO

# --- MELEE ATTACK & SPELL SYSTEM ---
var attack_cost = 15.0
var can_attack = true
var attack_cooldown = 0.3

func _ready(): 
	add_to_group("player")
	player_anim.play("idle")
	energy_bar.value = current_stamina
	health_bar.value = current_health
	energy_bar.tint_progress = Color.WHITE
	footstep_timer.timeout.connect(_on_footstep_timer_timeout)
	
func _physics_process(delta: float) -> void:
	# 1. Get movement input
	var direction = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	).normalized()

	# 2. Check for Dash trigger (Requires enough stamina!)
	if Input.is_action_just_pressed("dash") and not is_dashing and current_stamina >= dash_cost:
		is_dashing = true
		current_stamina -= dash_cost # Take away the stamina instantly
		dash_timer.start()
		player_anim.play("dash")
		dash_sfx.play()
		
		if direction != Vector2.ZERO:
			dash_direction = direction
		else:
			dash_direction = Vector2(-1 if player_anim.flip_h else 1, 0)

	# Damp knockback velocity over time
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 3000.0 * delta)

	# 3. Apply Velocity and handle Sprint/Regen
	if is_dashing:
		velocity = dash_direction * DASH_SPEED + knockback_velocity
		_update_footsteps(false, false)
	else:
		var current_speed = WALK_SPEED
		var is_sprinting = false
		
		# Check if sprinting AND we have stamina left
		if Input.is_action_pressed("sprint") and direction.length() > 0 and current_stamina > 0 and not is_stamina_debuffed: #milestone2
			current_speed = SPRINT_SPEED
			is_sprinting = true
			# Drain stamina continuously based on time (delta)
			current_stamina -= sprint_cost * delta 
		else:
			# If we aren't sprinting, regenerate stamina
			current_stamina += stamina_regen * delta

		# Check for Attack inputs
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and can_attack and current_stamina >= attack_cost:
			perform_attack()
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and can_attack and current_stamina >= 30.0:
			perform_explosion_spell()

		# Clamp stamina so it never goes below 0 or above max_stamina
		current_stamina = clamp(current_stamina, 0, max_stamina)
		energy_bar.value = current_stamina
		
		if is_stamina_debuffed: #milestone2
			current_speed *= DEBUFF_SPEED_MULT
			
		velocity = direction * current_speed + knockback_velocity
		
		# Handle Walk/Sprint/Idle animations
		if velocity.length() > 20: # Slightly higher threshold to ignore tiny slide
			if is_sprinting:
				player_anim.play("sprint")
			else:
				player_anim.play("walk")
		
			if direction.x < 0:
				player_anim.flip_h = true
			elif direction.x > 0:
				player_anim.flip_h = false
		else:
			player_anim.play("idle") 
		
		# Footsteps follow player INPUT, not velocity — so knockback,
		# slides and external forces don't trigger step sounds.
		_update_footsteps(direction.length() > 0, is_sprinting)
		
		if current_health < max_health and current_health > 0:
			current_health += health_regen * delta
			current_health = clamp(current_health, 0, max_health)
			health_bar.value = current_health
	
	# 4. Update debuff state
	_update_stamina_state() #milestone2
	
	# 4. Move the character
	move_and_slide()

# Make sure this signal is connected to your Timer node!
func _on_timer_timeout() -> void:
	is_dashing = false

func take_damage(amount: float, knockback: Vector2) -> void:
	if current_health <= 0:
		return
	
	if amount > 0.0:
		take_damage_sfx.play()
	
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	health_bar.value = current_health
	
	# Flash red
	var original_modulate = player_anim.modulate
	player_anim.modulate = Color(2.5, 0.3, 0.3, 1.0)
	var flash_timer = get_tree().create_timer(0.15)
	flash_timer.timeout.connect(func():
		if is_instance_valid(player_anim):
			player_anim.modulate = Color(1, 1, 1, 1)
	)
	
	# Apply knockback force
	knockback_velocity += knockback
	
	if current_health <= 0:
		# Reload current scene on death
		var death_timer = get_tree().create_timer(0.5)
		death_timer.timeout.connect(func():
			get_tree().reload_current_scene()
		)

func perform_attack() -> void:
	can_attack = false
	melee_attack_sfx.play()
	current_stamina -= attack_cost
	energy_bar.value = current_stamina
	
	# Spawn a melee hitbox Area2D dynamically in front of the player
	var attack_area = Area2D.new()
	attack_area.collision_mask = 4 # Detect enemies on layer 3
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 45.0
	col.shape = shape
	attack_area.add_child(col)
	
	# Determine attack direction (towards mouse)
	var mouse_pos = get_global_mouse_position()
	var attack_dir = (mouse_pos - global_position).normalized()
	if attack_dir == Vector2.ZERO:
		attack_dir = Vector2(-1 if player_anim.flip_h else 1, 0)
		
	attack_area.position = attack_dir * 40.0
	
	# Visual effect: a small transient ColorRect representing the slash
	var rect = ColorRect.new()
	rect.color = Color(1, 1, 1, 0.6) # White slash color
	rect.size = Vector2(30, 30)
	rect.position = -Vector2(15, 15)
	attack_area.add_child(rect)
	
	# Detect hits via body_entered
	attack_area.body_entered.connect(func(body):
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(10.0, attack_dir * 350.0)
	)
	
	add_child(attack_area)
	
	# Flash player sprite briefly
	var original_modulate = player_anim.modulate
	player_anim.modulate = Color(1.5, 1.5, 1.5, 1) # Bright white highlight
			
	# Remove attack area after 0.12 seconds
	var timer = get_tree().create_timer(0.12)
	timer.timeout.connect(func():
		attack_area.queue_free()
		player_anim.modulate = original_modulate
	)
	
	# Cooldown
	var cooldown_timer = get_tree().create_timer(attack_cooldown)
	cooldown_timer.timeout.connect(func():
		can_attack = true
	)

func perform_explosion_spell() -> void:
	can_attack = false
	spell_cast_sfx.play()
	current_stamina -= 30.0 # Drains 30 stamina
	energy_bar.value = current_stamina
	
	# Spawn explosion at mouse position
	var explosion_pos = get_global_mouse_position()
	
	# Spawn indicator circle
	var indicator = ColorRect.new()
	indicator.color = Color(0.8, 0.2, 0.8, 0.4) # Transparent magenta
	indicator.size = Vector2(80, 80)
	indicator.position = explosion_pos - Vector2(40, 40)
	get_parent().add_child(indicator)
	
	# Flash player sprite
	var original_modulate = player_anim.modulate
	player_anim.modulate = Color(0.5, 0.5, 2.5, 1) # Blue magic highlight
	
	# Detonate after 0.2 seconds
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		indicator.queue_free()
		player_anim.modulate = original_modulate
		if is_instance_valid(explosion_blast_sfx):
			explosion_blast_sfx.play()
		
		# Spawn an Area2D for the actual explosion hitbox
		var blast_area = Area2D.new()
		blast_area.collision_mask = 4 # Detect enemies on layer 3
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 60.0
		col.shape = shape
		blast_area.add_child(col)
		blast_area.global_position = explosion_pos
		
		# Detect blast hits via body_entered
		blast_area.body_entered.connect(func(body):
			if body.is_in_group("enemies") and body.has_method("take_damage"):
				var blast_dir = (body.global_position - explosion_pos).normalized()
				if blast_dir == Vector2.ZERO:
					blast_dir = Vector2.UP
				body.take_damage(20.0, blast_dir * 600.0)
		)
		
		get_parent().add_child(blast_area)
		
		# A transient visual blast circle
		var blast_visual = ColorRect.new()
		blast_visual.color = Color(0.8, 0.3, 0.8, 0.8) # Bright purple explosion
		blast_visual.size = Vector2(120, 120)
		blast_visual.position = explosion_pos - Vector2(60, 60)
		get_parent().add_child(blast_visual)
				
		var cleanup_timer = get_tree().create_timer(0.12)
		cleanup_timer.timeout.connect(func():
			blast_area.queue_free()
			blast_visual.queue_free()
		)
	)
	
	# Cooldown
	var cooldown_timer = get_tree().create_timer(attack_cooldown * 1.5)
	cooldown_timer.timeout.connect(func():
		can_attack = true
	)

#milestone2
func _update_stamina_state() -> void:
	if not is_stamina_debuffed and current_stamina <= EXHAUSTION_THRESHOLD:
		set_stamina_debuff(true)
	elif is_stamina_debuffed and current_stamina > RECOVERY_THRESHOLD:
		set_stamina_debuff(false)


func set_stamina_debuff(active: bool) -> void:
	if active == is_stamina_debuffed:
		return
	is_stamina_debuffed = active
	if active:
		stamina_debuff_sfx.play()
		_start_energy_warning()
	else:
		stamina_debuff_sfx.stop()
		_stop_energy_warning()


func _start_energy_warning() -> void:
	if not is_instance_valid(energy_bar):
		return
	if _energy_warning_tween != null and _energy_warning_tween.is_valid():
		_energy_warning_tween.kill()

	# Bound to energy_bar, not self, so it inherits the Hud's ALWAYS process mode.
	_energy_warning_tween = energy_bar.create_tween()
	_energy_warning_tween.set_loops()
	_energy_warning_tween.set_trans(Tween.TRANS_SINE)
	_energy_warning_tween.set_ease(Tween.EASE_IN_OUT)
	_energy_warning_tween.tween_property(energy_bar, "tint_progress", WARNING_TINT, WARNING_BLINK_TIME)
	_energy_warning_tween.tween_property(energy_bar, "tint_progress", Color.WHITE, WARNING_BLINK_TIME)


func _stop_energy_warning() -> void:
	if _energy_warning_tween != null and _energy_warning_tween.is_valid():
		_energy_warning_tween.kill()
	_energy_warning_tween = null
	if is_instance_valid(energy_bar):
		energy_bar.tint_progress = Color.WHITE
		
func _update_footsteps(is_moving: bool, is_sprinting: bool) -> void:
	if not is_moving:
		footstep_timer.stop()
		return

	_step_is_sprinting = is_sprinting

	var interval: float = STEP_INTERVAL_WALK
	if is_stamina_debuffed:
		interval = STEP_INTERVAL_DEBUFF
	elif is_sprinting:
		interval = STEP_INTERVAL_SPRINT

	if footstep_timer.is_stopped():
		# First step fires immediately, so movement and sound start together.
		footstep_timer.wait_time = interval
		_play_footstep()
		footstep_timer.start()
	else:
		# Timer already running: changing wait_time applies on the next cycle,
		# so speed changes don't clip the step currently in progress.
		footstep_timer.wait_time = interval

func _on_footstep_timer_timeout() -> void:
	_play_footstep()

func _play_footstep() -> void:
	footsteps_sfx.stream = STEP_L if _step_use_left else STEP_R
	_step_use_left = not _step_use_left

	var base_pitch: float = STEP_PITCH_SPRINT if _step_is_sprinting else 1.0
	footsteps_sfx.pitch_scale = base_pitch + randf_range(-STEP_PITCH_VARIANCE, STEP_PITCH_VARIANCE)
	footsteps_sfx.volume_db = STEP_VOLUME_SPRINT_DB if _step_is_sprinting else 0.0
	footsteps_sfx.play()
