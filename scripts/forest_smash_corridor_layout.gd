extends RefCounted

# Section 4 is a continuous ground corridor, not a new room.
const SOURCE_SIZE:=Vector2(1276,1233)
const SCALE:=1200.0/1276.0
const FLOOR:=707.0
const EXIT_Y:=preload("res://scripts/forest_upper_gallery_layout.gd").ENTRY_Y
const ORIGIN:=Vector2(7800,EXIT_Y-FLOOR*SCALE)
const ART_EXTENT:=Rect2(ORIGIN,SOURCE_SIZE*SCALE)
const CAMERA_TOP:=-760
const FUTURE_FLOOR:=Rect2(60,FLOOR,185,SOURCE_SIZE.y-FLOOR)

static func point(native: Vector2) -> Vector2:
	return ORIGIN+native*SCALE

static func ground_top() -> PackedVector2Array:
	return PackedVector2Array([Vector2(0,707),Vector2(480,707),
		Vector2(490,691),Vector2(505,677),Vector2(530,661),Vector2(555,652),
		Vector2(580,646),Vector2(630,643),Vector2(700,643),Vector2(760,648),
		Vector2(810,655),Vector2(850,668),Vector2(890,690),Vector2(910,707),Vector2(1276,707)])

static func surface_y(x: float) -> float:
	var native_x:=clampf((x-ORIGIN.x)/SCALE,0,SOURCE_SIZE.x)
	var top:=ground_top()
	for i in range(1,top.size()):
		if native_x<=top[i].x:
			return point(Vector2(native_x,lerpf(top[i-1].y,top[i].y,(native_x-top[i-1].x)/(top[i].x-top[i-1].x)))).y
	return EXIT_Y

static func solid_polygons() -> Array[PackedVector2Array]:
	# Separate the future seal without giving current attacks any opening behavior.
	var remaining:=PackedVector2Array([Vector2(245,FLOOR)])
	for vertex in ground_top():
		if vertex.x>245: remaining.append(vertex)
	remaining.append(Vector2(SOURCE_SIZE.x,SOURCE_SIZE.y))
	remaining.append(Vector2(245,SOURCE_SIZE.y))
	var result: Array[PackedVector2Array]=[]
	for native in [PackedVector2Array([Vector2(0,FLOOR),Vector2(60,FLOOR),Vector2(60,SOURCE_SIZE.y),Vector2(0,SOURCE_SIZE.y)]),
		PackedVector2Array([FUTURE_FLOOR.position,Vector2(FUTURE_FLOOR.end.x,FLOOR),FUTURE_FLOOR.end,Vector2(60,SOURCE_SIZE.y)]),remaining]:
		var polygon:=PackedVector2Array()
		for vertex in native: polygon.append(point(vertex))
		result.append(polygon)
	return result
