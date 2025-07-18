extends RigidBody2D

@export_range(50.0, 500.0) var speed := 300.0
@export var detection_range := 300.0

@onready var agent := %"NavigationAgent2D" as NavigationAgent2D
@onready var player := get_tree().get_first_node_in_group("player") as RigidBody2D

@onready var nav_timer := Timer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not player:
		print("Player node not found")
		return
	
	linear_damp = 10
	angular_damp = 10

	add_to_group("enemies")
	contact_monitor = true
	max_contacts_reported = 4

	add_child(nav_timer)
	nav_timer.wait_time = 0.5
	nav_timer.timeout.connect(_on_navigation_timer_timeout)
	nav_timer.start()

	agent.debug_enabled = true
	update_target_location()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if agent.is_navigation_finished():
		return

	var curr_loc := global_position
	var next_path_pos := agent.get_next_path_position()
	var direction := curr_loc.direction_to(next_path_pos)

	if direction != Vector2.ZERO:
		apply_central_impulse(direction * speed * delta)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("weapons"):
		print("enemy hit")
		#queue_free()

func update_target_location() -> void:
	if player && global_position.distance_to(player.global_position) < detection_range:
		agent.target_position = player.global_position

func _on_navigation_timer_timeout() -> void:
	update_target_location()