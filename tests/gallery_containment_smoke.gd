extends "res://tests/gallery_section_smoke.gd"

const CHECK_ROOT := "res://tests/.gallery_containment_saves"

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CHECK_ROOT))
	SLOTS.write_slot(3,SLOTS.new_slot(),CHECK_ROOT)
	set_meta("active_save_slot",3)
	set_meta("save_root",CHECK_ROOT)
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await physics_frame
	world=current_scene
	world.set_process(false)
	world.gallery_encounters.set_active(false)
	world.ledge_sentinel.set_process(false)
	world.scout.set_physics_process(false)
	world.scout.collision_layer=0
	world.player.invulnerability=1000
	world.player.set_physics_process(false)
	if world.background_rect.texture!=world.GALLERY_BACKGROUND or world.background_rect.stretch_mode!=TextureRect.STRETCH_SCALE:
		_fail("Room 2 is not using its continuous unique background")
		return
	var camera: Camera2D=world.player.get_node("Camera2D")
	if camera.limit_left!=-696 or camera.limit_right!=5096 or camera.limit_top!=-1996 or camera.limit_bottom!=1850:
		_fail("Camera does not frame the visible outer rock bands")
		return
	# The extreme camera corners must show authored solid rock, never empty space.
	for x in [camera.limit_left+8,camera.limit_right-8]:
		for y in [camera.limit_top+8,camera.limit_bottom-8]:
			var enclosed:=false
			for rect in world.gallery.LAYOUT.blocks():
				if rect.has_point(Vector2(x,y)):
					enclosed=true
					break
			if not enclosed:
				_fail("Camera corner exposes outside-of-room space")
				return
	# Sweep the complete shell every 32px, including regions outside the routes.
	# Only the authored, transition-controlled eastern doorway is an opening.
	for y in range(-1880,1840,32):
		if not _solid_between(Vector2(-580,y),Vector2(-1100,y)):
			_fail("Open west boundary at y=%s"%y)
			return
		if y<-1770 or y>=-1500:
			if not _solid_between(Vector2(4960,y),Vector2(5500,y)):
				_fail("Open east boundary at y=%s"%y)
				return
	for x in range(-568,4960,32):
		if not _solid_between(Vector2(x,-1860),Vector2(x,-2400)) or not _solid_between(Vector2(x,1700),Vector2(x,2300)):
			_fail("Open roof or bottom at x=%s"%x)
			return
	# Every rendered rock rectangle has its identical, active solid collider.
	for rect in world.gallery.enclosing_rock+world.gallery.LAYOUT.blocks():
		var matching:=false
		for body in world.gallery.bodies:
			if not is_instance_valid(body) or body.is_queued_for_deletion():
				continue
			var shape: CollisionShape2D=body.get_child(0)
			if body.position==rect.get_center() and shape.shape.size==rect.size and not shape.one_way_collision and body.collision_layer==1:
				matching=true
				break
		if not matching:
			_fail("Rendered cave mass has no matching solid collision: %s"%rect)
			return
	# The lowest floor is solid now. S+Jump must not phase through structural rock.
	world.player.set_physics_process(true)
	for x in [2840,3000,3160,3260]:
		world.player.position=Vector2(x,1625)
		world.player.reset_movement_state()
		world.player.health=5
		for i in 8:
			await physics_frame
		_key(KEY_S,true)
		_key(KEY_SPACE,true)
		for i in 3:
			await physics_frame
		_key(KEY_S,false)
		_key(KEY_SPACE,false)
		for i in 65:
			await physics_frame
		if not world.player.is_on_floor() or absf(world.player.position.y-1627)>5 or world.player.health!=5 or world.respawning or world.player.drop_exception_active:
			_fail("The solid deep floor allowed an unintended drop or invoked hole recovery")
			return
	# A deliberate undercroft descent reaches the lower loop and releases its exception.
	world.player.position=Vector2(2210,202)
	world.player.reset_movement_state()
	for i in 8:
		await physics_frame
	_key(KEY_S,true)
	_key(KEY_SPACE,true)
	for i in 3:
		await physics_frame
	_key(KEY_S,false)
	_key(KEY_SPACE,false)
	for i in 90:
		await physics_frame
	if not world.player.is_on_floor() or world.player.position.y<=230 or world.player.position.y>=1750 or world.player.health!=5 or world.player.drop_exception_active:
		_fail("The authored lower-loop descent did not land and release its exception")
		return
	# The Refuge's former hole is now a basin; retain its dash and ledge lesson.
	world.current_room=3
	world._set_camera_room()
	world.player.position=Vector2(2300,620)
	world.player.reset_movement_state()
	for i in 50:
		await physics_frame
	if not world.player.is_on_floor() or absf(world.player.position.y-667)>5 or world.player.health!=5:
		_fail("Refuge basin does not contain a missed crossing without a penalty")
		return
	if not await _jump(world.player.position,Vector2(2400,617)):
		return
	if not await _jump(world.player.position,Vector2(2480,577)):
		return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	SLOTS.delete_slot(3,CHECK_ROOT)
	print("GALLERY_CONTAINMENT_SMOKE_PASS")
	quit()

func _solid_between(start: Vector2,end: Vector2) -> bool:
	var query:=PhysicsRayQueryParameters2D.create(start,end,1)
	query.exclude=[world.player.get_rid()]
	query.hit_from_inside=true
	var hit: Dictionary=world.get_world_2d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider is StaticBody2D
