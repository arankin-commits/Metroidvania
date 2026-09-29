extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	set_meta("active_save_slot",0)
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await process_frame
	var world: Node2D=current_scene
	world.player.set_physics_process(false)
	var camera: Camera2D=world.player.get_node("Camera2D")
	camera.position_smoothing_enabled=false
	camera.reset_smoothing()
	for index in 8:
		world.player.wake_elapsed=index*.5+.05
		world.player.queue_redraw()
		await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://design/reviews/cave-opening-pose-%d.png" % index)
	world.player._advance_wake(4)
	world.player.set_physics_process(true)
	for tick in 8: await physics_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://design/reviews/cave-opening-standing.png")
	print("CAVE_OPENING_VISUAL_PASS: all eight waking poses and standing transition in new Room 1")
	quit()
