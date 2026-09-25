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
	if world.visited_rooms != [2] or not world._completed_rooms().is_empty():
		_fail("New-game map revealed unexplored or incomplete rooms")
		return
	if world.hand_chair.texture == null or world.hand_chair.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		_fail("Hand-chair checkpoint sprite is missing")
		return
	_map_key(KEY_M)
	await process_frame
	if not world.world_map.visible or not paused or world.world_map.visited_rooms != [2]:
		_fail("M did not open the discovery map")
		return
	_map_key(KEY_TAB)
	await process_frame
	if world.world_map.visible or paused:
		_fail("Tab did not close the map")
		return
	_map_key(KEY_M)
	await process_frame
	_map_key(KEY_ESCAPE)
	await process_frame
	if world.world_map.visible or world.pause_menu.visible or paused:
		_fail("Esc did not close the map cleanly")
		return
	if world.background_rect.get_parent() != world or world.background_rect.size.x <= 1200.0:
		_fail("Room 2 backdrop is not positioned in the scrolling world")
		return
	if world.checkpoint.x != 120.0 or world.hand_chair.position.x != 2610.0:
		_fail("The first visible hand checkpoint is not in Cave Room 3")
		return
	await create_timer(0.2).timeout
	var dodge_press := InputEventKey.new()
	dodge_press.physical_keycode = KEY_K
	dodge_press.keycode = KEY_K
	dodge_press.pressed = true
	Input.parse_input_event(dodge_press)
	await physics_frame
	await physics_frame
	if not world.player.has_dash or world.player.dash_time <= 0.0:
		_fail("The starting air dash or ground dodge is unavailable")
		return
	var dodge_release := InputEventKey.new()
	dodge_release.physical_keycode = KEY_K
	dodge_release.keycode = KEY_K
	dodge_release.pressed = false
	Input.parse_input_event(dodge_release)
	await create_timer(0.25).timeout
	world.player.dash_time = 0.0
	world.player.dash_cooldown = 0.0
	world.player.global_position = Vector2(240, 470)
	world.player.velocity = Vector2.ZERO
	await physics_frame
	await physics_frame
	_key(KEY_K, true)
	await physics_frame
	await physics_frame
	if world.player.dash_time <= 0.0 or world.player.dash_speed_current != world.player.DASH_SPEED:
		_fail("Air dash was not available at the start of a new game")
		return
	_key(KEY_K, false)
	world.player.dash_time = 0.0
	world.player.velocity = Vector2.ZERO
	world.player.global_position = Vector2(-2, 570)
	await process_frame
	if world.current_room != 2:
		_fail("Room changed before the player fully left the screen")
		return
	world.player.global_position = Vector2(-16, 570)
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
	if not world.visited_rooms.has(1) or not world._completed_rooms().has(1):
		_fail("Room 1 discovery/completion was not recorded")
		return
	world.player.global_position = Vector2(16, 570)
	await create_timer(0.7).timeout
	await process_frame
	await process_frame
	if world.current_room != 2 or world.background_rect.texture != world.CAVE_ROOM_BACKDROPS[1]:
		_fail("Room 1 to Room 2 return failed")
		return
	var air_path := PhysicsRayQueryParameters2D.create(Vector2(1005, 445), Vector2(1035, 445))
	air_path.exclude = [world.player.get_rid()]
	if not world.get_world_2d().direct_space_state.intersect_ray(air_path).is_empty():
		_fail("A wall still blocks the aerial enemy's ledge")
		return
	world.player.global_position = Vector2(995, 490)
	world.player.facing = 1
	await physics_frame
	var strike_press := InputEventKey.new()
	strike_press.physical_keycode = KEY_J
	strike_press.keycode = KEY_J
	strike_press.pressed = true
	Input.parse_input_event(strike_press)
	await physics_frame
	await physics_frame
	if not is_instance_valid(world.ledge_sentinel) or world.ledge_sentinel.health != 1 or world.aerial_practiced:
		_fail("First aerial hit did not damage the ledge enemy")
		return
	var strike_release := InputEventKey.new()
	strike_release.physical_keycode = KEY_J
	strike_release.keycode = KEY_J
	strike_release.pressed = false
	Input.parse_input_event(strike_release)
	await create_timer(0.35).timeout
	world.player.global_position = Vector2(995, 490)
	world.player.velocity = Vector2.ZERO
	await physics_frame
	_key(KEY_J, true)
	await physics_frame
	await physics_frame
	_key(KEY_J, false)
	if not world.aerial_practiced or is_instance_valid(world.ledge_sentinel):
		_fail("Second aerial hit did not clear the ledge enemy")
		return
	world.player.global_position = Vector2(1400, 497)
	world.player.velocity = Vector2.ZERO
	await physics_frame
	await physics_frame
	_key(KEY_S, true)
	_key(KEY_SPACE, true)
	await physics_frame
	await physics_frame
	_key(KEY_SPACE, false)
	_key(KEY_S, false)
	if not world.drop_practiced or world.player.drop_ignore_timer <= 0.0:
		_fail("S + Jump did not drop through the tutorial platform")
		return
	await create_timer(0.45).timeout
	world.player.global_position = Vector2(1495, 497)
	world.player.velocity = Vector2.ZERO
	await physics_frame
	await physics_frame
	_key(KEY_S, true)
	_key(KEY_SPACE, true)
	await physics_frame
	await physics_frame
	_key(KEY_SPACE, false)
	_key(KEY_S, false)
	await create_timer(0.12).timeout
	var drop_without_wall_input: float = world.player.global_position.y
	world.player.remove_collision_exception_with(world.drop_platform_body)
	world.player.drop_exception_active = false
	world.player.drop_ignore_timer = 0.0
	world.player.floor_block_on_wall = true
	world.player.global_position = Vector2(1495, 497)
	world.player.velocity = Vector2.ZERO
	await physics_frame
	await physics_frame
	_key(KEY_D, true)
	_key(KEY_S, true)
	_key(KEY_SPACE, true)
	await physics_frame
	await physics_frame
	_key(KEY_SPACE, false)
	_key(KEY_S, false)
	await create_timer(0.12).timeout
	_key(KEY_D, false)
	if absf(world.player.global_position.y - drop_without_wall_input) > 8.0:
		_fail("Pressing into the wall changed drop-through fall speed")
		return
	await create_timer(0.45).timeout
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
	if not world._completed_rooms().has(2):
		_fail("Room 2 did not become complete after collecting its Sigil")
		return
	_interact()
	await process_frame
	if world.note_open or world.note_panel.visible:
		_fail("Second interaction did not close the Cave Sigil")
		return
	world.player.global_position = Vector2(510, 502)
	_interact()
	await process_frame
	if world.note_open:
		_fail("Collected Cave Sigil appeared again")
		return
	world.last_safe_position = Vector2(650, 570)
	world.player.health = 5
	world.player.global_position = Vector2(750, 800)
	await process_frame
	if not world.respawning or world.player.health != 4:
		_fail("Falling did not remove 20 percent of maximum health")
		return
	await create_timer(0.75).timeout
	if absf(world.player.global_position.x - 620.0) > 3.0 or world.player.global_position.y > 590.0:
		_fail("Fall did not respawn at the last safe position")
		return
	world.seal_health = 0
	world.seal_body.queue_free()
	world.player.global_position = Vector2(1716, 570)
	await create_timer(0.7).timeout
	await process_frame
	await process_frame
	if world.current_room != 3 or world.background_rect.texture != world.CAVE_ROOM_BACKDROPS[2]:
		_fail("Room 2 to Room 3 transition failed")
		return
	world.last_safe_position = Vector2(2158, 447)
	world.player.health = 5
	world.player.global_position = Vector2(2300, 800)
	await process_frame
	await create_timer(0.75).timeout
	if absf(world.player.global_position.x - 2080.0) > 3.0 or world.player.global_position.y > 460.0 or world.respawning:
		_fail("Room 3 pit did not recover onto stable ground")
		return
	await create_timer(0.55).timeout
	if world.respawning or world.player.global_position.y > 650.0:
		_fail("Room 3 pit recovery fell back into the pit")
		return
	world.player.health = 1
	world.player.global_position = Vector2(2300, 800)
	await process_frame
	await process_frame
	if not world.respawning or world.player.health != 0:
		_fail("A pit fall at 20 percent health did not cause death")
		return
	await create_timer(1.15).timeout
	if world.current_room != 2 or absf(world.player.global_position.x - 120.0) > 3.0:
		_fail("Death before using the hand did not return to the starting spawn")
		return
	world.player.global_position = Vector2(1716, 570)
	await create_timer(0.7).timeout
	if world.current_room != 3:
		_fail("Could not return to Room 3 after death")
		return
	world.player.global_position = Vector2(1970, 577)
	world.player.velocity = Vector2.ZERO
	world.player.facing = 1
	await physics_frame
	await physics_frame
	_key(KEY_D, true)
	_key(KEY_SPACE, true)
	for i in 14:
		await physics_frame
	_key(KEY_D, false)
	_key(KEY_SPACE, false)
	await physics_frame
	await physics_frame
	if not world.player.ledge_grabbed and world.player.ledge_climb_time <= 0.0 and not world.ledge_practiced:
		_fail("The Room 3 terrain edge did not catch the player's head")
		return
	if world.player.ledge_grabbed:
		_key(KEY_SPACE, true)
		await physics_frame
		await physics_frame
		_key(KEY_SPACE, false)
	await create_timer(0.4).timeout
	if not world.ledge_practiced or world.player.global_position.y > 455.0:
		_fail("The Room 3 climb animation did not finish on top")
		return
	world.player.global_position = Vector2(1930, 480)
	world.player.velocity = Vector2.ZERO
	world.player.facing = 1
	world.player.dash_cooldown = 0.0
	await physics_frame
	_key(KEY_K, true)
	for i in 12:
		await physics_frame
	_key(KEY_K, false)
	if not world.player.ledge_grabbed and world.player.ledge_climb_time <= 0.0:
		print("DASH_LEDGE_DEBUG pos=", world.player.global_position, " dash=", world.player.dash_time, " wall=", world.player.is_on_wall(), " normal=", world.player.get_wall_normal(), " floor=", world.player.is_on_floor(), " facing=", world.player.facing)
		_fail("Air dashing into a head-height edge did not catch the ledge")
		return
	if world.player.ledge_grabbed:
		_key(KEY_D, true)
		await physics_frame
		await physics_frame
		_key(KEY_D, false)
	await create_timer(0.4).timeout
	if world.player.global_position.y > 455.0:
		_fail("Forward input did not climb after the air dash")
		return
	world.player.global_position = Vector2(2610, 570)
	_interact()
	await process_frame
	if not world.hand_menu.visible or not paused or not world.hand_menu.content.text.contains("Air dash") or not world.hand_activated or world.checkpoint.x != 2610.0:
		_fail("The Room 3 hand did not open its abilities menu")
		return
	world.player.health = 2
	world.hand_menu._save()
	if world.player.health != world.player.max_health or SAVE_SLOTS.load_slot(3, TEST_ROOT).get("checkpoint_x") != 2610.0:
		_fail("The Room 3 hand did not set the checkpoint and save")
		return
	world.hand_menu._show_notes()
	if not world.hand_menu.content.text.contains("CAVE SIGIL"):
		_fail("The hand did not retain the collected Cave Sigil")
		return
	_map_key(KEY_ESCAPE)
	await process_frame
	if world.hand_menu.visible or paused or world.pause_menu.visible:
		_fail("Esc did not close the hand menu cleanly")
		return
	world.player.global_position = world.NOTE_POSITION
	_interact()
	await process_frame
	if not world.note_found or not world.note_panel.visible:
		_fail("Hidden note did not open")
		return
	_interact()
	await process_frame
	_interact()
	await process_frame
	if world.note_open:
		_fail("Read note appeared again")
		return
	if not world.player.has_dash or not world._completed_rooms().has(3):
		_fail("Room 3 did not become complete after the note")
		return
	world.player.global_position = Vector2(3086, 570)
	await create_timer(0.7).timeout
	await process_frame
	await process_frame
	if world.current_room != 4 or world.background_rect.texture != world.CAVE_ROOM_BACKDROPS[3]:
		_fail("Room 3 to Room 4 transition failed")
		return
	if world.checkpoint.x != 2610.0 or not world.boss.active or not is_instance_valid(world.arena_barrier):
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
	if world.current_room != 3 or absf(world.player.global_position.x - 2610.0) > 3.0 or is_instance_valid(world.arena_barrier):
		_fail("Death did not return the player to the Room 3 respawn point")
		return
	world.player.global_position = Vector2(3086, 570)
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
	await physics_frame
	await physics_frame
	if not world.wall_broken:
		_fail("Holding and releasing H did not break the cracked wall")
		return
	world.player.global_position = Vector2(4466, 570)
	await create_timer(0.7).timeout
	if current_scene == null or current_scene.name != "ForestEntry":
		_fail("Forest exit did not load the forest room")
		return
	var forest := current_scene
	if not forest.visited_rooms.has(5) or not forest._completed_rooms().has(5):
		_fail("Forest map discovery was not recorded")
		return
	_map_key(KEY_TAB)
	await process_frame
	if not forest.world_map.visible or not paused:
		_fail("Forest map did not open")
		return
	_map_key(KEY_TAB)
	await process_frame
	if forest.world_map.visible or paused:
		_fail("Forest map did not close")
		return
	forest.player.global_position = Vector2(-16, 570)
	await create_timer(0.7).timeout
	if current_scene == null or current_scene.name != "TutorialWorld" or current_scene.current_room != 4:
		_fail("Forest return did not load Cave Room 4")
		return
	if not current_scene.visited_rooms.has(5) or not current_scene._completed_rooms().has(4):
		_fail("Room discoveries or boss completion were lost on forest return")
		return
	if current_scene.checkpoint.x != 2610.0 or not current_scene.hand_activated:
		_fail("Returning from the forest replaced the hand death checkpoint")
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

func _map_key(key: Key) -> void:
	var press := InputEventKey.new()
	press.physical_keycode = key
	press.keycode = key
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventKey.new()
	release.physical_keycode = key
	release.keycode = key
	release.pressed = false
	Input.parse_input_event(release)

func _key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)
