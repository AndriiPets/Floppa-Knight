extends Node2D

var map_dimemtions := Vector2(50, 30)

@onready var tilemap := %"TileMap" as TileMapLayer
@onready var region := %"NavigationRegion2D" as NavigationRegion2D

func _ready() -> void:
    tilemap.navigation_enabled = false
    tilemap.add_to_group("geometry")
    
    var poly := region.navigation_polygon
    poly.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
    poly.source_geometry_group_name = "geometry"

    NavigationServer2D.set_debug_enabled(true)
    regenerate_navmesh()

func regenerate_navmesh() -> void:
    region.navigation_polygon.clear()

    region.navigation_polygon.add_outline(
        PackedVector2Array([
            Vector2.ZERO,
            Vector2(map_dimemtions.x * 16, 0),
            Vector2(map_dimemtions.y * 16, map_dimemtions.y * 16),
            Vector2(0, map_dimemtions.y * 16)
        ])
    )

    region.bake_navigation_polygon(true)
