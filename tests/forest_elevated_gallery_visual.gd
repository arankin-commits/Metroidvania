extends "res://tests/forest_elevated_gallery_route.gd"

var cap_count:=0

func review_raised_entry() -> void:
	world=get_tree().current_scene
	assert(world.active_save_slot==0)
	# Isolated no-jump fixture; the full continuous route is verified separately.
	var takeoff:=Vector2(PREV.cap(2).end.x-30,PREV.cap(2).position.y-23)
	world.player.position=takeoff
	world.player.reset_movement_state()
	for i in 20: await get_tree().physics_frame
	await _capture("raised-entry")
	_key(KEY_D,true)
	for i in 45: await get_tree().physics_frame
	_key(KEY_D,false)
	if world.player.position.y<=E.cap(0).position.y-18 or world.player.ledge_grabbed:
		_fail("Section 6 can be entered from Section 5 without jumping"); return
	set_meta("walking_entry_denied",true)
	world.player.position=takeoff
	world.player.reset_movement_state()
	for i in 20: await get_tree().physics_frame
	if not await run_route(): return
	set_meta("raised_entry_verified",true)

func _jump(from: Vector2,to: Vector2) -> bool:
	if not await super._jump(from,to): return false
	cap_count+=1
	if cap_count<=3: await _capture("cap%d"%cap_count)
	return true

func _capture(label: String) -> void:
	for i in 35: await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-room2-section6-"+label+".png")

func begin() -> void:
	world=get_tree().current_scene
	assert(world.active_save_slot==0)
	# Section 5 climb is continuous; only initial entry is a receiving fixture.
	await world._change_room(6,8920)
	var climb: Node=load("res://tests/forest_stepped_gallery_route.gd").new()
	world.add_child(climb)
	if not await climb.run_route(): _fail(str(climb.get_meta("failure","climb failed"))); return
	# Repeat the elevated link with screenshots after the tested full approach.
	world.player.position=Vector2(PREV.cap(2).end.x-30,PREV.cap(2).position.y-23)
	world.player.velocity=Vector2.ZERO
	for i in 50: await get_tree().physics_frame
	if not await run_route(): return
	if not await _walk(Vector2(10620,E.EXIT_Y-23),"Section 6 open gap descent"): return
	if not await _walk(Vector2(10750,E.EXIT_Y-23),"Section 6 fall recovery"): return
	await _capture("floor")
	world.world_map.show_map(world.visited_rooms,world._completed_rooms(),world.current_room,world.get_fast_travel_hands())
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-room2-section6-map.png")
	world.world_map.hide_map()
	set_meta("visual_complete",true)
