extends "res://tests/forest_upper_gallery_route.gd"

func begin() -> void:
	world=get_tree().current_scene
	assert(world.active_save_slot==0)
	# Match the headless geometry fixture. Existing boss/combat behavior is
	# verified separately; an uncleared arena deliberately locks its doorway.
	world.bow_boss_defeated=true
	world.bow_boss.visible=false
	world.bow_boss.active=false
	world._unlock_arena()
	world.player.invulnerability=1000
	await world._change_room(6,3690)
	for x in [3900,4500,4980,5350,5800,6250,6740]:
		if not await _walk(Vector2(x,STAIR.surface_y(x)-23 if x>=5000 else 577),"whole-room continuous ascent"): return
	if not await run_route(): return
	await _overview()
	world.world_map.show_map(world.visited_rooms,world._completed_rooms(),world.current_room,world.get_fast_travel_hands())
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-room2-section910-map.png")
	world.world_map.hide_map()
	set_meta("global_complete",true)

func _new_dash_route() -> Node:
	return load("res://tests/forest_dash_galleries_visual.gd").new()

func _walk(target: Vector2,label: String) -> bool:
	if not await super._walk(target,label): return false
	if label=="whole-room continuous ascent" and roundi(target.x) in [4980,5350,6740]:
		for i in 35: await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-room2-section910-global%d.png"%roundi(target.x))
	return true

func _overview() -> void:
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(1260,230)
	viewport.disable_3d=true
	viewport.world_2d=get_viewport().world_2d
	add_child(viewport)
	var camera:=Camera2D.new()
	camera.position=Vector2(9900,175)
	camera.zoom=Vector2(0.1,0.1)
	viewport.add_child(camera)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	for i in 3: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://design/reviews/forest-room2-section910-overview.png")
	viewport.queue_free()
