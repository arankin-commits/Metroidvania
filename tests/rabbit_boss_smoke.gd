extends SceneTree

const ARENA_SCENE = preload("res://scenes/rabbit_boss_test.tscn")

func _initialize() -> void:
	call_deferred("run")

func fail(message: String) -> void:
	push_error(message)
	quit(1)

func frames(count: int) -> void:
	for _frame in count:
		await physics_frame

func run() -> void:
	var arena := ARENA_SCENE.instantiate()
	root.add_child(arena)
	await frames(2)
	var boss: RabbitBoss = arena.get_node("RabbitBoss")
	var player: CharacterBody2D = arena.get_node("Player")
	var hud: Control = arena.get_node("HUDLayer/HUD")
	player.collision_layer = 4
	player.collision_mask = 1
	boss.collision_layer = 2
	boss.collision_mask = 1
	player.global_position = Vector2(1120.0, 537.0)
	player.controls_enabled = false
	var saw_climb := false
	var saw_telegraph := false
	var saw_pounce := false
	for _frame in 1200:
		await physics_frame
		if boss.current_climb_surface != null:
			saw_climb = true
		if boss.is_telegraphing:
			var telegraph_position := boss.global_position
			await frames(5)
			if boss.global_position.distance_to(telegraph_position) > 0.01:
				fail("Rabbit moved during its attack telegraph")
				return
			saw_telegraph = true
		if boss.visual_state == RabbitBoss.VisualState.POUNCE and boss.pounce_timer > 0.0:
			if boss.sprite.position.y != -8.0:
				fail("Pounce pose did not receive its upward sprite offset")
				return
			saw_pounce = true
		if saw_climb and saw_telegraph and saw_pounce:
			break
	if not saw_climb:
		fail("Rabbit never clung to the arena wall: pos=%s velocity=%s state=%s jump_timer=%s" % [boss.global_position, boss.velocity, boss.action_state, boss.jump_timer])
		return
	if not saw_telegraph:
		fail("Rabbit never entered its attack telegraph")
		return
	if not saw_pounce:
		fail("Rabbit never showed its pounce pose")
		return
	boss.active = false
	player.global_position = boss.global_position + Vector2(-40.0, 0.0)
	player.facing = 1
	var health_before := boss.health
	player._normal_attack()
	await process_frame
	if boss.health >= health_before:
		fail("Player attack did not damage the rabbit boss")
		return
	if hud.boss_health != boss.health or not hud.notice.begins_with("BOSS HIT"):
		fail("HUD did not report boss damage")
		return
	print("RABBIT_BOSS_SMOKE_PASS")
	quit()