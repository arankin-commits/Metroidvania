extends "res://tests/gallery_section_smoke.gd"

const G=preload("res://scripts/forest_gallery_layout.gd")
const STAIR=preload("res://scripts/forest_stair_layout.gd")
const SAVE_ROOT="res://tests/.forest_gallery_saves"

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_ROOT))
	var data: Dictionary=SLOTS.new_slot()
	data.merge({"hand_activated":true,"is_injured":false,"last_hand_room":3,"checkpoint_x":2610.0,"checkpoint_y":570.0,"bow_boss_defeated":true},true)
	SLOTS.write_slot(1,data,SAVE_ROOT)
	set_meta("active_save_slot",1)
	set_meta("save_root",SAVE_ROOT)
	set_meta("forest_entry_room",6)
	change_scene_to_file("res://scenes/forest_entry.tscn")
	await process_frame
	await physics_frame
	world=current_scene
	world.player.invulnerability=1000
	if is_instance_valid(world.forest_encounters):
		world.forest_encounters.queue_free()
	for i in 8: await physics_frame
	var plate:=world.forest_gallery.get_node("RegisteredPainting") as Sprite2D
	if not (Vector2(plate.texture.get_size())*plate.scale).is_equal_approx(G.ART_EXTENT.size):
		_fail("Room 2 painting stretched beyond its collision registration")
		return
	var body_shape: CollisionShape2D
	for child in world.player.get_children():
		if child is CollisionShape2D: body_shape=child
	for at in [Vector2(230,700),Vector2(650,590),Vector2(1040,700),Vector2(650,798)]:
		var query:=PhysicsShapeQueryParameters2D.new()
		query.shape=body_shape.shape
		query.transform=Transform2D(0,G.point(at))
		query.collision_mask=1
		query.exclude=[world.player.get_rid()]
		if not world.get_world_2d().direct_space_state.intersect_shape(query).is_empty():
			_fail("Room 2 recessed arch or hanging foliage blocks the player at %s"%at)
			return
	for x in [3900,4150,4500,4780,4980]:
		if not await _walk(Vector2(x,577),"Room 2 ground walkway"): return
	if not await _walk(Vector2(5035,STAIR.surface_y(5035)-23),"Room 2 continuous Section 1–2 seam"): return
	if world.current_room!=6: _fail("Room 2 artwork join triggered a room change"); return
	for x in [5350,5650,5950,6250,6550,6780]:
		if not await _walk(Vector2(x,STAIR.surface_y(x)-23),"Room 2 stair route to Room 3"): return
	if world.last_hand_room!=3: _fail("Traversal before hand interaction replaced checkpoint"); return
	var route:=preload("res://tests/forest_upper_gallery_route.gd").new()
	world.add_child(route)
	if not await route.run_route(): _fail(str(route.get_meta("failure","Section 3 route failed"))); return
	for x in [6550,6250,5950,5650,5350,4980]:
		if not await _walk(Vector2(x,STAIR.surface_y(x)-23 if x>=5000 else 577),"Room 2 stair return"): return
	if not await _walk(Vector2(3690,577),"Room 2 reverse walkway"): return
	# A cap is not reachable merely because a fixture placed on it can stand.
	# Exercise every link from the public ground route to the central balcony,
	# from both side balconies and back through the same steps.
	if not await _check_balcony_routes(): return
	for native in [Vector2(260,613),Vector2(650,467),Vector2(1080,613)]:
		world.player.position=G.point(native)-Vector2(0,23)
		world.player.reset_movement_state()
		world._set_camera()
		for i in 40: await physics_frame
		if not world.player.is_on_floor(): _fail("Painted Room 2 balcony lacks support"); return
		var camera:=world.player.get_node("Camera2D") as Camera2D
		var start_y: float=world.player.position.y
		var start_camera: float=camera.get_screen_center_position().y
		var min_y:=start_y
		var min_camera:=start_camera
		_key(KEY_SPACE,true)
		for i in 60:
			if i==16: _key(KEY_SPACE,false)
			await physics_frame
			min_y=minf(min_y,world.player.position.y)
			min_camera=minf(min_camera,camera.get_screen_center_position().y)
			var frame_size: Vector2=world.get_viewport_rect().size/camera.zoom
			var view:=Rect2(camera.get_screen_center_position()-frame_size*0.5,frame_size)
			if not G.ART_EXTENT.merge(STAIR.ART_EXTENT).grow(2).encloses(view): _fail("Room 2 camera exposes missing artwork"); return
		if start_y-min_y<90 or (native.y==467 and start_camera-min_camera<35):
			_fail("Room 2 balcony jump is blocked or camera tracking is clamped")
			return
	world._save_progress()
	var saved:=SLOTS.load_slot(1,SAVE_ROOT)
	if saved.get("last_hand_room")!=9 or not saved.get("temple_hand_activated",false) or saved.get("checkpoint_x")!=2610.0:
		_fail("Return traversal lost the explicitly activated temple checkpoint")
		return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame
	SLOTS.delete_slot(1,SAVE_ROOT)
	print("FOREST_GALLERY_SMOKE_PASS")
	quit()

func _check_balcony_routes() -> bool:
	var left: Array[Vector2]=[
		Vector2(578,831),Vector2(505,750),Vector2(453,671),
		Vector2(380,613),Vector2(370,613),Vector2(444,534),Vector2(467,534),
		Vector2(421,462),Vector2(510,467)]
	var right: Array[Vector2]=[
		Vector2(745,831),Vector2(821,750),Vector2(874,671),
		Vector2(927,613),Vector2(1018,613),Vector2(967,542),
		Vector2(913,514),Vector2(864,514),Vector2(805,467)]
	for side in [left,right]:
		if not await _walk(G.point(side[0])-Vector2(0,23),"Room 2 balcony ground approach"): return false
		for i in range(side.size()-1):
			var a:=G.point(side[i])-Vector2(0,23)
			var b:=G.point(side[i+1])-Vector2(0,23)
			if not await _jump(a,b): return false
		# Walking off the central cap travels down the east arch and right
		# balcony into the known ground corridor, with no teleport or floor drop.
		if not await _walk(G.point(Vector2(1278,831))-Vector2(0,23),"Room 2 balcony return to ground"): return false
	return true
