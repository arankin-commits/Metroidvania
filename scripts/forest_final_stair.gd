extends Node2D
const L=preload("res://scripts/forest_final_stair_layout.gd")
const FOUNDATION=preload("res://assets/forest_room2_sections45678910_foundation.png")
const SHADER=preload("res://assets/forest_connected_foundation.gdshader")
const PROPS=preload("res://assets/forest_room2_section910_props.png")

func _ready() -> void:
	name="ForestRoom2Section11"
	for p in L.polygons():
		var body:=StaticBody2D.new()
		var shape:=CollisionPolygon2D.new()
		shape.polygon=p
		body.add_child(shape)
		add_child(body)
		var terrain:=Polygon2D.new()
		terrain.polygon=p
		terrain.texture=FOUNDATION
		terrain.uv=p
		terrain.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		terrain.z_index=-85
		var material:=ShaderMaterial.new()
		material.shader=SHADER
		material.set_shader_parameter("foundation",FOUNDATION)
		material.set_shader_parameter("preserve_growth",false)
		terrain.material=material
		add_child(terrain)
	# Scenery is attached to the stair and stays behind all live entities.
	for i in [0,2,5,7,9,11]:
		var x: float=L.X+120+i*130+10
		var s:=Sprite2D.new()
		s.texture=PROPS
		s.region_enabled=true
		s.region_rect=Rect2(180,315,360,280) if i%2==0 else Rect2(1200,315,350,280)
		s.centered=false
		s.scale=Vector2(0.20,0.20)
		s.position=Vector2(x,L.surface_y(x)-165*0.20)
		s.z_index=-84
		s.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(s)
	queue_redraw()

func _draw() -> void:
	draw_polyline(L.top(),Color("246b63"),7)
	draw_polyline(L.top(),Color("69ccb3"),2)
