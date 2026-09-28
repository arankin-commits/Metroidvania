extends Node2D

const LAYOUT = preload("res://scripts/split_gallery_layout.gd")
var world: Node2D
var bodies: Array[StaticBody2D] = []
var west_gate: StaticBody2D
var east_gate: StaticBody2D
var heavy_wall: StaticBody2D
var smash_floor: StaticBody2D
var drop_body: StaticBody2D
var drop_surfaces: Array[Dictionary] = []
var enclosing_rock: Array[Rect2] = []
var rock_polygons: Array[PackedVector2Array] = []
var rock_bins: Dictionary = {}
var exposed_edges: Array[PackedVector2Array] = []

func _ready() -> void:
	name = "SplitGallery"
	var stone_material := ShaderMaterial.new()
	stone_material.shader=preload("res://assets/gallery_stone.gdshader")
	material=stone_material
	enclosing_rock = LAYOUT.enclosing_rock().duplicate()
	var foundations := LAYOUT.foundation_rock()
	enclosing_rock.append_array(foundations)
	LAYOUT.map_space()
	for rect in enclosing_rock:
		_make_rect(rect)
	for rect in LAYOUT.blocks():
		_make_rect(rect)
	for rect in LAYOUT.steps():
		_make_rect(rect, LAYOUT.is_drop_step(rect))
	var flats := {}
	var slopes := {}
	for route_name in LAYOUT.routes():
		var points: PackedVector2Array = LAYOUT.routes()[route_name]
		for i in points.size() - 1:
			var a: Vector2 = points[i]
			var b: Vector2 = points[i + 1]
			if is_equal_approx(a.y, b.y):
				var key := Vector2(a.y,1 if LAYOUT.is_drop_segment(route_name,a,b) else 0)
				if not flats.has(key):
					flats[key] = []
				flats[key].append(Vector2(minf(a.x, b.x), maxf(a.x, b.x)))
			else:
				var polygon := LAYOUT.route_polygon(a, b)
				slopes[str(polygon)] = polygon
	# Merge shared landings: two overlapping one-way colliders would prevent a
	# drop even after the player correctly ignores the first collider.
	for key: Vector2 in flats:
		var y := key.x
		var one_way := key.y>0
		var spans: Array = flats[key]
		spans.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
		var merged: Vector2 = spans[0]
		for span: Vector2 in spans.slice(1):
			if span.x <= merged.y:
				merged.y = maxf(merged.y, span.y)
			else:
				_make_polygon(LAYOUT.route_polygon(Vector2(merged.x, y), Vector2(merged.y, y)),one_way)
				merged = span
		_make_polygon(LAYOUT.route_polygon(Vector2(merged.x, y), Vector2(merged.y, y)),one_way)
	for polygon in slopes.values():
		_make_polygon(polygon)
	smash_floor = _make_rect(LAYOUT.SMASH_FLOOR)
	if not world.gallery_heavy_open:
		heavy_wall = _make_rect(LAYOUT.HEAVY_WALL)
	west_gate = _make_rect(LAYOUT.WEST_GATE)
	east_gate = _make_rect(LAYOUT.EAST_GATE)
	drop_body = _make_rect(LAYOUT.DROP, true)
	if world.gallery_west_open:
		west_gate.queue_free()
	if world.gallery_east_open:
		east_gate.queue_free()
	if world.seal_health > 0:
		world.seal_body = _make_rect(LAYOUT.SEAL)
	_build_exposed_edges()

func try_open_shortcut(at: Vector2) -> bool:
	if not world.gallery_west_open and at.distance_to(LAYOUT.WEST_WINCH) < 55:
		world.gallery_west_open = true
		west_gate.queue_free()
		queue_redraw()
		return true
	if not world.gallery_east_open and at.distance_to(LAYOUT.EAST_WINCH) < 55:
		world.gallery_east_open = true
		east_gate.queue_free()
		queue_redraw()
		return true
	return false

func _make_polygon(polygon: PackedVector2Array, one_way: bool = false) -> StaticBody2D:
	var body := StaticBody2D.new()
	var edge := polygon[1] - polygon[0]
	body.position = (polygon[0] + polygon[1] + polygon[2] + polygon[3]) * 0.25
	body.rotation = edge.angle()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(edge.length(),polygon[2].distance_to(polygon[1]))
	var collision := CollisionShape2D.new()
	collision.shape = shape
	# Flat suspended shelves support from above. Ramps and enclosing rock are solid.
	collision.one_way_collision = one_way
	body.add_child(collision)
	add_child(body)
	bodies.append(body)
	_register_rock(polygon)
	if one_way:
		drop_surfaces.append({"body": body, "region": Rect2(polygon[0].x, polygon[0].y - 8, polygon[1].x - polygon[0].x, 26)})
	return body

func _physics_process(_delta: float) -> void:
	if not visible or not is_instance_valid(world.player) or world.player.drop_exception_active:
		return
	for surface in drop_surfaces:
		var region: Rect2 = surface.region
		if region.has_point(world.player.position + Vector2(0, 23)):
			world.player.drop_platform = surface.body
			world.player.drop_region = region
			world.player.drop_depth = surface.body.get_child(0).shape.size.y
			return

func _make_rect(rect: Rect2, one_way: bool = false) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.one_way_collision = one_way
	body.add_child(collision)
	add_child(body)
	bodies.append(body)
	if rect not in [LAYOUT.WEST_GATE,LAYOUT.EAST_GATE,LAYOUT.SEAL,LAYOUT.HEAVY_WALL]:
		_register_rock(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))
	if one_way:
		drop_surfaces.append({"body": body, "region": Rect2(rect.position - Vector2(0, 8), Vector2(rect.size.x, 26))})
	return body

func set_active(active: bool) -> void:
	visible = active
	for body in bodies:
		if not is_instance_valid(body) or body.is_queued_for_deletion():
			continue
		body.collision_layer = 1 if active else 0
		body.collision_mask = 1 if active else 0

func draw_objects(canvas: Node2D) -> void:
	if not world.secret_found:
		canvas.draw_rect(Rect2(LAYOUT.SIGIL - Vector2(14, 9), Vector2(28, 24)), Color(0.24, 0.24, 0.30))
		canvas.draw_circle(LAYOUT.SIGIL, 7, Color(0.96, 0.79, 0.39))
		canvas.draw_circle(LAYOUT.SIGIL, 20, Color(0.96, 0.79, 0.39, 0.10))
	if not world.gallery_cache_found:
		canvas.draw_circle(LAYOUT.OFFERING, 22, Color(0.44, 0.94, 0.76, 0.10))
		canvas.draw_rect(Rect2(LAYOUT.OFFERING - Vector2(10, 11), Vector2(20, 25)), Color(0.22, 0.43, 0.40))
		canvas.draw_rect(Rect2(LAYOUT.OFFERING - Vector2(4, 7), Vector2(8, 12)), Color(0.81, 1.0, 0.78))
	for station in [LAYOUT.WEST_WINCH, LAYOUT.EAST_WINCH]:
		canvas.draw_rect(Rect2(station + Vector2(-11, 7), Vector2(22, 34)), Color(0.26, 0.31, 0.31))
		canvas.draw_circle(station, 16, Color(0.10, 0.16, 0.18))
		canvas.draw_arc(station, 14, 0, TAU, 12, Color(0.67, 0.59, 0.38), 4)
		canvas.draw_line(station - Vector2(14, 0), station + Vector2(14, 0), Color(0.67, 0.59, 0.38), 4)
	if world.seal_health > 0:
		canvas.draw_rect(LAYOUT.SEAL, Color(0.28, 0.51, 0.57))
		canvas.draw_rect(LAYOUT.SEAL.grow(-7), Color(0.15, 0.23, 0.32))
		for i in world.seal_health:
			canvas.draw_circle(LAYOUT.SEAL.position + Vector2(16,LAYOUT.SEAL.size.y-79+i*23), 5, Color(0.95, 0.78, 0.44))
	for door: Rect2 in [LAYOUT.ENTRANCE_DOOR,LAYOUT.EXIT_DOOR]:
		var x := 0.0 if door==LAYOUT.ENTRANCE_DOOR else 5000.0
		var top := door.position.y
		var floor_y := LAYOUT.ENTRANCE.y+27 if door==LAYOUT.ENTRANCE_DOOR else LAYOUT.EXIT.y+27
		canvas.draw_rect(Rect2(x - 24, top, 16, floor_y-top), Color(0.17, 0.24, 0.31))
		canvas.draw_rect(Rect2(x - 28, top-20, 56, 20), Color(0.31, 0.45, 0.48))

func _register_rock(polygon: PackedVector2Array) -> void:
	var index := rock_polygons.size()
	rock_polygons.append(polygon)
	var bounds := Rect2(polygon[0],Vector2.ZERO)
	for point in polygon:
		bounds=bounds.expand(point)
	for y in range(floori(bounds.position.y/64),floori(bounds.end.y/64)+1):
		for x in range(floori(bounds.position.x/64),floori(bounds.end.x/64)+1):
			var key := Vector2i(x,y)
			if not rock_bins.has(key):
				rock_bins[key]=[]
			rock_bins[key].append(index)

func _rock_at(point: Vector2) -> bool:
	for index in rock_bins.get(Vector2i(floori(point.x/64),floori(point.y/64)),[]):
		if Geometry2D.is_point_in_polygon(point,rock_polygons[index]):
			return true
	return false

func _build_exposed_edges() -> void:
	for polygon in rock_polygons:
		for i in polygon.size():
			var a := polygon[i]
			var b := polygon[(i+1)%polygon.size()]
			var direction := (b-a).normalized()
			var outside := Vector2(direction.y,-direction.x)
			# Only upper/exposed edges receive a readable cap. Shared joins disappear.
			if outside.y>0.1:
				continue
			var count := ceili(a.distance_to(b)/16)
			for j in count:
				var start := a.lerp(b,float(j)/count)
				var end := a.lerp(b,float(j+1)/count)
				if not _rock_at((start+end)/2+outside*2):
					exposed_edges.append(PackedVector2Array([start,end]))

func _draw() -> void:
	# One palette and world-aligned texture for the union of all structural pieces.
	for polygon in rock_polygons:
		draw_colored_polygon(polygon,Color(0.14,0.20,0.24))
	for edge in exposed_edges:
		draw_line(edge[0],edge[1],Color(0.29,0.40,0.40),3)
	for surface in drop_surfaces:
		var r: Rect2=surface.region
		for x in range(int(r.position.x)+8,int(r.end.x)-8,28):
			draw_rect(Rect2(x,r.position.y+34,10,6),Color(0.06,0.10,0.14))
	# Ability gates share the rock palette but use directional amber fractures.
	if not world.gallery_heavy_open:
		draw_rect(LAYOUT.HEAVY_WALL,Color(0.14,0.20,0.24))
		var crack := PackedVector2Array()
		for i in 9:
			crack.append(LAYOUT.HEAVY_WALL.position+Vector2(12+(12 if i%2 else 0),i*LAYOUT.HEAVY_WALL.size.y/8))
		draw_polyline(crack,Color(0.76,0.59,0.35),3)
	for x in range(int(LAYOUT.SMASH_FLOOR.position.x)+16,int(LAYOUT.SMASH_FLOOR.end.x)-16,64):
		draw_polyline(PackedVector2Array([Vector2(x,945),Vector2(x+18,962),Vector2(x+8,982),Vector2(x+28,993)]),Color(0.76,0.59,0.35),3)
	for x in [LAYOUT.SMASH_FLOOR.position.x,LAYOUT.SMASH_FLOOR.end.x-12]:
		draw_rect(Rect2(x,945,12,48),Color(0.25,0.30,0.30))
	# Compressed seam converges downward; no drop-through underside marks.
	var center:=LAYOUT.SMASH_FLOOR.get_center()
	draw_polyline(PackedVector2Array([center+Vector2(-22,-15),center+Vector2(0,9),center+Vector2(22,-15)]),Color(0.62,0.51,0.34),3)
	if not world.gallery_west_open:
		world._draw_cave_terrain_on(self,LAYOUT.WEST_GATE)
	if not world.gallery_east_open:
		world._draw_cave_terrain_on(self,LAYOUT.EAST_GATE)

func try_break_heavy_wall(hitbox: Rect2) -> bool:
	if not world.player.has_heavy or world.gallery_heavy_open or not is_instance_valid(heavy_wall) or not hitbox.intersects(LAYOUT.HEAVY_WALL):
		return false
	world.gallery_heavy_open=true
	heavy_wall.queue_free()
	queue_redraw()
	return true
