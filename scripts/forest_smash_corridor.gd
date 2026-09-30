extends Node2D

const LAYOUT=preload("res://scripts/forest_smash_corridor_layout.gd")
const ART=preload("res://assets/forest_room2_section4_extended.png")
const FOUNDATION=preload("res://assets/forest_room2_sections45678910_foundation.png")
const FOUNDATION_SHADER=preload("res://assets/forest_connected_foundation.gdshader")

func _ready() -> void:
	name="ForestRoom2Section4"
	var polygons:=LAYOUT.solid_polygons()
	for i in polygons.size():
		var body:=StaticBody2D.new()
		body.name="FutureDownwardSmashFloor" if i==1 else "GroundMass%d"%i
		if i==1: body.set_meta("required_ability","future_downward_smash")
		var shape:=CollisionPolygon2D.new()
		shape.polygon=polygons[i]
		body.add_child(shape)
		add_child(body)
		var terrain:=Polygon2D.new()
		terrain.polygon=polygons[i]
		var uv:=PackedVector2Array()
		for vertex in terrain.polygon: uv.append((vertex-LAYOUT.ORIGIN)/LAYOUT.SCALE)
		terrain.uv=uv
		terrain.texture=ART
		var material:=ShaderMaterial.new()
		material.shader=FOUNDATION_SHADER
		material.set_shader_parameter("foundation",FOUNDATION)
		material.set_shader_parameter("future_seal",i==1)
		terrain.material=material
		terrain.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		terrain.z_index=-85
		add_child(terrain)
