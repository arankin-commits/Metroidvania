extends Node2D

const LAYOUT=preload("res://scripts/forest_gallery_layout.gd")
const ART=preload("res://assets/forest_room2_section1.png")
var bodies: Array[StaticBody2D]=[]

func _ready() -> void:
	name="ForestRoom2Section1"
	var painting:=Sprite2D.new()
	painting.name="RegisteredPainting"
	painting.texture=ART
	painting.centered=false
	painting.position=LAYOUT.ORIGIN
	painting.scale=Vector2.ONE*LAYOUT.SCALE
	painting.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	painting.z_index=-90
	add_child(painting)
	var step_index:=0
	for native in LAYOUT.added_steps():
		var bracket:=Polygon2D.new()
		bracket.name="MasonryStep"
		bracket.texture=ART
		bracket.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		bracket.z_index=-85
		bracket.modulate=Color(0.72,0.8,0.81)
		var source:=LAYOUT.step_polygon(native)
		var corners:=PackedVector2Array()
		var uv:=PackedVector2Array()
		var donor_x: Array[int]=[134,211,298,965,1092,1150]
		var donor:=Vector2(donor_x[step_index],614)
		for vertex in source:
			corners.append(LAYOUT.point(vertex))
			uv.append(donor+vertex-native.position)
		bracket.polygon=corners
		bracket.uv=uv
		add_child(bracket)
		step_index+=1
	for polygon in LAYOUT.polygons():
		var body:=StaticBody2D.new()
		var shape:=CollisionPolygon2D.new()
		shape.polygon=polygon
		body.add_child(shape)
		add_child(body)
		bodies.append(body)
