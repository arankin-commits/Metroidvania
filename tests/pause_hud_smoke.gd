extends SceneTree

const SAVE_SLOTS = preload("res://scripts/save_slots.gd")
const TEST_ROOT := "res://tests/.smoke_saves"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_ROOT))
	SAVE_SLOTS.write_slot(1, SAVE_SLOTS.new_slot(), TEST_ROOT)
	set_meta("active_save_slot", 1)
	set_meta("save_root", TEST_ROOT)
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await process_frame
	var world := current_scene
	if world.hud.level != 1 or world.hud.will_amount != 0 or world.hud.healing_charges != 3:
		_fail("Starting HUD values are wrong")
		return
	world.player.global_position = world.scout.global_position + Vector2(0, -40)
	world.scout.hit_cooldown = 0.0
	world.scout._physics_process(0.016)
	if world.player.health != 4:
		_fail("Landing on the scout did not damage the player")
		return
	world.player.global_position = world.boss.global_position
	world.player.invulnerability = 0.0
	world.boss.active = true
	world.boss._process(0.016)
	if world.player.health != 3:
		_fail("Touching the boss did not damage the player")
		return
	world.boss.active = false
	world.player.global_position = Vector2(120, 570)
	world.player.velocity = Vector2.ZERO
	var heal_press := InputEventKey.new()
	heal_press.physical_keycode = KEY_F
	heal_press.keycode = KEY_F
	heal_press.pressed = true
	Input.parse_input_event(heal_press)
	await physics_frame
	await physics_frame
	if world.player.health != 5 or world.player.healing_charges != 2:
		_fail("F did not consume one healing charge and heal")
		return
	var heal_release := InputEventKey.new()
	heal_release.physical_keycode = KEY_F
	heal_release.keycode = KEY_F
	heal_release.pressed = false
	Input.parse_input_event(heal_release)
	world.player.global_position = world.scout.global_position + Vector2(-30, 0)
	world.scout.take_hit()
	world.scout.take_hit()
	if world.will_amount != 0 or get_nodes_in_group("will_orb").is_empty():
		_fail("Scout Will did not appear as a moving orb")
		return
	await create_timer(0.7).timeout
	if world.will_amount != 5:
		_fail("Scout Will did not reach the player")
		return
	world.current_room = 4
	world._set_camera_room()
	world.player.global_position = world.boss.global_position + Vector2(-40, 0)
	world.boss.active = true
	world.boss.health = 1
	world.boss.take_hit()
	if world.will_amount != 5 or get_nodes_in_group("will_orb").is_empty():
		_fail("Warden Will did not appear as a moving orb")
		return
	await create_timer(0.7).timeout
	if world.will_amount != 55:
		_fail("Warden Will did not reach the player")
		return
	await process_frame
	await process_frame
	if world.hud.will_amount != 55 or world.hud.healing_charges != 2:
		_fail("Will or healing charges did not reach the HUD")
		return
	_press_escape()
	await process_frame
	await process_frame
	if not paused or not world.pause_menu.visible:
		_fail("Esc did not open the pause overlay")
		return
	world.pause_menu._show_options()
	if not world.pause_menu.options_page.visible:
		_fail("Pause Options did not open")
		return
	_press_escape()
	await process_frame
	await process_frame
	if not world.pause_menu.main_page.visible or not paused:
		_fail("Esc did not return from pause Options")
		return
	_press_escape()
	await process_frame
	await process_frame
	if paused or world.pause_menu.visible:
		_fail("Esc did not resume the game")
		return
	world.pause_menu._open()
	world.pause_menu._main_menu()
	await process_frame
	await process_frame
	if paused or current_scene == null or current_scene.name != "MainMenu":
		_fail("Main Menu button did not leave the game")
		return
	var restored: Dictionary = SAVE_SLOTS.load_slot(1, TEST_ROOT)
	if restored.get("will", 0) != 55 or restored.get("healing_charges", 0) != 2:
		_fail("Will or healing charges were not saved when returning to the menu")
		return
	SAVE_SLOTS.delete_slot(1, TEST_ROOT)
	remove_meta("active_save_slot")
	remove_meta("save_root")
	print("PAUSE_HUD_SMOKE_PASS")
	quit()

func _press_escape() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_ESCAPE
	event.keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	var release := InputEventKey.new()
	release.physical_keycode = KEY_ESCAPE
	release.keycode = KEY_ESCAPE
	release.pressed = false
	Input.parse_input_event(release)

func _fail(message: String) -> void:
	paused = false
	push_error(message)
	quit(1)
