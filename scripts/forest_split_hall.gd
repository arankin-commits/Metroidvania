extends Node2D

const LAYOUT=preload("res://scripts/forest_split_hall_layout.gd")
const UPPER=preload("res://assets/forest_room2_section8_upper.png")
const LOWER=preload("res://assets/forest_room2_section8_lower.png")
const JOINED_LOWER=preload("res://assets/forest_room2_sections8910_lower.png")
const NEXT=preload("res://scripts/forest_dash_galleries_layout.gd")
const PROPS=preload("res://assets/forest_room2_section8_upper_props.png")
const LOWER_PROPS=preload("res://assets/forest_room2_section8_lower_props.png")
const LOW_PROPS=preload("res://assets/forest_room2_section8_low_props.png")
const MIDDLE_PROPS=preload("res://assets/forest_room2_section8_middle_props.png")
const FOUNDATION=preload("res://assets/forest_room2_sections45678910_foundation.png")
const FOUNDATION_SHADER=preload("res://assets/forest_connected_foundation.gdshader")
var drop_platform: StaticBody2D

func _ready() -> void:
	name="ForestRoom2Sections8"
	# Registered lower hall remains at its native scale. Its ceiling meets the
	# finite upper foundation; recessed arches never acquire terrain collision.
	var backdrop:=_painting(LAYOUT.rectangle(Rect2(NEXT.LOWER_ORIGIN,NEXT.LOWER_SIZE)),LAYOUT.rectangle(Rect2(0,0,2048,768)),JOINED_LOWER,"LowerHallScenery",-94)
	backdrop.modulate=Color(0.72,0.8,0.9)
	var polygons:=LAYOUT.solid_polygons()
	for i in polygons.size():
		var body:=StaticBody2D.new()
		body.name=["UpperFloor","LowerFloor","LowerLeftWall","UpperLeftEnclosure"][i] if i<4 else "UpperLedge%d"%(i-4) if i<7 else "ReturnLedge%d"%(i-7)
		var shape:=CollisionPolygon2D.new()
		shape.polygon=polygons[i]
		body.add_child(shape)
		add_child(body)
		var uv:=PackedVector2Array()
		var art: Texture2D=UPPER if i==0 or i==3 or i>=4 else LOWER
		for vertex in polygons[i]:
			if i<4: uv.append((vertex-(LAYOUT.UPPER_ORIGIN if i==0 or i==3 else LAYOUT.LOWER_ORIGIN))/LAYOUT.SCALE)
			else:
				var target: Rect2=LAYOUT.CAPS[i-4] if i<7 else LAYOUT.return_cap(i-7)
				var source: Rect2=LAYOUT.UPPER_SOURCE[i-4] if i<7 else LAYOUT.UPPER_SOURCE[2]
				uv.append(source.position+(vertex-target.position)/target.size*source.size)
		var terrain:=_painting(polygons[i],uv,art,"RegisteredTerrain%d"%i,-85)
		if i in [1,3]:
			var material:=ShaderMaterial.new()
			material.shader=FOUNDATION_SHADER
			material.set_shader_parameter("foundation",FOUNDATION)
			material.set_shader_parameter("preserve_growth",i==1)
			terrain.material=material
		if i>=4:
			var target: Rect2=LAYOUT.CAPS[i-4] if i<7 else LAYOUT.return_cap(i-7)
			if i>=6:
				# Measured isolated extraction anchor; no source-floor foliage is reused.
				_add_props(Rect2(1040,600,390,250),Rect2(1060,675,350,65),target,LOW_PROPS)
			elif i==5:
				# This isolated extraction changed canvas size: register its measured
				# moss anchor and uniform scale, never assume original source pixels.
				_add_props(Rect2(0,0,1926,816),Rect2(126,380,1674,target.size.y*1674/target.size.x),target,MIDDLE_PROPS)
			else:
				var source: Rect2=LAYOUT.UPPER_SOURCE[i-4]
				_add_props(Rect2(315,210,1133,270),source,target,PROPS)
	# Scenery belongs to its cap, never the obsolete source location of a moved ledge.
	for region in [Rect2(0,735,330,351),Rect2(330,790,770,296),Rect2(1100,805,280,281),Rect2(1380,735,68,351)]:
		_add_props(region,Rect2(Vector2.ZERO,Vector2(1448,1086)),Rect2(LAYOUT.UPPER_ORIGIN-Vector2(0,3*LAYOUT.SCALE),Vector2(1448,1086)*LAYOUT.SCALE),PROPS)
	for region in [Rect2(0,0,340,650),Rect2(340,0,110,240)]:
		_add_props(region,Rect2(Vector2.ZERO,Vector2(1448,1086)),Rect2(LAYOUT.UPPER_ORIGIN,Vector2(1448,1086)*LAYOUT.SCALE),PROPS)
	# Floor foliage now belongs to the joined three-hall painting.
	drop_platform=StaticBody2D.new()
	drop_platform.name="PurpleDropFloor"
	var collision:=CollisionShape2D.new()
	var shape:=RectangleShape2D.new()
	shape.size=LAYOUT.DROP.size
	collision.shape=shape
	collision.position=LAYOUT.DROP.get_center()
	collision.one_way_collision=true
	collision.one_way_collision_margin=1.0
	drop_platform.add_child(collision)
	add_child(drop_platform)
	var enemy_body := StaticBody2D.new()
	enemy_body.name = "EnemyPurpleDropBlocker"
	enemy_body.collision_layer = 4
	enemy_body.collision_mask = 0
	var enemy_col := CollisionShape2D.new()
	enemy_col.shape = shape
	enemy_col.position = LAYOUT.DROP.get_center()
	enemy_body.add_child(enemy_col)
	add_child(enemy_body)
	var uv:=PackedVector2Array()
	for v in LAYOUT.rectangle(LAYOUT.DROP): uv.append((v-LAYOUT.UPPER_ORIGIN)/LAYOUT.SCALE)
	_painting(LAYOUT.rectangle(LAYOUT.DROP),uv,UPPER,"PurpleDropTerrain",-85)
	queue_redraw()

func _painting(polygon: PackedVector2Array,uv: PackedVector2Array,art: Texture2D,label: String,depth: int) -> Polygon2D:
	var painting:=Polygon2D.new()
	painting.name=label
	painting.polygon=polygon
	painting.uv=uv
	painting.texture=art
	painting.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	painting.z_index=depth
	add_child(painting)
	return painting

func _add_props(region: Rect2,source: Rect2,target: Rect2,texture: Texture2D) -> void:
	var uv:=LAYOUT.rectangle(region)
	var polygon:=PackedVector2Array()
	for v in uv: polygon.append(target.position+(v-source.position)/source.size*target.size)
	var painting:=_painting(polygon,uv,texture,"AttachedScenery",-84)
	if texture==PROPS: return # This extraction has real alpha; preserve bright cores.
	var material:=ShaderMaterial.new()
	material.shader=preload("res://assets/forest_section7_prop_cutout.gdshader")
	painting.material=material

func _draw() -> void:
	# Violet inlay marks one-way support, distinct from amber fractured smash stone.
	var panel: Rect2=LAYOUT.DROP
	draw_line(panel.position+Vector2(3,3),panel.position+Vector2(panel.size.x-3,3),Color("b9a5ef"),2)
	for offset in [55.0,205.0]:
		var p:=panel.position+Vector2(offset,5)
		draw_polyline(PackedVector2Array([p+Vector2(-5,0),p+Vector2(0,4),p+Vector2(5,0)]),Color("9f83d7"),2)
