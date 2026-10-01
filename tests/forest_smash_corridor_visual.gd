extends "res://tests/forest_upper_gallery_route.gd"

var captured: Array[int]=[]

func _walk(target: Vector2,label: String) -> bool:
	if not await super._walk(target,label): return false
	var x:=roundi(target.x)
	if x in [7830,7940,8430] and not captured.has(x):
		captured.append(x)
		for i in 35: await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-room2-section4-%d.png"%x)
		if x==8430:
			world.world_map.show_map(world.visited_rooms,world._completed_rooms(),world.current_room,world.get_fast_travel_hands())
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-room2-section4-map.png")
			world.world_map.hide_map()
	return true
