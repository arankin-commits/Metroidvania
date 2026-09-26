extends SceneTree

const SLOTS = preload("res://scripts/save_slots.gd")
const ROOT := "res://tests/.smoke_saves"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT))
	var data: Dictionary = SLOTS.new_slot()
	data["boss_defeated"] = true
	data["has_heavy"] = true
	data["wall_broken"] = true
	SLOTS.write_slot(1, data, ROOT)
	set_meta("active_save_slot", 1)
	set_meta("save_root", ROOT)
	change_scene_to_file("res://scenes/forest_entry.tscn")
	await process_frame
	await process_frame
	var forest := current_scene
	if forest.current_room != 5 or forest.BOUNDS.size() != 4 or not forest.visited_rooms.has(5):
		_fail("The Twisted Forest did not begin in its first room")
		return
	await forest._change_room(6, 1280.0)
	if forest.current_room != 6 or not forest.visited_rooms.has(6):
		_fail("Forest Room 2 did not transition or appear on the map")
		return
	await forest._change_room(7, 2680.0)
	await create_timer(0.1).timeout
	if not forest.bow_boss.active or not is_instance_valid(forest.arena_entrance) or not is_instance_valid(forest.arena_exit):
		_fail("The Bow Hunter did not start in Forest Room 3 (room=%d, active=%s, entrance=%s, exit=%s)" % [forest.current_room, forest.bow_boss.active, is_instance_valid(forest.arena_entrance), is_instance_valid(forest.arena_exit)])
		return
	forest.bow_boss.take_hit(10.0)
	await process_frame
	if not forest.bow_boss_defeated or not forest.player.has_bow or forest.player.bow_ammo != 3 or is_instance_valid(forest.arena_exit):
		_fail("The Bow Hunter did not grant the bow and unlock the room")
		return
	forest.player.bow_ammo = 0
	var bow_press := InputEventKey.new()
	bow_press.physical_keycode = KEY_L
	bow_press.keycode = KEY_L
	bow_press.pressed = true
	Input.parse_input_event(bow_press)
	await physics_frame
	var bow_release := InputEventKey.new()
	bow_release.physical_keycode = KEY_L
	bow_release.keycode = KEY_L
	bow_release.pressed = false
	Input.parse_input_event(bow_release)
	await create_timer(1.1).timeout
	if forest.player.bow_ammo != 0:
		_fail("Bow arrows reloaded without meditation")
		return
	await forest._change_room(8, 4080.0)
	forest.player.global_position = Vector2(forest.HAND_X, 570)
	forest._set_camera()
	await process_frame
	forest.player.health = 2
	forest.player.healing_charges = 1
	forest.player.bow_ammo = 0
	forest.activate_hand()
	if forest.player.health != 5 or forest.player.healing_charges != 3 or forest.player.bow_ammo != 3:
		_fail("Meditation did not refill health, charges, and arrows")
		return
	forest._on_bow(Vector2(forest.HAND_X, 550), Vector2.RIGHT)
	forest.save_at_hand()
	var saved: Dictionary = SLOTS.load_slot(1, ROOT)
	if saved.get("area") != "The Twisted Forest" or saved.get("room") != 8 or not saved.get("forest_hand_activated") or saved.get("bow_ammo") != 3:
		_fail("Forest progress was not saved")
		return
	if forest._completed_rooms().has(7) == false or forest._completed_rooms().has(8) == false:
		_fail("Forest map completion was not recorded")
		return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame
	SLOTS.delete_slot(1, ROOT)
	remove_meta("active_save_slot")
	remove_meta("save_root")
	print("TWISTED_FOREST_SMOKE_PASS")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
