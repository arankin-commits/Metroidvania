extends "res://tests/forest_upper_gallery_route.gd"

const N=preload("res://scripts/forest_dash_galleries_layout.gd")
const HALL=preload("res://scripts/forest_split_hall_layout.gd")
var camera_step:=0.0

func run_route() -> bool:
	world=get_tree().current_scene
	if not await _ascend(): return false
	if not await _ordinary_cross(1): return false
	if not await _ascend(): return false
	if not await _dash_cross(1): return false
	if not await _ordinary_cross(-1): return false
	if not await _ascend(): return false
	if not await _dash_cross(1): return false
	if not await _dash_cross(-1): return false
	set_meta("dash_both_directions",true)
	# Return through the real Section8 ledges, then descend into its lower hall.
	if not await _walk(Vector2(HALL.CAPS[1].position.x+35,HALL.CAPS[1].position.y-23),"high gallery return to8 middle"): return false
	if not await _walk(Vector2(HALL.CAPS[1].end.x-12,HALL.CAPS[1].position.y-23),"8 middle takeoff"): return false
	if not await _jump(world.player.position,Vector2(HALL.CAPS[2].position.x+30,HALL.CAPS[2].position.y-23)): return false
	if not await _walk(Vector2(13825,N.FLOOR-23),"8 low ledge east descent"): return false
	if not await _walk(Vector2(13670,N.FLOOR-23),"8 purple descent"): return false
	_key(KEY_S,true); _key(KEY_SPACE,true)
	for i in 180:
		if i==3: _key(KEY_S,false); _key(KEY_SPACE,false)
		await get_tree().physics_frame
		if i>15 and world.player.is_on_floor(): break
	if absf(world.player.position.y-(N.LOWER_FLOOR-23))>4: _fail("Lower branch did not receive descent"); return false
	for x in [13900,14500,N.PORTAL.x]:
		if not await _walk(Vector2(x,N.LOWER_FLOOR-23),"9.1 to10.1 nonblocking corridor"): return false
	if not await _door_and_hand(): return false
	if not await _walk(Vector2(N.WALL_FLOOR_X-35,N.LOWER_FLOOR-23),"10.1 blue wall approach"): return false
	_key(KEY_D,true)
	for i in 90: await get_tree().physics_frame
	_key(KEY_D,false)
	if world.player.position.x>N.WALL_FLOOR_X-12 or world.current_room!=6: _fail("10.1 blue wall is passable"); return false
	for x in [N.PORTAL.x,14500,13900,HALL.return_cap(0).end.x+30]:
		if not await _walk(Vector2(x,N.LOWER_FLOOR-23),"lower corridor return to8.1"): return false
	for i in 6:
		var cap: Rect2=HALL.return_cap(i)
		var from_left: bool=world.player.position.x<cap.position.x
		jump_delay=9
		if not await _jump(world.player.position,Vector2(cap.position.x+28 if from_left else cap.end.x-28,cap.position.y-23)): return false
		if i<5:
			var next: Rect2=HALL.return_cap(i+1)
			if not await _walk(Vector2(cap.end.x-12 if next.position.x>cap.position.x else cap.position.x+12,cap.position.y-23),"8.1 return shelf takeoff"): return false
	if not await _jump(world.player.position,Vector2(13670,N.FLOOR-23)): return false
	for x in [14000,15000,16165]:
		if not await _walk(Vector2(x,N.FLOOR-23),"9.2 and10.2 recovery floor"): return false
	set_meta("complete",true)
	return true

func _ascend() -> bool:
	if not await _walk(Vector2(13825,N.FLOOR-23),"dash failure recovery to8"): return false
	jump_delay=9
	if not await _jump(world.player.position,Vector2(HALL.CAPS[2].end.x-30,HALL.CAPS[2].position.y-23)): return false
	jump_delay=9
	if not await _walk(Vector2(HALL.CAPS[2].position.x+12,HALL.CAPS[2].position.y-23),"8 low takeoff"): return false
	if not await _jump(world.player.position,Vector2(HALL.CAPS[1].end.x-30,HALL.CAPS[1].position.y-23)): return false
	if not await _walk(Vector2(HALL.CAPS[1].position.x+12,HALL.CAPS[1].position.y-23),"8 middle takeoff"): return false
	if not await _jump(world.player.position,Vector2(HALL.CAPS[0].position.x+30,HALL.CAPS[0].position.y-23)): return false
	if not await _walk(Vector2(N.CAPS[0].end.x-20,N.HIGH-23),"8.2 to9.2 highest seam"): return false
	return true

func _ordinary_cross(direction: int) -> bool:
	var receiving: Rect2=N.CAPS[1] if direction>0 else N.CAPS[0]
	var at:=receiving.position.x if direction>0 else receiving.end.x
	for i in 12: await get_tree().physics_frame
	_key(KEY_D,direction>0); _key(KEY_A,direction<0); _key(KEY_SPACE,true)
	var reached:=false
	for i in 160:
		if i==3: _key(KEY_SPACE,false)
		await get_tree().physics_frame
		if world.player.position.y+23<N.HIGH+60 and ((direction>0 and world.player.position.x>=at-20) or (direction<0 and world.player.position.x<=at+20)): reached=true
		if i>30 and world.player.is_on_floor(): break
	_key(KEY_D,false); _key(KEY_A,false); _key(KEY_SPACE,false)
	if reached or absf(world.player.position.y-(N.FLOOR-23))>4: _fail("Ordinary jump bypassed dash gate or failed safe recovery"); return false
	set_meta("normal_denied_right" if direction>0 else "normal_denied_left",true)
	return true

func _dash_cross(direction: int) -> bool:
	var departing: Rect2=N.CAPS[0] if direction>0 else N.CAPS[1]
	var receiving: Rect2=N.CAPS[1] if direction>0 else N.CAPS[0]
	if not await _walk(Vector2(departing.end.x-20 if direction>0 else departing.position.x+20,N.HIGH-23),"dash takeoff"): return false
	for i in 45: await get_tree().physics_frame
	_key(KEY_D,direction>0); _key(KEY_A,direction<0); _key(KEY_SPACE,true)
	var camera:=world.player.get_node("Camera2D") as Camera2D
	var previous:=camera.get_screen_center_position()
	var landed:=false
	for i in 120:
		if i==3: _key(KEY_SPACE,false)
		if i==22: _key(KEY_K,true)
		if i==25: _key(KEY_K,false)
		await get_tree().physics_frame
		var now:=camera.get_screen_center_position()
		camera_step=maxf(camera_step,now.distance_to(previous)); previous=now
		if not _coverage(): return false
		if i>30 and world.player.is_on_floor():
			landed=absf(world.player.position.y-(N.HIGH-23))<4 and receiving.grow(2).has_point(world.player.position+Vector2(0,23))
			break
	_key(KEY_D,false); _key(KEY_A,false); _key(KEY_SPACE,false); _key(KEY_K,false)
	if not landed or world.current_room!=6 or camera_step>24: _fail("Air dash failed receiving gallery or camera seam"); return false
	return true

func _door_and_hand() -> bool:
	var checkpoint: int=world.last_hand_room
	for i in 20: await get_tree().physics_frame
	if world.interaction_prompt().is_empty() or world.current_room!=6: _fail("Door proximity lacks prompt or enters automatically"); return false
	_key(KEY_E,true); _key(KEY_E,false)
	for i in 100:
		await get_tree().physics_frame
		if world.current_room==9 and not world.transitioning: break
	if world.current_room!=9 or world.last_hand_room!=checkpoint: _fail("Entering hand room replaced checkpoint or failed transition"); return false
	if not await _walk(N.HAND,"temple hand approach"): return false
	# Walking near the chair is not activation; E is required a second time.
	if world.last_hand_room!=checkpoint: _fail("Chair proximity activated checkpoint"); return false
	_key(KEY_E,true); _key(KEY_E,false)
	for i in 45: await get_tree().physics_frame
	if world.last_hand_room!=9 or not world.temple_hand_activated or not world.hand_menu.visible: _fail("Temple hand interaction failed"); return false
	world.hand_menu.hide_menu()
	for i in 80: await get_tree().physics_frame
	if not await _walk(N.HAND_RETURN,"temple hand return portal"): return false
	_key(KEY_E,true); _key(KEY_E,false)
	for i in 100:
		await get_tree().physics_frame
		if world.current_room==6 and not world.transitioning: break
	if world.current_room!=6 or absf(world.player.position.y-(N.LOWER_FLOOR-23))>4 or world.last_hand_room!=9: _fail("Door failed lower return or checkpoint preservation"); return false
	set_meta("hand_verified",true)
	return true

func ground_return() -> bool:
	world=get_tree().current_scene
	for x in [16120,15000,14000,13710]:
		if not await _walk(Vector2(x,N.FLOOR-23),"10.2 to8.2 ground return"): return false
	return true

func _coverage() -> bool:
	if world.current_room==9: return true
	return super._coverage()
