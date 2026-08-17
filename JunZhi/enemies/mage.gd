extends EnemyBase
class_name MageEnemy

# The Mage uses line-of-sight proximity detection:
#   DetectionArea (large) → starts chasing / enters combat
#   FleeArea (small)      → teleports away when player gets too close
# After teleporting, it locks the player's position and telegraphs an
# AoE ring spell there, then enters a cooldown before attacking again.

const SPEED: float = 90.0

@export var telegraph_time: float = 0.8
@export var attack_cooldown: float = 3.0  # total cycle ≈ 3.8 s (0.8 telegraph + 3.0 cooldown)

const AOE_RADIUS: float = 80.0
# Safe teleport bounds in the room's LOCAL coordinate space
# (must match the playable area set up in dungeon_room.tscn)
const LOCAL_MIN: Vector2 = Vector2(260.0, 210.0)
const LOCAL_MAX: Vector2 = Vector2(880.0, 450.0)
const MIN_PLAYER_DIST: float = 200.0  # How far from the player to land

enum State { IDLE, CHASE, FLEE, TELEGRAPH, CAST, COOLDOWN }
var current_state: State = State.IDLE

var can_attack: bool = true
var aoe_center: Vector2 = Vector2.ZERO   # World-space target locked at cast start
var aoe_ratio: float = 0.0               # 0..1 used by _draw() for the expanding ring

@onready var telegraph_timer: Timer = $Telegraph
@onready var cooldown_timer: Timer = $Cooldown


func _ready() -> void:
	super._ready()
	max_health = 40.0
	current_health = max_health
	# Purple tint so the Mage is visually distinct from the Scout
	sprite.modulate = Color(0.7, 0.4, 1.0, 1.0)
	telegraph_timer.wait_time = telegraph_time
	telegraph_timer.one_shot = true
	telegraph_timer.timeout.connect(_on_telegraph_timeout)
	cooldown_timer.wait_time = attack_cooldown
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_timeout)
	$DetectionArea.body_entered.connect(_on_detection_body_entered)
	$DetectionArea.body_exited.connect(_on_detection_body_exited)
	$FleeArea.body_entered.connect(_on_flee_body_entered)


func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			sprite.play("idle")

		State.CHASE:
			if player != null:
				var direction = global_position.direction_to(player.global_position)
				velocity = direction * SPEED
				sprite.play("walk")
				sprite.flip_h = direction.x < 0
			else:
				current_state = State.IDLE

		State.FLEE:
			# Stationary after teleporting – waiting for telegraph or cooldown
			velocity = Vector2.ZERO
			sprite.play("idle")

		State.TELEGRAPH:
			velocity = Vector2.ZERO
			sprite.play("idle")
			# aoe_center was locked at telegraph start
			# so the ring stays fixed at the position and the player can dodge by moving away.
			if telegraph_timer.wait_time > 0.0:
				aoe_ratio = 1.0 - (telegraph_timer.time_left / telegraph_timer.wait_time)
			queue_redraw()

		State.CAST, State.COOLDOWN:
			velocity = Vector2.ZERO
			aoe_ratio = 0.0
			queue_redraw()

	move_and_slide()


# DETECTION AREA  (large circle – triggers Chase)
func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and current_state == State.IDLE:
		current_state = State.CHASE


func _on_detection_body_exited(body: Node2D) -> void:
	if body == player and current_state == State.CHASE:
		current_state = State.IDLE


# FLEE AREA  (small circle – triggers Teleport)
func _on_flee_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Don't interrupt an already-active telegraph or cast
		if current_state not in [State.TELEGRAPH, State.CAST]:
			teleport_away()


# TELEPORT
func teleport_away() -> void:
	if is_dead:
		return
	current_state = State.FLEE

	# Generate candidates in the room's LOCAL space, then convert to global.
	# This keeps the Mage inside the room regardless of where the room node
	# is positioned in the world.
	var room: Node2D = get_parent() as Node2D
	var new_pos: Vector2 = global_position
	for _attempt in range(20):
		var local_candidate := Vector2(
			randf_range(LOCAL_MIN.x, LOCAL_MAX.x),
			randf_range(LOCAL_MIN.y, LOCAL_MAX.y)
		)
		var global_candidate: Vector2 = (
			room.to_global(local_candidate) if room != null else local_candidate
		)
		if player == null or global_candidate.distance_to(player.global_position) > MIN_PLAYER_DIST:
			new_pos = global_candidate
			break

	# Flash purple-white → teleport → restore tint
	sprite.modulate = Color(1.8, 0.8, 2.0, 1.0)
	var flash := get_tree().create_timer(0.12)
	flash.timeout.connect(func() -> void:
		if not is_instance_valid(self) or is_dead:
			return
		global_position = new_pos
		sprite.modulate = Color(0.7, 0.4, 1.0, 1.0)
		if can_attack:
			_start_telegraph()
		# If on cooldown, remain in FLEE/COOLDOWN; _on_cooldown_timeout will resume
	)


# TELEGRAPH  (lock target position and show expanding ring)
func _start_telegraph() -> void:
	if is_dead or player == null:
		return
	current_state = State.TELEGRAPH
	aoe_center = player.global_position   # Snapshot – AoE hits where player IS now
	telegraph_timer.start()


func _on_telegraph_timeout() -> void:
	current_state = State.CAST
	_execute_cast()
	can_attack = false
	current_state = State.COOLDOWN
	cooldown_timer.start()


# CAST  (spawn AoE damage area at locked position)
func _execute_cast() -> void:
	if is_dead:
		return
	aoe_ratio = 0.0
	queue_redraw()

	# Direct distance check (same pattern as Scout's execute_attack).
	# body_entered is unreliable when the Area2D spawns on top of the player.
	if player and not is_dead:
		var dist: float = (player.global_position - aoe_center).length()
		if dist <= AOE_RADIUS:
			if player.has_method("take_damage"):
				var dir := (player.global_position - aoe_center).normalized()
				if dir == Vector2.ZERO:
					dir = Vector2.UP
				player.take_damage(15.0, dir * 300.0)

	# Visual-only ring that lingers briefly so the player sees where it landed
	var ring := ColorRect.new()
	ring.color = Color(0.6, 0.1, 0.9, 0.55)
	ring.size = Vector2(AOE_RADIUS * 2.0, AOE_RADIUS * 2.0)
	ring.position = aoe_center - Vector2(AOE_RADIUS, AOE_RADIUS)
	get_parent().add_child(ring)
	var cleanup := get_tree().create_timer(0.3)
	cleanup.timeout.connect(func() -> void:
		if is_instance_valid(ring):
			ring.queue_free()
	)


func _on_cooldown_timeout() -> void:
	can_attack = true
	current_state = State.CHASE if (not is_dead and player != null) else State.IDLE


# _draw()  – telegraph ring expands from aoe_center towards AOE_RADIUS
func _draw() -> void:
	if current_state == State.TELEGRAPH and aoe_ratio > 0.0:
		var local_center := to_local(aoe_center)
		draw_circle(local_center, AOE_RADIUS * aoe_ratio, Color(0.6, 0.1, 0.9, 0.25))
		draw_arc(local_center, AOE_RADIUS, 0.0, TAU, 48, Color(0.85, 0.2, 1.0, 0.9), 2.0)
