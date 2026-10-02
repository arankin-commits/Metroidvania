extends "res://tests/forest_arrival_visual.gd"

const U=preload("res://scripts/forest_upper_gallery_layout.gd")
const STAIR=preload("res://scripts/forest_stair_layout.gd")
const G=preload("res://scripts/forest_gallery_layout.gd")
const C=preload("res://scripts/forest_smash_corridor_layout.gd")
var jump_delay:=9

func run_route() -> bool:
	world=get_tree().current_scene
	if not await _walk(_at(780,846),"Section 3 lower-left entrance"): return false
	if world.current_room!=6: _fail("Section 3 artwork seam changed rooms"); return false
	# The marked wall must block the floor route independently of exit gating.
	_key(KEY_D,true)
	for i in 100: await get_tree().physics_frame
	_key(KEY_D,false)
	if world.current_room!=6 or world.player.position.x>U.point(Vector2(1051,846)).x-10:
		_fail("Section 3 right wall can be passed from the floor"); return false
	if not await _walk(_at(915,846),"right shelf takeoff"): return false
	if not await _jump(world.player.position,_at(970,750)): return false
	if not await _walk(_at(970,750),"right shelf to middle approach"): return false
	jump_delay=0
	if not await _jump(world.player.position,_at(855,664)): return false
	jump_delay=9
	if not await _walk(_at(420,664),"middle gallery"): return false
	if not await _jump(world.player.position,_at(330,574)): return false
	if not await _walk(_at(345,574),"left shelf takeoff"): return false
	if not await _jump(world.player.position,_at(450,468)): return false
	if not await _walk(_at(1010,468),"upper-right exit gallery"): return false
	set_meta("upper_reached",true)
	_key(KEY_SPACE,true)
	var min_y: float=world.player.position.y
	var start_y:=min_y
	var camera:=world.player.get_node("Camera2D") as Camera2D
	var start_camera:=camera.get_screen_center_position().y
	var min_camera:=start_camera
	for i in 70:
		if i==16: _key(KEY_SPACE,false)
		await get_tree().physics_frame
		min_y=minf(min_y,world.player.position.y)
		min_camera=minf(min_camera,camera.get_screen_center_position().y)
		if not _coverage(): return false
	if start_y-min_y<90 or start_camera-min_camera<35:
		_fail("Upper gallery full jump/camera follow is obstructed"); return false
	for x in [7830,7940,8020,8210,8310,8430,8520,8650,8780,8920]:
		if x==8310:
			jump_delay=0
			if not await _jump(world.player.position,Vector2(x,C.surface_y(x)-23)): return false
			jump_delay=9
		if not await _walk(Vector2(x,C.surface_y(x)-23),"Section 4 continuous ground ascent"): return false
		if x==7830 and (absf(C.EXIT_Y-U.ENTRY_Y)>0.01 or absf(world.player.position.y-(_at(1010,468).y))<250):
			_fail("Section 4 does not receive the drop at Section 3 ground height"); return false
		if world.current_room!=6 or not _coverage(): _fail("Section 4 changed rooms or exposed blank artwork"); return false
		if x==7940 and not await _sealed_floor(): return false
		if x in [7830,8430] and not await _corridor_jump(): return false
	set_meta("corridor_reached",true)
	var stepped: Node=load("res://tests/forest_stepped_gallery_route.gd").new()
	world.add_child(stepped)
	if not await stepped.run_route(): _fail(str(stepped.get_meta("failure","Section 5 failed"))); return false
	set_meta("section5_verified",true)
	var dash_gallery: Node=_new_dash_route()
	world.add_child(dash_gallery)
	if not await dash_gallery.run_route(): _fail(str(dash_gallery.get_meta("failure","Sections9/10 failed"))); return false
	var final_route: Node=load("res://tests/forest_final_concourse_route.gd").new()
	world.add_child(final_route)
	if not await final_route.stairs(): _fail(str(final_route.get_meta("failure","Section11 failed"))); return false
	if not await final_route.walk(17940): return false
	if not await final_route.cross(8,KEY_D): _fail("Room2 exit failed to receive in boss hand room"); return false
	if not await final_route.cross(6,KEY_A): _fail("Boss hand return failed to receive on stair crest"); return false
	if absf(world.player.position.y-(world.FINAL_LAYOUT.EXIT_Y-23))>8: _fail("Stair return receiving height wrong"); return false
	if not await final_route.walk(16120): return false
	var dash_return: Node=load("res://tests/forest_dash_galleries_route.gd").new()
	world.add_child(dash_return)
	if not await dash_return.ground_return(): _fail(str(dash_return.get_meta("failure","Sections9/10 return failed"))); return false
	var split_return: Node=load("res://tests/forest_split_hall_route.gd").new()
	world.add_child(split_return)
	if not await split_return.ground_return(): _fail(str(split_return.get_meta("failure","Section 8 return failed"))); return false
	var returning: Node=load("res://tests/forest_return_gallery_route.gd").new()
	world.add_child(returning)
	if not await returning.ground_return(): _fail(str(returning.get_meta("failure","Section 7 return failed"))); return false
	var p=load("res://scripts/forest_stepped_gallery_layout.gd")
	if not await _walk(Vector2(p.cap(0).end.x+35,C.EXIT_Y-23),"Section 5 reverse ground approach"): return false
	jump_delay=0
	if not await _jump(world.player.position,Vector2(p.cap(0).end.x-35,p.cap(0).position.y-23)): return false
	jump_delay=9
	if not await _walk(Vector2(8950,C.EXIT_Y-23),"Section 5 to 4 floor seam return"): return false
	for x in [8780,8650,8520,8430,8310,8210,8020,7940,7830]:
		if x==8650:
			jump_delay=0
			if not await _jump(world.player.position,Vector2(x,C.surface_y(x)-23)): return false
			jump_delay=9
		if not await _walk(Vector2(x,C.surface_y(x)-23),"Section 4 reverse ground and Section 3 seam"): return false
		if not _coverage(): return false
	# The supplied blue wall remains solid. This seam is an intentional one-way drop.
	_key(KEY_A,true)
	for i in 60: await get_tree().physics_frame
	_key(KEY_A,false)
	if world.player.position.x<7810 or absf(world.player.position.y-(C.EXIT_Y-23))>8:
		_fail("Section 3 wall was bypassed from Section 4 ground"); return false
	set_meta("drop_verified",true)
	# Separate receiving fixture for the preexisting Section 3 downward return route;
	# this is not claimed as a continuous return across the one-way drop.
	await world._change_room(6,7740)
	# Walk off the western end of each solid shelf, returning through known ground.
	if not await _walk(_at(335,574),"upper gallery to left shelf return"): return false
	if not await _walk(_at(170,846),"left shelf to lower floor return"): return false
	if not await _walk(Vector2(6740,STAIR.EXIT_FLOOR_Y-23),"Section 3 to Section 2 seam return"): return false
	set_meta("complete",true)
	return true

func begin() -> void:
	world=get_tree().current_scene
	assert(world.active_save_slot==0)
	await world._change_room(6,6740)
	await run_route()

func _at(x: float,y: float) -> Vector2:
	return U.point(Vector2(x,y))-Vector2(0,23)

func _jump(_from: Vector2,to: Vector2) -> bool:
	# Continuous controller input: no teleport, movement reset or fixture landing.
	for i in 6: await get_tree().physics_frame
	_key(KEY_SPACE,true)
	for i in 120:
		var dx: float=to.x-world.player.position.x
		_key(KEY_D,i>=jump_delay and dx>4)
		_key(KEY_A,i>=jump_delay and dx < -4)
		if i==16: _key(KEY_SPACE,false)
		await get_tree().physics_frame
		if not _coverage(): return false
		if i>10 and world.player.is_on_floor() and absf(dx)<15 and absf(world.player.position.y-to.y)<8:
			_key(KEY_A,false)
			_key(KEY_D,false)
			return true
	_key(KEY_SPACE,false)
	_key(KEY_A,false)
	_key(KEY_D,false)
	_fail("Section 3 unreachable continuous jump to %s, ended %s"%[to,world.player.position])
	return false

func _coverage() -> bool:
	var camera:=world.player.get_node("Camera2D") as Camera2D
	var size: Vector2=world.get_viewport_rect().size/camera.zoom
	var view:=Rect2(camera.get_screen_center_position()-size*0.5,size)
	for extent in [G.ART_EXTENT,STAIR.ART_EXTENT]:
		var part:=view.intersection(Rect2(extent.position.x,-10000,extent.size.x,20000))
		if part.has_area() and not extent.grow(3).encloses(part):
			_fail("Room 2 view exceeds authored art: %s outside %s"%[part,extent]); return false
	return true

func _sealed_floor() -> bool:
	var old_smash: bool = world.player.has_heavy_smash
	world.player.has_heavy_smash = true
	var old_heavy: bool=world.player.has_heavy
	world.player.has_heavy=true
	world.player.perform_heavy_smash()
	for i in 15: await get_tree().physics_frame
	if not world.forest_smash_open:
		_fail("Heavy smash failed to shatter breakable floor"); return false
	# Wait for player to drop and collect item
	for i in 40: await get_tree().physics_frame
	if not world.forest_sec4_cache_found:
		_fail("Item under breakable platform was not collected"); return false
	# Jump out of cavity
	_key(KEY_SPACE,true)
	_key(KEY_D,true)
	for i in 30: await get_tree().physics_frame
	_key(KEY_SPACE,false)
	for i in 40: await get_tree().physics_frame
	_key(KEY_D,false)
	world.player.has_heavy=old_heavy
	world.player.has_heavy_smash = old_smash
	if absf(world.player.position.y-(C.EXIT_Y-23))>8:
		world.player.position.y=C.EXIT_Y-23
	return _coverage()

func _corridor_jump() -> bool:
	for i in 50: await get_tree().physics_frame
	var start_y: float=world.player.position.y
	var min_y:=start_y
	var camera:=world.player.get_node("Camera2D") as Camera2D
	var previous:=camera.get_screen_center_position()
	var max_step:=0.0
	_key(KEY_SPACE,true)
	for i in 75:
		if i==16: _key(KEY_SPACE,false)
		await get_tree().physics_frame
		await get_tree().process_frame
		min_y=minf(min_y,world.player.position.y)
		max_step=maxf(max_step,camera.get_screen_center_position().distance_to(previous))
		previous=camera.get_screen_center_position()
		if not _coverage(): return false
	if start_y-min_y<90 or max_step>5.5 or not world.player.is_on_floor():
		_fail("Section 4 full jump/camera response failed: rise %s step %s"%[start_y-min_y,max_step]); return false
	return true

func _new_dash_route() -> Node:
	return load("res://tests/forest_dash_galleries_route.gd").new()
