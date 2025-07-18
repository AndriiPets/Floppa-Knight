extends RigidBody2D

@export_range(0, 1000) var speed := 800.0
@export var acceleration := 2000.0
@export var friction := 2000.0

@export var weapon_scene: PackedScene

@onready var right_hand := $RHand as RigidBody2D

var weapon: RigidBody2D

func _ready() -> void:
	linear_damp = 10
	angular_damp = 10
	add_to_group("player")

	
func _physics_process(delta: float) -> void:
#
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_axis("Left", "Right")
	input_vector.y = Input.get_axis("Up", "Down")
	input_vector = input_vector.normalized()

	##More complicated way
	#var target := input_vector * speed
	#var diff := target - linear_velocity

	#if input_vector.is_zero_approx():
	#	apply_central_force(-linear_velocity * friction)
	#else:
	#	apply_central_force(diff * acceleration)
	
	##Easier Way
	if input_vector != Vector2.ZERO:
		apply_central_impulse(input_vector * speed * delta)
	
#func resolve_collisions() -> void:
#	for i in get_slide_collision_count():
#			var collision := get_slide_collision(i)
#			var body := collision.get_collider() as RigidBody2D
#			if body:
#				body.apply_force(-100.0 * collision.get_normal())
