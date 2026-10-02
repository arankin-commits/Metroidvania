extends SceneTree

const TUTORIAL_WORLD := preload("res://scripts/tutorial_world.gd")
const FOREST_ENTRY := preload("res://scripts/forest_entry.gd")
const SLOTS := preload("res://scripts/save_slots.gd")
const GALLERY_LAYOUT := preload("res://scripts/split_gallery_layout.gd")
const LEDGE_SENTINEL := preload("res://scripts/ledge_sentinel.gd")
const SAVE_ROOT := "res://tests/.new_features_smoke_saves"

func _init() -> void:
	call_deferred("run")

func fail(msg: String) -> void:
	push_error("TEST FAILED: " + msg)
	quit(1)

func run() -> void:
	print("--- Running New Bosses, Spearmen, Sleeping Goblin, and Respawn Smoke Test ---")
	var global_save_root := ProjectSettings.globalize_path(SAVE_ROOT)
	if DirAccess.dir_exists_absolute(global_save_root):
		for f in DirAccess.get_files_at(global_save_root):
			DirAccess.remove_absolute(global_save_root.path_join(f))
	DirAccess.make_dir_recursive_absolute(global_save_root)

	# -------------------------------------------------------------------------
	# 1. TEST: Sleeping Goblin Visual Offset Fix
	# -------------------------------------------------------------------------
	print("1. Testing Sleeping Goblin visual offset fix...")
	var sentinel := LEDGE_SENTINEL.new()
	root.add_child(sentinel)
	await process_frame
	if not is_instance_valid(sentinel.visual):
		fail("Ledge sentinel must have a visual container node")
		return
	if sentinel.visual.position != Vector2.ZERO:
		fail("Ledge sentinel visual container must be at (0, 0)")
		return
	# Test flipping facing direction
	sentinel.facing = 1
	sentinel._update_visual_facing()
	if sentinel.visual.scale.x != 1.0:
		fail("Visual scale.x should be 1.0 when facing 1")
		return
	sentinel.facing = -1
	sentinel._update_visual_facing()
	if sentinel.visual.scale.x != -1.0:
		fail("Visual scale.x should be -1.0 when facing -1")
		return
	# Ensure sprite is child of visual, not root
	if sentinel.sprite.get_parent() != sentinel.visual:
		fail("Sprite must be a child of visual container to prevent flip offsets")
		return
	sentinel.queue_free()
	print("   Sleeping goblin visual offset fix: OK")

	# -------------------------------------------------------------------------
	# 2. TEST: Goblin Spearmen Spawns at 5 Red X coordinates
	# -------------------------------------------------------------------------
	print("2. Testing Goblin Spearmen spawns in Cave Room 2...")
	var encounters := GALLERY_LAYOUT.encounters()
	var spearmen: Array[Dictionary] = []
	for enc in encounters:
		if enc.get("kind") == "goblin_sentinel" or enc.get("kind") == "spearman":
			spearmen.append(enc)
	if spearmen.size() != 5:
		fail("Expected exactly 5 goblin spearmen, got %d" % spearmen.size())
		return
	var expected_ids := ["EntranceSpearman", "AscentSpearman", "SealSpearman", "CrownSpearmanWest", "CrownSpearmanEast"]
	for id in expected_ids:
		var found := false
		for s in spearmen:
			if s.get("id") == id:
				found = true
				break
		if not found:
			fail("Missing expected spearman: %s" % id)
			return
	print("   Goblin Spearmen 5 Red X spawns verified: OK")

	# -------------------------------------------------------------------------
	# 3. TEST: Death in Injured State / Respawn Behavior
	# -------------------------------------------------------------------------
	print("3. Testing Injured State death & respawn...")
	var slot := SLOTS.new_slot()
	slot["is_injured"] = true
	slot["hand_activated"] = false
	slot["room"] = 2
	slot["checkpoint_x"] = -640.0
	slot["checkpoint_y"] = 577.0
	slot["healing_charges"] = 0
	SLOTS.write_slot(1, slot, SAVE_ROOT)

	set_meta("active_save_slot", 1)
	set_meta("save_root", SAVE_ROOT)
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await physics_frame
	var cave: TUTORIAL_WORLD = current_scene
	if cave == null:
		fail("Failed to load tutorial scene")
		return
	for i in 10:
		await physics_frame

	# Damage scout
	if is_instance_valid(cave.scout):
		cave.scout.health = 1.0
		cave.scout.posture = 1.0
		cave.scout.global_position = Vector2(9999, 9999) # move away

	# Trigger player death in injured state
	cave.player.health = 0.0
	cave._respawn()
	for i in 5:
		await physics_frame

	# Verify player respawns with 1 healing item, full health, in room 1
	if cave.player.healing_charges != 1:
		fail("Player should respawn with 1 healing charge when dying in injured state (got %d)" % cave.player.healing_charges)
		return
	if cave.player.health != cave.player.injured_max_health:
		fail("Player should regain full health on respawn (expected %f, got %f)" % [cave.player.injured_max_health, cave.player.health])
		return
	if cave.current_room != 1:
		fail("Player without hand statue used should respawn in room 1 (got %d)" % cave.current_room)
		return
	# Verify scout respawned, position reset, regained full health and posture
	if not is_instance_valid(cave.scout) or cave.scout.is_queued_for_deletion():
		fail("Scout should be respawned")
		return
	if cave.scout.health != cave.scout.max_health:
		fail("Scout should regain full health on respawn (got %f)" % cave.scout.health)
		return
	if cave.scout.posture != cave.scout.max_posture:
		fail("Scout should regain full posture on respawn (got %f)" % cave.scout.posture)
		return
	if cave.scout.global_position.distance_to(GALLERY_LAYOUT.SCOUT) > 5.0:
		fail("Scout position should reset to spawn position on respawn")
		return
	print("   Injured state death and enemy respawn verified: OK")

	# -------------------------------------------------------------------------
	# 4. TEST: Room 11 (Rabbit Boss) & Room 12 (Ironback Boss) Progression
	# -------------------------------------------------------------------------
	print("4. Testing Room 11 & Room 12 Boss Progression...")
	var forest_slot := SLOTS.new_slot()
	forest_slot["hand_activated"] = true
	forest_slot["last_hand_room"] = 8
	forest_slot["forest_hand_activated"] = true
	forest_slot["bow_boss_defeated"] = true
	forest_slot["has_heavy"] = true
	forest_slot["room"] = 11
	forest_slot["visited_rooms"] = [5, 6, 7, 8, 11]
	SLOTS.write_slot(2, forest_slot, SAVE_ROOT)

	set_meta("active_save_slot", 2)
	set_meta("save_root", SAVE_ROOT)
	set_meta("forest_entry_room", 11)
	change_scene_to_file("res://scenes/forest_entry.tscn")
	await process_frame
	await physics_frame
	var forest: FOREST_ENTRY = current_scene
	if forest == null:
		fail("Failed to load forest_entry scene")
		return
	for i in 10:
		await physics_frame

	if forest.current_room != 11:
		fail("Forest entry room should be 11 (was: %d)" % forest.current_room)
		return
	if not is_instance_valid(forest.rabbit_boss):
		fail("Rabbit boss should be instantiated in Room 11")
		return
	if not is_instance_valid(forest.rabbit_chamber):
		fail("Rabbit chamber should be instantiated")
		return
	if not forest.rabbit_chamber.visible:
		fail("Rabbit chamber should be visible in Room 11")
		return

	# Defeat Rabbit Boss
	forest._on_rabbit_defeated()
	if not forest.rabbit_boss_defeated:
		fail("rabbit_boss_defeated should be true")
		return
	print("   Room 11 Rabbit Boss setup and defeat: OK")

	# Transition to Room 12 (Ironback Boss)
	forest.player.position.x = 27280.0 + 80.0
	forest.current_room = 12
	forest._mark_room_visited(12)
	forest._set_camera()
	for i in 5:
		await physics_frame

	if not is_instance_valid(forest.ironback_boss):
		fail("Ironback boss should be instantiated in Room 12")
		return
	if not is_instance_valid(forest.ironback_chamber):
		fail("Ironback chamber should be instantiated")
		return
	if not forest.ironback_chamber.visible:
		fail("Ironback chamber should be visible in Room 12")
		return
	if forest.player.has_heavy_smash:
		fail("Player should not have heavy smash before defeating Ironback")
		return

	# Defeat Ironback Boss
	forest._on_ironback_defeated()
	if not forest.ironback_boss_defeated:
		fail("ironback_boss_defeated should be true")
		return
	if not forest.player.has_heavy_smash:
		fail("Defeating Ironback boss must grant player has_heavy_smash ability!")
		return
	print("   Room 12 Ironback Boss setup and heavy smash reward: OK")

	# Save and verify persistence of new abilities & defeat flags
	forest._save_progress()
	var reloaded_forest := SLOTS.load_slot(2, SAVE_ROOT)
	if not reloaded_forest.get("rabbit_boss_defeated", false):
		fail("rabbit_boss_defeated should be saved in slot")
		return
	if not reloaded_forest.get("ironback_boss_defeated", false):
		fail("ironback_boss_defeated should be saved in slot")
		return
	if not reloaded_forest.get("has_heavy_smash", false):
		fail("has_heavy_smash should be saved in slot")
		return
	print("   New boss progression and heavy smash persistence: OK")

	print("NEW_BOSSES_AND_RESPAWN_SMOKE_PASS: All new boss rooms, spearmen spawns, sleeping goblin fix, and respawn logic verified successfully!")
	quit(0)
