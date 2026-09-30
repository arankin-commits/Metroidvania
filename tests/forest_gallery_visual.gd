extends "res://tests/forest_arrival_visual.gd"

const G=preload("res://scripts/forest_gallery_layout.gd")
const STAIR=preload("res://scripts/forest_stair_layout.gd")

func begin() -> void:
	world=get_tree().current_scene
	assert(world.active_save_slot==0)
	await world._change_room(6,3680)
	for x in [3900,4150,4500,4780,4970,4500,4150,3690]:
		if not await _walk(Vector2(x,577),"Room 2 walkway and arches"): return
	if not await _climb([
		Vector2(578,831),Vector2(505,750),Vector2(453,671),
		Vector2(380,613),Vector2(370,613),Vector2(444,534),
		Vector2(467,534),Vector2(421,462),Vector2(510,467)]): return
	if not await _walk(G.point(Vector2(1278,831))-Vector2(0,23),"west climb return"): return
	if not await _climb([
		Vector2(745,831),Vector2(821,750),Vector2(874,671),
		Vector2(927,613),Vector2(1018,613),Vector2(967,542),
		Vector2(913,514),Vector2(864,514),Vector2(805,467)]): return
	if not await _walk(G.point(Vector2(650,467))-Vector2(0,23),"central overlook"): return
	var camera:=world.player.get_node("Camera2D") as Camera2D
	var start_y: float=world.player.position.y
	var start_camera: float=camera.get_screen_center_position().y
	var min_y:=start_y
	var min_camera:=start_camera
	_key(KEY_SPACE,true)
	for i in 60:
		if i==3: _key(KEY_SPACE,false)
		await get_tree().physics_frame
		min_y=minf(min_y,world.player.position.y)
		min_camera=minf(min_camera,camera.get_screen_center_position().y)
		var frame_size: Vector2=world.get_viewport_rect().size/camera.zoom
		if not G.ART_EXTENT.merge(STAIR.ART_EXTENT).grow(2).encloses(Rect2(camera.get_screen_center_position()-frame_size*0.5,frame_size)):
			_fail("Room 2 camera exposes missing painting")
			return
	if start_y-min_y<90 or start_camera-min_camera<35:
		_fail("Room 2 jump or upper camera tracking failed")
		return
	set_meta("jump",{"rise":start_y-min_y,"camera_follow":start_camera-min_camera})
	if not await _walk(G.point(Vector2(1278,831))-Vector2(0,23),"east climb return"): return
	set_meta("complete",true)

func _climb(native_points: Array[Vector2]) -> bool:
	if not await _walk(G.point(native_points[0])-Vector2(0,23),"balcony ground approach"): return false
	for i in range(1,native_points.size()):
		var destination:=G.point(native_points[i])-Vector2(0,23)
		if absf(native_points[i].y-native_points[i-1].y)<2:
			if not await _walk_precise(destination): return false
		else:
			if not await _jump(world.player.position,destination): return false
		if not await _walk_precise(destination): return false
	return true

func _walk_precise(target: Vector2) -> bool:
	for i in 150:
		var dx: float=target.x-world.player.position.x
		_key(KEY_D,dx>2)
		_key(KEY_A,dx< -2)
		await get_tree().physics_frame
		if absf(dx)<4 and world.player.is_on_floor() and absf(world.player.position.y-target.y)<8:
			_key(KEY_D,false)
			_key(KEY_A,false)
			return true
	_key(KEY_D,false)
	_key(KEY_A,false)
	_fail("Cannot stand at precise balcony takeoff %s; ended %s"%[target,world.player.position])
	return false

func gallery_capture(label: String,at: Vector2) -> void:
	world.player.set_physics_process(false)
	world.player.position=at
	world._set_camera()
	world.player.get_node("Camera2D").position_smoothing_enabled=false
	world.player.get_node("Camera2D").force_update_scroll()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-room2-"+label+".png")
