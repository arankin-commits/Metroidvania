extends SceneTree
const PLAYER = preload("res://scripts/player.gd")
const ART = preload("res://scripts/player_presentation.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://design/references/player/complete-player-frames.json"))
	assert(catalog.frame_count == 67 and catalog.sequences.size() == 15)
	var pixels := ART.COMPLETE.get_image()
	if pixels.is_compressed(): pixels.decompress()
	assert(pixels.get_size() == Vector2i(1792, 2016))
	var accounted := {}
	for name in ART.SEQUENCES:
		assert(ART.SEQUENCES[name].size() == catalog.sequences[name].size(), "Supplied frame count changed")
		for slot in ART.SEQUENCES[name].size():
			assert(ART.SEQUENCES[name][slot] == int(catalog.sequences[name][slot]), "Supplied frame order changed")
		for index in ART.SEQUENCES[name]:
			assert(not accounted.has(index), "Frame duplicated between sequences")
			accounted[index] = true
			var cell := pixels.get_region(Rect2i(Vector2i(index % 8, index / 8) * 224, Vector2i(224, 224)))
			var bounds := cell.get_used_rect()
			assert(bounds.size.x > 10 and bounds.size.y > 30)
			assert(bounds.position.x > 0 and bounds.end.x < 224 and bounds.position.y > 0 and bounds.end.y == 160, "Frame lost gutter or foot alignment")
			if name.ends_with("idle"): assert(bounds.size.y == 58, "Standing height changed")
			for y in 224:
				for x in 224:
					var c := cell.get_pixel(x, y)
					assert(not(c.a > 0.1 and c.r > 0.7 and c.b > 0.7 and c.g < 0.3), "Magenta matte survived")
	assert(accounted.size() == 67, "Supplied frames missing")
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(0, 625)
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(2000, 50)
	collider.shape = shape
	floor_body.add_child(collider)
	root.add_child(floor_body)
	var p := PLAYER.new()
	p.position = Vector2(0, 577)
	root.add_child(p)
	for i in 4: await physics_frame
	p.set_physics_process(false)
	for name in ART.SEQUENCES:
		p.weapon_visible_time = 3 if name.begins_with("unsheathed") else 0
		p.attack_time = 0
		p.dash_time = 0
		p.velocity = Vector2.ZERO
		if name.ends_with("run"): p.velocity.x = 255
		elif name.ends_with("walk"): p.velocity.x = 90
		elif name.ends_with("jump") or name.ends_with("fall"):
			p.position = Vector2(0, 500)
			p.velocity.y = -200 if name.ends_with("jump") else 200
			p.move_and_slide()
		elif p.position.y < 575:
			p.position = Vector2(0, 577)
			p.velocity.y = 1
			p.move_and_slide()
			p.velocity = Vector2.ZERO
		var expected: Array = ART.SEQUENCES[name]
		for slot in expected.size():
			if name.begins_with("slash"):
				p.attack_style = "swing"
				p.sword_combo_step = ["slash_horizontal", "slash_upward", "slash_downward"].find(name)
				p.attack_time = 0.3 * (1.0 - (slot + 0.2) / expected.size())
			elif name.ends_with("dash"):
				p.dash_speed_current = 225
				p.dash_time = 0.17 * (1.0 - (slot + 0.2) / expected.size())
			p.visual_state = name
			var fps := 6.0 if name.ends_with("idle") else 14.0 if name.ends_with("jump") or name.ends_with("fall") else 12.0
			p.visual_state_time = (slot + 0.2) / fps
			assert(ART.sequence(p) == name, "Wrong controller state for " + name)
			assert(ART.frame_index(p) == expected[slot], "Playback skipped frame of " + name)
	p.queue_free()
	floor_body.queue_free()
	await process_frame
	print("COMPLETE_PLAYER_ANIMATION_PASS: all 67 supplied frames, 15 complete sequences, runtime order, alpha, registered feet and 58px standing height")
	quit()
