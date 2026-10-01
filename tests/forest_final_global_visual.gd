extends "res://tests/forest_upper_gallery_route.gd"

func begin() -> void:
	world=get_tree().current_scene
	assert(world.active_save_slot==0)
	world.player.invulnerability=1000
	await world._change_room(6,3690)
	for x in [3900,4500,4980,5350,5800,6250,6740]:
		if not await _walk(Vector2(x,STAIR.surface_y(x)-23 if x>=5000 else 577),"final whole-room ascent"): return
	if not await run_route(): return
	set_meta("room2_complete",true)
	# Separate receiving fixture from the verified Section3 one-way return.
	world.player.position=Vector2(16120,world.FINAL_LAYOUT.FLOOR-23)
	world.player.reset_movement_state()
	world._set_camera()
	var local: Node=load("res://tests/forest_final_concourse_route.gd").new()
	local.name="FinalLocalReview"
	local.visual=true
	world.add_child(local)
	if not await local.run_route(): _fail(str(local.get_meta("failure","Final-area route failed"))); return
	await _overview()
	world.world_map.show_map(world.visited_rooms,world._completed_rooms(),world.current_room,world.get_fast_travel_hands())
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-final-map.png")
	world.world_map.hide_map()
	set_meta("global_complete",true)

func _walk(target: Vector2,label: String) -> bool:
	if not await super._walk(target,label): return false
	if label=="final whole-room ascent" and roundi(target.x) in [4980,5350,6740]:
		for i in 35: await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-final-global%d.png"%roundi(target.x))
	return true

func _overview() -> void:
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(1440,230)
	viewport.disable_3d=true
	viewport.world_2d=get_viewport().world_2d
	add_child(viewport)
	var camera:=Camera2D.new()
	camera.position=Vector2(10800,175)
	camera.zoom=Vector2(0.1,0.1)
	viewport.add_child(camera)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	for i in 3: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://design/reviews/forest-final-overview.png")
	viewport.queue_free()
