extends SceneTree

const GALLERY = preload("res://scripts/split_gallery_layout.gd")
const ORIGINAL := [Rect2(0, 600, 690, 120), Rect2(840, 600, 860, 120), Rect2(380, 525, 155, 18), Rect2(1040, 510, 120, 90), Rect2(1350, 520, 170, 18), Rect2(560, 445, 130, 24), Rect2(730, 365, 160, 24), Rect2(935, 430, 100, 24)]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# No active slot: this read-only physics audit cannot write a player save.
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await physics_frame
	var world := current_scene
	world.set_process(false)
	world.player.set_physics_process(false)
	world.gallery_encounters.set_active(false)
	world.scout.set_physics_process(false)
	world.scout.collision_layer = 0
	world.gallery.west_gate.queue_free()
	world.gallery.east_gate.queue_free()
	world.seal_body.queue_free()
	await process_frame
	await physics_frame
	var current_segments: Array[PackedVector2Array] = []
	for route: PackedVector2Array in GALLERY.routes().values():
		for i in route.size() - 1:
			current_segments.append(PackedVector2Array([route[i], route[i + 1]]))
	var current_floors: Array[Rect2] = GALLERY.blocks().slice(0, 5)
	for step in GALLERY.steps():
		if not GALLERY.FUTURE_CHAMBER.has_point(step.position):
			current_floors.append(step)
	current_floors.append(GALLERY.DROP)
	for rect in current_floors:
		current_segments.append(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y)]))
	var current_cells := _reachable_centers(world, current_segments)
	world.gallery.set_active(false)
	for body in world.legacy_bodies:
		if is_instance_valid(body) and not body.is_queued_for_deletion():
			body.collision_layer = 1
	await physics_frame
	var original_segments: Array[PackedVector2Array] = []
	for rect in ORIGINAL:
		original_segments.append(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y)]))
	var original_cells := _reachable_centers(world, original_segments)
	var ratio := float(current_cells) / original_cells
	print("GALLERY_REACHABLE_CENTER_AREA original=", original_cells * 256, " current=", current_cells * 256, " ratio=", ratio)
	# The revised approved topology adds a service shaft/basal return inside the
	# same envelope. Report its measured size; do not count the inaccessible pocket.
	if ratio < 10.0:
		push_error("Gallery lost its substantial connected playable space")
		quit(1)
		return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	print("GALLERY_SPACE_AUDIT_PASS")
	quit()

func _reachable_centers(world: Node2D, segments: Array[PackedVector2Array]) -> int:
	# Same 16px grid, 28x46 body, and measured 100px normal-jump envelope for both
	# versions. Count unioned center positions above reachable supporting surfaces.
	# Background, free air beyond jump reach and enclosing-rock tops never enter
	# the candidates. Solid terrain rejects positions that the body cannot occupy.
	var cells := {}
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28, 46)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 1
	query.exclude = [world.player.get_rid()]
	var space: PhysicsDirectSpaceState2D = world.get_world_2d().direct_space_state
	for segment in segments:
		var a := segment[0]
		var b := segment[1]
		var slope_clearance := absf((b.y - a.y) / (b.x - a.x)) * 14
		for x in range(int(minf(a.x, b.x)) + 14, int(maxf(a.x, b.x)) - 13, 16):
			var floor_y := GALLERY.surface_y(a, b, x)
			for rise in range(0, 101, 8):
				var at := Vector2(x, floor_y - 23 - slope_clearance - rise - 0.2)
				var cell := Vector2i(roundi(at.x / 16), roundi(at.y / 16))
				if cells.has(cell):
					continue
				query.transform = Transform2D(0, at)
				var blocked := false
				for hit in space.intersect_shape(query, 16):
					if not hit.collider is StaticBody2D:
						continue
					for collision in hit.collider.get_children():
						if collision is CollisionShape2D or collision is CollisionPolygon2D:
							if not collision.one_way_collision:
								blocked = true
					if blocked:
						break
				if not blocked:
					cells[cell] = true
	return cells.size()
