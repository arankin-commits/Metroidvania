extends "res://tests/forest_upper_gallery_route.gd"

const P=preload("res://scripts/forest_stepped_gallery_layout.gd")

func run_route() -> bool:
	world=get_tree().current_scene
	for x in [9008,9125]:
		if not await _walk(Vector2(x,P.EXIT_Y-23),"Section 4 to 5 ground seam"): return false
		if world.current_room!=6 or not _coverage(): _fail("Section 5 seam changes rooms or exposes blank art"); return false
	if not await _walk(Vector2(P.cap(0).position.x-35,P.EXIT_Y-23),"pedestal launch pocket"): return false
	if not await _jump(world.player.position,Vector2(P.cap(0).position.x+35,P.cap(0).position.y-23)): return false
	if not await _walk(Vector2(P.cap(0).end.x-12,P.cap(0).position.y-23),"pedestal to middle takeoff"): return false
	if not await _jump(world.player.position,Vector2(P.cap(1).position.x+30,P.cap(1).position.y-23)): return false
	if not await _walk(Vector2(P.cap(1).end.x-12,P.cap(1).position.y-23),"middle to highest takeoff"): return false
	if not await _jump(world.player.position,Vector2(P.cap(2).position.x+30,P.cap(2).position.y-23)): return false
	if not await _walk(Vector2(P.cap(2).end.x-30,P.cap(2).position.y-23),"highest Section 6 approach"): return false
	set_meta("highest_reached",true)
	if not await _corridor_jump(): return false
	var elevated: Node=load("res://tests/forest_elevated_gallery_route.gd").new()
	world.add_child(elevated)
	if not await elevated.run_route(): _fail(str(elevated.get_meta("failure","Section 6 route failed"))); return false
	set_meta("section6_verified",true)
	# Return along the same three stone objects with continuous input.
	if not await _walk(Vector2(P.cap(1).end.x-25,P.cap(1).position.y-23),"highest to middle drop"): return false
	if not await _walk(Vector2(P.cap(0).end.x-25,P.cap(0).position.y-23),"middle to pedestal drop"): return false
	if not await _walk(Vector2(9130,P.EXIT_Y-23),"pedestal to entrance floor"): return false
	# Cross underneath the floating platforms, jumping to clear the solid pedestal.
	if not await _jump(world.player.position,Vector2(P.cap(0).position.x+35,P.cap(0).position.y-23)): return false
	if not await _walk(Vector2(P.cap(0).end.x+40,P.EXIT_Y-23),"pedestal east drop"): return false
	for x in [9600,9850,10110]:
		if not await _walk(Vector2(x,P.EXIT_Y-23),"Section 5 lower ground route"): return false
		if not _coverage(): return false
	for x in [10215,10400,10750,11150,11310]:
		if not await _walk(Vector2(x,P.EXIT_Y-23),"Section 6 lower ground route"): return false
		if not _coverage(): return false
	if not await elevated.floor_denial(): _fail(str(elevated.get_meta("failure","floor denial failed"))); return false
	if not await _walk(Vector2(11310,P.EXIT_Y-23),"Section 6 temporary outer exit"): return false
	var returning: Node=load("res://tests/forest_return_gallery_route.gd").new()
	world.add_child(returning)
	if not await returning.ground_route(): _fail(str(returning.get_meta("failure","Section 7 ground failed"))); return false
	var split: Node=load("res://tests/forest_split_hall_route.gd").new()
	world.add_child(split)
	if not await split.run_route(): _fail(str(split.get_meta("failure","Section 8 failed"))); return false
	set_meta("complete",true)
	return true

func begin() -> void:
	world=get_tree().current_scene
	assert(world.active_save_slot==0)
	await world._change_room(6,8920)
	await run_route()
