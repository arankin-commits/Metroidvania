extends SceneTree

const PLAYER_SCRIPT := preload("res://scripts/player.gd")
const SUMMON_SCRIPT := preload("res://scripts/forest_guardian_spirit.gd")
const SLOTS := preload("res://scripts/save_slots.gd")
const SAVE_ROOT := "res://tests/.test_air_dash_saves"

func _initialize() -> void:
	call_deferred("run")

func fail(msg: String) -> void:
	push_error("TEST FAILED: " + msg)
	quit(1)

func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run() -> void:
	print("--- Running Summon and Air Dash Smoke Test ---")
	
	# 1. Check reference images exist
	for ref_file in ["earthen bear.png", "earthen troll.png", "tree ent.png"]:
		var path: String = "res://assets/references/forest_boss_summons/" + str(ref_file)
		if not FileAccess.file_exists(path):
			fail("Missing reference file: " + path)
			return
	print("Reference images verified.")
	
	# 2. Test Summon Variants & Animations
	for v in range(3):
		var summon: CharacterBody2D = SUMMON_SCRIPT.new()
		summon.variant = v
		root.add_child(summon)
		
		if summon.TEXTURES[v] == null:
			fail("Summon texture missing for variant %d" % v)
			return
		
		# Test idle animation state
		summon._physics_process(0.016)
		if summon.anim_state != "idle":
			fail("Summon variant %d not idle on start" % v)
			return
			
		# Test take_hit / hurt state
		summon.take_hit(1.0)
		if summon.hurt_time <= 0.0 or summon.anim_state != "hurt":
			fail("Summon variant %d did not enter hurt state" % v)
			return
			
		# Test run / walk state
		summon.hurt_time = 0.0
		summon.velocity.x = 80.0
		summon._physics_process(0.016)
		if not (summon.anim_state in ["walk", "run"]):
			fail("Summon variant %d did not enter walk/run state when moving" % v)
			return
			
		summon.queue_free()
	print("Summon variants and animation states verified.")
	
	# 3. Test Air Dash Gating
	var player: CharacterBody2D = PLAYER_SCRIPT.new()
	root.add_child(player)
	player.position = Vector2(500, 200) # In the air
	player.has_dash = true # Player has ground dash (from Hand Chair)
	player.has_air_dash = false # Player has NOT beaten forest boss
	player.controls_enabled = true
	player.dash_cooldown = 0.0
	player.velocity = Vector2(0, 100) # falling in air
	
	# Trigger dash while airborne without air dash
	key(KEY_K, true)
	await physics_frame
	await physics_frame
	key(KEY_K, false)
	await physics_frame
	
	if player.dash_time > 0.0:
		fail("Air dash was allowed before beating the forest boss!")
		return
	print("Air dash is correctly blocked before beating forest boss.")
	
	# Now unlock air dash (after beating forest boss)
	player.reset_movement_state()
	player.position = Vector2(500, 200)
	player.has_air_dash = true
	player.dash_cooldown = 0.0
	await physics_frame
	
	key(KEY_K, true)
	await physics_frame
	await physics_frame
	key(KEY_K, false)
	
	if player.dash_time <= 0.0:
		fail("Air dash failed after unlocking has_air_dash! (dash_time=%f)" % player.dash_time)
		return
	print("Air dash works correctly after defeating forest boss.")
	
	# 4. Save and Persistence Verification
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_ROOT))
	var slot := SLOTS.new_slot()
	slot["has_dash"] = true
	slot["bow_boss_defeated"] = false
	slot["has_air_dash"] = false
	SLOTS.write_slot(1, slot, SAVE_ROOT)
	
	var loaded := SLOTS.load_slot(1, SAVE_ROOT)
	if loaded.has_air_dash:
		fail("has_air_dash was loaded true when bow_boss_defeated is false")
		return
		
	slot["bow_boss_defeated"] = true
	slot["has_air_dash"] = true
	SLOTS.write_slot(1, slot, SAVE_ROOT)
	loaded = SLOTS.load_slot(1, SAVE_ROOT)
	if not loaded.has_air_dash:
		fail("has_air_dash was not saved/loaded after defeating bow boss")
		return
	print("Save persistence for air dash verified.")
	
	player.queue_free()
	SLOTS.delete_slot(1, SAVE_ROOT)
	
	print("SUMMON_AND_AIR_DASH_TEST_PASS")
	quit(0)
