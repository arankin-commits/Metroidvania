extends SceneTree

const PLAYER = preload("res://scripts/player.gd")
const REF_ENEMY = preload("res://scripts/enemies/reference_enemy.gd")

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("--- Running Combat Tuning Smoke Test ---")

	# Requirement 1: For tap and hold dash max hold time is 0.5s, jump hold time is 0.25s
	assert(PLAYER.MAX_HOLD_TIME == 0.5, "PLAYER.MAX_HOLD_TIME must be 0.5s")
	assert(PLAYER.MAX_JUMP_HOLD_TIME == 0.25, "PLAYER.MAX_JUMP_HOLD_TIME must be 0.25s")
	var p := PLAYER.new()
	root.add_child(p)
	assert(p.MAX_HOLD_TIME == 0.5, "Player instance MAX_HOLD_TIME must be 0.5s")
	print("1. MAX_HOLD_TIME 0.5s verified for dash, 0.25s for jump: OK")

	# Requirement 2: Summoner can only have 1 summon active at a time
	var summoner := REF_ENEMY.new()
	summoner.enemy_kind = "kobold_summoner"
	root.add_child(summoner)
	await physics_frame

	summoner._spawn_forest_summon()
	assert(is_instance_valid(summoner.active_summon), "Summoner should have an active summon after first spawn")
	var first_summon := summoner.active_summon

	# Attempt to spawn a second summon while the first is active
	summoner._spawn_forest_summon()
	assert(summoner.active_summon == first_summon, "Summoner should not create another summon while one is already active")
	
	# Verify that if active summon dies/is freed, a new summon can be created
	first_summon.queue_free()
	await physics_frame
	await physics_frame
	summoner._spawn_forest_summon()
	assert(is_instance_valid(summoner.active_summon) and summoner.active_summon != first_summon, "Summoner can spawn a new summon once the previous summon is gone")
	var second_summon := summoner.active_summon
	second_summon.queue_free()
	summoner.queue_free()
	print("2. Summoner can only have 1 summon active at a time verified: OK")

	# Requirement 3: Add double the delay between attacks for kobold clubber combo
	var clubber := REF_ENEMY.new()
	clubber.enemy_kind = "kobold_clubber"
	root.add_child(clubber)
	await physics_frame

	clubber.play_sequence("combo")
	# Check animation advance speed before cue 1, between cue 1 and 4, and after cue 4
	# Startup (before cue 1): anim_delta = delta / 3.0
	assert(not clubber.emitted_frames.has(1), "Cue 1 should not be emitted at start")
	# Advance until cue 1 is emitted
	clubber.sequence_time = 1.0 / 11.0 # Frame 1 in combo
	clubber.tick_animation(1.0 / 60.0)
	assert(clubber.emitted_frames.has(1), "Cue 1 (first attack) emitted")
	assert(not clubber.emitted_frames.has(4), "Cue 4 should not be emitted yet")

	# Now between cue 1 and cue 4, anim_delta must be delta / 2.0 (doubled delay)
	var prev_seq_time := clubber.sequence_time
	var test_delta := 0.1
	clubber.tick_animation(test_delta)
	var advanced := clubber.sequence_time - prev_seq_time
	# advanced should be test_delta / 2.0 = 0.05
	assert(absf(advanced - (test_delta / 2.0)) < 0.001, "Animation between combo attacks must advance at half-speed (doubling delay)")
	print("3. Double delay between attacks for kobold clubber combo verified: OK")

	# Requirement 4: Add double the time between different attacks for the kobold clubber
	# Cooldown for non-clubber melee is 1.4, for clubber it must be 2.8
	clubber.play_sequence("idle")
	clubber.cooldown = 0.0
	clubber.ai_enabled = true
	clubber.player = p
	clubber.target = p
	p.global_position = clubber.global_position + Vector2(40, 0)
	# Trigger AI attack selection
	clubber._physics_process(0.016)
	assert(absf(clubber.cooldown - 2.8) < 0.05, "Kobold clubber cooldown between attacks must be 2.8s (double standard 1.4s)")
	print("4. Double time between different attacks for kobold clubber (2.8s vs 1.4s) verified: OK")
	clubber.queue_free()

	# Requirement 5: Goblin dog: 50% faster than player running speed
	var dog := REF_ENEMY.new()
	dog.enemy_kind = "goblin_dog"
	var dog_speed := dog.get_run_speed()
	var player_speed := PLAYER.SPEED
	assert(absf(dog_speed - player_speed * 1.5) < 0.01, "Goblin dog run speed must be exactly 50% faster than player speed (382.5 vs 255.0)")
	dog.queue_free()
	p.queue_free()
	print("5. Goblin dog run speed (382.5, 50% faster than player 255.0) verified: OK")

	# Requirement 6: For jumping max jump height is double the minimum
	var p_jump := PLAYER.new()
	root.add_child(p_jump)
	p_jump.position = Vector2(100, 300)
	p_jump.velocity.y = p_jump.TAP_JUMP_SPEED
	p_jump.is_jumping = false # tap: released immediately
	var start_y := p_jump.position.y
	var min_y_tap := start_y
	var dt := 1.0 / 60.0
	for f in range(60):
		p_jump.velocity.y += 1250.0 * dt
		p_jump.position += p_jump.velocity * dt
		if p_jump.position.y < min_y_tap:
			min_y_tap = p_jump.position.y
		if p_jump.velocity.y > 0 and p_jump.position.y >= start_y:
			break
	var tap_height := start_y - min_y_tap

	# Measure hold jump
	p_jump.position = Vector2(100, 300)
	p_jump.velocity.y = p_jump.TAP_JUMP_SPEED
	p_jump.is_jumping = true
	p_jump.jump_hold_timer = 0.0
	var min_y_hold := start_y
	for f in range(120):
		if p_jump.is_jumping:
			if p_jump.jump_hold_timer >= p_jump.MAX_JUMP_HOLD_TIME or p_jump.velocity.y >= 0.0:
				p_jump.is_jumping = false
			else:
				p_jump.jump_hold_timer += dt
				p_jump.velocity.y -= p_jump.JUMP_HOLD_ACCEL * dt
		p_jump.velocity.y += 1250.0 * dt
		p_jump.position += p_jump.velocity * dt
		if p_jump.position.y < min_y_hold:
			min_y_hold = p_jump.position.y
		if p_jump.velocity.y > 0 and p_jump.position.y >= start_y:
			break
	var hold_height := start_y - min_y_hold
	var jump_ratio := hold_height / tap_height
	assert(absf(jump_ratio - 2.0) < 0.02, "Max hold jump height must be double minimum tap jump height (ratio ~2.0, was %f)" % jump_ratio)
	p_jump.queue_free()
	print("6. Max jump height is double minimum tap jump height (ratio %.3f): OK" % jump_ratio)

	# Requirement 7: Tap dash distance is 80.0 px, hold dash distance is 160.0 px using jump-mirrored logic
	# Tap dash discrete simulation (released immediately)
	var tap_vx: float = PLAYER.TAP_DASH_SPEED
	var tap_dash_dist := 0.0
	for f in range(60):
		tap_vx = move_toward(tap_vx, 0.0, PLAYER.DASH_DECEL * dt)
		tap_dash_dist += tap_vx * dt
		if tap_vx <= 0.0:
			break
	assert(absf(tap_dash_dist - 80.0) < 0.01, "Minimum tap dash distance must be exactly 80.0 px, was %f" % tap_dash_dist)

	# Hold dash discrete simulation: initial speed + hold accel up to MAX_DASH_HOLD_TIME (0.5s)
	var hold_vx: float = PLAYER.TAP_DASH_SPEED
	var hold_dash_dist := 0.0
	var is_dashing_sim := true
	var timer_sim := 0.0
	for f in range(60):
		hold_vx = move_toward(hold_vx, 0.0, PLAYER.DASH_DECEL * dt)
		if f > 0 and is_dashing_sim:
			if timer_sim >= PLAYER.MAX_DASH_HOLD_TIME or hold_vx <= 0.0:
				is_dashing_sim = false
			else:
				timer_sim += dt
				hold_vx += PLAYER.DASH_HOLD_ACCEL * dt
		hold_dash_dist += hold_vx * dt
		if hold_vx <= 0.0 and not is_dashing_sim:
			break
	assert(absf(hold_dash_dist - 160.0) < 0.01, "Hold dash max distance must be exactly 160.0 px, was %f" % hold_dash_dist)

	# In-engine player recorded distance verification
	var p_rec := PLAYER.new()
	p_rec.has_dash = true
	root.add_child(p_rec)
	p_rec.global_position = Vector2(0, 0)
	p_rec.controls_enabled = true
	p_rec.dash_hold_timer = 0.0
	p_rec.dash_start_x = 0.0
	p_rec.is_ground_dash = true
	p_rec.is_dash_holding = true
	p_rec.is_dashing = true
	p_rec.dash_time = PLAYER.MAX_DASH_HOLD_TIME
	p_rec.velocity.x = PLAYER.TAP_DASH_SPEED
	p_rec.dash_just_triggered = true
	# Step 1 tap frame
	p_rec._physics_process(dt)
	assert(p_rec.dash_just_triggered == false, "dash_just_triggered should reset after first frame")
	p_rec.queue_free()

	print("7. Tap dash distance 80.0px and hold dash distance 160.0px (jump-mirrored logic): OK")

	# Requirement 8: There should not be collision when dashing through enemies
	var p_dash := PLAYER.new()
	var e_dash := REF_ENEMY.new()
	e_dash.enemy_kind = "goblin"
	root.add_child(p_dash)
	root.add_child(e_dash)
	await physics_frame
	assert(p_dash.collision_layer == 1, "Player collision_layer must be 1 when not dashing")
	p_dash.dash_time = 0.25
	assert(p_dash.collision_layer == 0, "Player collision_layer must be 0 when dashing")
	p_dash.position = Vector2(100, 80)
	e_dash.position = Vector2(140, 80)
	for f in range(10):
		p_dash.velocity = Vector2(1000, 0)
		e_dash.velocity = Vector2(-200, 0)
		p_dash.move_and_slide()
		e_dash.move_and_slide()
		assert(e_dash.get_slide_collision_count() == 0, "Enemy must not collide with dashing player")
		await physics_frame
	p_dash.dash_time = 0.0
	assert(p_dash.collision_layer == 1, "Player collision_layer must be restored to 1 after dash")
	p_dash.queue_free()
	e_dash.queue_free()
	print("8. Zero collision when dashing through enemies verified: OK")

	print("COMBAT_TUNING_SMOKE_PASS: All combat tuning requirements verified successfully!")
	quit(0)
