extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await physics_frame
	var w = current_scene
	w.set_process(false)
	w.player.set_physics_process(false)
	w.gallery_encounters.set_active(false)
	w.scout.set_physics_process(false)
	w.scout.collision_layer=0
	var space: PhysicsDirectSpaceState2D=w.get_world_2d().direct_space_state
	var solid := func(p: Vector2) -> bool:
		var q:=PhysicsPointQueryParameters2D.new()
		q.position=p
		for hit in space.intersect_point(q,16):
			if hit.collider is StaticBody2D:
				return true
		return false
	var errors: Array[String]=[]
	for x in range(-580,5040,32):
		if not solid.call(Vector2(x,-1950)) or not solid.call(Vector2(x,1800)):
			errors.append("outer horizontal shell %s"%x)
	for y in range(-1880,1750,32):
		if not solid.call(Vector2(-650,y)):
			errors.append("west shell %s"%y)
		if not w.GALLERY_LAYOUT.EXIT_DOOR.has_point(Vector2(5020,y)) and not solid.call(Vector2(5020,y)):
			errors.append("east shell %s"%y)
	# Both sides and the bottom of the future pocket must be uninterrupted rock.
	for y in range(998,1390,16):
		for x in [3230,4250]:
			if not solid.call(Vector2(x,y)):
				errors.append("future side opening %s"%Vector2(x,y))
	for x in range(3220,4260,16):
		if not solid.call(Vector2(x,1400)) or not solid.call(Vector2(x,970)):
			errors.append("future roof/bottom %s"%x)
	for y in range(-1180,1420,16):
		if not solid.call(Vector2(4650,y)):
			errors.append("service shaft intermediate opening %s"%y)
	for anchor in [w.GALLERY_LAYOUT.START,w.GALLERY_LAYOUT.EXIT,w.GALLERY_LAYOUT.SIGIL,w.GALLERY_LAYOUT.OFFERING]:
		if solid.call(anchor):
			errors.append("buried anchor %s"%anchor)
	# The pocket must contain actual empty space, not merely an outlined solid block.
	for p in [Vector2(3330,1200),Vector2(3820,1200),Vector2(4100,1320)]:
		if solid.call(p): errors.append("filled future pocket %s"%p)
	for cell: Vector2i in w.GALLERY_LAYOUT.map_space():
		if w.GALLERY_LAYOUT.FUTURE_CHAMBER.has_point(Vector2(cell)+Vector2(32,32)):
			errors.append("future pocket marked explored")
	# Removing only this gate in the isolated fixture creates the sole aperture.
	w.gallery.smash_floor.queue_free()
	await process_frame
	await physics_frame
	for x in range(3550,3770,16):
		if solid.call(Vector2(x,970)): errors.append("future aperture has hidden backing")
	if not errors.is_empty():
		for e in errors: push_error(e)
		quit(1)
		return
	print("GALLERY_SHELL_AUDIT_PASS: outer shell, isolated future pocket, shaft wall, anchors")
	quit()
