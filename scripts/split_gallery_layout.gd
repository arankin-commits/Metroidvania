extends RefCounted

# Room-local coordinates. Other cave rooms keep their original geometry and spawns.
const EXTENT := Rect2(-600, -1900, 5640, 3750)
const ENTRANCE := Vector2(80, 1473)
const START := Vector2(120, 1473)
const EXIT := Vector2(4920, -1527)
const ENTRANCE_DOOR := Rect2(-80, 1290, 100, 210)
const HEAVY_WALL := Rect2(4660, -1500, 48, 300)
const SMASH_FLOOR := Rect2(3540, 945, 240, 48)
const FUTURE_CHAMBER := Rect2(3260, 993, 960, 387)
const EXIT_DOOR := Rect2(5000, -1770, 80, 270)
const SEAL := Rect2(4980, -1770, 32, 270)
const SENTINEL := Vector2(1058, 1385)
const SIGIL := Vector2(-300, -777)
const OFFERING := Vector2(600, -1602)
const SCOUT := Vector2(3500, 924)
const DROP := Rect2(3700, 0, 100, 24)
const WEST_GATE := Rect2(1260, 870, 32, 180)
const EAST_GATE := Rect2(3900, -80, 100, 200)
const WEST_WINCH := Vector2(1450, 1009)
const EAST_WINCH := Vector2(4510, 409)
static var _rock_cache: Array[Rect2] = []
static var map_cells: Dictionary = {}
static var _foundation_cache: Array[Rect2] = []
static var _map_synced := false

# Each route is a distinct stone gallery. Links share endpoints, so returns do not
# depend on a jump that works only in the first-visit direction.
static func routes() -> Dictionary:
	return {
		"balcony_ascent": PackedVector2Array([Vector2(1160,1410),Vector2(1410,1230),Vector2(1640,1230),Vector2(1880,1050),Vector2(2100,900)]),
		"chain_well": PackedVector2Array([Vector2(2100,900),Vector2(2440,675),Vector2(2040,675),Vector2(1740,450),Vector2(2140,450),Vector2(2440,225),Vector2(2040,225),Vector2(1740,0),Vector2(2100,0), Vector2(2440, -225), Vector2(2040, -225), Vector2(1740, -450), Vector2(2140, -450), Vector2(2440, -675), Vector2(2040, -675), Vector2(1740, -900), Vector2(2200, -900)]),
		"sigil_gallery": PackedVector2Array([Vector2(2140, -450), Vector2(1350, -450), Vector2(1050, -525), Vector2(650, -525), Vector2(450, -675), Vector2(-50, -675), Vector2(-350, -750)]),
		"sigil_perch": PackedVector2Array([Vector2(-460, -750), Vector2(-350, -750)]),
		"memorial_return": PackedVector2Array([Vector2(-550, -525), Vector2(-100, -525), Vector2(200, -300), Vector2(550, -300), Vector2(850, -75), Vector2(1150, -75), Vector2(1420, 120), Vector2(1600, 120)]),
		"offering_ascent": PackedVector2Array([Vector2(1740, -900), Vector2(1440, -1125), Vector2(1300, -1125), Vector2(950, -1350), Vector2(350, -1350), Vector2(50, -1575), Vector2(600, -1575), Vector2(1100, -1575)]),
		"crown_walk": PackedVector2Array([Vector2(1100, -1575), Vector2(1600, -1575), Vector2(1900, -1500), Vector2(2200, -1500), Vector2(2500, -1275), Vector2(3100, -1275), Vector2(3400, -1500), Vector2(3850, -1500)]),
		"east_brow": PackedVector2Array([Vector2(3850,-1500),Vector2(4180,-1350),Vector2(4380,-1200),Vector2(4580,-1200)]),
		"eastern_overlook": PackedVector2Array([Vector2(4550,-975),Vector2(4420,-975),Vector2(4120,-750),Vector2(3950,-750),Vector2(3650,-525),Vector2(3400,-525)]),
		"east_gallery": PackedVector2Array([Vector2(2440, -225), Vector2(2700, 0), Vector2(3150, 0), Vector2(3350, -75), Vector2(3550, -75), Vector2(3700, 0)]),
		"undercroft": PackedVector2Array([Vector2(3540,945),Vector2(3200,945),Vector2(2900,1050),Vector2(2700,1050),Vector2(2500,900)]),
		"floor_approach": PackedVector2Array([Vector2(3780,945),Vector2(3820,945),Vector2(3900,900)]),
		"fallen_return": PackedVector2Array([Vector2(1050,1050),Vector2(750,825),Vector2(1050,825),Vector2(1350,600),Vector2(1550,600),Vector2(1740,450)]),
		"foundation_link": PackedVector2Array([Vector2(1450,1050),Vector2(1880,1050)]),
		"west_shortcut": PackedVector2Array([Vector2(1050,1050),Vector2(1450,1050)]),
		"east_ascent": PackedVector2Array([Vector2(3900,900),Vector2(4100,900),Vector2(4350,675),Vector2(4580,675)]),
		"east_shortcut": PackedVector2Array([Vector2(3900,120),Vector2(4000,120),Vector2(4480,450),Vector2(4580,450)]),
		"crown_lip": PackedVector2Array([Vector2(3850,-1500),Vector2(4120,-1500)]),
		"seal_floor": PackedVector2Array([Vector2(4270,-1500),Vector2(5040,-1500)]),
		"heavy_mouth": PackedVector2Array([Vector2(4580,-1200),Vector2(4820,-1200)]),
		"basal_return": PackedVector2Array([Vector2(700,1650),Vector2(4940,1650)]),
	}

# Combat islands have clear approaches and quiet rewards/landing zones between them.
# Existing entrance sentinel and undercroft scout are owned by tutorial_world.
static func encounters() -> Array[Dictionary]:
	return [
		# The 5 Goblin Spearmen at the authoritative Red X locations from screenshots:
		# 1. Screenshot 014541: Entrance floor (floor y=1500)
		{"id":"EntranceSpearman", "kind":"goblin_sentinel", "position":Vector2(320,1473), "patrol":Vector2(80,550)},
		# 2. Screenshot 014517: Ascent / Chain Well Approach (floor y=1230)
		{"id":"AscentSpearman", "kind":"goblin_sentinel", "position":Vector2(1530,1203), "patrol":Vector2(1420,1630)},
		# 3. Screenshot 014049: Seal Floor (floor y=-1500)
		{"id":"SealSpearman", "kind":"goblin_sentinel", "position":Vector2(4680,-1500), "patrol":Vector2(4300,4900)},
		# 4 & 5. Screenshot 014549: Crown Walk / Upper Gallery West & East (floor y=-1296)
		{"id":"CrownSpearmanWest", "kind":"goblin_sentinel", "position":Vector2(2550,-1296), "patrol":Vector2(2500,2750)},
		{"id":"CrownSpearmanEast", "kind":"goblin_sentinel", "position":Vector2(3050,-1296), "patrol":Vector2(2850,3100)},

		# Stationary sleeping goblins (kind: "sentinel" -> ledge_sentinel.gd playing "sleep"):
		{"id":"WellJunction", "kind":"sentinel", "position":Vector2(2220,-252)},
		{"id":"MemorialReturn", "kind":"sentinel", "position":Vector2(410,-327)},
		{"id":"CrownThreshold", "kind":"sentinel", "position":Vector2(1420,-1602)},
		{"id":"OverlookGuard", "kind":"sentinel", "position":Vector2(4050,-777)},
		{"id":"FallenGuard", "kind":"sentinel", "position":Vector2(2220,648)},
		{"id":"ReturnGuard", "kind":"sentinel", "position":Vector2(1450,573)},
		{"id":"WestWinchApproach", "kind":"sentinel", "position":Vector2(1670,1023)},
		{"id":"AscentGuard", "kind":"sentinel", "position":Vector2(4400,648)},

		# Patrol groups (roving zones):
		{"id":"EntrancePatrol", "kind":"scout", "position":Vector2(600,1473), "patrol":Vector2(450,700), "roster":["goblin"], "offsets":[0.0]},
		{"id":"SealPatrol", "kind":"scout", "position":Vector2(4900,-1500), "patrol":Vector2(4750,5000), "roster":["goblin_dog"], "offsets":[0.0]},
		{"id":"CrownPatrolDogs", "kind":"scout", "position":Vector2(2800,-1296), "patrol":Vector2(2650,2950), "roster":["goblin_dog","goblin_dog"], "offsets":[-60.0, 60.0]},
		{"id":"MemorialPatrol", "kind":"scout", "position":Vector2(800,-546), "patrol":Vector2(700,960), "roster":["goblin","goblin_dog"], "offsets":[-50.0, 50.0]},
		{"id":"OfferingApproach", "kind":"scout", "position":Vector2(650,-1371), "patrol":Vector2(450,850), "roster":["goblin","goblin_dog"], "offsets":[-55.0, 55.0]},
		{"id":"DropApproach", "kind":"scout", "position":Vector2(2920,-21), "patrol":Vector2(2760,3070), "roster":["goblin","goblin_dog"], "offsets":[-50.0, 50.0]},
		{"id":"FoundationPatrol", "kind":"scout", "position":Vector2(2800,1029), "patrol":Vector2(2730,2870), "roster":["goblin","goblin_dog"], "offsets":[-45.0, 45.0]},
		{"id":"FallenPatrol", "kind":"scout", "position":Vector2(2210,204), "patrol":Vector2(2120,2330), "roster":["goblin","goblin_dog","goblin_dog"], "offsets":[-75.0, 0.0, 75.0]},
		{"id":"DeepPatrol", "kind":"scout", "position":Vector2(2210,-696), "patrol":Vector2(2120,2330), "roster":["goblin","goblin","goblin_dog"], "offsets":[-75.0, 0.0, 75.0]},
	]

static func blocks() -> Array[Rect2]:
	return [
		Rect2(-80,1500,770,100),Rect2(840,1500,420,100),
		Rect2(380,1425,155,18),Rect2(1040,1410,120,90),
		Rect2(3800,0,100,120),
		Rect2(-984,-2284,384,4518),Rect2(-600,-2284,5984,384),
		Rect2(-600,1750,5984,484),
		Rect2(5000,-1900,384,130),Rect2(5000,-1500,384,3734),
		# Door tunnel is the only route across x=0 at its level.
		Rect2(-80,1150,360,140),
		# Service shaft has NO intermediate connections to the exploration network.
		Rect2(4600,-1200,108,2620),
		# Roof, sides and floor of the future pocket, with only one floor aperture.
		Rect2(3200,945,340,48),Rect2(3780,945,500,48),
		Rect2(3200,993,60,427),Rect2(4220,993,60,427),
		Rect2(3200,1380,1080,40),
	]

static func steps() -> Array[Rect2]:
	var result: Array[Rect2] = [
		Rect2(-545,-600,110,18),Rect2(-415,-675,110,18),
		Rect2(4380,-1050,120,18),Rect2(4510,-1125,120,18),
		Rect2(3480,-150,140,18),Rect2(3350,-225,140,18),
		Rect2(3480,-300,140,18),Rect2(3350,-375,140,18),Rect2(3480,-450,140,18),
		Rect2(4450,600,130,18),Rect2(4450,525,130,18),
		Rect2(1600,45,120,18),
		Rect2(720,1575,100,18),
		Rect2(4150,-1425,110,18),
		Rect2(2460,825,120,18),Rect2(2460,750,120,18),
	]
	# Paired footholds permit climbing back; the inner shaft lane stays clear for descent.
	for i in 37:
		result.append(Rect2(4708 if i%2==0 else 4810,-1125+i*75,115,18))
	# Reserved chamber: these ledges return through the SAME future opening.
	for i in 5:
		result.append(Rect2(3500 if i%2==0 else 3640,1305-i*75,120,18))
	return result

static func chambers() -> Array[Dictionary]:
	return [
		{"name":"BROKEN BALCONY","rect":Rect2(0,1110,1320,490)},
		{"name":"CHAIN WELL","rect":Rect2(1550,-1150,980,2290)},
		{"name":"MEMORIAL RECESS","rect":Rect2(-570,-980,1180,530)},
		{"name":"OFFERING GALLERIES","rect":Rect2(20,-1800,1200,650)},
		{"name":"EASTERN OVERLOOK","rect":Rect2(3320,-1290,1260,640)},
		{"name":"DROP BAY","rect":Rect2(3580,-160,320,1100)},
		{"name":"UNDERCROFT","rect":Rect2(2500,700,2080,390)},
		{"name":"FOUNDATION RETURN","rect":Rect2(850,370,920,740)},
		{"name":"EASTERN ASCENT","rect":Rect2(4100,390,480,580)},
		{"name":"SEAL VESTIBULE","rect":Rect2(4300,-1790,740,300)},
	]

# Each void is authored independently. Long ribs and irregular shoulders belong to
# the geology, never to a work-zone boundary. The raster shell and collision agree.
static func chamber_outlines() -> Array[PackedVector2Array]:
	return [
		PackedVector2Array([Vector2(-80,1290),Vector2(280,1290),Vector2(470,1170),Vector2(690,1150),Vector2(1080,1210),Vector2(1320,1360),Vector2(1300,1550),Vector2(0,1570)]),
		PackedVector2Array([Vector2(1570,-900),Vector2(1720,-1120),Vector2(2110,-1090),Vector2(2480,-830),Vector2(2570,-330),Vector2(2470,220),Vector2(2520,710),Vector2(2110,1120),Vector2(1700,1000),Vector2(1600,630),Vector2(1690,270),Vector2(1550,-140)]),
		PackedVector2Array([Vector2(-570,-760),Vector2(-450,-960),Vector2(-170,-980),Vector2(220,-840),Vector2(600,-620),Vector2(460,-470),Vector2(-540,-470)]),
		PackedVector2Array([Vector2(30,-1630),Vector2(160,-1800),Vector2(600,-1850),Vector2(1040,-1760),Vector2(1230,-1450),Vector2(1110,-1170),Vector2(350,-1240)]),
		PackedVector2Array([Vector2(3360,-980),Vector2(3650,-1190),Vector2(4220,-1290),Vector2(4580,-1120),Vector2(4530,-840),Vector2(4110,-680),Vector2(3520,-570)]),
		PackedVector2Array([Vector2(3580,-160),Vector2(3820,-160),Vector2(3890,280),Vector2(3850,660),Vector2(3920,940),Vector2(3580,940)]),
		PackedVector2Array([Vector2(2490,860),Vector2(2800,730),Vector2(3230,780),Vector2(3500,660),Vector2(3820,730),Vector2(4000,850),Vector2(3900,940),Vector2(3500,940),Vector2(3200,1090),Vector2(2700,1090)]),
		PackedVector2Array([Vector2(4310,-1710),Vector2(4520,-1810),Vector2(4800,-1770),Vector2(5040,-1770),Vector2(5040,-1500),Vector2(4350,-1460)]),
		PackedVector2Array([Vector2(4708,-1400),Vector2(4960,-1400),Vector2(4960,1650),Vector2(4708,1650)]),
		PackedVector2Array([Vector2(3260,993),Vector2(4220,993),Vector2(4220,1380),Vector2(3260,1380)]),
	]

static func enclosing_rock() -> Array[Rect2]:
	if not _rock_cache.is_empty():
		return _rock_cache
	var passages: Array[Dictionary] = []
	for route_name in routes():
		var route: PackedVector2Array = routes()[route_name]
		# Only intentional suspended galleries have air beneath their floors.
		var below := 100.0 if route_name in ["chain_well", "offering_ascent", "sigil_perch", "east_shortcut"] else 24.0
		for i in route.size()-1:
			passages.append({"a":route[i], "b":route[i+1], "below":below})
	var outlines := chamber_outlines()
	var step_clearings: Array[Rect2] = []
	for rect in steps():
		if FUTURE_CHAMBER.has_point(rect.position) or rect.position.x>=4708:
			continue
		step_clearings.append(Rect2(rect.position-Vector2(50,180),rect.size+Vector2(100,230)))
	step_clearings.append(ENTRANCE_DOOR)
	var rocks: Array[Rect2] = []
	var columns := {}
	for y in range(-1900,1750,64):
		var run_start := -1
		for column in range(89):
			var x := -600+column*64
			var free := column==88
			if not free:
				for offset: Vector2 in [Vector2.ZERO,Vector2(64,0),Vector2(0,64),Vector2(64,64)]:
					var p := Vector2(x,y)+offset
					for outline in outlines:
						if Geometry2D.is_point_in_polygon(p,outline):
							free = true
							break
					for clearing in step_clearings:
						if clearing.has_point(p):
							free = true
							break
					if free:
						break
					for passage in passages:
						var a: Vector2 = passage.a
						var b: Vector2 = passage.b
						if p.x>=minf(a.x,b.x)-80 and p.x<=maxf(a.x,b.x)+80:
							var floor_y := surface_y(a,b,p.x)
							if p.y>=floor_y-250 and p.y<=floor_y+float(passage.below):
								free = true
								break
					if free:
						break
			if not free and run_start<0:
				run_start=x
			if free and column<88:
				map_cells[Vector2i(x,y)] = true
			if free and run_start>=0:
				var key := Vector2i(run_start,x-run_start)
				if columns.has(key) and rocks[columns[key]].end.y==y:
					rocks[columns[key]].size.y+=64
				else:
					columns[key]=rocks.size()
					rocks.append(Rect2(run_start,y,x-run_start,64))
				run_start=-1
	_rock_cache=rocks
	return _rock_cache

# Only these suspended switchback floors deliberately connect to a lower gallery.
# Other horizontal floors, including the eastern receiving ledge, are solid.
static func drop_routes() -> Array[String]:
	return ["chain_well", "offering_ascent", "memorial_return", "sigil_gallery", "sigil_perch", "west_shortcut", "foundation_link", "crown_lip", "fallen_return", "east_brow", "east_shortcut"]

static func is_drop_segment(route_name: String,a: Vector2,b: Vector2) -> bool:
	if not is_equal_approx(a.y,b.y):
		return false
	return route_name in drop_routes() or (route_name=="undercroft" and a.y==1275) or (route_name=="eastern_overlook" and a.y==-525) or (route_name=="east_ascent" and a.y==675)

static func is_drop_step(rect: Rect2) -> bool:
	# Each staircase has a named climb/descent purpose: memorial return, upper
	# overlook, inner overlook ladder, lower ascent, and exit return ledge.
	return rect in steps()

static func foundation_rock() -> Array[Rect2]:
	if not _foundation_cache.is_empty():
		return _foundation_cache
	var result: Array[Rect2] = []
	var all_routes := routes()
	var original_rock := enclosing_rock()
	for route_name in all_routes:
		if route_name in drop_routes():
			continue
		var route: PackedVector2Array = all_routes[route_name]
		for i in route.size()-1:
			var a := route[i]
			var b := route[i+1]
			if is_drop_segment(route_name,a,b):
				continue
			for x in range(int(minf(a.x,b.x)),int(maxf(a.x,b.x)),16):
				var width := minf(16,maxf(a.x,b.x)-x)
				var floor_y := maxf(surface_y(a,b,x),surface_y(a,b,x+width))
				var bottom := minf(floor_y+512,1420) if floor_y<1420 else floor_y+512
				if x>=3200 and x<4280 and floor_y<993:
					bottom=minf(bottom,945)
				if x>=4708 and floor_y<1420:
					bottom=floor_y+32
				# Keep real lower passages clear; geological backing must not bury them.
				for other_route: PackedVector2Array in all_routes.values():
					for j in other_route.size()-1:
						var c := other_route[j]
						var d := other_route[j+1]
						if x+width>minf(c.x,d.x)-20 and x<maxf(c.x,d.x)+20:
							var lower := surface_y(c,d,x+width/2)
							if lower>floor_y+32:
								bottom=minf(bottom,lower-185)
				for step in steps():
					if x+width>step.position.x-64 and x<step.end.x+64 and step.position.y>floor_y+16:
						bottom=minf(bottom,step.position.y-185)
				for rock in original_rock:
					if rock.position.x<=x and rock.end.x>=x+width and rock.position.y>floor_y+16:
						bottom=minf(bottom,rock.position.y+16)
				if bottom>floor_y+32:
					result.append(Rect2(x,floor_y+16,width,bottom-floor_y-16))
	result.sort_custom(func(a: Rect2,b: Rect2) -> bool:
		if a.position.y!=b.position.y:
			return a.position.y<b.position.y
		if a.size.y!=b.size.y:
			return a.size.y<b.size.y
		return a.position.x<b.position.x)
	var merged: Array[Rect2] = []
	for rect in result:
		if not merged.is_empty() and merged[-1].position.y==rect.position.y and merged[-1].size.y==rect.size.y and merged[-1].end.x==rect.position.x:
			merged[-1].size.x+=rect.size.x
		else:
			merged.append(rect)
	_foundation_cache=merged
	return merged

static func map_space() -> Dictionary:
	enclosing_rock()
	if not _map_synced:
		var map_solids:=foundation_rock()+blocks()
		for cell: Vector2i in map_cells.keys():
			if FUTURE_CHAMBER.has_point(Vector2(cell)+Vector2(32,32)):
				map_cells.erase(cell)
				continue
			for rect in map_solids:
				if rect.has_point(Vector2(cell)+Vector2(32,32)):
					map_cells.erase(cell)
					break
		_map_synced=true
	return map_cells

static func route_polygon(a: Vector2, b: Vector2) -> PackedVector2Array:
	var left := a if a.x < b.x else b
	var right := b if a.x < b.x else a
	var depth := 32.0 if is_equal_approx(left.y,right.y) else 64.0
	var down := (right - left).normalized().orthogonal() * -depth
	return PackedVector2Array([left, right, right + down, left + down])

static func surface_y(a: Vector2, b: Vector2, x: float) -> float:
	return lerpf(a.y, b.y, clampf((x - a.x) / (b.x - a.x), 0.0, 1.0))

static func supporting_length() -> float:
	var flats := {}
	var slopes := {}
	for points in routes().values():
		for i in points.size() - 1:
			var a: Vector2 = points[i]
			var b: Vector2 = points[i + 1]
			if is_equal_approx(a.y, b.y):
				if not flats.has(a.y):
					flats[a.y] = []
				flats[a.y].append(Vector2(minf(a.x, b.x), maxf(a.x, b.x)))
			else:
				slopes[str(route_polygon(a, b))] = a.distance_to(b)
	# Only tested supporting floors count. Boundary roofs, walls, rock fill and
	# inaccessible top faces contribute nothing to the expansion measurement.
	var floors: Array[Rect2] = blocks().slice(0, 5)
	for step in steps():
		if not FUTURE_CHAMBER.has_point(step.position):
			floors.append(step)
	floors.append(DROP)
	for rect in floors:
		if not flats.has(rect.position.y):
			flats[rect.position.y] = []
		flats[rect.position.y].append(Vector2(rect.position.x, rect.end.x))
	var total := 0.0
	for length: float in slopes.values():
		total += length
	for spans: Array in flats.values():
		spans.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
		var merged: Vector2 = spans[0]
		for span: Vector2 in spans.slice(1):
			if span.x <= merged.y:
				merged.y = maxf(merged.y, span.y)
			else:
				total += merged.y - merged.x
				merged = span
		total += merged.y - merged.x
	return total
