extends RigidBody2D

enum FurnitureType {
	Chair,
	Table
}

@export var type: FurnitureType = FurnitureType.Chair

@onready var obj_shape := %Shape as Node2D
@onready var collision := %CollisionShape as CollisionShape2D
@onready var light_poly := %LightOccluder2D as LightOccluder2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("movables")

	var width: float
	var heigth: float
	var base_mass = mass

	match type:
		FurnitureType.Chair:
			width = 8.0
			heigth = 8.0
		FurnitureType.Table:
			width = 8.0 * 4.0
			heigth = 8.0 * 2.0
			mass = base_mass * 10.0
	#Scale sprite and collision shape
	collision.shape = collision.shape.duplicate()

	#Sprite
	obj_shape.scale = Vector2(width / 8, heigth / 8)

	#Collision
	var coll_shape := collision.shape as RectangleShape2D
	if coll_shape:
		coll_shape.size = Vector2(width, heigth)

	#Occluder shape
	light_poly.occluder = light_poly.occluder.duplicate()

	var poly := light_poly.occluder as OccluderPolygon2D
	var sprite_scale := obj_shape.scale
	var new_poly := PackedVector2Array()

	for point in poly.polygon:
		new_poly.append(point * sprite_scale)
	
	poly.polygon = new_poly
