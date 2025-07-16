extends RigidBody2D

@export_range(0, 1000) var speed := 800.0

@export var weapon_scene: PackedScene

@onready var right_hand := $RHand as RigidBody2D

var weapon: RigidBody2D

func _ready() -> void:
	linear_damp = 10
	angular_damp = 10

	#weapon = weapon_scene.instantiate() as RigidBody2D
	#add_child(weapon)

	#weapon.top_level = true
	#weapon.rotation = 90
	
	#weapon.global_position = (right_hand.global_position + left_hand.global_position) / 2
	# config hand physics
	#right_hand.linear_damp = 0.5
	#right_hand.mass = 0.5
	#right_hand.top_level = true


	#left_hand.linear_damp = 0.5
	#left_hand.mass = 0.3
	#left_hand.top_level = true
	

	#create_joint(right_hand)
	#create_swinging_joint(left_hand)

	#var weapon_joint := PinJoint2D.new()
	#add_child(weapon_joint)
	#weapon_joint.node_a = right_hand.get_path()
	#weapon_joint.node_b = weapon.get_path()
	#weapon_joint.position = right_hand.position + Vector2(8, 0)
	

func _physics_process(delta: float) -> void:
#	get_player_input()
#	if move_and_slide():
#		resolve_collisions()
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	input_vector.y = Input.get_action_strength("Down") - Input.get_action_strength("Up")
	input_vector = input_vector.normalized()

	if input_vector != Vector2.ZERO:
		apply_central_impulse(input_vector * speed * delta)
	
#func get_player_input() -> void:
#	var vector := Input.get_vector("Left", "Right", "Up", "Down")
#	velocity = vector * speed

#func resolve_collisions() -> void:
#	for i in get_slide_collision_count():
#			var collision := get_slide_collision(i)
#			var body := collision.get_collider() as RigidBody2D
#			if body:
#				body.apply_force(-100.0 * collision.get_normal())

func create_joint(anchor: RigidBody2D) -> void:
	var joint := PinJoint2D.new()
	add_child(joint)
	
	# Node A is the player's body
	joint.node_a = self.get_path()
	# The anchor point on the player is the hand's local positio
	
	# Node B is the weapon
	joint.node_b = anchor.get_path()

	joint.position = anchor.position
	# The anchor point on the weapon is its center (0,0) by default, which is fine.

	# --- Tweak these values to change the feel of the weapon ---
	# How long the "spring" of the joint is. Should be 0 for a tight grip.
	#joint.length = 10.0
	# How stiff the spring is. Higher values mean a tighter connection.
	#joint.stiffness = 5000.0
	# How much the spring resists "bouncing." Higher values mean less oscillation.
	#joint.damping = 500.0