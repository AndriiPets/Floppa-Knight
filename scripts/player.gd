extends CharacterBody2D

@export_range(0, 1000) var speed := 200

func _physics_process(delta: float) -> void:
	get_player_input()
	if move_and_slide():
		resolve_collisions()

func get_player_input() -> void:
	var vector := Input.get_vector("Left", "Right", "Up", "Down")
	velocity = vector * speed

func resolve_collisions() -> void:
	for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var body := collision.get_collider() as RigidBody2D
			if body:
				body.apply_force(-100.0 * collision.get_normal())