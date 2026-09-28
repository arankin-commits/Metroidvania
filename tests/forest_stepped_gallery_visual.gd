extends "res://tests/forest_stepped_gallery_route.gd"

var capture_count:=0
var seam_captured:=false

func _walk(target: Vector2,label: String) -> bool:
	if not await super._walk(target,label): return false
	if roundi(target.x)==9008 and not seam_captured:
		seam_captured=true
		await _capture("seam")
	if label=="highest Section 6 approach":
		await _capture("highest")
		world.world_map.show_map(world.visited_rooms,world._completed_rooms(),world.current_room,world.get_fast_travel_hands())
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-room2-section5-map.png")
		world.world_map.hide_map()
	return true

func _jump(from: Vector2,to: Vector2) -> bool:
	if not await super._jump(from,to): return false
	if capture_count<3:
		capture_count+=1
		await _capture("cap%d"%capture_count)
	return true

func _capture(label: String) -> void:
	for i in 35: await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-room2-section5-"+label+".png")
