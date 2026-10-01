extends "res://tests/forest_upper_gallery_route.gd"

func begin() -> void:
	world=get_tree().current_scene
	assert(world.active_save_slot==0)
	# Isolated visual receiving fixture after the continuous whole-room pass.
	await world._change_room(6,5350)
	for x in [5350,5800,6250,6740]:
		if not await _walk(Vector2(x,STAIR.surface_y(x)-23),"expanded stair foundation view"): return
		if not _coverage(): return
		for i in 35: await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-room2-section8-global%d.png"%x)
	set_meta("visual_complete",true)
