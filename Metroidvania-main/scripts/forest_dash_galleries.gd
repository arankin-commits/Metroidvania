extends Node2D

const LAYOUT=preload("res://scripts/forest_dash_galleries_layout.gd")
const KIT=preload("res://assets/forest_room2_section8_upper.png")
const PROPS=preload("res://assets/forest_room2_section910_props.png")
const LOWER=preload("res://assets/forest_room2_sections8910_lower.png")
const FOUNDATION=preload("res://assets/forest_room2_sections45678910_foundation.png")
const SHADER=preload("res://assets/forest_connected_foundation.gdshader")

func _ready() -> void:
	name="ForestRoom2Sections9And10"
	# Shell is complete before any local decoration. The cap polygons own their
	# stone collision; banners, recessed piers and foliage never receive bodies.
	var polygons:=LAYOUT.solid_polygons()
	for i in polygons.size():
		var body:=StaticBody2D.new()
		body.name=["UpperFloor","LowerFloor","Roof","LowerRightWall","Section9High","Section10High"][i]
		var collision:=CollisionPolygon2D.new()
		collision.polygon=polygons[i]
		body.add_child(collision)
		add_child(body)
		var terrain:=Polygon2D.new()
		terrain.name="RegisteredTerrain%d"%i
		terrain.polygon=polygons[i]
		terrain.texture=LOWER if i==3 else KIT
		terrain.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		terrain.z_index=-85
		var uv:=PackedVector2Array()
		for v in polygons[i]:
			if i==3: uv.append((v-LAYOUT.LOWER_ORIGIN)/LAYOUT.LOWER_SIZE*Vector2(2048,768))
			elif i>=4:
				var cap: Rect2=LAYOUT.CAPS[i-4]
				uv.append(Vector2(350,280)+(v-cap.position)/cap.size*Vector2(1098,75))
			else: uv.append((v-LAYOUT.PREVIOUS.UPPER_ORIGIN)/LAYOUT.PREVIOUS.SCALE)
		terrain.uv=uv
		if i!=3:
			var material:=ShaderMaterial.new()
			material.shader=SHADER
			material.set_shader_parameter("foundation",FOUNDATION)
			material.set_shader_parameter("preserve_growth",false)
			terrain.material=material

		add_child(terrain)
	# Material-kit clusters have distinct ownership and placements. Their real
	# alpha and entity-behind depth preserve the clear takeoff/receiving edges.
	_cluster(Rect2(110,315,840,280),Vector2(13930,LAYOUT.HIGH),0.72)
	_cluster(Rect2(1090,315,845,280),Vector2(15400,LAYOUT.HIGH),0.64)
	_cluster(Rect2(110,315,840,280),Vector2(14030,LAYOUT.FLOOR),0.48)
	_cluster(Rect2(1090,315,845,280),Vector2(15580,LAYOUT.FLOOR),0.50)
	queue_redraw()

func _cluster(region: Rect2,at: Vector2,scale: float) -> void:
	var painting:=Polygon2D.new()
	painting.texture=PROPS
	painting.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	painting.z_index=-84
	painting.uv=LAYOUT.rectangle(region)
	var polygon:=PackedVector2Array()
	for v in painting.uv: polygon.append(at+(v-Vector2(region.position.x,480))*scale)
	painting.polygon=polygon
	add_child(painting)

func _draw() -> void:
	# Shared support edges remain world-anchored, never painted over foreground.
	for y in [LAYOUT.FLOOR,LAYOUT.LOWER_FLOOR]:
		draw_line(Vector2(LAYOUT.X,y),Vector2(LAYOUT.END,y),Color("56bfae"),3)
	for cap in LAYOUT.CAPS:
		draw_line(cap.position+Vector2(5,1),Vector2(cap.end.x-5,cap.position.y+1),Color("87cdda"),2)
