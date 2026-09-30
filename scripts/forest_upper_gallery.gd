extends Node2D

const LAYOUT=preload("res://scripts/forest_upper_gallery_layout.gd")
const ART=preload("res://assets/forest_room2_section3.png")
const PROPS=preload("res://assets/forest_room2_section3_props.png")
const CUTOUT=preload("res://assets/forest_prop_cutout.gdshader")

func _ready() -> void:
	name="ForestRoom2Section3"
	var solid_index:=0
	for polygon in LAYOUT.solid_polygons():
		var body:=StaticBody2D.new()
		var collision:=CollisionPolygon2D.new()
		collision.polygon=polygon
		body.add_child(collision)
		add_child(body)
		var terrain:=Polygon2D.new()
		terrain.polygon=polygon
		var uv:=PackedVector2Array()
		for vertex in polygon:
			uv.append((vertex-LAYOUT.ORIGIN)/LAYOUT.SCALE)
		terrain.uv=uv
		terrain.texture=ART
		if solid_index==4:
			var material:=ShaderMaterial.new()
			material.shader=preload("res://assets/forest_connected_foundation.gdshader")
			material.set_shader_parameter("foundation",preload("res://assets/forest_room2_sections45678910_foundation.png"))
			material.set_shader_parameter("growth_green_ratio",0.95)
			terrain.material=material
		solid_index+=1
		terrain.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		terrain.z_index=-85
		add_child(terrain)
	# Decorative silhouettes never acquire the supporting stone's collision.
	for rect in LAYOUT.ledges():
		_add_props(Rect2(rect.position-Vector2(0,65),Vector2(rect.size.x,63)))
	_add_props(Rect2(0,777,1079,67))

func _add_props(rect: Rect2) -> void:
	var decoration:=Polygon2D.new()
	var uv:=PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)])
	var polygon:=PackedVector2Array()
	for vertex in uv: polygon.append(LAYOUT.point(vertex))
	decoration.polygon=polygon
	decoration.uv=uv
	decoration.texture=PROPS
	decoration.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var material:=ShaderMaterial.new()
	material.shader=CUTOUT
	decoration.material=material
	decoration.z_index=-84
	add_child(decoration)

func _draw() -> void:
	draw_line(LAYOUT.point(Vector2(0,LAYOUT.FLOOR)),LAYOUT.point(Vector2(1079,LAYOUT.FLOOR)),Color("56bfae"),3)
