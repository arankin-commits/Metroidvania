extends SceneTree

const SAVE_SLOTS = preload("res://scripts/save_slots.gd")
const TEST_ROOT := "res://tests/.smoke_saves"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_ROOT)) != OK:
		_fail("Could not prepare test saves")
		return
	SAVE_SLOTS.write_slot(3, SAVE_SLOTS.new_slot(), TEST_ROOT)
	set_meta("active_save_slot", 3)
	set_meta("save_root", TEST_ROOT)
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await process_frame
	var world := current_scene
	if world.current_room != 2 or world.player.position.x != 120.0:
		_fail("New game did not spawn in Cave Room 2")
		return
	if world.background_rect.texture != world.CAVE_ROOM_BACKDROPS[1]:
		_fail("Room 2 backdrop is wrong")
		return
	if world.background_rect.get_parent() != world or world.background_rect.size.x <= 1200.0:
		_fail("Room 2 backdrop is not positioned in the scrolling world")
		return
	if world.checkpoint.x != 120.0:
		_fail("The Room 2 hand bench is not the first respawn point")
		return
	await create_timer(0.2).timeout
	var dodge_press := InputEventKey.new()
	dodge_press.physical_keycode = KEY_K
	dodge_press.keycode = KEY_K
	dodge_press.pressed = true
	Input.parse_input_event(dodge_press)
	await physics_frame
	await physics_frame
	if world.player.has_dash or world.player.dash_time <= 0.0:
		_fail("The starting ground dodge did not activate")
		return
	var dodge_release := InputEventKey.new()
	dodge_release.physical_keycode = KEY_K
	dodge_release.keycode = KEY_K
	dodge_release.pressed = false
	Input.parse_input_event(dodge_release)
	await create_timer(0.25).timeout
	world.player.dash_time = 0.0
	world.player.velocity = Vector2.ZERO
	world.player.global_position = Vector2(-2, 570)
	await process_frame
	await process_frame
	if not world.loading_overlay.visible:
		_fail("Room entry did not show a loading screen")
		return
	await create_timer(0.7).timeout
	await process_frame
	await process_frame
	if world.current_room != 1 or world.loading_overlay.visible or world.background_rect.texture != world.CAVE_ROOM_BACKDROPS[0]:
		_fail("Room 2 to Room 1 transition failed")
		return
	world.player.global_position = Vector2(2, 570)
	await create_timer(0.7).timeout
	await process_frame
	await process_frame
	if world.current_room != 2 or world.background_rect.texture != world.CAVE_ROOM_BACKDROPS[1]:
		_fail("Room 1 to Room 2 return failed")
		return
	world.player.global_position = Vector2(520, 570)
	world.player.facing = 1
	var strike_press := InputEventKey.new()
	strike_press.physical_keycode = KEY_J
	strike_press.keycode = KEY_J
	strike_press.pressed = true
	Input.parse_input_event(strike_press)
	await physics_frame
	await physics_frame
	if not world.practice_target_hit:
		_fail("The training post did not respond to a strike")
		return
	var strike_release := InputEventKey.new()
	strike_release.physical_keycode = KEY_J
	strike_release.keycode = KEY_J
	strike_release.pressed = false
	Input.parse_input_event(strike_release)
	# The raised platform puts the Sigil within interaction range.
	world.player.global_position = Vector2(510, 502)
	await process_frame
	await process_frame
	if world.secret_found:
		_fail("Cave Sigil was collected without interaction")
		return
	_interact()
	await process_frame
	if not world.secret_found or not world.note_open or not world.sigil_icon.visible or not world.note_text.text.contains("Heartroot"):
		_fail("Cave Sigil did not open its lore close-up")
		return
	_interact()
	await process_frame
	if world.note_open or world.note_panel.visible:
		_fail("Second interaction did not close the Cave Sigil")
		return
	world.last_safe_position = Vector2(650, 570)
	world.player.health = 5
	world.player.global_position = Vector2(750, 800)
	await process_frame
	if not world.respawning or world.player.health != 4:
		_fail("Falling did not remove 20 percent of maximum health")
		return
	await create_timer(0.75).timeout
	if absf(world.player.global_position.x - 650.0) > 3.0 or world.player.global_position.y > 590.0:
		_fail("Fall did not respawn at the last safe position")
		return
	world.seal_health = 0
	world.seal_body.queue_free()
	world.player.global_position = Vector2(1702, 570)
	await create_timer(0.7).timeout
	await process_frame
	await process_frame
	if world.current_room != 3 or world.background_rect.texture != world.CAVE_ROOM_BACKDROPS[2]:
		_fail("Room 2 to Room 3 transition failed")
		return
	world.player.global_position = world.NOTE_POSITION
	world._open_note()
	if not world.note_found or not world.note_panel.visible:
		_fail("Hidden note did not open")
		return
	world._close_note()
	world.player.global_position = Vector2(3072, 570)
	await create_timer(0.7).timeout
	await process_frame
	await process_frame
	if world.current_room != 4 or world.background_rect.texture != world.CAVE_ROOM_BACKDROPS[3]:
		_fail("Room 3 to Room 4 transition failed")
		return
	if world.checkpoint.x != 2760.0 or not world.boss.active or not is_instance_valid(world.arena_barrier):
		_fail("Warden fight did not preserve the prior checkpoint and seal the arena")
		return
	world.player.global_position = Vector2(3060, 570)
	await process_frame
	if world.current_room != 4 or world.player.global_position.x < 3110.0:
		_fail("Player escaped the active Warden arena")
		return
	world.player.invulnerability = 0.0
	world.player.health = 1
	world.player.take_damage(1, world.boss.global_position.x)
	await create_timer(1.15).timeout
	if world.current_room != 3 or absf(world.player.global_position.x - 2760.0) > 3.0 or is_instance_valid(world.arena_barrier):
		_fail("Death did not return the player to the Room 3 respawn point")
		return
	world.player.global_position = Vector2(3072, 570)
	await create_timer(0.7).timeout
	if world.current_room != 4 or not world.boss.active or not is_instance_valid(world.arena_barrier):
		_fail("Warden arena did not lock on retry")
		return
	world._on_boss_defeated()
	if not world.player.has_heavy or world.wall_broken or is_instance_valid(world.arena_barrier):
		_fail("Boss reward or cracked wall state is wrong")
		return
	world.boss.active = false
	world.player.global_position = Vector2(3810, 570)
	world.player.facing = 1
	var press := InputEventKey.new()
	press.physical_keycode = KEY_H
	press.keycode = KEY_H
	press.pressed = true
	Input.parse_input_event(press)
	await create_timer(1.2).timeout
	var release := InputEventKey.new()
	release.physical_keycode = KEY_H
	release.keycode = KEY_H
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame
	await process_frame
	if not world.wall_broken:
		_fail("Holding and releasing H did not break the cracked wall")
		return
	world.player.global_position = Vector2(4202, 570)
	await create_timer(0.7).timeout
	if current_scene == null or current_scene.name != "ForestEntry":
		_fail("Forest exit did not load the forest room")
		return
	var forest := current_scene
	forest.player.global_position = Vector2(50, 570)
	await create_timer(0.7).timeout
	if current_scene == null or current_scene.name != "TutorialWorld" or current_scene.current_room != 4:
		_fail("Forest return did not load Cave Room 4")
		return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame
	SAVE_SLOTS.delete_slot(3, TEST_ROOT)
	remove_meta("active_save_slot")
	remove_meta("save_root")
	print("CAVE_ROOMS_SMOKE_PASS")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _interact() -> void:
	var press := InputEventKey.new()
	press.physical_keycode = KEY_E
	press.keycode = KEY_E
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventKey.new()
	release.physical_keycode = KEY_E
	release.keycode = KEY_E
	release.pressed = false
	Input.parse_input_event(release)
