extends SceneTree

const GUARDIAN = preload("res://scripts/forest_temple_guardian.gd")
const PLAYER = preload("res://scripts/player.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://design/references/temple-boss/temple-guardian-frames.json"))
	assert(catalog.frames.size() == 13)
	var pixels := GUARDIAN.ATLAS.get_image()
	if pixels.is_compressed(): pixels.decompress()
	assert(pixels.get_size() == Vector2i(1536,1536))
	for index in 13:
		var bounds := pixels.get_region(Rect2i(Vector2i(index%4,index/4)*384,Vector2i(384,384))).get_used_rect()
		assert(bounds.position.x > 0 and bounds.position.y > 0 and bounds.end.x < 384 and bounds.end.y < 384, "Clipped guardian cutout")
		assert(bounds.size.y > 100, "Missing guardian pose")
	var p := PLAYER.new()
	p.position = Vector2(23400,577)
	root.add_child(p)
	p.set_physics_process(false)
	p.controls_enabled = false
	p.invulnerability = 1000
	var boss := GUARDIAN.new()
	boss.position = Vector2(23300,553)
	boss.player = p
	root.add_child(boss)
	boss.active = true
	boss.set_physics_process(false)
	for direction in [-1,1]:
		p.position.x = boss.position.x + direction * 400
		boss.reset_encounter()
		boss.active = true
		for i in 30: assert(boss.choose_attack() == "rocket_punch", "Phase one used locked charged shot")
		boss.health = 3
		assert(boss.choose_attack() == "fire", "Half-health transition failed to unlock shot")
		boss.begin_attack("fire")
		assert(boss.state == "phase_transition" and boss.phase.get("invulnerable",false))
		boss.take_hit(1)
		assert(boss.health == 3, "Transition protection failed")
		while boss.state != "fire": boss._physics_process(1.0/60.0)
		assert(not boss.phase.get("invulnerable",false), "Shot launch retained protection")
		boss.take_hit(1)
		assert(boss.health == 2)
		var choices := {}
		for i in 100: choices[boss.choose_attack()] = true
		assert(choices.has("fire") and choices.has("rocket_punch") and choices.size()==2, "Phase two ranged selection changed")
		p.position.x = boss.position.x + direction * 90
		choices.clear()
		for i in 100: choices[boss.choose_attack()] = true
		assert(choices.has("punch_combo") and choices.has("slam") and choices.has("one_hit_combo") and choices.size()==3)
		var poses := {0:true}
		for name in ["rocket_punch","fire","punch_combo","slam","one_hit_combo"]:
			boss.begin_attack(name)
			var hits := 0
			var previous_phase: Dictionary = {}
			for tick in 300:
				poses[boss.frame_index()] = true
				if boss.phase.has("hit") and boss.phase != previous_phase:
					hits += 1
				previous_phase = boss.phase
				boss._physics_process(1.0/60.0)
				if boss.state == "idle": break
			assert(boss.state == "idle", "Attack failed to recover")
			assert(hits == (3 if name=="punch_combo" else 1 if (name=="slam" or name=="one_hit_combo") else 0), "Incorrect melee strike count")
		assert(poses.size()==13, "Supplied pose unreachable in runtime attacks")
		for shot in get_nodes_in_group("combat_projectiles"):
			assert(shot.get_script() == GUARDIAN.TEMPLE_PROJECTILE, "Placeholder projectile used")
			assert(shot.radius == (15 if shot.kind=="fist" else 21))
			if shot.kind=="fist": assert(shot.return_position().is_equal_approx(boss.rocket_wrist()), "Fist return missed the wrist")
			shot.queue_free()
		boss.reset_encounter()
		assert(not boss.phase_two_started and not boss.transition_pending and boss.phase_glow()==0)
		await process_frame
	boss.queue_free()
	p.queue_free()
	await process_frame
	print("TEMPLE_GUARDIAN_PASS: 13 poses, both facings, phase gates/protection/recovery, three punches, slam, reference projectiles, reset")
	quit()
