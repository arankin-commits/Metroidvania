extends RefCounted

# Four supplied ledges only. Architecture and vines are recessed scenery.
const SOURCE_SIZE:=Vector2(1079,1457)
const SCALE:=1000.0/1079.0
const FLOOR:=846.0
const ENTRY_Y:=preload("res://scripts/forest_stair_layout.gd").EXIT_FLOOR_Y
const ORIGIN:=Vector2(6800,ENTRY_Y-FLOOR*SCALE)
const ART_EXTENT:=Rect2(ORIGIN,SOURCE_SIZE*SCALE)
const EXIT_Y:=ORIGIN.y+468*SCALE
const CAMERA_TOP:=-620

static func point(native: Vector2) -> Vector2:
	return ORIGIN+native*SCALE

static func ledges() -> Array[Rect2]:
	# Only actual stone caps are solid; hanging foliage is excluded.
	return [Rect2(944,750,93,33),Rect2(215,664,666,39),
		Rect2(212,574,155,33),Rect2(408,468,671,29)]

static func solid_polygons() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array]=[]
	for native in [
		PackedVector2Array([Vector2(944,750),Vector2(1037,750),Vector2(1044,758),Vector2(1036,781),Vector2(1010,799),Vector2(972,799),Vector2(951,779)]),
		PackedVector2Array([Vector2(215,664),Vector2(881,664),Vector2(881,675),Vector2(870,694),Vector2(235,703),Vector2(218,684)]),
		PackedVector2Array([Vector2(212,574),Vector2(367,574),Vector2(377,582),Vector2(367,597),Vector2(351,607),Vector2(232,607),Vector2(217,595)]),
		PackedVector2Array([Vector2(408,468),Vector2(1079,468),Vector2(1079,497),Vector2(427,497),Vector2(410,487)])]:
		var polygon:=PackedVector2Array()
		for vertex in native: polygon.append(point(vertex))
		result.append(polygon)
	for rect in [Rect2(0,FLOOR,1079,611),Rect2(1051,468,28,FLOOR-468)]:
		result.append(PackedVector2Array([point(rect.position),point(rect.position+Vector2(rect.size.x,0)),point(rect.end),point(rect.position+Vector2(0,rect.size.y))]))
	return result
