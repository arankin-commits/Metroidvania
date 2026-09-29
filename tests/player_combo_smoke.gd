extends SceneTree
const PLAYER = preload("res://scripts/player.gd")
const ART = preload("res://scripts/player_presentation.gd")
var hits: Array[Rect2] = []

func _initialize() -> void: call_deferred("run")
func key(down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_J
	event.keycode = KEY_J
	event.pressed = down
	Input.parse_input_event(event)
func frames(count: int) -> void:
	for i in count: await physics_frame

func run() -> void:
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(0, 625)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(2000, 50)
	collision.shape = shape
	floor_body.add_child(collision)
	root.add_child(floor_body)
	var p := PLAYER.new()
	p.position = Vector2(0, 577)
	root.add_child(p)
	p.attacked.connect(func(bounds: Rect2): hits.append(bounds))
	await frames(5)
	for direction in [-1, 1]:
		p.facing = direction
		p.reset_movement_state()
		await frames(20)
		for step in 4:
			var before := hits.size()
			key(true)
			await frames(3)
			assert(hits.size() == before, "Windup incorrectly dealt damage")
			assert(p.sword_combo_step == step % 3)
			assert(ART.sequence(p) == ["slash_horizontal", "slash_upward", "slash_downward"][step % 3], "Slash did not use its own animation")
			key(false)
			await frames(9)
			assert(hits.size() == before + 1, "Active hit failed: step=%s delay=%s timer=%s hits=%s before=%s" % [step, p.sword_hit_delay, p.attack_time, hits.size(), before])
			assert(hits.back().size == Vector2(72, 56), "Combo changed damage size")
			assert(hits.back().position == p.global_position + Vector2(10 if direction > 0 else -82, -28))
			await frames(11)
		await frames(55)
		key(true)
		await frames(3)
		assert(p.sword_combo_step == 0, "Pause failed to restart horizontal slash")
		await frames(8)
		var before := hits.size()
		await frames(40)
		assert(hits.size() == before, "Holding attack silently added hits")
		key(false)
		await frames(5)
		p.has_scimitar = true
		p.equipped_weapon = "scimitar"
		p._normal_attack()
		assert(p.sword_combo_step == 0, "Changing sword failed to restart chain")
		p.take_damage(1, p.global_position.x - 100)
		assert(p.sword_combo_step == -1 and p.sword_combo_window == 0)
		p.invulnerability = 0
		p.equipped_weapon = "starter"
	p.queue_free()
	floor_body.queue_free()
	await process_frame
	print("PLAYER_COMBO_PASS: three distinct slashes, both facings, wrap/reset, real presses, no extra hits and unchanged damage volumes")
	quit()
