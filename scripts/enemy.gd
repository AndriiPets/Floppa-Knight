extends RigidBody2D

@export_range(50.0, 500.0) var speed := 150.0
@export var detection_range := 300.0
@export var invulnerability_time := 0.3
@export var blood_splatter_scene: PackedScene
@export var health := 3

const KNOCKBACK_FORCE := 100.0
const MIN_IMPACT_SPEED := 30.0

@onready var agent := %"NavigationAgent2D" as NavigationAgent2D
@onready var player := get_tree().get_first_node_in_group("player") as RigidBody2D

@onready var nav_timer := Timer.new()
@onready var inv_timer := Timer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not player:
		print("Player node not found")
		return
	add_to_group("enemies")

	#PHYSICS
	linear_damp = 10
	angular_damp = 10
	contact_monitor = true
	max_contacts_reported = 4

	#TIMERS
	add_child(nav_timer)
	nav_timer.timeout.connect(_on_navigation_timer_timeout)
	nav_timer.start()

	inv_timer.wait_time = 1.0
	inv_timer.one_shot = true
	add_child(inv_timer)

	agent.debug_enabled = true
	update_target_location()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if inv_timer.time_left > 0:
		return
	if agent.is_navigation_finished():
		return

	var curr_loc := global_position
	var next_path_pos := agent.get_next_path_position()
	var direction := curr_loc.direction_to(next_path_pos)

	if direction != Vector2.ZERO:
		apply_central_impulse(direction * speed * delta)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	for i in get_contact_count():
		var collider := state.get_contact_collider_object(i) as Node
		if collider && collider.is_in_group("weapons"):
			var loc_normal := state.get_contact_local_normal(i)
			var world_normal := -loc_normal.rotated(global_rotation)
			var world_point := state.get_contact_local_position(i)

			if collider is RigidBody2D:
				weapon_collision_response(collider, world_point, world_normal)
			break


func weapon_collision_response(weapon: RigidBody2D, pos: Vector2, normal: Vector2) -> void:
	if inv_timer.time_left > 0:
		#print("enemy still invulnerable")
		return

	var weapon_speed := weapon.linear_velocity.length()
	if weapon_speed < MIN_IMPACT_SPEED:
		#print("too slow", weapon_speed)
		return

	##Hit connected damage recieved
	health -= 1

	if health <= 0:
		print("enemy dead")

	print("enemy recieved damage ", "health = ", health)
	splatter_blood(pos, normal, health <= 0)
	var direction = weapon.linear_velocity.normalized()
	apply_central_impulse(direction * KNOCKBACK_FORCE)

	inv_timer.start(invulnerability_time)
	#queue_free()

func _draw() -> void:
	draw_circle(global_position, detection_range, Color.TEAL)


func splatter_blood(pos: Vector2, normal: Vector2, dead: bool = false) -> void:
	##Particle setup
	if not blood_splatter_scene:
		print("blood scene not setup on the enemy")
		return

	print("drawing blood on the enemy")
	var particles := blood_splatter_scene.instantiate() as GPUParticles2D

	get_tree().current_scene.add_child(particles)

	##Particle style
	if dead:
		particles.global_position = global_position
		particles.amount = 30
		particles.lifetime = 20
		var mat := particles.process_material as ParticleProcessMaterial
		mat.spread = 180
		queue_free()
	else:
		particles.global_position = pos
		particles.rotation = normal.angle()

	particles.set_deferred("emitting", true)

func update_target_location() -> void:
	if player && global_position.distance_to(player.global_position) < detection_range:
		agent.target_position = player.global_position

func _on_navigation_timer_timeout() -> void:
	update_target_location()