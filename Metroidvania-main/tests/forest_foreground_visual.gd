extends Node
const L=preload("res://scripts/forest_arrival_layout.gd")

func begin() -> void:
	var world:=get_tree().current_scene
	assert(world.active_save_slot==0)
	var player: Node2D=world.player
	var threshold:=world.arrival.get_node("ForegroundOccluders/SharedSection3Threshold") as Sprite2D
	var bark_image:=threshold.texture.get_image()
	player.set_physics_process(false)
	var camera:=player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled=false
	# Independent samples chosen on the CURRENT painting, including the bark edge
	# reported by the player. Do not derive acceptance from the occluder polygon.
	for sample in [[Vector2(235,850),true],[Vector2(280,740),true],[Vector2(330,790),true],[Vector2(250,750),false],[Vector2(350,790),false],[Vector2(205,770),false],[Vector2(395,770),false],[Vector2(1140,450),true],[Vector2(1120,520),false]]:
		player.position=L.SECTION2_ORIGIN-Vector2(0,416*L.SCALE)+sample[0]*Vector2(1200.0/1303.0,1548.7*L.SCALE/1207.0)
		player.visible=true
		world._set_camera()
		camera.force_update_scroll()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var shown:=get_viewport().get_texture().get_image()
		var center: Vector2=get_viewport().get_canvas_transform()*player.position
		player.visible=false
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var hidden:=get_viewport().get_texture().get_image()
		var changed:=0
		for y in range(int(center.y)-6,int(center.y)+7):
			for x in range(int(center.x)-3,int(center.x)+4):
				if shown.get_pixel(x,y)!=hidden.get_pixel(x,y): changed+=1
		if (sample[1] and changed>0) or (not sample[1] and changed<70):
			set_meta("failure","Current bark edge sample %s: visible=%d expected covered=%s"%[sample[0],changed,sample[1]])
			player.visible=true
			return
	for at in [L.section2_point(Vector2(380,611)),L.section2_point(Vector2(1640,345)),L.section3_point(Vector2(40,415)),L.section3_point(Vector2(0,415))]:
		player.position=at-Vector2(0,23)
		player.visible=true
		world._set_camera()
		camera.force_update_scroll()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var shown:=get_viewport().get_texture().get_image()
		var center: Vector2=get_viewport().get_canvas_transform()*player.position
		player.visible=false
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var hidden:=get_viewport().get_texture().get_image()
		var changed:=0
		var coverage:=0
		for y in range(int(center.y)-35,int(center.y)+35):
			for x in range(int(center.x)-28,int(center.x)+28):
				if x>=0 and y>=0 and x<shown.get_width() and y<shown.get_height():
					var pixel_world: Vector2=get_viewport().get_canvas_transform().affine_inverse()*Vector2(x+0.5,y+0.5)
					var covered:=false
					for layer in world.arrival.get_node("ForegroundOccluders").get_children():
						if not layer is Polygon2D: continue
						var local: Vector2=layer.to_local(pixel_world)
						if Geometry2D.is_point_in_polygon(local,layer.polygon) and Geometry2D.is_point_in_polygon(local+Vector2(2,2),layer.polygon) and Geometry2D.is_point_in_polygon(local-Vector2(2,2),layer.polygon): covered=true
					var bark_pixel:=threshold.to_local(pixel_world)
					if bark_pixel.x>=0 and bark_pixel.y>=0 and bark_pixel.x<bark_image.get_width() and bark_pixel.y<bark_image.get_height():
						if bark_image.get_pixel(int(bark_pixel.x),int(bark_pixel.y)).a>=0.9: covered=true
					if covered:
						coverage+=1
						if shown.get_pixel(x,y)!=hidden.get_pixel(x,y): changed+=1
		if changed>0 or coverage<50:
			set_meta("failure","Foreground pixel check at %s: leaks=%d coverage=%d"%[at,changed,coverage])
			player.visible=true
			return
	# Receiving/return foliage and recessed ruins must not obscure the live player.
	for at in [L.point(Vector2(1660,416)),L.section3_point(Vector2(1260,778)),L.section3_point(Vector2(1160,676)),L.section3_point(Vector2(1270,425))]:
		player.position=at-Vector2(0,23)
		player.visible=true
		world._set_camera()
		camera.force_update_scroll()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var shown:=get_viewport().get_texture().get_image()
		var center: Vector2=get_viewport().get_canvas_transform()*player.position
		player.visible=false
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var hidden:=get_viewport().get_texture().get_image()
		var changed:=0
		for y in range(int(center.y)-18,int(center.y)+18):
			for x in range(int(center.x)-10,int(center.x)+10):
				if shown.get_pixel(x,y)!=hidden.get_pixel(x,y): changed+=1
		if changed<300:
			set_meta("failure","Landing/player obscured at %s: visible pixels=%d"%[at,changed])
			player.visible=true
			return
	player.visible=true
	player.position=L.entry()
	player.reset_movement_state()
	player.set_physics_process(true)
	camera.position_smoothing_enabled=true
	world._set_camera()
	set_meta("complete",true)
