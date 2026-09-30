extends "res://tests/forest_upper_gallery_route.gd"

const E=preload("res://scripts/forest_elevated_gallery_layout.gd")
const PREV=preload("res://scripts/forest_stepped_gallery_layout.gd")

func run_route() -> bool:
	world=get_tree().current_scene
	if PREV.cap(2).position.y-E.cap(0).position.y<90:
		_fail("Section 6 entrance must require an upward jump from Section 5"); return false
	if not await _jump(world.player.position,Vector2(E.cap(0).position.x+35,E.cap(0).position.y-23)): return false
	if not await _walk(Vector2(E.cap(0).end.x-12,E.cap(0).position.y-23),"Section 6 west high takeoff"): return false
	if not await _jump(world.player.position,Vector2(E.cap(1).position.x+35,E.cap(1).position.y-23)): return false
	if not await _walk(Vector2(E.cap(1).end.x-12,E.cap(1).position.y-23),"Section 6 center takeoff"): return false
	if not await _jump(world.player.position,Vector2(E.cap(2).position.x+30,E.cap(2).position.y-23)): return false
	if not await _walk(Vector2(E.cap(2).end.x-35,E.cap(2).position.y-23),"Section 7 reserved high approach"): return false
	if not await _corridor_jump(): return false
	set_meta("all_caps_reached",true)
	var returning: Node=load("res://tests/forest_return_gallery_route.gd").new()
	world.add_child(returning)
	if not await returning.run_route(): _fail(str(returning.get_meta("failure","Section 7 failed"))); return false
	set_meta("section7_verified",true)
	if not await _walk(Vector2(E.cap(2).position.x+12,E.cap(2).position.y-23),"east reverse takeoff"): return false
	if not await _jump(world.player.position,Vector2(E.cap(1).end.x-30,E.cap(1).position.y-23)): return false
	if not await _walk(Vector2(E.cap(1).position.x+12,E.cap(1).position.y-23),"center reverse takeoff"): return false
	if not await _jump(world.player.position,Vector2(E.cap(0).end.x-30,E.cap(0).position.y-23)): return false
	if not await _walk(Vector2(E.cap(0).position.x+12,E.cap(0).position.y-23),"west reverse seam takeoff"): return false
	if not await _jump(world.player.position,Vector2(PREV.cap(2).end.x-30,PREV.cap(2).position.y-23)): return false
	set_meta("complete",true)
	return true

func floor_denial() -> bool:
	world=get_tree().current_scene
	# Explicit floor fixtures isolate access attempts; elevated acceptance uses continuous input.
	for c in [E.cap(0),E.cap(1),E.cap(2)]:
		for direction in [-1,0,1]:
			world.player.position=Vector2(c.get_center().x-direction*230,E.EXIT_Y-23)
			world.player.velocity=Vector2.ZERO
			for i in 40: await get_tree().physics_frame
			_key(KEY_SPACE,true)
			_key(KEY_A,direction==-1)
			_key(KEY_D,direction==1)
			for i in 100:
				if i==3: _key(KEY_SPACE,false)
				if i==12 and direction!=0: _key(KEY_K,true)
				if i==15: _key(KEY_K,false)
				if i==30:
					_key(KEY_A,false)
					_key(KEY_D,false)
				await get_tree().physics_frame
				if world.player.position.y<E.EXIT_Y-160:
					_fail("Section 6 floor jump/dash gained elevated access"); return false
			if not world.player.is_on_floor() or absf(world.player.position.y-(E.EXIT_Y-23))>3:
				_fail("Section 6 floor attempt did not recover on ground: %s direction %s room %s"%[world.player.position,direction,world.current_room]); return false
	set_meta("floor_denied",true)
	return true
