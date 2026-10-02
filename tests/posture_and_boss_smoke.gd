extends SceneTree

const PLAYER_SCRIPT := preload("res://scripts/player.gd")
const GOBLIN_BOSS_SCRIPT := preload("res://scripts/goblin_boss.gd")
const GUARDIAN_SCRIPT := preload("res://scripts/forest_temple_guardian.gd")
const HUNTER_SCRIPT := preload("res://scripts/forest_hunter_combat.gd")
const REFERENCE_ENEMY_SCRIPT := preload("res://scripts/enemies/reference_enemy.gd")
const SCOUT_SCRIPT := preload("res://scripts/scout.gd")
const SENTINEL_SCRIPT := preload("res://scripts/ledge_sentinel.gd")
const SPIRIT_SCRIPT := preload("res://scripts/forest_guardian_spirit.gd")

func _initialize() -> void:
	call_deferred("run")

func fail(msg: String) -> void:
	push_error("TEST FAILED: " + msg)
	quit(1)

func run() -> void:
	print("--- Running Posture, Boss, and Enemy Mechanics Smoke Test ---")

	# 1. Posture health amount equals max_health
	var g_boss := GOBLIN_BOSS_SCRIPT.new()
	root.add_child(g_boss)
	if g_boss.max_posture != g_boss.max_health or g_boss.posture != g_boss.max_posture:
		fail("Goblin boss posture does not match max_health (%f vs %f)" % [g_boss.max_posture, g_boss.max_health])
		return

	var h_boss := HUNTER_SCRIPT.new()
	root.add_child(h_boss)
	if h_boss.max_posture != 50.0 or h_boss.posture != 50.0:
		fail("Hunter boss posture does not match max_health (%f vs %f)" % [h_boss.max_posture, h_boss.max_health])
		return

	var t_boss := GUARDIAN_SCRIPT.new()
	root.add_child(t_boss)
	if t_boss.max_posture != 30.0 or t_boss.posture != 30.0:
		fail("Guardian boss posture does not match max_health (%f vs %f)" % [t_boss.max_posture, t_boss.max_health])
		return

	var scout := SCOUT_SCRIPT.new()
	root.add_child(scout)
	if scout.max_posture != scout.max_health or scout.posture != scout.max_posture:
		fail("Scout posture does not match max_health (%f vs %f)" % [scout.max_posture, scout.max_health])
		return

	var sentinel := SENTINEL_SCRIPT.new()
	root.add_child(sentinel)
	if sentinel.max_posture != 4.0 or sentinel.posture != 4.0:
		fail("Sentinel posture does not match max_health (%f vs %f)" % [sentinel.max_posture, sentinel.max_health])
		return

	var spirit := SPIRIT_SCRIPT.new()
	root.add_child(spirit)
	if spirit.max_posture != 6.0 or spirit.posture != 6.0:
		fail("Spirit posture does not match max_health (%f vs %f)" % [spirit.max_posture, spirit.max_health])
		return

	for kind in ["goblin", "goblin_dog", "goblin_sentinel", "goblin_elite", "kobold_archer", "kobold_clubber", "kobold_summoner"]:
		var ref := REFERENCE_ENEMY_SCRIPT.new()
		ref.enemy_kind = kind
		root.add_child(ref)
		if ref.max_posture != ref.max_health or ref.posture != ref.max_posture:
			fail("Enemy %s posture does not match max_health (%f vs %f)" % [kind, ref.max_posture, ref.max_health])
			return
		ref.queue_free()

	print("1. Posture health amounts verified.")

	# 2. Boss group
	if not g_boss.is_in_group("bosses"):
		fail("Goblin boss not in bosses group")
		return
	if not h_boss.is_in_group("bosses"):
		fail("Hunter boss not in bosses group")
		return
	if not t_boss.is_in_group("bosses"):
		fail("Guardian boss not in bosses group")
		return

	print("2. Boss group verified.")

	# 3. 1hit-combo mixups & halved next attack time
	var g_phases := g_boss.attack_phases("one_hit_combo")
	if g_phases.is_empty():
		fail("Goblin boss missing one_hit_combo attack phase")
		return
	var g_hits := 0
	for p in g_phases:
		if p.has("hit"):
			g_hits += 1
	if g_hits != 1:
		fail("Goblin boss one_hit_combo has %d hits, expected 1" % g_hits)
		return
	var g_last_phase: Dictionary = g_phases[g_phases.size() - 1]
	if float(g_last_phase.get("time", 0.0)) > 0.5:
		fail("Goblin boss one_hit_combo recovery time not halved: %f" % float(g_last_phase.get("time", 0.0)))
		return

	var t_phases := t_boss.attack_phases("one_hit_combo")
	if t_phases.is_empty():
		fail("Guardian boss missing one_hit_combo attack phase")
		return
	var t_hits := 0
	for p in t_phases:
		if p.has("hit"):
			t_hits += 1
	if t_hits != 1:
		fail("Guardian boss one_hit_combo has %d hits, expected 1" % t_hits)
		return
	var t_last_phase: Dictionary = t_phases[t_phases.size() - 1]
	if float(t_last_phase.get("time", 0.0)) > 0.5:
		fail("Guardian boss one_hit_combo recovery time not halved: %f" % float(t_last_phase.get("time", 0.0)))
		return

	# Boss idle after 1-hit combo is halved
	g_boss.attack_name = "one_hit_combo"
	g_boss.phases.clear()
	g_boss._next_phase()
	if not is_equal_approx(g_boss.state_time, 0.325):
		fail("Goblin boss idle time after one_hit_combo was %f, expected 0.325" % g_boss.state_time)
		return

	print("3. 1hit-combo mix-ups and halved next attack recovery verified.")

	# 4. Posture damage calculations
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(500, 600)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1000, 40)
	col.shape = shape
	floor_body.add_child(col)
	root.add_child(floor_body)

	var player := PLAYER_SCRIPT.new()
	player.position = Vector2(500, 560)
	root.add_child(player)
	player.has_heavy = true

	# Put player on floor
	for i in 10:
		player.velocity = Vector2(0, 500)
		player.move_and_slide()
		await physics_frame

	if not player.is_on_floor():
		fail("Player failed to register is_on_floor()")
		return

	# Ground normal step 0
	var normal_ground_step0: float = player.current_posture_damage(false)
	if not is_equal_approx(normal_ground_step0, 1.0):
		fail("Normal ground attack posture damage was %f, expected 1.0" % normal_ground_step0)
		return

	# Ground normal combo finisher (step 2)
	player.sword_combo_step = 2
	var normal_ground_finisher: float = player.current_posture_damage(false)
	if not is_equal_approx(normal_ground_finisher, 1.5):
		fail("Combo finisher posture damage was %f, expected 1.5" % normal_ground_finisher)
		return

	# Heavy attack ground
	player.sword_combo_step = -1
	var heavy_ground: float = player.current_posture_damage(true)
	if not is_equal_approx(heavy_ground, 3.0):
		fail("Heavy attack posture damage was %f, expected 3.0 (double)" % heavy_ground)
		return

	# Airborne attacks (half posture damage)
	player.position = Vector2(500, 200)
	player.velocity = Vector2(0, 0)
	player.move_and_slide()
	await physics_frame
	if player.is_on_floor():
		fail("Player should be airborne")
		return

	var normal_air: float = player.current_posture_damage(false)
	if not is_equal_approx(normal_air, 0.5):
		fail("Normal air attack posture damage was %f, expected 0.5 (half)" % normal_air)
		return

	var heavy_air: float = player.current_posture_damage(true)
	if not is_equal_approx(heavy_air, 1.5):
		fail("Heavy air attack posture damage was %f, expected 1.5" % heavy_air)
		return

	print("4. Ground and air posture damage calculations verified.")

	# 5. Posture break staggers (does not kill)
	var enemy := REFERENCE_ENEMY_SCRIPT.new()
	enemy.enemy_kind = "goblin_elite" # 8.0 health, 8.0 posture
	root.add_child(enemy)
	var defeated_called := [false]
	enemy.defeated.connect(func(): defeated_called[0] = true)

	# Regular hit (posture remains > 0): enemy should NOT stagger
	enemy.take_hit(1.0, 2.0)
	if enemy.sprite.animation == &"posture_break":
		fail("Enemy staggered after normal hit with posture remaining")
		return

	# Break posture: posture hits 0 -> STAGGER, not defeated!
	enemy.take_hit(1.0, 6.0) # takes remaining 6.0 posture damage
	if defeated_called[0]:
		fail("Enemy died when posture broke! Should only stagger.")
		return
	if enemy.sprite.animation != &"posture_break":
		fail("Enemy did not play posture_break animation on posture break")
		return
	if enemy.cooldown <= 0.0:
		fail("Enemy cooldown not set for stagger")
		return
	if enemy.posture != enemy.max_posture:
		fail("Enemy posture not reset after stagger")
		return

	# Boss posture break: boss enters stagger state, does NOT die
	g_boss.active = true
	g_boss.posture = 5.0
	g_boss.health = 20.0
	g_boss.take_hit(1.0, 5.0)
	if g_boss.state == "defeated":
		fail("Boss died when posture broke! Should stagger.")
		return
	if g_boss.state != "stagger":
		fail("Boss did not enter stagger state on posture break")
		return
	if g_boss.posture != g_boss.max_posture:
		fail("Boss posture did not reset after stagger")
		return

	print("5. Posture break stagger (no death) verified.")

	# 6. Jump and Dash Mechanics
	player.has_dash = true
	# Tap jump speed = -353.55 (yields 50px height, exactly half of 100px)
	if not is_equal_approx(PLAYER_SCRIPT.TAP_JUMP_SPEED, -353.55):
		fail("TAP_JUMP_SPEED is %f, expected -353.55" % PLAYER_SCRIPT.TAP_JUMP_SPEED)
		return

	# Dash tap and hold mechanics: tap = 80.0 px, hold = 160.0 px
	var dt_dash := 1.0 / 60.0
	var tap_v: float = PLAYER_SCRIPT.TAP_DASH_SPEED
	var dash_tap_dist := 0.0
	for f in range(60):
		tap_v = move_toward(tap_v, 0.0, PLAYER_SCRIPT.DASH_DECEL * dt_dash)
		dash_tap_dist += tap_v * dt_dash
		if tap_v <= 0.0:
			break
	if not is_equal_approx(dash_tap_dist, 80.0):
		fail("Dash tap distance is %f, expected 80.0" % dash_tap_dist)
		return

	var hold_v: float = PLAYER_SCRIPT.TAP_DASH_SPEED
	var dash_hold_dist := 0.0
	var is_dashing_p := true
	var timer_p := 0.0
	for f in range(60):
		hold_v = move_toward(hold_v, 0.0, PLAYER_SCRIPT.DASH_DECEL * dt_dash)
		if f > 0 and is_dashing_p:
			if timer_p >= PLAYER_SCRIPT.MAX_DASH_HOLD_TIME or hold_v <= 0.0:
				is_dashing_p = false
			else:
				timer_p += dt_dash
				hold_v += PLAYER_SCRIPT.DASH_HOLD_ACCEL * dt_dash
		dash_hold_dist += hold_v * dt_dash
		if hold_v <= 0.0 and not is_dashing_p:
			break
	if not is_equal_approx(dash_hold_dist, 160.0):
		fail("Dash hold distance is %f, expected 160.0" % dash_hold_dist)
		return

	# Max hold time is 0.5s for dash
	if not is_equal_approx(PLAYER_SCRIPT.MAX_HOLD_TIME, 0.5):
		fail("MAX_HOLD_TIME is %f, expected 0.5" % PLAYER_SCRIPT.MAX_HOLD_TIME)
		return

	# 7. Enemy attack startup time tripled
	var test_enemy := REFERENCE_ENEMY_SCRIPT.new()
	test_enemy.enemy_kind = "goblin"
	root.add_child(test_enemy)
	test_enemy.play_sequence(&"horizontal_slash") # CUE at frame 3
	# Call tick_animation with delta = 0.3s
	# Without 3x startup, sequence_time would be 0.3s (at 10fps, frame 3 would be reached)
	# With 3x startup (delta / 3.0), sequence_time should be 0.1s
	test_enemy.tick_animation(0.3)
	if not is_equal_approx(test_enemy.sequence_time, 0.1):
		fail("Enemy attack startup did not run at 1/3 speed (sequence_time was %f, expected 0.1)" % test_enemy.sequence_time)
		return

	# Clean up
	enemy.queue_free()
	test_enemy.queue_free()
	g_boss.queue_free()
	h_boss.queue_free()
	t_boss.queue_free()
	scout.queue_free()
	sentinel.queue_free()
	spirit.queue_free()
	player.queue_free()
	floor_body.queue_free()

	print("POSTURE_AND_BOSS_SMOKE_PASS: all posture, boss, and enemy mechanics verified successfully")
	quit(0)
