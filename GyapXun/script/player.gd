extends CharacterBody2D

@onready var player_anim = $AnimatedSprite2D
@onready var dash_timer = $Timer # Updated to match your screenshot!
@onready var stamina_bar = $ProgressBar

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

var dash_cost = 25.0       # Costs 25 stamina instantly
var sprint_cost = 30.0     # Drains 30 stamina per second
var stamina_regen = 15.0   # Recovers 15 stamina per second

func _ready(): 
	player_anim.play("idle")
	stamina_bar.value = current_stamina
	
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
		
		if direction != Vector2.ZERO:
			dash_direction = direction
		else:
			dash_direction = Vector2(-1 if player_anim.flip_h else 1, 0)

	# 3. Apply Velocity and handle Sprint/Regen
	if is_dashing:
		velocity = dash_direction * DASH_SPEED
	else:
		var current_speed = WALK_SPEED
		var is_sprinting = false
		
		# Check if sprinting AND we have stamina left
		if Input.is_action_pressed("sprint") and direction.length() > 0 and current_stamina > 0:
			current_speed = SPRINT_SPEED
			is_sprinting = true
			# Drain stamina continuously based on time (delta)
			current_stamina -= sprint_cost * delta 
		else:
			# If we aren't sprinting, regenerate stamina
			current_stamina += stamina_regen * delta

		# Clamp stamina so it never goes below 0 or above max_stamina
		current_stamina = clamp(current_stamina, 0, max_stamina)
		stamina_bar.value = current_stamina

		velocity = direction * current_speed
		
		# Handle Walk/Sprint/Idle animations
		if velocity.length() > 0:
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

	# 4. Move the character
	move_and_slide()

# Make sure this signal is connected to your Timer node!
func _on_timer_timeout() -> void:
	is_dashing = false
