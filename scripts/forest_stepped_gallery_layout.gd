extends RefCounted

const SOURCE_SIZE:=Vector2(1261,1247)
const SCALE:=1200.0/1261.0
const FLOOR:=759.0
const EXIT_Y:=preload("res://scripts/forest_smash_corridor_layout.gd").EXIT_Y
const ORIGIN:=Vector2(9000,EXIT_Y-FLOOR*SCALE)
const ART_EXTENT:=Rect2(ORIGIN,SOURCE_SIZE*SCALE)
const CAPS:=[Rect2(192,662,232,97),Rect2(474,457,279,56),Rect2(866,326,382,56)]

static func offset(index: int) -> Vector2:
	if index==0: return Vector2.ZERO
	var lower_y:=point(CAPS[0].position).y
	return Vector2(0,lower_y-112.0*index-point(CAPS[index].position).y)

static func point(native: Vector2,index: int=-1) -> Vector2:
	return ORIGIN+native*SCALE+(offset(index) if index>=0 else Vector2.ZERO)

static func cap(index: int) -> Rect2:
	return Rect2(point(CAPS[index].position,index),CAPS[index].size*SCALE)

static func native_polygons() -> Array[PackedVector2Array]:
	return [PackedVector2Array([Vector2(192,668),Vector2(198,662),Vector2(419,662),Vector2(424,668),Vector2(424,759),Vector2(192,759)]),
		PackedVector2Array([Vector2(474,464),Vector2(480,457),Vector2(747,457),Vector2(753,464),Vector2(753,501),Vector2(740,513),Vector2(487,513),Vector2(474,501)]),
		PackedVector2Array([Vector2(866,333),Vector2(873,326),Vector2(1241,326),Vector2(1248,333),Vector2(1248,370),Vector2(1235,382),Vector2(879,382),Vector2(866,370)]),
		PackedVector2Array([Vector2(0,FLOOR),Vector2(SOURCE_SIZE.x,FLOOR),SOURCE_SIZE,Vector2(0,SOURCE_SIZE.y)])]

static func solid_polygons() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array]=[]
	var native:=native_polygons()
	for i in native.size():
		var polygon:=PackedVector2Array()
		for vertex in native[i]: polygon.append(point(vertex,i if i<3 else -1))
		result.append(polygon)
	return result
