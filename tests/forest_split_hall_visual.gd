extends "res://tests/forest_split_hall_route.gd"

var landings:=0

func _capture(label: String) -> void:
	for i in 35: await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-room2-section8-"+label+".png")

func _jump(from: Vector2,to: Vector2) -> bool:
	if not await super._jump(from,to): return false
	landings+=1
	if landings in [1,2,3,5,8,10,11]: await _capture("landing%d"%landings)
	return true

func _walk(target: Vector2,label: String) -> bool:
	if not await super._walk(target,label): return false
	if label=="Section 7 to 8 upper ground" and target.x==12625: await _capture("west-seam")
	if label=="lower hall floor" and target.x==H.X+800: await _capture("lower-hall")
	return true

func begin() -> void:
	world=get_tree().current_scene
	assert(world.active_save_slot==0)
	await world._change_room(6,12555)
	await _capture("section7-approach")
	if not await run_route(): return
	world.world_map.show_map(world.visited_rooms,world._completed_rooms(),world.current_room,world.get_fast_travel_hands())
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-room2-section8-map.png")
	world.world_map.hide_map()
	if not await ground_return(): return
	await _capture("west-return")
	set_meta("visual_complete",true)
