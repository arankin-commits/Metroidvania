extends Node2D

const LAYOUT=preload("res://scripts/forest_arrival_layout.gd")
const ART=preload("res://assets/forest_room1_section1.png")
var bodies: Array[StaticBody2D]=[]

func _ready() -> void:
	name="ForestArrival"
	var plate:=Sprite2D.new()
	plate.name="ContinuousRoomArtwork"
	plate.texture=ART
	plate.position=LAYOUT.ART_EXTENT.position
	plate.centered=false
	plate.scale=LAYOUT.ART_EXTENT.size/Vector2(ART.get_size())
	plate.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	plate.z_index=-90
	var material:=ShaderMaterial.new()
	material.shader=preload("res://scripts/forest_room_plate.gdshader")
	material.set_shader_parameter("sky_one",preload("res://assets/forest_room1_section1_sky.png"))
	material.set_shader_parameter("sky_two",preload("res://assets/forest_room1_section2_sky.png"))
	material.set_shader_parameter("sky_three",preload("res://assets/forest_room1_section3_sky.png"))
	plate.material=material
	add_child(plate)
	_build_supported_terrain()
	_build_foreground()
	for polygon in LAYOUT.polygons():
		var body:=StaticBody2D.new()
		var collision:=CollisionPolygon2D.new()
		collision.polygon=polygon
		body.add_child(collision)
		add_child(body)
		bodies.append(body)

func _build_supported_terrain() -> void:
	# Source-painted supports match physics; complete sky paintings stay behind them.
	var terrain:=Node2D.new()
	terrain.name="RegisteredTerrain"
	terrain.z_index=-80
	add_child(terrain)
	for solid in LAYOUT.source_solids().slice(0,3):
		_add_occluder(terrain,"Section1EastRoot",preload("res://assets/forest_room1_canopy_extended.png"),LAYOUT.ORIGIN,solid)
	for solid in LAYOUT.section2_solids().slice(0,1):
		var layer:=Polygon2D.new()
		layer.polygon=solid
		var registered:=PackedVector2Array()
		var texture:=preload("res://assets/forest_room1_foundation_extended.png")
		for p in solid: registered.append(p*Vector2(texture.get_size())/Vector2(1672,1203))
		layer.uv=registered
		layer.texture=texture
		layer.position=LAYOUT.SECTION2_ORIGIN
		layer.scale=Vector2.ONE*LAYOUT.SCALE
		layer.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		terrain.add_child(layer)
	for solid in LAYOUT.section3_solids().slice(0,7):
		_add_occluder(terrain,"Section3Support",preload("res://assets/forest_room1_section3_extended.png"),LAYOUT.SECTION3_ORIGIN,solid)

func _build_foreground() -> void:
	# These near silhouettes cover terrain AND the traveller. Their collision remains
	# the continuous route behind the scenery; never add a bright cap over the trunk.
	var foreground:=Node2D.new()
	foreground.name="ForegroundOccluders"
	foreground.z_index=20
	add_child(foreground)
	# Sample the current displayed paintings with the SAME native-to-world transform.
	# Section 1's end tree stays behind terrain and the player. The separately
	# identified Section 2 trunk beside the first ascending steps is foreground.
	_add_current_occluder(foreground,"Section2NearTree",preload("res://assets/forest_room1_section2_sky.png"),
		LAYOUT.SECTION2_ORIGIN-Vector2(0,416*LAYOUT.SCALE),1548.7,PackedVector2Array([
		Vector2(305,290),Vector2(421,290),Vector2(388,415),Vector2(374,505),
		Vector2(342,550),Vector2(331,590),Vector2(335,620),Vector2(334,650),
		Vector2(341,680),Vector2(340,710),Vector2(347,740),Vector2(343,770),
		Vector2(341,795),Vector2(340,815),Vector2(338,840),Vector2(343,870),
		Vector2(350,900),Vector2(390,940),Vector2(490,1000),Vector2(570,1050),
		Vector2(570,1110),Vector2(95,1110),Vector2(112,1000),Vector2(161,924),
		Vector2(190,900),Vector2(213,870),Vector2(220,850),Vector2(227,830),
		Vector2(233,810),Vector2(247,790),Vector2(257,775),Vector2(269,760),
		Vector2(276,746),Vector2(273,730),Vector2(265,710),Vector2(255,690),
		Vector2(247,670),Vector2(241,650),Vector2(239,630),Vector2(242,608),
		Vector2(245,570),Vector2(195,553),Vector2(167,516),Vector2(225,537),
		Vector2(277,557),Vector2(286,485),Vector2(298,410),Vector2(310,351)]))
	_add_current_occluder(foreground,"Section2EastTree",preload("res://assets/forest_room1_section2_sky.png"),
		LAYOUT.SECTION2_ORIGIN-Vector2(0,416*LAYOUT.SCALE),1548.7,PackedVector2Array([
		Vector2(1040,300),Vector2(1303,300),Vector2(1303,1207),Vector2(1130,1207),
		Vector2(1170,1050),Vector2(1210,955),Vector2(1232,825),Vector2(1230,715),
		Vector2(1220,610),Vector2(1226,580),Vector2(1220,560),Vector2(1205,530),
		Vector2(1185,510),Vector2(1160,490),Vector2(1135,470),Vector2(1110,450),
		Vector2(1095,430),Vector2(1080,410),Vector2(1065,390),Vector2(1050,365),
		Vector2(1040,335)]))

	var threshold:=Sprite2D.new()
	threshold.name="SharedSection3Threshold"
	threshold.texture=preload("res://assets/forest_room1_section3_threshold.png")
	threshold.centered=false
	threshold.position=LAYOUT.SECTION3_ORIGIN-Vector2(256*LAYOUT.SCALE,0)
	threshold.scale=Vector2(512,1273)*LAYOUT.SCALE/Vector2(threshold.texture.get_size())
	threshold.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var bark_material:=ShaderMaterial.new()
	bark_material.shader=preload("res://scripts/forest_foreground.gdshader")
	threshold.material=bark_material
	foreground.add_child(threshold)
	_add_current_occluder(foreground,"Section3WestTree",preload("res://assets/forest_room1_section3_sky.png"),
		LAYOUT.SECTION3_ORIGIN-Vector2(0,485*LAYOUT.SCALE),1522.0,PackedVector2Array([
		Vector2(0,360),Vector2(95,360),Vector2(62,510),Vector2(42,600),
		Vector2(60,690),Vector2(61,755),Vector2(49,830),Vector2(48,900),
		Vector2(80,986),Vector2(220,1110),Vector2(220,1197),Vector2(0,1197)]))
	# Landing foliage and recessed roots stay in the background plate.

func _add_occluder(parent: Node2D,label: String,texture: Texture2D,origin: Vector2,outline: PackedVector2Array) -> void:
	var layer:=Polygon2D.new()
	layer.name=label
	layer.polygon=outline
	layer.uv=outline
	if label=="Section1EastRoot":
		var registered:=PackedVector2Array()
		for point in outline:
			registered.append((point+Vector2(0,262))*Vector2(texture.get_size())/Vector2(1672,1203))
		layer.uv=registered
	if label.begins_with("Section3"):
		var registered:=PackedVector2Array()
		for point in outline: registered.append(point*Vector2(texture.get_size())/Vector2(1672,1273))
		layer.uv=registered
	layer.texture=texture
	layer.position=origin
	layer.scale=Vector2.ONE*LAYOUT.SCALE
	layer.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(layer)

func _add_current_occluder(parent: Node2D,label: String,texture: Texture2D,origin: Vector2,logical_height: float,native_outline: PackedVector2Array) -> void:
	var layer:=Polygon2D.new()
	layer.name=label
	layer.polygon=native_outline
	layer.uv=native_outline
	layer.texture=texture
	layer.position=origin
	layer.scale=Vector2(1200.0/texture.get_width(),logical_height*LAYOUT.SCALE/texture.get_height())
	layer.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(layer)
