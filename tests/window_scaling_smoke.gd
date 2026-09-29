extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	assert(root.content_scale_size==Vector2i(1152,648))
	assert(root.content_scale_stretch==Window.CONTENT_SCALE_STRETCH_FRACTIONAL)
	for dimensions in [Vector2i(768,432),Vector2i(1152,648),Vector2i(800,600)]:
		root.size=dimensions
		await process_frame
		await process_frame
		var transform:=root.get_final_transform()
		var image:=transform*Rect2(Vector2.ZERO,Vector2(1152,648))
		assert(image.position.x>=-1 and image.position.y>=-1,"View begins outside the window")
		assert(image.end.x<=root.size.x+1 and image.end.y<=root.size.y+1,"Window crops the game")
		assert(is_equal_approx(transform.x.x,transform.y.y),"Display distorts the room")
	print("WINDOW_SCALING_SMOKE_PASS: smaller, native and 4:3 windows contain the complete 16:9 view")
	quit()
