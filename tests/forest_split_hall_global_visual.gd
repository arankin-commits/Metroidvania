extends "res://tests/forest_upper_gallery_route.gd"

func begin() -> void:
	world=get_tree().current_scene
	assert(world.active_save_slot==0)
	await world._change_room(6,3690)
	for x in [3900,4500,4980,5350,5800,6250,6740]:
		if not await _walk(Vector2(x,STAIR.surface_y(x)-23 if x>=5000 else 577),"whole-room continuous ascent"): return
	if not await run_route(): return
	set_meta("global_complete",true)

func _walk(target: Vector2,label: String) -> bool:
	if not await super._walk(target,label): return false
	if label=="whole-room continuous ascent" and roundi(target.x) in [4980,5350,6740]:
		for i in 35: await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-room2-section8-global%d.png"%roundi(target.x))
	return true
