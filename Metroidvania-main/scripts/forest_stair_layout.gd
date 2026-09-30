extends RefCounted

# Section 2 belongs to Forest Room 2. Its painted stair is the only playable
# route; the arches and apparent ledges below and above it are recessed scenery.
const SOURCE_SIZE:=Vector2(1672,941)
const SCALE:=Vector2(1800.0/1672.0,890.0/795.0)
const ORIGIN:=Vector2(5000,-290)
const ART_SIZE:=Vector2(2172,724)
const ART_SCALE:=Vector2(13000.0/2172.0,2250.0/724.0)
const ART_ORIGIN:=Vector2(5000,-950)
const ART_EXTENT:=Rect2(ART_ORIGIN,ART_SIZE*ART_SCALE)
const EXIT_FLOOR_Y:=ORIGIN.y+404*SCALE.y

static func point(source: Vector2) -> Vector2:
	return ORIGIN+source*SCALE

static func stair_top() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0,795),Vector2(304,795),
		Vector2(330,778),Vector2(350,778),Vector2(375,761),
		Vector2(401,745),Vector2(430,729),Vector2(459,715),
		Vector2(489,700),Vector2(520,684),Vector2(560,655),
		Vector2(780,655),
		Vector2(802,636),Vector2(830,618),Vector2(860,602),
		Vector2(890,577),Vector2(950,521),
		Vector2(1190,521),
		Vector2(1250,471),Vector2(1300,438),Vector2(1380,404),
		Vector2(1672,404)])

static func solid_polygon() -> PackedVector2Array:
	var result:=PackedVector2Array()
	for vertex in stair_top():
		result.append(point(vertex))
	# The shared camera now sees the lower hall: continue stair mass below every
	# earlier ground view rather than exposing its old bitmap-bottom cutoff.
	result.append(point(Vector2(1672,1450)))
	result.append(point(Vector2(0,1450)))
	return result

static func surface_y(world_x: float) -> float:
	var path:=stair_top()
	var native_x: float=(world_x-ORIGIN.x)/SCALE.x
	for i in range(path.size()-1):
		if native_x<=path[i+1].x:
			return point(Vector2(native_x,lerpf(path[i].y,path[i+1].y,(native_x-path[i].x)/(path[i+1].x-path[i].x)))).y
	return EXIT_FLOOR_Y
