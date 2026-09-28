extends RefCounted

# Native coordinates of the inspected, character-free Room 2 painting.
const WIDTH:=1400.0
const SOURCE_SIZE:=Vector2(1307,1203)
const SCALE:=WIDTH/SOURCE_SIZE.x
const FLOOR:=831.0
const ORIGIN:=Vector2(3600,600-FLOOR*SCALE)
const ART_EXTENT:=Rect2(ORIGIN,SOURCE_SIZE*SCALE)
const CAMERA_TOP:=ceili(ORIGIN.y)

static func point(native: Vector2) -> Vector2:
	return ORIGIN+native*SCALE

# Each bracket is a small visible masonry ledge. Native top coordinates are kept
# alongside the painted caps so art, physics and route tests share registration.
static func added_steps() -> Array[Rect2]:
	return [
		Rect2(465,750,78,26),  # climb beside the left balcony's eastern edge
		Rect2(418,671,70,24),  # clear of the solid balcony underside
		Rect2(409,534,71,29),  # west tower bracket
		Rect2(930,542,66,27),  # east tower bracket, attached to its masonry pier
		Rect2(839,671,67,24),  # climb beside the right balcony's western edge
		Rect2(785,750,78,26),  # right ground approach
	]

static func step_polygon(ledge: Rect2) -> PackedVector2Array:
	var x:=ledge.position.x
	var y:=ledge.position.y
	var w:=ledge.size.x
	var h:=ledge.size.y
	return PackedVector2Array([
		Vector2(x+3,y),Vector2(x+w-3,y),Vector2(x+w,y+4),
		Vector2(x+w-2,y+h-7),Vector2(x+w-10,y+h-7),
		Vector2(x+w-10,y+h),Vector2(x+13,y+h),
		Vector2(x+13,y+h-5),Vector2(x+3,y+h-5),Vector2(x,y+7)])

static func existing_minor_caps() -> Array[Rect2]:
	return [
		Rect2(382,462,70,20), # masonry nub west of the banner tower
		Rect2(849,514,99,22), # crystal ledge east of the banner tower
	]

static func source_solids() -> Array[PackedVector2Array]:
	# Arches, banners, plants and piers are recessed scenery. Only the masonry
	# caps are supports; their undersides exclude hanging roots and open arches.
	var solids: Array[PackedVector2Array]=[
		PackedVector2Array([Vector2(0,FLOOR),Vector2(1307,FLOOR),Vector2(1307,1203),Vector2(0,1203)]),
		PackedVector2Array([Vector2(96,613),Vector2(415,613),Vector2(415,640),Vector2(403,640),Vector2(403,655),Vector2(386,655),Vector2(386,666),Vector2(124,666),Vector2(124,651),Vector2(108,651),Vector2(108,635),Vector2(96,635)]),
		PackedVector2Array([Vector2(489,467),Vector2(819,467),Vector2(819,493),Vector2(809,493),Vector2(809,516),Vector2(796,516),Vector2(796,532),Vector2(515,532),Vector2(515,516),Vector2(503,516),Vector2(503,493),Vector2(489,493)]),
		PackedVector2Array([Vector2(914,613),Vector2(1214,613),Vector2(1214,638),Vector2(1201,638),Vector2(1201,652),Vector2(1189,652),Vector2(1189,666),Vector2(940,666),Vector2(940,652),Vector2(927,652),Vector2(927,636),Vector2(914,636)])
	]
	for ledge in added_steps():
		solids.append(step_polygon(ledge))
	for ledge in existing_minor_caps():
		solids.append(PackedVector2Array([ledge.position,Vector2(ledge.end.x,ledge.position.y),ledge.end,Vector2(ledge.position.x,ledge.end.y)]))
	return solids

static func polygons() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array]=[]
	for native in source_solids():
		var polygon:=PackedVector2Array()
		for vertex in native: polygon.append(point(vertex))
		result.append(polygon)
	return result
