extends "res://tests/forest_arrival_visual.gd"

func begin() -> void:
	world=get_tree().current_scene
	assert(world.active_save_slot==0)
	world.player.position=L.section3_point(Vector2(1160,676))-Vector2(0,23)
	world.player.reset_movement_state()
	world.player.set_physics_process(true)
	for i in 8: await get_tree().physics_frame
	var crossed_plant:=false
	var returned_through_plant:=false
	var root_target:=L.section3_point(Vector2(1280,778))-Vector2(0,23)
	var root_return:=L.section3_point(Vector2(1270,590))
	_key(KEY_SPACE,true)
	for i in 80:
		_key(KEY_D,not crossed_plant and world.player.position.x<root_target.x-3)
		_key(KEY_A,crossed_plant and world.player.position.x>root_return.x+3)
		if i==3: _key(KEY_SPACE,false)
		await get_tree().physics_frame
		if world.player.position.x>=root_target.x-3 and world.player.position.y<L.section3_point(Vector2(1280,590)).y:
			crossed_plant=true
		if crossed_plant and world.player.position.x<=root_return.x+3 and world.player.position.y-23<root_return.y:
			returned_through_plant=true
	_key(KEY_D,false)
	_key(KEY_A,false)
	if not crossed_plant or not returned_through_plant:
		_fail("Hanging terrace plant still blocks the airborne approach")
		return
	set_meta("plant_clearance",true)
	world.player.position=L.section3_point(Vector2(600,752))-Vector2(0,23)
	world.player.reset_movement_state()
	world.player.set_physics_process(true)
	for i in 8: await get_tree().physics_frame
	_key(KEY_A,true)
	for i in 22: await get_tree().physics_frame
	_key(KEY_A,false)
	if world.player.position.x>L.section3_point(Vector2(535,752)).x+2 or not world.player.is_on_floor():
		_fail("Pictured left-shelf approach still blocked at %s"%world.player.position)
		return
	set_meta("left_shelf_position",str(world.player.position))
	if not await _walk(L.section3_point(Vector2(600,752))-Vector2(0,23),"left-shelf pocket reverse approach"): return
	world.player.position=L.section3_point(Vector2(790,752))-Vector2(0,23)
	world.player.reset_movement_state()
	world.player.set_physics_process(true)
	if not await _walk(L.section3_point(Vector2(835,752))-Vector2(0,23),"pillar pocket approach"): return
	if not await _walk(L.section3_point(Vector2(790,752))-Vector2(0,23),"pillar pocket reverse"): return
	world.player.position=L.section3_point(Vector2(250,730))-Vector2(0,23)
	world.player.reset_movement_state()
	if not await _jump(world.player.position,L.section3_point(Vector2(430,603))-Vector2(0,23)): return
	if not await _jump(world.player.position,L.section3_point(Vector2(280,434))-Vector2(0,23)): return
	set_meta("complete",true)
