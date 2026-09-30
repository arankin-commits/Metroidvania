extends "res://tests/gallery_section_smoke.gd"

const L=preload("res://scripts/forest_arrival_layout.gd")
const ARRIVAL_ROOT="res://tests/.forest_arrival_saves"

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ARRIVAL_ROOT))
	var data: Dictionary=SLOTS.new_slot()
	data["hand_activated"]=true
	data["last_hand_room"]=3
	data["checkpoint_x"]=2610.0
	data["checkpoint_y"]=570.0
	data["gallery_heavy_open"]=true
	data["gallery_cache_found"]=true
	SLOTS.write_slot(1,data,ARRIVAL_ROOT)
	set_meta("active_save_slot",1)
	set_meta("save_root",ARRIVAL_ROOT)
	change_scene_to_file("res://scenes/forest_entry.tscn")
	await process_frame
	await physics_frame
	world=current_scene
	world.player.invulnerability=1000
	var plate:=world.arrival.get_node("ContinuousRoomArtwork") as Sprite2D
	if not (Vector2(plate.texture.get_size())*plate.scale).is_equal_approx(L.ART_EXTENT.size) or not is_equal_approx(L.point(Vector2(1672,416)).y,L.section2_point(Vector2(0,678)).y):
		_fail("Artwork registration stretched terrain or misaligned the joining floors")
		return
	if world.player.position.distance_to(L.entry())>5:
		_fail("Forest arrival did not use the painted receiving terrace")
		return
	if Geometry2D.is_point_in_polygon(Vector2(400,-180),L.map_outline()):
		_fail("Map includes framing above the actual arrival canopy")
		return
	for i in 8: await physics_frame
	if not world.player.is_on_floor():
		_fail("Forest arrival spawn has no painted support")
		return
	# Test the actual body in open pockets missed by the centerline route.
	var body_shape: CollisionShape2D
	for child in world.player.get_children():
		if child is CollisionShape2D: body_shape=child
	for source in [Vector2(290,580),Vector2(535,715),Vector2(830,715),Vector2(1210,530),Vector2(1280,530)]:
		var query:=PhysicsShapeQueryParameters2D.new()
		query.shape=body_shape.shape
		query.transform=Transform2D(0,L.section3_point(source))
		query.collision_mask=world.player.collision_mask
		query.exclude=[world.player.get_rid()]
		if not world.get_world_2d().direct_space_state.intersect_shape(query).is_empty():
			_fail("Visible Section 3 pocket blocks the full player body at %s"%source)
			return
	world.player.position=L.section3_point(Vector2(1160,676))-Vector2(0,23)
	world.player.reset_movement_state()
	for i in 8: await physics_frame
	var crossed_plant:=false
	var returned_through_plant:=false
	var root_target:=L.section3_point(Vector2(1280,778))-Vector2(0,23)
	var root_return:=L.section3_point(Vector2(1270,590))
	_key(KEY_SPACE,true)
	for i in 80:
		_key(KEY_D,not crossed_plant and world.player.position.x<root_target.x-3)
		_key(KEY_A,crossed_plant and world.player.position.x>root_return.x+3)
		if i==3: _key(KEY_SPACE,false)
		await physics_frame
		if world.player.position.x>=root_target.x-3 and world.player.position.y<L.section3_point(Vector2(1280,590)).y:
			crossed_plant=true
		if crossed_plant and world.player.position.x<=root_return.x+3 and world.player.position.y-23<root_return.y:
			returned_through_plant=true
	_key(KEY_D,false)
	_key(KEY_A,false)
	if not crossed_plant or not returned_through_plant:
		_fail("Hanging terrace plant approach: outward=%s reverse=%s"%[crossed_plant,returned_through_plant])
		return
	print("FOREST_HANGING_PLANT_CLEARANCE_PASS")
	world.player.position=L.section3_point(Vector2(600,752))-Vector2(0,23)
	world.player.reset_movement_state()
	for i in 8: await physics_frame
	_key(KEY_A,true)
	for i in 22: await physics_frame
	_key(KEY_A,false)
	# A loose route tolerance could accept the old wall while still outside it.
	if world.player.position.x>L.section3_point(Vector2(535,752)).x+2 or not world.player.is_on_floor():
		_fail("Pictured left-shelf approach still blocked at %s"%world.player.position)
		return
	if not await _walk(L.section3_point(Vector2(600,752))-Vector2(0,23),"left-shelf pocket reverse approach"): return
	world.player.position=L.section3_point(Vector2(790,752))-Vector2(0,23)
	world.player.reset_movement_state()
	if not await _walk(L.section3_point(Vector2(835,752))-Vector2(0,23),"recessed pillar approach"): return
	if not await _walk(L.section3_point(Vector2(790,752))-Vector2(0,23),"recessed pillar reverse approach"): return
	world.player.position=L.entry()
	world.player.reset_movement_state()
	print("FOREST_FULL_BODY_CLEARANCE_PASS")
	if not await _walk(_feet(590,578),"arrival terrace"): return
	if not await _walk(_feet(740,781),"contained basin descent"): return
	if not await _walk(_feet(960,781),"stair approach"): return
	for hop in [[960,781,1040,745],[1040,745,1100,722],[1100,722,1170,697],[1170,697,1245,671],[1245,671,1340,608],[1340,608,1465,596],[1465,596,1580,416]]:
		if not await _jump(world.player.position,_feet(hop[2],hop[3])): return
	print("FOREST_ARRIVAL_OUTWARD_ROUTE_PASS")
	if not await _walk(Vector2(1320,_feet(1580,416).y),"continuous section seam"): return
	if world.current_room!=5 or world.transitioning or not world.player.controls_enabled:
		_fail("Section seam triggered a room transition")
		return
	for p in [Vector2(380,611),Vector2(670,585),Vector2(780,561),Vector2(960,489),Vector2(1100,453),Vector2(1200,426),Vector2(1400,357),Vector2(1560,345)]:
		if not await _jump(world.player.position,L.section2_point(p)-Vector2(0,23)): return
	print("FOREST_SECTION_SEAM_PASS")
	if not await _walk(L.section3_point(Vector2(60,415))-Vector2(0,23),"Section 2 to 3 seam"): return
	if world.current_room!=5 or world.transitioning:
		_fail("Section 3 seam triggered a room change")
		return
	for p in [Vector2(260,434),Vector2(430,603),Vector2(740,752)]:
		if not await _walk(L.section3_point(p)-Vector2(0,23),"Section 3 descent"): return
	if not await _jump(world.player.position,L.section3_point(Vector2(900,569))-Vector2(0,23)): return
	if not await _walk(L.section3_point(Vector2(990,569))-Vector2(0,23),"central takeoff"): return
	for p in [Vector2(1140,425),Vector2(1200,425),Vector2(1440,234)]:
		if not await _jump(world.player.position,L.section3_point(p)-Vector2(0,23)): return
	if not await _walk(L.section3_point(Vector2(1560,234))-Vector2(0,23),"arch crown"): return
	if not await _walk(L.section3_point(Vector2(1655,565))-Vector2(0,23),"right receiving terrace"): return
	print("FOREST_SECTION3_OUTWARD_PASS")
	if not await _walk(Vector2(3588,L.section3_point(Vector2(1580,565)).y-23),"Room 2 exit approach"): return
	_key(KEY_D,true)
	for i in 110:
		await physics_frame
		if world.current_room==6 and not world.transitioning: break
	_key(KEY_D,false)
	if world.current_room!=6 or not world.player.is_on_floor():
		_fail("The upper arrival exit did not receive safely into Forest Room 2")
		return
	_key(KEY_A,true)
	for i in 110:
		await physics_frame
		if world.current_room==5 and not world.transitioning: break
	_key(KEY_A,false)
	for i in 8: await physics_frame
	if world.current_room!=5 or not world.player.is_on_floor() or absf(world.player.position.y-(L.section3_point(Vector2(1580,565)).y-23))>5:
		_fail("Forest Room 2 return is buried or unsupported on the upper terrace: room=%s at=%s floor=%s"%[world.current_room,world.player.position,world.player.is_on_floor()])
		return
	for p in [Vector2(1450,778),Vector2(1230,778)]:
		if not await _walk(L.section3_point(p)-Vector2(0,23),"lower arch return"): return
	# Land in the tread's outer half before climbing the newly unobstructed pillar.
	for p in [Vector2(1190,676),Vector2(1080,569)]:
		if not await _jump(world.player.position,L.section3_point(p)-Vector2(0,23)): return
	if not await _walk(L.section3_point(Vector2(700,752))-Vector2(0,23),"lower clearing return"): return
	for p in [Vector2(450,603),Vector2(280,434)]:
		if not await _jump(world.player.position,L.section3_point(p)-Vector2(0,23)): return
	if not await _walk(L.section3_point(Vector2(40,415))-Vector2(0,23),"Section 3 seam return"): return
	if not await _walk(L.section2_point(Vector2(1580,345))-Vector2(0,23),"Section 2 rejoin"): return
	print("FOREST_SECTION3_RETURN_PASS")
	for p in [Vector2(1400,357),Vector2(1200,426),Vector2(1100,453),Vector2(960,489),Vector2(780,561),Vector2(670,585),Vector2(380,611),Vector2(120,678)]:
		if not await _walk(L.section2_point(p)-Vector2(0,23),"Section 2 return"): return
	if not await _walk(_feet(1580,416),"reverse section seam"): return
	if world.current_room!=5 or world.transitioning:
		_fail("Reverse section seam changed rooms")
		return
	if not await _walk(_feet(1465,596),"upper terrace return descent"): return
	for p in [Vector2(1340,608),Vector2(1245,671),Vector2(1170,697),Vector2(1100,722),Vector2(1040,745),Vector2(740,781)]:
		if not await _walk(L.point(p)-Vector2(0,23),"stair return"): return
	if not await _jump(world.player.position,_feet(600,578)): return
	if not await _walk(Vector2(32,_feet(600,578).y),"cave return approach"): return
	world._save_progress()
	var saved:=SLOTS.load_slot(1,ARRIVAL_ROOT)
	if saved.get("checkpoint_x")!=2610.0 or saved.get("checkpoint_y")!=570.0 or saved.get("last_hand_room")!=3 or not saved.get("gallery_heavy_open",false) or not saved.get("gallery_cache_found",false):
		_fail("Forest traversal replaced the cave checkpoint or lost cave state")
		return
	_key(KEY_A,true)
	for i in 130:
		await physics_frame
		if is_instance_valid(current_scene) and current_scene.scene_file_path=="res://scenes/tutorial.tscn": break
	_key(KEY_A,false)
	for i in 12: await physics_frame
	if current_scene.scene_file_path!="res://scenes/tutorial.tscn" or current_scene.checkpoint!=Vector2(2610,570):
		_fail("Physical forest-to-cave return changed the activated hand")
		return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame
	SLOTS.delete_slot(1,ARRIVAL_ROOT)
	print("FOREST_ARRIVAL_SMOKE_PASS")
	quit()

func _feet(x: float,y: float) -> Vector2:
	return L.point(Vector2(x,y))-Vector2(0,23)
