extends Node2D

const LAYOUT=preload("res://scripts/forest_stair_layout.gd")
const ART=preload("res://assets/forest_room2_section2.png")
const EXTENDED_ART=preload("res://assets/forest_room2_sections234567891011_background.png")

func _ready() -> void:
	name="ForestRoom2Section2"
	var painting:=Sprite2D.new()
	painting.name="RegisteredPainting"
	painting.texture=EXTENDED_ART
	painting.centered=false
	painting.position=LAYOUT.ART_ORIGIN
	painting.scale=LAYOUT.ART_SCALE
	painting.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	painting.z_index=-95
	painting.modulate=Color(0.60,0.68,0.78)
	add_child(painting)
	var body:=StaticBody2D.new()
	body.name="OnlyStairRoute"
	var shape:=CollisionPolygon2D.new()
	shape.polygon=LAYOUT.solid_polygon()
	body.add_child(shape)
	add_child(body)
	# Preserve the established stair contours under the newly extended sky painting.
	var terrain:=Polygon2D.new()
	terrain.polygon=LAYOUT.solid_polygon()
	var uv:=PackedVector2Array()
	for vertex in terrain.polygon:
		uv.append((vertex-LAYOUT.ORIGIN)/LAYOUT.SCALE)
	terrain.uv=uv
	terrain.texture=ART
	var material:=ShaderMaterial.new()
	material.shader=preload("res://assets/forest_connected_foundation.gdshader")
	material.set_shader_parameter("foundation",preload("res://assets/forest_room2_sections45678910_foundation.png"))
	material.set_shader_parameter("growth_green_ratio",0.95)
	terrain.material=material
	terrain.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	terrain.z_index=-85
	add_child(terrain)
