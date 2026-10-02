extends SceneTree

const ARENA_SCENE := preload("res://scenes/ironback_boss_test.tscn")

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
	var boss: CharacterBody2D = arena.get_node("Ironback")
	var player: CharacterBody2D = arena.get_node("Player")
	var hud: Control = arena.get_node("HUDLayer/HUD")
	player.controls_enabled = false
	player.global_position = Vector2(760.0, 537.0)
	player.invulnerability = 0.0
	player.health = 5.0
	boss.active = true
	boss.begin_attack("seismic_smash")
	var tell_position := boss.global_position
	await frames(30)
	if boss.state != "smash_tell" or boss.global_position != tell_position:
		fail("Ironback moved or left the tell before impact")
		return
	var health_before: float = player.health
	await frames(40)
	if boss.state != "smash_recovery" and boss.state != "idle":
		fail("Ironback did not reach recovery after its smash")
		return
	if player.health >= health_before:
		fail("Ironback smash did not damage the player")
		return
	var waves := arena.get_tree().get_nodes_in_group("ironback_v2_waves")
	if waves.size() != 2:
		fail("Ironback emitted %d shockwaves instead of one pair" % waves.size())
		return
	if hud.boss_title != "IRONBACK, THE SEISMIC FIST" or hud.boss_health != boss.health:
		fail("Ironback HUD is not driven by authoritative boss state")
		return
	await frames(100)
	if not arena.get_tree().get_nodes_in_group("ironback_v2_waves").is_empty():
		fail("Ironback shockwaves did not clean themselves up")
		return
	boss.take_hit(99.0)
	await frames(2)
	if boss.active or not arena.get_tree().get_nodes_in_group("ironback_v2_waves").is_empty():
		fail("Ironback defeat did not deactivate and clean danger")
		return
	print("IRONBACK_BOSS_SMOKE_PASS")
	quit()