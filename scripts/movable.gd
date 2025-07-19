extends RigidBody2D

@export_range(8, 80) var width := 8.0
@export_range(8, 80) var heigth := 8.0

@onready var obj_shape := $%Shape as Node2D
@onready var collision := $%CollisionShape as CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("movables")
	collision.shape = collision.shape.duplicate()
	
	obj_shape.scale = Vector2(width / 8, heigth / 8)

	var coll_shape := collision.shape as RectangleShape2D
	if coll_shape:
		coll_shape.size = Vector2(width, heigth)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
