extends SceneTree

const REFERENCE_ENEMY = preload("res://scripts/enemies/reference_enemy.gd")
const PLAYER = preload("res://scripts/player.gd")
const PROJECTILE = preload("res://scripts/combat_projectile.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("STARTING KOBOLD ARCHER SMOKE TEST...")
	var test_root := Node2D.new()
	root.add_child(test_root)

	# 1. Floor
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	var floor_shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(2000, 60)
	floor_shape.shape = box
	floor_body.position = Vector2(500, 600)
	floor_body.add_child(floor_shape)
	test_root.add_child(floor_body)

	# 2. Player
	var player := PLAYER.new()
	player.position = Vector2(400, 547)
	test_root.add_child(player)

	# 3. Archer
	var archer := REFERENCE_ENEMY.new()
	archer.enemy_kind = "kobold_archer"
	archer.ground_origin = true
	archer.position = Vector2(200, 570)
	archer.player = player
	archer.ai_enabled = true
	test_root.add_child(archer)

	for i in 5:
		await physics_frame

	assert(archer.is_on_floor(), "Archer must be grounded on the floor")
	assert(player.is_on_floor(), "Player must be grounded on the floor")
	assert(archer.can_see_target(player), "Archer must be able to see the player")

	var initial_player_health: float = player.health
	assert(initial_player_health == 5.0, "Player starting health should be 5.0")

	# 4. Wait for archer to shoot arrow
	var flags := {
		"arrow_spawned": false,
		"attack_landed": false,
		"archer_defeated": false,
	}
	archer.attack_landed.connect(func() -> void: flags["attack_landed"] = true)

	for frame in 180:
		await physics_frame
		if not flags["arrow_spawned"]:
			for child in test_root.get_children():
				if child is PROJECTILE and not child.friendly and child.kind == "arrow":
					flags["arrow_spawned"] = true
					print("Arrow projectile detected in scene!")
					break
		if player.health < initial_player_health:
			print("Player took damage from arrow! Health is now: ", player.health)
			break

	if not flags["arrow_spawned"]:
		push_error("FAIL: Kobold archer must spawn an arrow projectile when shooting")
		quit(1)
		return
	if player.health >= initial_player_health:
		push_error("FAIL: Player must take damage when hit by the archer's arrow")
		quit(1)
		return
	if player.health != initial_player_health - 1.0:
		push_error("FAIL: Archer arrow should deal exactly 1.0 damage")
		quit(1)
		return
	if not flags["attack_landed"]:
		push_error("FAIL: Archer must emit attack_landed signal when arrow connects")
		quit(1)
		return

	# 5. Test player hitting archer
	var initial_archer_health := archer.health
	assert(initial_archer_health == 4.0, "Kobold archer must have 4.0 health")
	archer.take_hit(1.0)
	assert(archer.health == 3.0, "Archer should have 3.0 health after taking 1.0 damage")
	assert(archer.sprite.animation == &"posture_break", "Archer should enter posture_break on hit")

	archer.defeated.connect(func() -> void: flags["archer_defeated"] = true)
	archer.take_hit(3.0)
	assert(archer.health <= 0.0, "Archer should reach 0 health")
	if not flags["archer_defeated"]:
		push_error("FAIL: Archer should emit defeated signal on lethal hit")
		quit(1)
		return

	test_root.queue_free()
	print("KOBOLD_ARCHER_SMOKE_PASS: Archer shoots arrow, damages player, and responds to hits correctly!")
	quit(0)
