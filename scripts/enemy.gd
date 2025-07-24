extends RigidBody2D

const KNOCKBACK_FORCE := 500.0
const MIN_IMPACT_SPEED := 30.0
enum EnemyType {
	CHARGER,
	FENCER,
	SHOOTER
}

@export_group("AI Behavior")
@export var behavior_type: EnemyType = EnemyType.FENCER
@export_range(50.0, 500.0) var speed := 400.0
@export var detection_range := 300.0
@export var max_speed := 150.0
@export var attack_time := 1.0

@export_group("Attack Properties")
@export var swing_radius := 70.0 # pixels
@export var swing_cooldown := 4.0 # seconds
@export var windup_force := 8000.0 # impulse into the body for one swing
@export var swing_torque := 2000.0 # Rotational force for the sword swing
@export var orbit_distance_buffer := 10.0 # The "sweet spot" distance for orbiting
@export var swing_arc_force := 1500.0

@export_group("Combat Stats")
@export var invulnerability_time := 0.5
@export var blood_splatter_scene: PackedScene
@export var projectile_scene: PackedScene
@export var health := 3

var _next_swing := 0.0
var _is_swining := false
var _is_dead := false
var attack_target: Vector2

var max_turn_speed := 4.0
var follow_smoothing := 8.0

var is_invulnarable := false

@onready var agent := %"NavigationAgent2D" as NavigationAgent2D
@onready var hand := %"hand" as RigidBody2D
@onready var sprite := %Sprite as Sprite2D
@onready var weapon := $Weapon
@onready var player := get_tree().get_first_node_in_group("player") as RigidBody2D

@onready var nav_timer := Timer.new()
@onready var inv_timer := Timer.new()
@onready var swing_timer := Timer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not player:
		print("Player node not found")
		return
	add_to_group("enemies")

	if weapon:
		weapon.remove_from_group("weapons")
		weapon.add_to_group("enemy_weapon")

	#PHYSICS
	linear_damp = 10
	angular_damp = 10
	contact_monitor = true
	max_contacts_reported = 4

	#TIMERS
	#Navigation
	nav_timer.wait_time = 0.5
	nav_timer.timeout.connect(_on_navigation_timer_timeout)
	nav_timer.start()
	add_child(nav_timer)

	#Invulnarability
	inv_timer.wait_time = invulnerability_time
	inv_timer.one_shot = true
	inv_timer.timeout.connect(_on_inv_timer_timeout)
	add_child(inv_timer)

	#Swing
	swing_timer.one_shot = true
	swing_timer.wait_time = attack_time
	swing_timer.timeout.connect(_on_swing_timer_timeout)
	add_child(swing_timer)

	agent.debug_enabled = true
	update_target_location()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if is_invulnarable or not player:
		return
	if _is_dead:
		return

	var dir_to_player := (player.global_position - global_position).normalized()
	var distance_to_player := global_position.distance_to(player.global_position)

	if _is_swining:
		match behavior_type:
			EnemyType.FENCER:
					apply_central_force(attack_target * speed * 500.0 * delta)
					apply_torque(15000)
					hand.apply_torque(10000)
					return

			EnemyType.SHOOTER:
				if not projectile_scene:
					print("projectile scene not set on SHOOTER enemy")
					return
				
				var arrow := projectile_scene.instantiate() as RigidBody2D
				get_tree().current_scene.add_child(arrow)
				arrow.global_position = global_position + attack_target * 10.0
				arrow.rotation = attack_target.angle()
				arrow.continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
				arrow.apply_impulse(attack_target * 800.0)
				_is_swining = false

			EnemyType.CHARGER:
				apply_central_force(attack_target * speed * 200.0 * delta)
				return

	##--ORBIT AND SWING LOGIC--
	#APPROACH
	if distance_to_player > swing_radius + orbit_distance_buffer:
		##If out of range navigate to get closer
		update_target_location()

		var next_path_pos := agent.get_next_path_position()
		var direction_to_path := global_position.direction_to(next_path_pos)
		if direction_to_path != Vector2.ZERO:
			apply_central_force(direction_to_path * speed)
	
	elif distance_to_player < swing_radius + orbit_distance_buffer && behavior_type == EnemyType.CHARGER:
		do_attack(dir_to_player)
		return

	#BACK AWAY BUT CONTINUE SWINING
	elif distance_to_player < swing_radius - orbit_distance_buffer:
		agent.target_position = global_position
		var move_direction := -dir_to_player
		apply_central_force(move_direction * speed * 5.0)
		if Time.get_unix_time_from_system() >= _next_swing:
			do_attack(dir_to_player)
	
	#ORBIT & ATTACK
	else:
		##if in range switch to orbital
		agent.target_position = global_position

		##Radial force to maintain the distance
		var tangent := dir_to_player.rotated(PI / 2.0)
		var tangential_force := tangent * speed * 0.8

		apply_central_force(tangential_force)

		if Time.get_unix_time_from_system() >= _next_swing:
			do_attack(dir_to_player)
		
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

##--PLAN--
## do_windup activates swining state
## apply_force towards the player and apply_torque for a set time 
## after time is done stop applying force and torque 

func do_attack(dir_to_player: Vector2) -> void:
	print("Swing started", position)
	_is_swining = true
	_next_swing = Time.get_unix_time_from_system() + swing_cooldown + attack_time
	swing_timer.start(attack_time)
	attack_target = dir_to_player
	##Wind-Up
	#apply_central_impulse(-dir_to_player * windup_force * 0.4)
	#apply_torque_impulse(-swing_torque * 0.2)

	#await get_tree().create_timer(0.15, Timer.TIMER_PROCESS_PHYSICS).timeout

	##Lunge and swing
	#apply_central_impulse(dir_to_player * windup_force)
	#apply_torque_impulse(10000)

	#var tangent = dir_to_player.rotated(PI / 2.0)
	#hand.apply_central_impulse(tangent * swing_arc_force)

	
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if is_invulnarable:
		return
	if _is_dead:
		return
	if not _is_swining:
		##FACE THE PLAYER
		var dir_to_player := (player.global_position - global_position).normalized()
		var current_fwd := -transform.x.normalized()
		var angle_error := current_fwd.angle_to(dir_to_player)
		if current_fwd.cross(dir_to_player) > 0:
			angle_error = - angle_error
		var turn_vel := angle_error * follow_smoothing
		turn_vel = clamp(turn_vel, -max_turn_speed, max_turn_speed)
		angular_velocity = turn_vel

	for i in get_contact_count():
		var collider := state.get_contact_collider_object(i) as Node
		if collider && collider.is_in_group("weapons"):
			var loc_normal := state.get_contact_local_normal(i)
			var world_normal := -loc_normal.rotated(global_rotation)
			var world_point := state.get_contact_local_position(i)

			if collider is RigidBody2D:
				weapon_collision_response(collider, world_point, world_normal)
			break


func weapon_collision_response(weapon_body: RigidBody2D, pos: Vector2, normal: Vector2) -> void:
	if is_invulnarable:
		print("enemy still invulnerable")
		return

	var weapon_speed := weapon_body.linear_velocity.length()
	if weapon_speed < MIN_IMPACT_SPEED:
		print("too slow", weapon_speed)
		return

	##Hit connected damage recieved
	is_invulnarable = true
	inv_timer.start()

	health -= 1

	if health <= 0:
		print("enemy dead")
		_is_dead = true
		sprite.modulate = Color.DIM_GRAY
		set_physics_process(false)

	#print("enemy recieved damage ", "health = ", health)
	splatter_blood(pos, normal)
	var direction = weapon_body.linear_velocity.normalized()
	apply_central_impulse(direction * KNOCKBACK_FORCE)

	inv_timer.start(invulnerability_time)
	#queue_free()

#func _draw() -> void:
#	draw_circle(global_position, detection_range, Color.TEAL)

func _on_inv_timer_timeout():
	is_invulnarable = false

func splatter_blood(pos: Vector2, normal: Vector2) -> void:
	##Particle setup
	if not blood_splatter_scene:
		print("blood scene not setup on the enemy")
		return

	#print("drawing blood on the enemy")
	var particles := blood_splatter_scene.instantiate() as GPUParticles2D

	get_tree().current_scene.add_child(particles)

	##Particle style
	if _is_dead:
		particles.global_position = global_position
		particles.amount = 100
		particles.lifetime = 20
		var mat := particles.process_material as ParticleProcessMaterial
		mat.spread = 180
		
	else:
		particles.global_position = pos
		particles.rotation = normal.angle()

	particles.set_deferred("emitting", true)

func update_target_location() -> void:
	if player && global_position.distance_to(player.global_position) < detection_range:
		agent.target_position = player.global_position

func _on_navigation_timer_timeout() -> void:
	update_target_location()

func _on_swing_timer_timeout() -> void:
	print("Swing ended")
	_is_swining = false
