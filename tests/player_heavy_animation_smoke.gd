extends SceneTree
const PLAYER = preload("res://scripts/player.gd")
const ART = preload("res://scripts/player_presentation.gd")
var hits: Array[Rect2] = []

func _initialize() -> void: call_deferred("run")

func key(down: bool, code := KEY_H) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func frames(count: int) -> void:
	for i in count: await physics_frame

func run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://design/references/player/heavy-attack-frames.json"))
	assert(catalog.frames.size() == 9)
	var pixels := ART.HEAVY.get_image()
	if pixels.is_compressed(): pixels.decompress()
	assert(pixels.get_size() == Vector2i(576, 576))
	for index in 9:
		assert(int(catalog.frames[index].index) == index)
		var cell := pixels.get_region(Rect2i(Vector2i(index % 3, index / 3) * 192, Vector2i(192, 192)))
		var used := cell.get_used_rect()
		assert(used.position.x > 0 and used.end.x < 192 and used.position.y > 0 and used.end.y == 128, "Heavy pose lost foot pivot/gutter")
		if index in [0, 8]: assert(used.size.y == 58, "Heavy standing endpoint changed scale")
		for y in 192:
			for x in 192:
				var c := cell.get_pixel(x, y)
				assert(not(c.a > 0.1 and c.r > 0.7 and c.b > 0.7 and c.g < 0.3), "Heavy matte survived")
	var arena := Node2D.new()
	root.add_child(arena)
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(0, 625)
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(2000, 50)
	collider.shape = shape
	floor_body.add_child(collider)
	arena.add_child(floor_body)
	var floor_art := Polygon2D.new()
	floor_art.polygon = PackedVector2Array([Vector2(-1000, 600), Vector2(1000, 600), Vector2(1000, 700), Vector2(-1000, 700)])
	floor_art.color = Color("283b48")
	arena.add_child(floor_art)
	var p := PLAYER.new()
	p.position = Vector2(0, 577)
	arena.add_child(p)
	var camera := Camera2D.new()
	camera.position = Vector2(0, 570)
	camera.zoom = Vector2(3, 3)
	arena.add_child(camera)
	p.heavy_attacked.connect(func(bounds: Rect2): hits.append(bounds))
	await frames(5)
	key(true)
	await frames(55)
	key(false)
	await frames(2)
	assert(hits.is_empty(), "Heavy ability gate bypassed")
	p.has_heavy = true
	for direction in [-1, 1]:
		p.facing = direction
		p.reset_movement_state()
		key(true)
		await frames(12)
		key(false)
		await frames(2)
		assert(hits.size() == (0 if direction == -1 else 1), "Partial charge dealt damage")
		var seen: Array[int] = []
		key(true)
		for tick in 62:
			await frames(1)
			assert(p.heavy_attack_time == 0, "Holding H released attack")
			var index := ART.heavy_frame(p)
			if not seen.has(index):
				seen.append(index)
				await capture(direction, index)
		assert(seen == [0, 1, 2, 3, 4], "Charge skipped/reordered a supplied pose")
		var before := hits.size()
		key(false)
		for tick in 18:
			await frames(1)
			if p.heavy_attack_time <= 0: continue
			assert(ART.sequence(p) == "heavy_release")
			var index := ART.heavy_frame(p)
			if not seen.has(index):
				seen.append(index)
				await capture(direction, index)
		assert(seen == [0, 1, 2, 3, 4, 5, 6, 7, 8], "Release skipped/reordered a supplied pose")
		assert(hits.size() == before + 1, "Heavy must emit exactly one contact")
		assert(hits.back() == Rect2(p.global_position + Vector2(10 if direction > 0 else -106, -40), Vector2(96, 80)), "Heavy damage reach changed")
		await frames(45)
		p.heavy_charge = 1
		p.heavy_attack_time = 0.2
		p.reset_movement_state()
		assert(p.heavy_charge == 0 and p.heavy_attack_time == 0 and not p._heavy_was_down, "Room/death reset retained heavy state")
		assert(p.heavy_ready_time == 0 and ART.charge_flash(p) == 0, "Reset retained charge-ready blink")
	for direction in [-1, 1]:
		p.reset_movement_state()
		var move_key := KEY_A if direction < 0 else KEY_D
		key(true, move_key)
		await frames(12)
		assert(is_equal_approx(p.velocity.x, direction * p.SPEED), "Normal movement speed changed")
		key(true)
		await frames(2)
		assert(is_equal_approx(p.velocity.x, direction * p.SPEED * 0.5), "Charging must immediately halve movement speed")
		assert(ART.charge_flash(p) == 0, "Partial charge blinked ready")
		var walk_seen: Array[int] = []
		for tick in 54:
			await frames(1)
			assert(is_equal_approx(p.velocity.x, direction * p.SPEED * 0.5), "Charge movement exceeded half speed")
			assert(ART.sequence(p) == "heavy_charge", "Walking replaced the charging upper-body pose")
			var walk_index := ART.charge_walk_frame(p)
			if not walk_seen.has(walk_index): walk_seen.append(walk_index)
		assert(walk_seen.size() == 5, "Charging walk skipped leg frames")
		assert(p.heavy_charge == 1.0, "Moving prevented full charge")
		var blink_seen := false
		var normal_seen := false
		for tick in 18:
			await frames(1)
			if ART.charge_flash(p) == 1.0:
				blink_seen = true
				await capture_walk(direction, "white")
			else:
				normal_seen = true
				await capture_walk(direction, "normal")
		assert(blink_seen and normal_seen, "Full charge failed to blink white repeatedly")
		key(false)
		await frames(12)
		assert(ART.charge_flash(p) == 0 and p.heavy_ready_time == 0, "Release retained ready blink")
		assert(is_equal_approx(p.velocity.x, direction * p.SPEED), "Release failed to restore normal movement speed")
		key(false, move_key)
		await frames(12)
	key(false)
	arena.queue_free()
	await process_frame
	print("PLAYER_HEAVY_ANIMATION_PASS: nine poses, both facings, ability/contact/reset, half-speed charge walking with all five leg frames, full-charge white blink and release recovery")
	quit()

func capture(direction: int, index: int) -> void:
	if DisplayServer.get_name() == "headless": return
	# Hidden automated review windows may skip ordinary frame drawing.
	RenderingServer.force_draw()
	get_root().get_texture().get_image().save_png("res://design/reviews/player-heavy-%s-frame-%s.png" % [direction, index])

func capture_walk(direction: int, phase: String) -> void:
	if DisplayServer.get_name() == "headless": return
	RenderingServer.force_draw()
	var screenshot := get_root().get_texture().get_image()
	assert(screenshot.save_png("res://design/reviews/player-charge-walk-%s-%s.png" % [direction, phase]) == OK)
