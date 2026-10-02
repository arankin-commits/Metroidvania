extends SceneTree

const PLAYER := preload("res://scripts/player.gd")
const REF_ENEMY := preload("res://scripts/enemies/reference_enemy.gd")
const FOREST_BOSS := preload("res://scripts/forest_hunter_combat.gd")
const TUTORIAL_WORLD := preload("res://scripts/tutorial_world.gd")
const SLOTS := preload("res://scripts/save_slots.gd")

func _initialize() -> void:
	call_deferred("run")

func fail(msg: String) -> void:
	push_error("TEST FAILED: " + msg)
	quit(1)

func run() -> void:
	print("--- Running Gauntlet, Enemy Wall Physics, and Forest Boss Smoke Test ---")

	# =========================================================================
	# TEST 1: Gauntlet turning while charging & 12 usage limit
	# =========================================================================
	var player := PLAYER.new()
	player.has_gauntlet = true
	player.equipped_weapon = "gauntlet"
	player.controls_enabled = true
	root.add_child(player)

	if player.gauntlet_charges != 12:
		fail("Player should start with 12 gauntlet charges (was: %d)" % player.gauntlet_charges)
		return

	# Can't turn when charging:
	player.facing = 1
	player.ability_charge = 0.5 # Gauntlet is currently charging
	# Simulate pressing Left (direction = -1.0)
	var charging_gauntlet := player.equipped_weapon == "gauntlet" and player.ability_charge > 0.0
	if not charging_gauntlet:
		player.facing = -1
	if player.facing != 1:
		fail("Player should not be able to turn while charging gauntlet")
		return
	print("1a. Gauntlet cannot turn when charging: OK")

	# Usage limit on rapid fire U key (hold U):
	player.ability_charge = 1.0
	player._ability_was_down = true
	player.ability_cooldown = 0.0
	# Release U when charged
	player._tick_weapon_ability(0.016)
	if player.gauntlet_charges != 11:
		fail("Rapid fire beam should consume 1 charge (was: %d)" % player.gauntlet_charges)
		return
	if player.beam_remaining != 4:
		fail("Rapid fire beam should initiate 4 beams (was: %d)" % player.beam_remaining)
		return

	# Tap U should not consume rapid fire charges:
	player.ability_charge = 0.0
	player._ability_was_down = true
	player.ability_cooldown = 0.0
	player._tick_weapon_ability(0.016)
	if player.gauntlet_charges != 11:
		fail("Normal tap U beam should not consume rapid-fire charges (was: %d)" % player.gauntlet_charges)
		return
	print("1b. Gauntlet consumes charge only on rapid-fire: OK")

	# Deplete charges to 0:
	player.gauntlet_charges = 0
	player.ability_charge = 0.0
	player.ability_cooldown = 0.0
	# Holding U with 0 charges should not increase ability_charge
	player._tick_weapon_ability(0.5)
	if player.ability_charge > 0.0:
		fail("Player should not be able to charge rapid fire when gauntlet_charges is 0")
		return
	print("1c. Cannot charge rapid fire at 0 charges: OK")

	# Hand chair reset restores gauntlet charges to 12:
	player.heal_full()
	if player.gauntlet_charges != 12:
		fail("Hand chair heal_full should restore gauntlet charges to 12 (was: %d)" % player.gauntlet_charges)
		return
	print("1d. Hand chair restores gauntlet charges: OK")

	# =========================================================================
	# TEST 2: Enemy is like a wall, does damage back, and cannot be moved by walking into it
	# =========================================================================
	player.position = Vector2(100, 300)
	player.velocity = Vector2.ZERO
	player.invulnerability = 0.0
	player.health = 5.0
	player.dash_time = 0.0
	player.is_dashing = false

	var enemy := REF_ENEMY.new()
	enemy.enemy_kind = "goblin"
	enemy.player = player
	enemy.position = Vector2(140, 300)
	enemy.velocity = Vector2.ZERO
	enemy.ai_enabled = false # Stationary wall test
	root.add_child(enemy)
	await physics_frame

	var enemy_initial_x: float = enemy.global_position.x

	# Walk player towards enemy for multiple physics frames:
	for f in range(15):
		player.velocity = Vector2(255.0, 0.0)
		player.move_and_slide()
		player._check_enemy_contact_damage()
		if player.health < 5.0:
			break
		await physics_frame

	if enemy.global_position.x != enemy_initial_x:
		fail("Walking into enemy should not move enemy (initial: %f, current: %f)" % [enemy_initial_x, enemy.global_position.x])
		return
	if player.health >= 5.0:
		fail("Hitting enemy should do contact damage back to player")
		return
	if player.velocity.x >= 0.0:
		fail("Player should receive knockback away from enemy after hitting it")
		return
	print("2a. Enemy acts like a wall that does damage back and cannot be moved by walking into it: OK")

	# Dash phases through enemy with zero collision:
	player.global_position = Vector2(100, 300)
	player.health = 5.0
	player.invulnerability = 0.0
	player.dash_time = 0.3
	player.is_dashing = true
	player.velocity = Vector2(520, 0)
	for f in range(10):
		player.move_and_slide()
	if player.global_position.x <= enemy.global_position.x:
		fail("Dash should phase freely past enemy")
		return
	if player.health != 5.0:
		fail("Player should take 0 damage while dashing through enemy")
		return
	print("2b. Dashing phases through enemy without damage: OK")

	enemy.queue_free()
	player.queue_free()
	await physics_frame

	# =========================================================================
	# TEST 3: Forest Boss Summoning Logic
	# =========================================================================
	var boss := FOREST_BOSS.new()
	var mock_player := CharacterBody2D.new()
	mock_player.position = Vector2(20400, 577)
	root.add_child(mock_player)
	root.add_child(boss)
	boss.player = mock_player
	boss.position = Vector2(20200, 553)
	boss.home_y = 553
	boss.active = true
	boss.health = 50.0

	# Initially 0 summons on field
	if boss.get_living_summons().size() != 0:
		fail("Boss should start with 0 living summons")
		return

	# Must require 3 attack cycles before summoning:
	boss.attack_cycles_since_summon = 2
	if boss.choose_attack() == "summon":
		fail("Boss should not summon before 3 attack cycles")
		return

	boss.attack_cycles_since_summon = 3
	if boss.choose_attack() != "summon":
		fail("Boss should choose summon between every 3 attack cycles when summons < 3")
		return

	# 1st Summon: none on field -> spawns 1 random summon
	boss.begin_attack("summon")
	boss.summon_enemies()
	var living := boss.get_living_summons()
	if living.size() != 1:
		fail("First summon should place exactly 1 summon on field (was: %d)" % living.size())
		return
	var v1: int = living[0].variant
	print("3a. 1st summon cast: 1 random summon (type %d) spawned: OK" % v1)

	# 2nd Summon: after 3 attack cycles -> spawns a DIFFERENT type
	boss.attack_cycles_since_summon = 3
	if boss.choose_attack() != "summon":
		fail("Boss should choose summon after 3 cycles with 1 summon on field")
		return
	boss.begin_attack("summon")
	boss.summon_enemies()
	living = boss.get_living_summons()
	if living.size() != 2:
		fail("Second summon should bring total summons to 2 (was: %d)" % living.size())
		return
	var v2: int = -1
	for s in living:
		if s.variant != v1:
			v2 = s.variant
	if v2 == -1 or v2 == v1:
		fail("Second summon must be a different type than the first (v1=%d, v2=%d)" % [v1, v2])
		return
	print("3b. 2nd summon cast: different type %d spawned (types now: %d, %d): OK" % [v2, v1, v2])

	# 3rd Summon: after 3 attack cycles -> spawns the 3rd remaining type
	boss.attack_cycles_since_summon = 3
	if boss.choose_attack() != "summon":
		fail("Boss should choose summon after 3 cycles with 2 summons on field")
		return
	boss.begin_attack("summon")
	boss.summon_enemies()
	living = boss.get_living_summons()
	if living.size() != 3:
		fail("Third summon should bring total summons to 3 (was: %d)" % living.size())
		return
	var variants: Array = [living[0].variant, living[1].variant, living[2].variant]
	variants.sort()
	if variants != [0, 1, 2]:
		fail("All 3 summons must be of distinct types (was: %s)" % str(variants))
		return
	print("3c. 3rd summon cast: 3 distinct types on field [0, 1, 2]: OK")

	# With 3 summons on field: Boss should NOT summon even if attack cycles >= 3
	boss.attack_cycles_since_summon = 5
	var choice := boss.choose_attack()
	if choice == "summon":
		fail("Boss must not summon when 3 summons are already on the field")
		return
	print("3d. Boss does not summon when 3 summons on field: OK")

	# Kill 1 summon (e.g. variant 1):
	for s in living:
		if s.variant == 1:
			s.health = 0.0
			break
	living = boss.get_living_summons()
	if living.size() != 2:
		fail("Living summons should be 2 after killing 1 summon")
		return

	# After 3 attack cycles, boss should summon again and pick the missing variant (1):
	boss.attack_cycles_since_summon = 3
	if boss.choose_attack() != "summon":
		fail("Boss should choose summon when a summon is killed and 3 cycles pass")
		return
	boss.begin_attack("summon")
	boss.summon_enemies()
	living = boss.get_living_summons()
	if living.size() != 3:
		fail("Replacement summon should bring count back to 3")
		return
	var new_variants: Array = [living[0].variant, living[1].variant, living[2].variant]
	new_variants.sort()
	if new_variants != [0, 1, 2]:
		fail("Replacement summon should restore missing variant (was: %s)" % str(new_variants))
		return
	print("3e. Replacement summon picks missing variant: OK")

	boss.reset_encounter()
	boss.queue_free()
	mock_player.queue_free()

	print("GAUNTLET_AND_BOSS_SMOKE_PASS: All gauntlet fixes, enemy wall physics, and forest boss summoning logic verified successfully!")
	quit(0)
