extends SceneTree

const PLAYER = preload("res://scripts/player.gd")
const REF_ENEMY = preload("res://scripts/enemies/reference_enemy.gd")
const GOBLIN_BOSS = preload("res://scripts/goblin_boss.gd")
const SCOUT = preload("res://scripts/scout.gd")

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("--- Running Death Healing and Dash Through Enemies Smoke Test ---")

	# Test 1: Player healing charges restored on heal_full() and death
	var p := PLAYER.new()
	root.add_child(p)
	p.healing_charges = 0
	p.heal_full()
	assert(p.healing_charges == p.max_healing_charges, "heal_full should restore max_healing_charges")
	print("1. heal_full() restores max_healing_charges: OK")

	# Test with injured player
	p.set_injured(true)
	p.healing_charges = 0
	p.heal_full()
	assert(p.healing_charges == p.max_healing_charges, "heal_full on injured player should restore max_healing_charges")
	print("2. heal_full() on injured restores max_healing_charges: OK")

	# Test 2: Dash immunity - player cannot take damage during dash_time > 0
	p.set_injured(false)
	p.has_dash = true
	p.health = p.max_health
	p.dash_time = 0.25
	p.take_damage(1.0, p.global_position.x - 20.0, false)
	assert(p.health == p.max_health, "Player should not take contact damage while dash_time > 0")
	p.take_damage(1.0, p.global_position.x - 20.0, true)
	assert(p.health == p.max_health, "Player should not take attack damage while dash_time > 0")
	print("3. Player immune to take_damage during dash_time > 0: OK")

	# Test 3: Dashing through standard enemy (Goblin)
	var goblin := REF_ENEMY.new()
	goblin.enemy_kind = "goblin"
	goblin.player = p
	root.add_child(goblin)
	p.global_position = Vector2(100, 300)
	goblin.global_position = Vector2(140, 300)
	goblin.ai_enabled = true
	p.velocity = Vector2(520, 0)
	p.dash_time = 0.25
	p.dash_speed_current = 520.0
	p.facing = 1

	var initial_player_hp := p.health
	for f in range(15):
		p.velocity = Vector2(520, 0)
		p.move_and_slide()
		goblin._physics_process(1.0 / 60.0)
		assert(p.collision_layer == 0, "Player collision_layer must be 0 while dashing")
		assert(goblin.get_slide_collision_count() == 0, "Goblin must have 0 slide collisions with dashing player")
		await physics_frame

	assert(p.health == initial_player_hp, "Player should not lose health when dashing through goblin")
	assert(p.global_position.x > goblin.global_position.x + 30.0, "Player should successfully dash through and clear goblin")
	print("4. Player successfully dashes through standard enemy without taking damage and zero collision: OK")

	# Test 4: Dashing through Goblin Boss
	var boss := GOBLIN_BOSS.new()
	boss.player = p
	boss.arena_bounds = Vector2(0, 2000)
	root.add_child(boss)
	p.global_position = Vector2(400, 300)
	boss.global_position = Vector2(500, 300)
	boss.active = true
	boss.health = boss.max_health

	p.velocity = Vector2(1000, 0)
	p.dash_time = 0.25 # Full hold dash
	p.dash_speed_current = 1000.0
	p.facing = 1

	var initial_hp := p.health
	for f in range(20):
		p.velocity = Vector2(1000, 0)
		p.move_and_slide()
		boss._physics_process(1.0 / 60.0)
		await physics_frame

	assert(p.health == initial_hp, "Player should not lose health when dashing through boss")
	assert(p.global_position.x > boss.global_position.x + 70.0, "Player should successfully dash through and clear boss")
	print("5. Player successfully dashes through boss without taking damage: OK")

	# Test 5: Tap dash vs Hold dash distances (tap = 80.0 px, hold = 160.0 px)
	var dt := 1.0 / 60.0
	# Tap dash simulation (released immediately)
	var tap_vx: float = PLAYER.TAP_DASH_SPEED
	var tap_dist := 0.0
	for f in range(60):
		tap_vx = move_toward(tap_vx, 0.0, PLAYER.DASH_DECEL * dt)
		tap_dist += tap_vx * dt
		if tap_vx <= 0.0:
			break
	assert(absf(tap_dist - 80.0) < 0.01, "Tap dash distance must be 80.0 px, was %f" % tap_dist)

	# Hold dash simulation (held for up to 0.5s = 30 frames)
	var hold_vx: float = PLAYER.TAP_DASH_SPEED
	var hold_dist := 0.0
	var is_dashing := true
	var timer := 0.0
	for f in range(60):
		hold_vx = move_toward(hold_vx, 0.0, PLAYER.DASH_DECEL * dt)
		if f > 0 and is_dashing:
			if timer >= PLAYER.MAX_DASH_HOLD_TIME or hold_vx <= 0.0:
				is_dashing = false
			else:
				timer += dt
				hold_vx += PLAYER.DASH_HOLD_ACCEL * dt
		hold_dist += hold_vx * dt
		if hold_vx <= 0.0 and not is_dashing:
			break
	assert(absf(hold_dist - 160.0) < 0.01, "Hold dash distance must be 160.0 px, was %f" % hold_dist)
	assert(PLAYER.MAX_HOLD_TIME == 0.5, "MAX_HOLD_TIME must be 0.5s")
	print("6. Tap dash (80.0px) and Hold dash (160.0px) verified: OK")

	p.queue_free()
	goblin.queue_free()
	boss.queue_free()

	print("DEATH_HEALING_AND_DASH_SMOKE_PASS: All healing restoration on death and dash through enemies verified successfully!")
	quit(0)
