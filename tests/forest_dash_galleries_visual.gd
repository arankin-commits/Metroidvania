extends "res://tests/forest_dash_galleries_route.gd"

var capture_count:=0

func _capture(label: String) -> void:
	for i in 30: await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-room2-section910-"+label+".png")

func _walk(target: Vector2,label: String) -> bool:
	if not await super._walk(target,label): return false
	if label=="8.2 to9.2 highest seam" and capture_count==0:
		await _capture("9-upper"); capture_count+=1
	if label=="9.1 to10.1 nonblocking corridor": await _capture("lower-%d"%int(target.x))
	if label=="10.1 blue wall approach": await _capture("blue-wall")
	if label=="temple hand approach": await _capture("hand")
	if label=="temple hand return portal": await _capture("hand-return")
	return true

func _dash_cross(direction: int) -> bool:
	if not await super._dash_cross(direction): return false
	await _capture("dash-right" if direction>0 else "dash-left")
	return true

func begin() -> void:
	world=get_tree().current_scene
	assert(world.active_save_slot==0)
	await world._change_room(6,13670)
	await _capture("8-9-approach")
	if not await run_route(): return
	world.world_map.show_map(world.visited_rooms,world._completed_rooms(),world.current_room,world.get_fast_travel_hands())
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-room2-section910-map.png")
	world.world_map.hide_map()
	set_meta("visual_complete",true)
