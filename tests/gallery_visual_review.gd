extends Node

# Isolated visual review, attached only by the editor inspection tools. No active save.
func capture(label: String, at: Vector2, overview: bool=false) -> void:
	var w=get_tree().current_scene
	assert(w.active_save_slot==0)
	w.set_process(false)
	w.player.set_physics_process(false)
	w.player.position=at
	w.player.invulnerability=0
	var c: Camera2D=w.player.get_node("Camera2D")
	c.position_smoothing_enabled=false
	c.zoom=Vector2.ONE
	w._set_camera_room()
	for enemy in w.gallery_encounters.targets():
		enemy.visible=true
		enemy.set_process(false)
		enemy.set_physics_process(false)
	w.ledge_sentinel.set_process(false)
	w.scout.set_physics_process(false)
	w.scout.collision_layer=0
	w.player.queue_redraw()
	if overview:
		c.zoom=Vector2(0.17,0.17)
		c.limit_left=-20000
		c.limit_right=20000
		c.limit_top=-20000
		c.limit_bottom=20000
	c.reset_smoothing()
	c.force_update_scroll()
	w.queue_redraw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var error:=get_viewport().get_texture().get_image().save_png("res://design/reviews/gallery-"+label+".png")
	set_meta("capture",label)
	set_meta("error",error)

func capture_all() -> void:
	for shot in [
		["overview",Vector2(2220,-30),true],
		["entrance",Vector2(650,1477),false],
		["well",Vector2(2140,-248),false],
		["memorial",Vector2(-230,-773),false],
		["future-floor",Vector2(3660,922),false],
		["crown-exit",Vector2(4630,-1523),false],
	]:
		await capture(shot[0],shot[1],shot[2])
	var w=get_tree().current_scene
	w.visited_rooms.assign([1,2,3,4])
	w.world_map.show_map(w.visited_rooms,w._completed_rooms(),2,w.get_fast_travel_hands())
	await capture("map",Vector2(3660,922))
	w.world_map.hide_map()
	w.hand_activated=true
	w.world_map.show_fast_travel(w)
	await capture("fast-travel",Vector2(120,1477))
	set_meta("all_complete",true)
