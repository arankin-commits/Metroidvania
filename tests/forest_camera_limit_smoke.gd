extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	set_meta("active_save_slot",0)
	set_meta("forest_entry_room",6)
	change_scene_to_file("res://scenes/forest_entry.tscn")
	await process_frame
	await physics_frame
	var world:=current_scene
	var camera: Camera2D=world.player.get_node("Camera2D")
	if not camera.limit_smoothed:
		push_error("Room 2 camera limit smoothing is disabled")
		quit(1)
		return
	for native_x in [820,970]:
		world.player.position=world.UPPER_LAYOUT.point(Vector2(native_x,468))-Vector2(0,23)
		world.player.reset_movement_state()
		world._set_camera()
		for i in 90: await physics_frame
		var previous:=camera.get_screen_center_position()
		var maximum:=0.0
		var stopped_frames:=0
		var maximum_stop:=0
		var previous_player_y: float=world.player.position.y
		_key(true)
		for i in 90:
			if i==3: _key(false)
			await physics_frame
			await process_frame
			var center:=camera.get_screen_center_position()
			maximum=maxf(maximum,center.distance_to(previous))
			if absf(world.player.position.y-previous_player_y)>1 and absf(center.y-previous.y)<0.02:
				stopped_frames+=1
			else: stopped_frames=0
			maximum_stop=maxi(maximum_stop,stopped_frames)
			previous_player_y=world.player.position.y
			previous=center
		if maximum>5.5 or maximum_stop>2 or world.current_room!=6:
			push_error("Room 2 jump camera snaps or stalls: step %s, stopped %s"%[maximum,maximum_stop])
			quit(1)
			return
		print("FOREST_CAMERA_LIMIT_SAMPLE ",JSON.stringify({"native_x":native_x,"max_frame_step":maximum,"hard_stop_frames":maximum_stop}))
	print("FOREST_CAMERA_LIMIT_SMOKE_PASS")
	quit()

func _key(pressed: bool) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=KEY_SPACE
	event.keycode=KEY_SPACE
	event.pressed=pressed
	Input.parse_input_event(event)
