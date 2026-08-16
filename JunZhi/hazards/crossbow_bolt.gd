extends CharacterBody2D
class_name CrossbowBolt

# --- CROSSBOW BOLT (Milestone 2 - Khor Jun Zhi) ---
# Set by WallCrossbow before adding to the scene tree.
var bolt_direction: Vector2 = Vector2.RIGHT
var bolt_speed: float = 400.0
var bolt_damage: float = 15.0

@onready var hit_area: Area2D = $HitArea


func _ready() -> void:
	hit_area.body_entered.connect(_on_hit_area_body_entered)


func _physics_process(_delta: float) -> void:
	velocity = bolt_direction.normalized() * bolt_speed
	move_and_slide()
	# Destroy on any wall / solid body collision
	if get_slide_collision_count() > 0:
		queue_free()


func _on_hit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(bolt_damage, bolt_direction.normalized() * bolt_speed * 0.6)
		queue_free()
