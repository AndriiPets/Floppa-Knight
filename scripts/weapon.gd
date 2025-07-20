extends RigidBody2D

@onready var particles := %SparkParticles as GPUParticles2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("weapons")

	contact_monitor = true
	max_contacts_reported = 4



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	for i in get_contact_count():
		var collider := state.get_contact_collider_object(i) as Node
		if collider && (collider.is_in_group("geometry") || collider.is_in_group("movables")):
			var loc_normal := state.get_contact_local_normal(i)
			var world_normal := -loc_normal.rotated(global_rotation)
			var world_point := state.get_contact_local_position(i)

			if not linear_velocity.is_zero_approx():
				spawn_sparks(world_point, world_normal)
			break

func spawn_sparks(pos: Vector2, normal: Vector2) -> void:
	print("spawning sparks")
	#particles.reparent(get_tree().current_scene, false)
	
	particles.global_position = pos
	particles.rotation = normal.angle()

	particles.set_deferred("emitting", true)
	

#func _on_body_entered(body: Node) -> void:
#	if not (body.is_in_group("movables") || body.is_in_group("geometry")):
#		return

#	if linear_velocity.is_zero_approx():
#		particles.emitting = false
#		return
	
#	particles.emitting = true
