extends Node
var complete := false

func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame

func snap(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/reviews/player-%s.png" % label)

func begin() -> void:
	get_tree().set_meta("active_save_slot", 0)
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")
	await get_tree().scene_changed
	await frames(20)
	var p = get_tree().current_scene.player
	p.position = Vector2(180, 1477)
	p.controls_enabled = true
	p.invulnerability = 0
	await frames(10)
	await snap("idle")
	for direction in [1, -1]:
		var code := KEY_D if direction > 0 else KEY_A
		key(code, true)
		await frames(10)
		await snap("run-%s" % direction)
		key(code, false)
		await frames(8)
	key(KEY_SPACE, true)
	await frames(6)
	key(KEY_SPACE, false)
	await snap("jump")
	await frames(30)
	await snap("fall")
	await frames(25)
	key(KEY_K, true)
	await frames(3)
	key(KEY_K, false)
	await snap("dash")
	await frames(20)
	for step in 3:
		key(KEY_J, true)
		await frames(2)
		key(KEY_J, false)
		assert(p.sword_combo_step == step)
		var sequence: String = p.PRESENTATION.sequence(p)
		var expected: Array = p.PRESENTATION.SEQUENCES[sequence]
		var seen := {}
		for i in 30:
			if p.attack_time <= 0: break
			var index: int = p.PRESENTATION.frame_index(p)
			if not seen.has(index):
				seen[index] = true
				await snap("combo-%s-frame-%s" % [step + 1, expected.find(index) + 1])
			await frames(1)
		assert(seen.size() == expected.size(), "Live playback skipped a supplied slash frame")
		await frames(5)
	p.has_heavy = true
	key(KEY_H, true)
	await frames(55)
	await snap("charge")
	key(KEY_H, false)
	await frames(3)
	await snap("heavy")
	await frames(25)
	complete = true
