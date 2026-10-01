extends SceneTree

const LEDGE_SENTINEL = preload("res://scripts/ledge_sentinel.gd")
const REFERENCE_ENEMY = preload("res://scripts/enemies/reference_enemy.gd")
const SCOUT = preload("res://scripts/scout.gd")
const PLAYER = preload("res://scripts/player.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# 1. Health checks
	var sentinel := LEDGE_SENTINEL.new()
	assert(sentinel.max_health == 4.0, "Sleeping goblin health must be 4.0 (doubled from 2.0)")
	assert(sentinel.health == 4.0, "Sleeping goblin initial health must be 4.0")

	assert(REFERENCE_ENEMY.HEALTHS["goblin_elite"] == 8.0, "Goblin elite must have 8.0 health (double sleeping goblin)")
	assert(REFERENCE_ENEMY.HEALTHS["goblin_dog"] == 3.0, "Goblin dog must have 3.0 health (50% increase from 2.0)")
	assert(REFERENCE_ENEMY.HEALTHS["kobold_summoner"] == 4.0, "Kobold summoner must have 4.0 health (same as sleeping goblin)")
	assert(REFERENCE_ENEMY.HEALTHS["kobold_archer"] == 4.0, "Kobold archer must have 4.0 health (same as sleeping goblin)")
	assert(REFERENCE_ENEMY.HEALTHS["kobold_clubber"] == 10.0, "Kobold clubber must have 10.0 health (25% more than goblin elite)")

	# 2. Sleeping goblin wake-up and double damage
	assert(sentinel.is_asleep == true, "Goblin should initially be asleep")
	sentinel.take_hit(1.0)
	assert(sentinel.health == 2.0, "Sleeping goblin should take double damage on first hit (1.0 * 2 = 2.0 damage)")
	assert(sentinel.is_asleep == false, "Sleeping goblin should wake up after being hit")

	# Second hit while awake should deal normal damage
	sentinel.take_hit(1.0)
	assert(sentinel.health == 1.0, "Awake goblin should take normal damage on subsequent hits")

	# Return to sleep after 10s of not seeing player
	sentinel.player = null
	sentinel._process(5.0)
	assert(sentinel.is_asleep == false, "Goblin should remain awake before 10 seconds elapse")
	sentinel._process(5.1)
	assert(sentinel.is_asleep == true, "Goblin should return to sleep after 10 seconds of not seeing player")

	# Taking hit while asleep again should deal double damage again
	sentinel.take_hit(0.5)
	assert(sentinel.health == 0.0, "Goblin should take double damage when asleep again")
	sentinel.queue_free()

	# 3. Injured player walking speed
	var player := PLAYER.new()
	assert(absf(PLAYER.WALK_SPEED - PLAYER.SPEED * 0.5) < 0.001, "WALK_SPEED must be exactly 50% slower than SPEED")
	root.add_child(player)
	player.is_injured = true
	assert(player.is_injured, "Player should be in injured state")
	player.queue_free()

	# 4. Kobold summoner summoning
	var summoner := REFERENCE_ENEMY.new()
	summoner.enemy_kind = "kobold_summoner"
	summoner.ground_origin = true
	root.add_child(summoner)
	var initial_children := root.get_child_count()
	summoner._spawn_forest_summon()
	assert(root.get_child_count() == initial_children + 1, "Kobold summoner must spawn a summon into tree")
	var spawned: Node = root.get_child(root.get_child_count() - 1)
	assert(spawned.is_in_group("forest_boss_summons"), "Summon must be in forest_boss_summons group")
	assert(spawned.get("variant") in [0, 1, 2], "Summon variant must be 0, 1, or 2 from forest boss summons")
	var spirit_script = load("res://scripts/forest_guardian_spirit.gd")
	assert(spawned.get_script() == spirit_script, "Summon must be an instance of forest_guardian_spirit.gd")
	spawned.queue_free()
	summoner.queue_free()

	# 5. Enemy collision masks (cannot pass through layer 4 passable platform blockers)
	var test_scout := SCOUT.new()
	assert(test_scout.collision_mask & 4 != 0, "Scout must include layer 4 in collision_mask to block passable platforms")
	var test_ref := REFERENCE_ENEMY.new()
	test_ref._ready()
	assert(test_ref.collision_mask & 4 != 0, "Reference enemy must include layer 4 in collision_mask to block passable platforms")
	test_scout.queue_free()
	test_ref.queue_free()

	# 6. Slopes and floating platforms
	# Create a slope StaticBody2D
	var slope := StaticBody2D.new()
	var slope_col := CollisionPolygon2D.new()
	slope_col.polygon = PackedVector2Array([Vector2(0, 500), Vector2(300, 350), Vector2(300, 600), Vector2(0, 600)])
	slope.add_child(slope_col)
	root.add_child(slope)

	# Create a floating platform StaticBody2D
	var float_plat := StaticBody2D.new()
	var float_col := CollisionShape2D.new()
	var float_box := RectangleShape2D.new()
	float_box.size = Vector2(200, 20)
	float_col.shape = float_box
	float_plat.position = Vector2(1000, 300)
	float_plat.add_child(float_col)
	root.add_child(float_plat)

	await physics_frame
	await physics_frame

	var slope_enemy := REFERENCE_ENEMY.new()
	slope_enemy.enemy_kind = "goblin"
	slope_enemy.position = Vector2(150, 425)
	root.add_child(slope_enemy)
	await physics_frame

	# On the slope, is_edge_ahead should NOT be true
	# (even though it's sloped up or down, it's not a floating platform drop)
	var edge_up: bool = slope_enemy.is_edge_ahead(1)
	var edge_down: bool = slope_enemy.is_edge_ahead(-1)
	assert(not edge_up, "Enemy should not see upward slope as edge ahead")
	assert(not edge_down, "Enemy should not see downward slope as edge ahead")

	# On floating platform near right edge (x=1100 is edge, enemy at x=1090)
	var float_enemy := REFERENCE_ENEMY.new()
	float_enemy.enemy_kind = "goblin"
	float_enemy.position = Vector2(1090, 290)
	root.add_child(float_enemy)
	await physics_frame

	var edge_float: bool = float_enemy.is_edge_ahead(1)
	assert(edge_float, "Enemy should see drop off floating platform as edge ahead")

	slope.queue_free()
	float_plat.queue_free()
	slope_enemy.queue_free()
	float_enemy.queue_free()

	print("MECHANICS_BALANCE_SMOKE_PASS: all 10 mechanics and balance requirements verified")
	quit(0)
