extends SceneTree

const PLAYER := preload("res://scripts/player.gd")
const PRESENTATION := preload("res://scripts/player_presentation.gd")
const REF_ENEMY := preload("res://scripts/enemies/reference_enemy.gd")
const SUMMON := preload("res://scripts/forest_guardian_spirit.gd")
const AUDIO := preload("res://scripts/game_audio.gd")
const SLOTS := preload("res://scripts/save_slots.gd")
const TUTORIAL_WORLD := preload("res://scripts/tutorial_world.gd")
const FOREST_ENTRY := preload("res://scripts/forest_entry.gd")
const GALLERY_ENCOUNTERS := preload("res://scripts/gallery_encounters.gd")
const GALLERY_LAYOUT := preload("res://scripts/split_gallery_layout.gd")
const CAVE_LAYOUT := preload("res://scripts/cave_layout.gd")
const DASH_LAYOUT := preload("res://scripts/forest_dash_galleries_layout.gd")
const FOREST_LAYOUT := preload("res://scripts/forest_world_layout.gd")

class MockGalleryWorld extends Node2D:
	var gallery_defeated: Array = []
	var player: Node2D = null
	var current_room: int = 2
	var game_audio = null
	func _spawn_will_orb(_pos, _amt): pass
	func _save_progress(): pass

func _initialize() -> void:
	call_deferred("run")

func fail(msg: String) -> void:
	push_error("TEST FAILED: " + msg)
	quit(1)

func run() -> void:
	print("--- Running New Features and Bugfixes Verification Test ---")

	# 1. Dash i-frames and zero enemy collision during entire dash
	var player := PLAYER.new()
	player.has_dash = true
	player.position = Vector2(0, 0)
	root.add_child(player)
	
	var enemy := REF_ENEMY.new()
	enemy.enemy_kind = "goblin"
	enemy.position = Vector2(40, 0)
	root.add_child(enemy)
	await physics_frame
	await physics_frame

	# Trigger ground dash
	player.dash_hold_timer = 0.0
	player.dash_z = 0.0
	player.dash_start_x = player.global_position.x
	player.is_ground_dash = true
	player.is_dash_holding = false # Tap dash
	player.is_dashing = true
	player.dash_just_triggered = false
	player.dash_speed_current = PLAYER.TAP_DASH_SPEED
	player.velocity.x = PLAYER.TAP_DASH_SPEED
	player.velocity.y = 0.0
	player.dash_time = 0.75
	player.invulnerability = 0.35

	# Check that throughout the dash, player is dashing, has i-frames, and collision_layer is 0
	var dt := 0.016
	var max_steps := 30
	var dash_completed := false
	for step in range(max_steps):
		player._physics_process(dt)
		if player.dash_time > 0.0:
			if player.collision_layer != 0:
				fail("Player collision_layer must be 0 while dashing at step %d" % step)
				return
			if player.invulnerability <= 0.0:
				fail("Player invulnerability must be active while dashing at step %d" % step)
				return
			if not player.is_dashing:
				fail("Player is_dashing must be true throughout dash at step %d" % step)
				return
		else:
			dash_completed = true
			if player.collision_layer != 1:
				fail("Player collision_layer must be 1 after dash ends")
				return
			break

	if not dash_completed:
		fail("Dash did not complete within expected time")
		return
	print("1. Dash i-frames and collision exceptions during entire dash: OK")

	# 2. Summons count as enemies
	var summon := SUMMON.new()
	summon.variant = 0
	root.add_child(summon)
	await physics_frame
	if not summon.is_in_group("enemies"):
		fail("Summon must be in 'enemies' group")
		return
	if not summon.is_in_group("combat_targets"):
		fail("Summon must be in 'combat_targets' group")
		return
	summon.take_hit(1.0)
	if summon.health >= summon.max_health:
		fail("Summon must take damage when hit")
		return
	summon.queue_free()
	print("2. Summons count as enemies and take damage: OK")

	# 3. Enemy bump/contact damage
	player.reset_movement_state()
	player.invulnerability = 0.0
	player.health = 5.0
	player.position = Vector2(0, 0)
	enemy.position = Vector2(5, 0)
	# Check contact damage
	player._check_enemy_contact_damage()
	if player.health >= 5.0:
		fail("Player should take contact damage when touching an enemy without i-frames")
		return
	if player.invulnerability <= 0.0:
		fail("Player should receive i-frames after taking contact damage")
		return
	print("3. Player takes contact damage when touching enemy without i-frames: OK")

	# 4. Crouch animation when pressing/holding S
	player.reset_movement_state()
	player.set_injured(false)
	player.is_crouching = true
	player.crouch_time = 0.0
	var seq_uninj := PRESENTATION.sequence(player)
	if not seq_uninj.ends_with("crouch"):
		fail("Player presentation sequence should be crouch when crouching (was: %s)" % seq_uninj)
		return
	player.crouch_time = 0.35 # Reached full crouch frame 4
	var crouch_box := player.combat_bounds()
	if crouch_box.size.y > 30.0:
		fail("Player crouching hitbox height should be reduced (was: %f)" % crouch_box.size.y)
		return

	player.set_injured(true)
	var seq_inj := PRESENTATION.sequence(player)
	if not seq_inj.ends_with("crouch"):
		fail("Injured player presentation sequence should be crouch when crouching")
		return
	print("4. Crouch animation and hitbox reduction for uninjured and injured: OK")

	# 5. Cave Room 2 Goblin Sentinels
	var mock_world := MockGalleryWorld.new()
	mock_world.player = player
	mock_world.current_room = 2
	var encounters := GALLERY_ENCOUNTERS.new()
	encounters.world = mock_world
	root.add_child(mock_world)
	mock_world.add_child(encounters)
	await physics_frame
	var sentinels_found := 0
	for child in encounters.get_children():
		if child is CharacterBody2D and child.get("enemy_kind") == "goblin_sentinel":
			sentinels_found += 1
			if child.max_health != 8.0:
				fail("Goblin sentinel must have 8.0 max health")
				return
	if sentinels_found != 1:
		fail("Expected exactly 1 goblin sentinel in Cave Room 2 encounters (SealSpearman), found: %d" % sentinels_found)
		return
	encounters.queue_free()
	mock_world.queue_free()
	print("5. Cave Room 2 Goblin Sentinel verified (found %d): OK" % sentinels_found)

	# 6. Save load spawn locations
	var test_saves_dir := "res://tests/.test_spawns_saves"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_saves_dir))
	
	# Test A: Save with NO hand activated -> Spawns in Cave Room 1
	var save_no_hand := SLOTS.new_slot()
	save_no_hand["hand_activated"] = false
	save_no_hand["forest_hand_activated"] = false
	save_no_hand["temple_hand_activated"] = false
	save_no_hand["last_hand_room"] = 1
	save_no_hand["room"] = 2 # Player was in room 2 when saved
	SLOTS.write_slot(1, save_no_hand, test_saves_dir)

	var tut_world := TUTORIAL_WORLD.new()
	tut_world.save_root = test_saves_dir
	tut_world.active_save_slot = 1
	root.add_child(tut_world)
	await physics_frame
	await physics_frame
	if tut_world.current_room != 1:
		fail("Save with no hand activated should load into Cave Room 1 (was: %d)" % tut_world.current_room)
		return
	if tut_world.player.global_position.distance_to(CAVE_LAYOUT.START) > 10.0:
		fail("Save with no hand activated should spawn player at CAVE_LAYOUT.START")
		return
	tut_world.queue_free()
	await physics_frame

	# Test B: Save with Cave Room 3 Hand activated -> Spawns in Cave Room 3
	var save_cave_hand := SLOTS.new_slot()
	save_cave_hand["hand_activated"] = true
	save_cave_hand["forest_hand_activated"] = false
	save_cave_hand["temple_hand_activated"] = false
	save_cave_hand["last_hand_room"] = 3
	save_cave_hand["room"] = 4 # Player was in room 4 when saved
	SLOTS.write_slot(2, save_cave_hand, test_saves_dir)

	var tut_world_hand := TUTORIAL_WORLD.new()
	tut_world_hand.save_root = test_saves_dir
	tut_world_hand.active_save_slot = 2
	root.add_child(tut_world_hand)
	await physics_frame
	await physics_frame
	if tut_world_hand.current_room != 3:
		fail("Save with room 3 hand activated should load into Cave Room 3 (was: %d)" % tut_world_hand.current_room)
		return
	if tut_world_hand.player.global_position.distance_to(Vector2(2610, 570)) > 10.0:
		fail("Save with room 3 hand activated should spawn player at Vector2(2610, 570)")
		return
	tut_world_hand.queue_free()
	await physics_frame

	# Test C: Save with Forest Room 8 Hand activated -> Spawns at Forest Room 8 Hand
	var save_forest_hand := SLOTS.new_slot()
	save_forest_hand["hand_activated"] = true
	save_forest_hand["forest_hand_activated"] = true
	save_forest_hand["temple_hand_activated"] = false
	save_forest_hand["last_hand_room"] = 8
	save_forest_hand["area"] = "The Twisted Forest"
	save_forest_hand["room"] = 6
	SLOTS.write_slot(3, save_forest_hand, test_saves_dir)

	var forest_hand_world := FOREST_ENTRY.new()
	forest_hand_world.save_root = test_saves_dir
	forest_hand_world.active_save_slot = 3
	root.add_child(forest_hand_world)
	await physics_frame
	await physics_frame
	if forest_hand_world.current_room != 8:
		fail("Save with room 8 hand activated should load into Forest Room 8 (was: %d)" % forest_hand_world.current_room)
		return
	if forest_hand_world.player.global_position.distance_to(Vector2(FOREST_LAYOUT.HAND_X, 570)) > 10.0:
		fail("Save with room 8 hand activated should spawn player at Room 8 hand")
		return
	forest_hand_world.queue_free()
	await physics_frame

	# Test D: Save with Temple Room 9 Hand activated -> Spawns at Temple Hand
	var save_temple_hand := SLOTS.new_slot()
	save_temple_hand["hand_activated"] = true
	save_temple_hand["forest_hand_activated"] = true
	save_temple_hand["temple_hand_activated"] = true
	save_temple_hand["last_hand_room"] = 9
	save_temple_hand["area"] = "The Twisted Forest"
	save_temple_hand["room"] = 10
	SLOTS.write_slot(3, save_temple_hand, test_saves_dir)

	var temple_hand_world := FOREST_ENTRY.new()
	temple_hand_world.save_root = test_saves_dir
	temple_hand_world.active_save_slot = 3
	root.add_child(temple_hand_world)
	await physics_frame
	await physics_frame
	if temple_hand_world.current_room != 9:
		fail("Save with room 9 hand activated should load into Forest Room 9 (was: %d)" % temple_hand_world.current_room)
		return
	if temple_hand_world.player.global_position.distance_to(DASH_LAYOUT.HAND) > 10.0:
		fail("Save with room 9 hand activated should spawn player at DASH_LAYOUT.HAND")
		return
	temple_hand_world.queue_free()
	await physics_frame

	# Clean up test save files
	for i in range(1, 5):
		SLOTS.delete_slot(i, test_saves_dir)
	print("6. Save load spawn locations (Cave Room 1, Hand 3, Hand 8, Hand 9): OK")

	# 7. Music Overhaul Tracks
	var audio := AUDIO.new()
	root.add_child(audio)
	audio.play_cave()
	if audio.current_track != "cave" or audio.music.stream == null:
		fail("Cave music failed to play")
		return
	audio.play_forest()
	if audio.current_track != "forest" or audio.music.stream == null:
		fail("Forest music failed to play")
		return
	audio.play_goblin_boss()
	if audio.current_track != "warden" or audio.music.stream == null:
		fail("Goblin boss music failed to play")
		return
	audio.play_forest_boss()
	if audio.current_track != "forest_boss" or audio.music.stream == null:
		fail("Forest boss music failed to play")
		return
	audio.play_temple_boss()
	if audio.current_track != "temple_boss" or audio.music.stream == null:
		fail("Temple boss music failed to play")
		return
	audio.queue_free()
	print("7. Music overhaul 5 tracks verified: OK")

	player.queue_free()
	enemy.queue_free()

	print("NEW_FEATURES_SMOKE_PASS: All 7 requested features and bug fixes verified successfully!")
	quit(0)
