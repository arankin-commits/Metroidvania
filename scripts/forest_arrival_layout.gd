extends RefCounted

# Three supplied sections form one room; registration owns art and collision.
const SOURCE_SIZE := Vector2(1672,941)
const SCALE := 1200.0/1672.0
const ORIGIN := Vector2(0,-40)
const SECTION2_ORIGIN := Vector2(1200,-40-262*SCALE)
const SECTION3_ORIGIN := Vector2(2400,SECTION2_ORIGIN.y-70*SCALE)
const EXTENT := Rect2(Vector2(0,SECTION3_ORIGIN.y),Vector2(3600,1273*SCALE))
const CAMERA_TOP := -620
const ART_EXTENT := Rect2(Vector2(0,SECTION3_ORIGIN.y-600*SCALE),Vector2(3600,1873*SCALE))
const ENTRY_SOURCE := Vector2(168,578)
const RETURN_SOURCE := Vector2(1560,565)

static func point(p: Vector2) -> Vector2:
	return ORIGIN+p*SCALE

static func section2_point(p: Vector2) -> Vector2:
	return SECTION2_ORIGIN+p*SCALE

static func section3_point(p: Vector2) -> Vector2:
	return SECTION3_ORIGIN+p*SCALE

static func entry() -> Vector2:
	return point(ENTRY_SOURCE)-Vector2(0,27)

static func receiving(x: float) -> Vector2:
	return Vector2(x,section3_point(RETURN_SOURCE).y-27) if x>3000 else entry()

static func source_solids() -> Array[PackedVector2Array]:
	return [
		# Raised arrival shelf: its weathered supporting pier encloses the grotto.
		PackedVector2Array([Vector2(-96,578),Vector2(648,578),Vector2(648,817),Vector2(610,817),Vector2(610,618),Vector2(-96,618)]),
		# Continuous lower floor, with the upper-right exit embedded in its mass.
		PackedVector2Array([Vector2(0,817),Vector2(648,817),Vector2(648,781),Vector2(1332,781),Vector2(1332,704),Vector2(1530,704),Vector2(1530,416),Vector2(1672,416),Vector2(1672,1041),Vector2(0,1041)]),
		# Authored steps trace the foreground masonry, not the distant bridge.
		PackedVector2Array([Vector2(1006,745),Vector2(1074,745),Vector2(1074,722),Vector2(1140,722),Vector2(1140,697),Vector2(1204,697),Vector2(1204,671),Vector2(1304,671),Vector2(1304,608),Vector2(1390,608),Vector2(1390,596),Vector2(1530,596),Vector2(1530,704),Vector2(1332,704),Vector2(1332,781),Vector2(1006,781)]),
		# Only the thick canopy frame is solid; slender vines and arches are scenery.
		PackedVector2Array([Vector2(-96,-400),Vector2(1672,-400),Vector2(1672,24),Vector2(1610,24),Vector2(1510,12),Vector2(1370,12),Vector2(1270,48),Vector2(1150,36),Vector2(1020,20),Vector2(900,42),Vector2(760,48),Vector2(650,104),Vector2(530,36),Vector2(350,36),Vector2(180,24),Vector2(80,84),Vector2(-96,100)]),
		# Left return doorway is above the lower grotto; both entrances are safe.
		PackedVector2Array([Vector2(-96,90),Vector2(0,90),Vector2(0,450),Vector2(-96,450)]),
		PackedVector2Array([Vector2(-96,618),Vector2(0,618),Vector2(0,1041),Vector2(-96,1041)]),
	]

static func section2_solids() -> Array[PackedVector2Array]:
	# Main moss crest is continuous masonry; lower relief is its supporting facade.
	return [PackedVector2Array([
		Vector2(0,678),Vector2(290,678),Vector2(290,640),Vector2(340,640),Vector2(340,611),
		Vector2(615,611),Vector2(615,585),Vector2(718,585),Vector2(718,561),
		Vector2(872,561),Vector2(872,510),Vector2(906,510),Vector2(906,489),
		Vector2(1030,489),Vector2(1030,463),Vector2(1080,463),Vector2(1080,453),
		Vector2(1135,453),Vector2(1135,426),Vector2(1318,426),Vector2(1318,376),
		Vector2(1344,376),Vector2(1344,357),Vector2(1450,357),Vector2(1450,345),
		Vector2(1672,345),Vector2(1672,1300),Vector2(0,1300)]),
		PackedVector2Array([Vector2(0,-100),Vector2(1768,-100),Vector2(1768,80),
		Vector2(1530,54),Vector2(1390,34),Vector2(1240,76),Vector2(1020,12),
		Vector2(860,10),Vector2(720,0),Vector2(630,0),Vector2(530,28),Vector2(380,0),Vector2(0,0)])]

static func section3_solids() -> Array[PackedVector2Array]:
	return [
		# Basin and foundations keep every descent physically contained.
		PackedVector2Array([Vector2(0,730),Vector2(340,730),Vector2(340,752),Vector2(936,752),Vector2(936,807),Vector2(1154,807),Vector2(1154,778),Vector2(1490,778),Vector2(1490,565),Vector2(1672,565),Vector2(1672,1400),Vector2(0,1400)]),
		# Supporting cap only; recessed roots beneath it leave the lower approach open.
		PackedVector2Array([Vector2(0,415),Vector2(100,415),Vector2(260,434),Vector2(340,434),Vector2(340,474),Vector2(260,474),Vector2(100,455),Vector2(0,455)]),
		# The left shelf's stone narrows beneath its cap; hanging roots are scenery.
		# Never extend the cap's right edge vertically through the lower approach.
		PackedVector2Array([Vector2(310,603),Vector2(530,603),Vector2(530,624),
			Vector2(518,644),Vector2(509,675),Vector2(497,703),Vector2(486,731),
			Vector2(475,752),Vector2(310,752)]),
		# Trace the tapering stone side, leaving the recessed root pocket accessible.
		PackedVector2Array([Vector2(830,569),Vector2(1130,569),Vector2(1130,807),Vector2(936,807),Vector2(900,750),Vector2(870,705),Vector2(848,635),Vector2(830,620)]),
		# Attached return tread painted into the central pillar's right foot.
		PackedVector2Array([Vector2(1130,676),Vector2(1210,676),Vector2(1210,807),Vector2(1130,807)]),
		# Only the cap and narrow right masonry pier are solid. Hanging plants
		# beneath the cap are recessed scenery, not a broad supporting wall.
		PackedVector2Array([Vector2(1060,425),Vector2(1370,425),Vector2(1370,590),Vector2(1320,590),Vector2(1320,480),Vector2(1060,480)]),
		# Recessed spire and arch masonry are background. Only the moss crown supports feet.
		PackedVector2Array([Vector2(1334,234),Vector2(1628,234),Vector2(1628,280),Vector2(1334,280)]),
		# Thin outer canopy stays above the complete threshold jump arc.
		# Near trunk branches are scenery and must not conceal a collision barrier.
		PackedVector2Array([Vector2(0,-100),Vector2(1672,-100),Vector2(1672,0),Vector2(0,0)]),
	]

static func polygons() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array]=[]
	for source in source_solids():
		var transformed:=PackedVector2Array()
		for p in source: transformed.append(point(p))
		result.append(transformed)
	for source in section2_solids():
		var transformed:=PackedVector2Array()
		for p in source: transformed.append(section2_point(p))
		result.append(transformed)
	for source in section3_solids():
		var transformed:=PackedVector2Array()
		for p in source: transformed.append(section3_point(p))
		result.append(transformed)
	return result

static func walkable_surfaces() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array]=[]
	for source: PackedVector2Array in source_solids().slice(0,3):
		for i in source.size()-1:
			var a: Vector2=source[i]
			var b: Vector2=source[i+1]
			if a.y==817 and b.y==817: continue
			if is_equal_approx(a.y,b.y) and b.x>a.x:
				result.append(PackedVector2Array([point(a),point(b)]))
	var crest:=section2_solids()[0]
	for i in crest.size()-1:
		if is_equal_approx(crest[i].y,crest[i+1].y) and crest[i+1].x>crest[i].x:
			result.append(PackedVector2Array([section2_point(crest[i]),section2_point(crest[i+1])]))
	for solid in section3_solids().slice(0,7):
		for i in solid.size()-1:
			if is_equal_approx(solid[i].y,solid[i+1].y) and solid[i+1].x>solid[i].x:
				result.append(PackedVector2Array([section3_point(solid[i]),section3_point(solid[i+1])]))
	return result

static func map_outline() -> PackedVector2Array:
	# Subtract the authored solids, then retain the connected arrival chamber.
	# The dark grotto beneath the shelf is scenery, not an explored route.
	var voids: Array[PackedVector2Array]=[PackedVector2Array([
		EXTENT.position,Vector2(EXTENT.end.x,EXTENT.position.y),EXTENT.end,Vector2(EXTENT.position.x,EXTENT.end.y)])]
	for solid in polygons():
		var next: Array[PackedVector2Array]=[]
		for chamber in voids:
			next.append_array(Geometry2D.clip_polygons(chamber,solid))
		voids=next
	for chamber in voids:
		if Geometry2D.is_point_in_polygon(entry(),chamber): return chamber
	return PackedVector2Array()
