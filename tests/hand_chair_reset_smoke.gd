extends SceneTree

const TUTORIAL_WORLD := preload("res://scripts/tutorial_world.gd")
const FOREST_ENTRY := preload("res://scripts/forest_entry.gd")
const GALLERY_LAYOUT := preload("res://scripts/split_gallery_layout.gd")

func _initialize() -> void:
	call_deferred("run")

func fail(msg: String) -> void:
	push_error("TEST FAILED: " + msg)
	quit(1)

func run() -> void:
	print("--- Running Hand Chair Reset Smoke Test ---")

	# 1. Tutorial World Hand Chair Reset
	var world := TUTORIAL_WORLD.new()
	root.add_child(world)
	await physics_frame
	await physics_frame

	# Damage and defeat scout
	if is_instance_valid(world.scout):
		world.scout.take_hit(100.0) # Defeat scout
		await physics_frame

	# Damage and displace ledge sentinel
	if is_instance_valid(world.ledge_sentinel):
		world.ledge_sentinel.is_asleep = false
		world.ledge_sentinel.health = 1.0
		world.ledge_sentinel.posture = 1.0
		world.ledge_sentinel.position = Vector2(9999, 9999)

	# Using the hand chair
	world.activate_hand()
	await physics_frame

	# Verify scout respawned, health & posture full, position reset
	if not is_instance_valid(world.scout) or world.scout.is_queued_for_deletion():
		fail("Scout did not respawn after hand chair reset")
		return
	if world.scout.health != world.scout.max_health:
		fail("Scout health not restored (%f vs %f)" % [world.scout.health, world.scout.max_health])
		return
	if world.scout.posture != world.scout.max_posture:
		fail("Scout posture not restored (%f vs %f)" % [world.scout.posture, world.scout.max_posture])
		return
	if world.scout.global_position.distance_to(GALLERY_LAYOUT.SCOUT) > 5.0:
		fail("Scout position not reset to spawn point (%s vs %s)" % [world.scout.global_position, GALLERY_LAYOUT.SCOUT])
		return

	# Verify ledge sentinel health & posture full, position reset, asleep
	if not is_instance_valid(world.ledge_sentinel) or world.ledge_sentinel.is_queued_for_deletion():
		fail("Ledge sentinel invalid after hand chair reset")
		return
	if world.ledge_sentinel.health != world.ledge_sentinel.max_health:
		fail("Ledge sentinel health not restored (%f vs %f)" % [world.ledge_sentinel.health, world.ledge_sentinel.max_health])
		return
	if world.ledge_sentinel.posture != world.ledge_sentinel.max_posture:
		fail("Ledge sentinel posture not restored (%f vs %f)" % [world.ledge_sentinel.posture, world.ledge_sentinel.max_posture])
		return
	if world.ledge_sentinel.position.distance_to(GALLERY_LAYOUT.SENTINEL) > 5.0:
		fail("Ledge sentinel position not reset to spawn point")
		return
	if not world.ledge_sentinel.is_asleep:
		fail("Ledge sentinel should be asleep after hand chair reset")
		return

	world.queue_free()
	await physics_frame

	# 2. Forest Entry Hand Chair Reset
	var forest := FOREST_ENTRY.new()
	forest.current_room = 8
	root.add_child(forest)
	await physics_frame
	await physics_frame

	if is_instance_valid(forest.forest_encounters):
		# Damage an encounter enemy
		var targets: Array = forest.forest_encounters.targets()
		if not targets.is_empty():
			var first_enemy = targets[0]
			first_enemy.take_hit(100.0) # defeat it
			await physics_frame

		# Rest at hand chair
		forest.activate_hand()
		await physics_frame

		# Check all enemies are respawned and healthy
		var refreshed_targets: Array = forest.forest_encounters.targets()
		for e in refreshed_targets:
			if e.health != e.max_health or e.posture != e.max_posture:
				fail("Forest enemy health or posture not restored after hand reset")
				return

	forest.queue_free()

	print("HAND_CHAIR_RESET_SMOKE_PASS: Hand chair properly resets, restores, and respawns enemies")
	quit(0)
