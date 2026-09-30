extends "res://tests/forest_upper_gallery_route.gd"

const R=preload("res://scripts/forest_return_gallery_layout.gd")
const E=preload("res://scripts/forest_elevated_gallery_layout.gd")

func run_route() -> bool:
	world=get_tree().current_scene
	if not await _jump(world.player.position,Vector2(R.cap(0).position.x+30,R.cap(0).position.y-23)): return false
	if not await _walk(Vector2(R.cap(0).end.x-12,R.cap(0).position.y-23),"Section 7 highest takeoff"): return false
	if not await _corridor_jump(): return false
	if not await _jump(world.player.position,Vector2(R.cap(1).position.x+30,R.cap(1).position.y-23)): return false
	if not await _walk(Vector2(R.cap(1).end.x-12,R.cap(1).position.y-23),"Section 7 middle takeoff"): return false
	if not await _jump(world.player.position,Vector2(R.cap(2).position.x+35,R.cap(2).position.y-23)): return false
	if not await _walk(Vector2(R.cap(2).end.x+35,R.EXIT_Y-23),"Section 7 east ground pocket"): return false
	# Reverse climb starts on the actual floor, without a fixture landing.
	if not await _jump(world.player.position,Vector2(R.cap(2).end.x-35,R.cap(2).position.y-23)): return false
	if not await _walk(Vector2(R.cap(2).position.x+12,R.cap(2).position.y-23),"pedestal reverse takeoff"): return false
	if not await _jump(world.player.position,Vector2(R.cap(1).end.x-30,R.cap(1).position.y-23)): return false
	if not await _walk(Vector2(R.cap(1).position.x+12,R.cap(1).position.y-23),"middle reverse takeoff"): return false
	if not await _jump(world.player.position,Vector2(R.cap(0).end.x-30,R.cap(0).position.y-23)): return false
	if not await _walk(Vector2(R.cap(0).position.x+12,R.cap(0).position.y-23),"Section 7 to 6 high takeoff"): return false
	if not await _jump(world.player.position,Vector2(E.cap(2).end.x-30,E.cap(2).position.y-23)): return false
	if world.current_room!=6 or not _coverage(): _fail("Section 7 high seam changes rooms or exposes blank art"); return false
	set_meta("complete",true)
	return true

func ground_route() -> bool:
	world=get_tree().current_scene
	for x in [11415,11800,R.cap(2).position.x-35]:
		if not await _walk(Vector2(x,R.EXIT_Y-23),"Section 7 ground approach"): return false
		if not _coverage(): return false
	if not await _jump(world.player.position,Vector2(R.cap(2).position.x+35,R.cap(2).position.y-23)): return false
	if not await _walk(Vector2(R.cap(2).end.x+35,R.EXIT_Y-23),"Section 7 pedestal east drop"): return false
	return true

func ground_return() -> bool:
	world=get_tree().current_scene
	jump_delay=0
	if not await _jump(world.player.position,Vector2(R.cap(2).end.x-35,R.cap(2).position.y-23)): return false
	jump_delay=9
	if not await _walk(Vector2(R.cap(2).position.x-35,R.EXIT_Y-23),"Section 7 pedestal west drop"): return false
	return true
