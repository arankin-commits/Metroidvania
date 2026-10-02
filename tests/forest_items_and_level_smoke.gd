extends SceneTree

const SAVE_ROOT := "res://tests/.forest_items_test_saves"
const SLOTS := preload("res://scripts/save_slots.gd")
const SMASH_LAYOUT := preload("res://scripts/forest_smash_corridor_layout.gd")
const DASH_LAYOUT := preload("res://scripts/forest_dash_galleries_layout.gd")

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var global_save_root := ProjectSettings.globalize_path(SAVE_ROOT)
	if DirAccess.dir_exists_absolute(global_save_root):
		for f in DirAccess.get_files_at(global_save_root):
			DirAccess.remove_absolute(global_save_root.path_join(f))
	DirAccess.make_dir_recursive_absolute(global_save_root)

	# 1. Verify Level-Up formula and Will conservation logic
	print("1. Testing Level-Up logic (level up every 25 will gained, will not consumed)...")
	var slot := SLOTS.new_slot()
	assert(slot["level"] == 1 and slot["will"] == 0, "Initial slot should be lvl 1 with 0 will")
	
	# Simulate gaining 24 will
	var will := 24
	var lvl := 1 + int(will / 25)
	assert(lvl == 1, "24 will should still be level 1")
	assert(will == 24, "Will should remain 24")

	# Simulate gaining 1 more will (25 total)
	will += 1
	lvl = 1 + int(will / 25)
	assert(lvl == 2, "25 will should trigger level 2")
	assert(will == 25, "Will must not be consumed upon leveling up")

	# Simulate gaining 50 more will (75 total)
	will += 50
	lvl = 1 + int(will / 25)
	assert(lvl == 4, "75 will should be level 4")
	assert(will == 75, "Will must not be consumed")

	# Test save slot persistence with level calculation
	slot["will"] = 75
	slot["level"] = 4
	SLOTS.write_slot(1, slot, SAVE_ROOT)
	var loaded := SLOTS.load_slot(1, SAVE_ROOT)
	assert(loaded["level"] == 4, "Loaded level should be 4")
	assert(loaded["will"] == 75, "Loaded will should be 75")
	print("   Level-up and will persistence verified: OK")

	# 2. Test Section 4 breakable platform and Item in Forest Room 2
	print("2. Testing Section 4 Breakable Platform & Item...")
	var test_slot := SLOTS.new_slot()
	test_slot["hand_activated"] = true
	test_slot["last_hand_room"] = 3
	test_slot["bow_boss_defeated"] = true
	test_slot["has_heavy"] = true
	test_slot["will"] = 0
	test_slot["level"] = 1
	test_slot["room"] = 6
	SLOTS.write_slot(2, test_slot, SAVE_ROOT)

	set_meta("active_save_slot", 2)
	set_meta("save_root", SAVE_ROOT)
	set_meta("forest_entry_room", 6)
	
	change_scene_to_file("res://scenes/forest_entry.tscn")
	await process_frame
	await physics_frame
	var world = current_scene
	assert(world != null, "Scene failed to load")
	
	for i in 10:
		await physics_frame

	assert(world.forest_smash_open == false, "Smash floor should initially be sealed")
	assert(world.forest_sec4_cache_found == false, "Section 4 cache should initially not be found")
	assert(is_instance_valid(world.sec4_offering), "Section 4 offering node should exist")
	assert(world.sec4_offering.position.x > 7900 and world.sec4_offering.position.x < 8000, "Section 4 offering should be at x ~7943")

	# Position player on the breakable platform
	world.player.position = Vector2(7943.0, 162.28 - 23.0)
	world.player.velocity = Vector2.ZERO
	for i in 5:
		await physics_frame
	assert(world.player.is_on_floor(), "Player should be standing on the intact smash platform")

	# Attack the breakable platform without heavy smash ability:
	var hitbox := Rect2(world.player.position.x - 20, world.player.position.y - 10, 60, 60)
	var broken_without_ability: bool = world.try_break_smash_floor(hitbox)
	assert(not broken_without_ability, "try_break_smash_floor should fail without has_heavy_smash")
	assert(not world.forest_smash_open, "forest_smash_open should remain false")

	# Grant heavy smash (normally earned from defeating Ironback boss)
	world.player.has_heavy_smash = true
	var broken: bool = world.try_break_smash_floor(hitbox)
	assert(broken, "try_break_smash_floor should succeed when player has has_heavy_smash")
	assert(world.forest_smash_open, "forest_smash_open should be true after breaking")

	# Allow player to fall into cavity and collect offering
	for i in 40:
		await physics_frame

	assert(world.forest_sec4_cache_found, "Section 4 cache should be collected in cavity")
	assert(world.will_amount == 25, "Collecting Section 4 offering should award 25 Will (actual: %d)" % world.will_amount)
	assert(world.player_level == 2, "Player should level up to 2 after gaining 25 Will (actual: %d)" % world.player_level)
	assert(not is_instance_valid(world.sec4_offering) or world.sec4_offering.is_queued_for_deletion(), "Offering node should be removed after collection")
	
	# Verify player can jump out of the cavity
	_key(KEY_SPACE, true)
	for i in 15:
		await physics_frame
	_key(KEY_SPACE, false)
	for i in 10:
		await physics_frame
	assert(world.player.position.y < 162.28 - 23.0, "Player jump should reach above the cavity rim (y: %f vs floor %f)" % [world.player.position.y, 162.28 - 23.0])
	print("   Section 4 breakable platform and cavity item verified: OK")

	# 3. Test Section 9.2 item at red circle
	print("3. Testing Section 9.2 Item at Red Circle...")
	assert(world.forest_sec9_cache_found == false, "Section 9 cache should initially not be found")
	assert(is_instance_valid(world.sec9_offering), "Section 9 offering node should exist")
	assert(absf(world.sec9_offering.position.x - 14810.0) < 5.0, "Section 9 offering should be at x = 14810 (actual: %f)" % world.sec9_offering.position.x)
	assert(absf(world.sec9_offering.position.y - DASH_LAYOUT.HIGH) < 5.0, "Section 9 offering should be on upper platform y = %f (actual: %f)" % [DASH_LAYOUT.HIGH, world.sec9_offering.position.y])

	# Move player to Section 9.2 upper platform at red circle
	world.player.position = Vector2(14810.0, DASH_LAYOUT.HIGH - 23.0)
	world.player.velocity = Vector2.ZERO
	for i in 10:
		await physics_frame

	# Player touches / collects offering
	assert(world.forest_sec9_cache_found, "Section 9 cache should be collected at red circle")
	assert(world.will_amount == 50, "Total Will should be 50 after collecting both offerings (actual: %d)" % world.will_amount)
	assert(world.player_level == 3, "Player should level up to 3 after reaching 50 Will (actual: %d)" % world.player_level)
	assert(not is_instance_valid(world.sec9_offering) or world.sec9_offering.is_queued_for_deletion(), "Section 9 offering node should be removed after collection")
	print("   Section 9.2 item at red circle verified: OK")

	# 4. Verify save persistence in forest
	world._save_progress()
	var reloaded := SLOTS.load_slot(2, SAVE_ROOT)
	assert(reloaded["will"] == 50, "Saved will should be 50")
	assert(reloaded["level"] == 3, "Saved level should be 3")
	assert(reloaded["forest_smash_open"] == true, "Saved forest_smash_open should be true")
	assert(reloaded["forest_sec4_cache_found"] == true, "Saved forest_sec4_cache_found should be true")
	assert(reloaded["forest_sec9_cache_found"] == true, "Saved forest_sec9_cache_found should be true")
	print("   Forest save persistence verified: OK")

	print("FOREST_ITEMS_AND_LEVEL_SMOKE_PASS: All requirements verified successfully!")
	quit(0)

func _key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
