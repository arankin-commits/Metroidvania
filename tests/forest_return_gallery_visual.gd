extends "res://tests/forest_return_gallery_route.gd"

var captures:=0

func _capture(label: String) -> void:
	for i in 35: await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-room2-section7-"+label+".png")

func _jump(from: Vector2,to: Vector2) -> bool:
	if not await super._jump(from,to): return false
	captures+=1
	if captures<=3 or captures==7: await _capture("landing%d"%captures)
	return true

func _walk(target: Vector2,label: String) -> bool:
	if not await super._walk(target,label): return false
	if label=="Section 7 east ground pocket": await _capture("east-ground")
	if label=="Section 7 to 6 high takeoff": await _capture("high-return")
	return true

func begin() -> void:
	world=get_tree().current_scene
	assert(world.active_save_slot==0)
	# The full-room test supplies the continuous approach; this visual fixture
	# isolates the same high seam and reverses without fixture landings afterward.
	world.player.position=Vector2(E.cap(2).end.x-35,E.cap(2).position.y-23)
	world.player.reset_movement_state()
	world._set_camera()
	for i in 40: await get_tree().physics_frame
	await _capture("high-seam")
	if not await run_route(): return
	if not await _walk(Vector2(11375,R.EXIT_Y-23),"Section 6 open-gap descent"): return
	if not await _walk(Vector2(11310,R.EXIT_Y-23),"Section 6 floor recovery"): return
	await _capture("ground-seam")
	if not await ground_route(): return
	if not await ground_return(): return
	world.world_map.show_map(world.visited_rooms,world._completed_rooms(),world.current_room,world.get_fast_travel_hands())
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-room2-section7-map.png")
	world.world_map.hide_map()
	set_meta("visual_complete",true)
