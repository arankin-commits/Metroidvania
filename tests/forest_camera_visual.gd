extends Node
const L=preload("res://scripts/forest_arrival_layout.gd")

func begin() -> void:
	var w=get_tree().current_scene
	assert(w.active_save_slot==0)
	var p=w.player
	var camera=p.get_node("Camera2D") as Camera2D
	for at in [L.section2_point(Vector2(1500,345)),L.section3_point(Vector2(0,415)),L.section3_point(Vector2(1440,234))]:
		p.set_physics_process(true)
		p.position=at-Vector2(0,23)
		p.reset_movement_state()
		w._set_camera()
		for f in 40: await get_tree().physics_frame
		var start_y: float=p.position.y
		var start_camera: float=camera.get_screen_center_position().y
		var min_y:=start_y
		var min_camera:=start_camera
		_key(KEY_SPACE,true)
		for f in 52:
			if f==3: _key(KEY_SPACE,false)
			await get_tree().physics_frame
			min_y=minf(min_y,p.position.y)
			min_camera=minf(min_camera,camera.get_screen_center_position().y)
			if camera.limit_top!=L.CAMERA_TOP:
				_fail("Camera bound changed inside the room")
				return
			if f==24:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-jump-%d.png"%int(at.x))
		if start_y-min_y<90 or start_camera-min_camera<35:
			_fail("Jump blocked or camera clamped at %s: rise=%s follow=%s"%[at,start_y-min_y,start_camera-min_camera])
			return
		set_meta("jump_%d"%int(at.x),{"rise":start_y-min_y,"camera_follow":start_camera-min_camera})
	# Walk through the decorative spire with the real controller.
	p.position=L.section3_point(Vector2(1200,425))-Vector2(0,23)
	p.reset_movement_state()
	for f in 10: await get_tree().physics_frame
	_key(KEY_D,true)
	for f in 27: await get_tree().physics_frame
	_key(KEY_D,false)
	if p.position.x<L.section3_point(Vector2(1320,425)).x-15:
		_fail("Recessed spire still blocks walking")
		return
	set_meta("complete",true)
	set_meta("failure","")

func _key(code: Key,pressed: bool) -> void:
	var e:=InputEventKey.new()
	e.physical_keycode=code
	e.keycode=code
	e.pressed=pressed
	Input.parse_input_event(e)

func _fail(message: String) -> void:
	_key(KEY_SPACE,false)
	_key(KEY_D,false)
	set_meta("failure",message)
