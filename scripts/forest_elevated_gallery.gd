extends Node2D

const LAYOUT=preload("res://scripts/forest_elevated_gallery_layout.gd")
const ART=preload("res://assets/forest_room2_section6.png")
const PROPS=preload("res://assets/forest_room2_section6_props.png")
const FOUNDATION=preload("res://assets/forest_room2_sections45678910_foundation.png")
const FOUNDATION_SHADER=preload("res://assets/forest_connected_foundation.gdshader")

func _ready() -> void:
	name="ForestRoom2Section6"
	var native:=LAYOUT.native_polygons()
	var polygons:=LAYOUT.solid_polygons()
	for i in polygons.size():
		var body:=StaticBody2D.new()
		body.name=["WestHighPlatform","CenterPlatform","EastHighPlatform","GroundMass"][i]
		var shape:=CollisionPolygon2D.new()
		shape.polygon=polygons[i]
		body.add_child(shape)
		add_child(body)
		var terrain:=Polygon2D.new()
		terrain.name="RegisteredTerrain%d"%i
		terrain.polygon=polygons[i]
		terrain.uv=native[i]
		terrain.texture=ART
		if i==3:
			var material:=ShaderMaterial.new()
			material.shader=FOUNDATION_SHADER
			material.set_shader_parameter("foundation",FOUNDATION)
			terrain.material=material
		terrain.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		terrain.z_index=-85
		add_child(terrain)
	for i in 3:
		var cap: Rect2=LAYOUT.CAPS[i]
		_add_props(Rect2(cap.position-Vector2(20,80),Vector2(cap.size.x+40,270)),i)
	_add_props(Rect2(0,700,1448,386),-1)

func _add_props(rect: Rect2,index: int) -> void:
	var uv:=PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)])
	var polygon:=PackedVector2Array()
	for vertex in uv: polygon.append(LAYOUT.point(vertex,index))
	var decoration:=Polygon2D.new()
	decoration.polygon=polygon
	decoration.uv=uv
	decoration.texture=PROPS
	var material:=ShaderMaterial.new()
	material.shader=preload("res://assets/forest_prop_cutout.gdshader")
	decoration.material=material
	decoration.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	decoration.z_index=-84
	add_child(decoration)
