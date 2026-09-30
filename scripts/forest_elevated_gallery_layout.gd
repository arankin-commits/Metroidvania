extends RefCounted

const SOURCE_SIZE:=Vector2(1448,1086)
const SCALE:=1200.0/1448.0
const FLOOR:=885.0
const PREVIOUS=preload("res://scripts/forest_stepped_gallery_layout.gd")
const EXIT_Y:=PREVIOUS.EXIT_Y
const ORIGIN:=Vector2(10200,EXIT_Y-FLOOR*SCALE)
const CAPS:=[Rect2(48,315,401,79),Rect2(563,495,322,79),Rect2(1000,315,384,79)]
const ENTRY_RISE:=96.0

static func offset(index: int) -> Vector2:
	var target:=PREVIOUS.cap(2).position.y-ENTRY_RISE+(112.0 if index==1 else 0.0)
	return Vector2(0,target-(ORIGIN.y+CAPS[index].position.y*SCALE))

static func point(native: Vector2,index: int=-1) -> Vector2:
	return ORIGIN+native*SCALE+(offset(index) if index>=0 else Vector2.ZERO)

static func cap(index: int) -> Rect2:
	return Rect2(point(CAPS[index].position,index),CAPS[index].size*SCALE)

static func native_polygons() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array]=[]
	for c in CAPS:
		result.append(PackedVector2Array([c.position+Vector2(7,0),Vector2(c.end.x-7,c.position.y),Vector2(c.end.x,c.position.y+7),c.end-Vector2(0,7),c.end-Vector2(10,0),Vector2(c.position.x+10,c.end.y),Vector2(c.position.x,c.end.y-7),c.position+Vector2(0,7)]))
	result.append(PackedVector2Array([Vector2(0,FLOOR),Vector2(SOURCE_SIZE.x,FLOOR),Vector2(SOURCE_SIZE.x,1700),Vector2(0,1700)]))
	return result

static func solid_polygons() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array]=[]
	var native:=native_polygons()
	for i in native.size():
		var polygon:=PackedVector2Array()
		for vertex in native[i]: polygon.append(point(vertex,i if i<3 else -1))
		result.append(polygon)
	return result
