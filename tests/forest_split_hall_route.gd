extends "res://tests/forest_upper_gallery_route.gd"

const H=preload("res://scripts/forest_split_hall_layout.gd")
var max_camera_step:=0.0

func run_route() -> bool:
	world=get_tree().current_scene
	for x in [12625,12800,H.X+1185]:
		if not await _walk(Vector2(x,H.EXIT_Y-23),"Section 7 to 8 upper ground"): return false
		if world.current_room!=6 or world.transitioning: _fail("Section 8 seam triggered a room change"); return false
	jump_delay=0
	if not await _jump(world.player.position,Vector2(H.CAPS[2].end.x-30,H.CAPS[2].position.y-23)): return false
	jump_delay=9
	if not await _walk(Vector2(H.CAPS[2].position.x+12,H.CAPS[2].position.y-23),"low ledge takeoff"): return false
	if not await _jump(world.player.position,Vector2(H.CAPS[1].end.x-30,H.CAPS[1].position.y-23)): return false
	if not await _walk(Vector2(H.CAPS[1].position.x+12,H.CAPS[1].position.y-23),"middle open takeoff"): return false
	if not await _jump(world.player.position,Vector2(H.CAPS[0].position.x+30,H.CAPS[0].position.y-23)): return false
	if not await _walk(Vector2(H.CAPS[0].end.x-45,H.CAPS[0].position.y-23),"highest gallery"): return false
	if not await _corridor_jump(): return false
	if not await _walk(Vector2(H.CAPS[1].position.x+35,H.CAPS[1].position.y-23),"highest to middle descent"): return false
	if not await _walk(Vector2(H.CAPS[1].end.x-12,H.CAPS[1].position.y-23),"middle reverse takeoff"): return false
	if not await _jump(world.player.position,Vector2(H.CAPS[2].position.x+30,H.CAPS[2].position.y-23)): return false
	if not await _walk(Vector2(H.X+1185,H.EXIT_Y-23),"upper east ground"): return false
	# Drop in the open central lane between the staggered return shelves.
	if not await _walk(Vector2(H.X+1070,H.EXIT_Y-23),"purple descent panel"): return false
	for repeat in 2:
		if not await _drop_and_return(): return false
	set_meta("complete",true)
	return true

func _drop_and_return() -> bool:
	var camera:=world.player.get_node("Camera2D") as Camera2D
	for i in 40: await get_tree().physics_frame
	var start_camera:=camera.get_screen_center_position().y
	var previous:=camera.get_screen_center_position()
	_key(KEY_S,true)
	_key(KEY_SPACE,true)
	for i in 180:
		if i==3: _key(KEY_SPACE,false); _key(KEY_S,false)
		await get_tree().physics_frame
		var current:=camera.get_screen_center_position()
		max_camera_step=maxf(max_camera_step,current.distance_to(previous))
		previous=current
		if not _coverage(): return false
		if i>10 and world.player.is_on_floor() and absf(world.player.position.y-(H.LOWER_Y-23))<3: break
	_key(KEY_SPACE,false)
	_key(KEY_S,false)
	if absf(world.player.position.y-(H.LOWER_Y-23))>3 or not world.player.is_on_floor(): _fail("Purple panel did not descend safely to lower hall"); return false
	for i in 50: await get_tree().physics_frame
	if camera.get_screen_center_position().y-start_camera<400 or max_camera_step>24: _fail("Lower camera failed to follow smoothly"); return false
	if world.player.drop_exception_active: _fail("Drop exception did not clear below panel"); return false
	set_meta("lower_reached",true)
	# The lower corridor's recessed piers and crystal crests must remain walkable air.
	for x in [H.X+150,H.X+450,H.X+800,H.X+1070]:
		if not await _walk(Vector2(x,H.LOWER_Y-23),"lower hall floor"): return false
	if not await _walk(Vector2(13900,H.LOWER_Y-23),"8.1 open continuation into9.1"): return false
	if world.current_room!=6: _fail("Lower artwork seam changed rooms"); return false
	if not await _walk(Vector2(H.return_cap(0).end.x+30,H.LOWER_Y-23),"return shaft takeoff"): return false
	for i in 6:
		var cap: Rect2=H.return_cap(i)
		var from_left: bool=world.player.position.x<cap.position.x
		jump_delay=9
		if not await _jump(world.player.position,Vector2(cap.position.x+28 if from_left else cap.end.x-28,cap.position.y-23)): return false
		if i<5:
			var next: Rect2=H.return_cap(i+1)
			if not await _walk(Vector2(cap.end.x-12 if next.position.x>cap.position.x else cap.position.x+12,cap.position.y-23),"return shelf takeoff"): return false
	jump_delay=9
	# Jump up through the one-way support and land on it again.
	if not await _jump(world.player.position,Vector2(H.X+1070,H.EXIT_Y-23)): return false
	if world.player.drop_exception_active or not world.player.is_on_floor(): _fail("Purple floor failed to reattach after return"); return false
	if world.current_room!=6 or not _coverage(): _fail("Vertical branch changed rooms or exposed blank art"); return false
	set_meta("return_verified",true)
	return true

func ground_return() -> bool:
	world=get_tree().current_scene
	for x in [13710,13300,12800,12555]:
		if not await _walk(Vector2(x,H.EXIT_Y-23),"Section 8 to 7 ground return"): return false
	return true
