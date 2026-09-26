extends SceneTree

const SLOTS = preload("res://scripts/save_slots.gd")
const ROOT := "res://tests/.forest_regression_saves"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT))
	var data: Dictionary = SLOTS.new_slot()
	SLOTS.write_slot(1, data, ROOT)
	set_meta("active_save_slot", 1)
	set_meta("save_root", ROOT)
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await process_frame
	var cave := current_scene
	cave.activate_hand()
	cave._save_progress()
	data = SLOTS.load_slot(1, ROOT)
	if not data.get("hand_activated", false) or data.get("last_hand_room") != 3 or data.get("checkpoint_x") != 2610.0:
		_fail("Leaving the cave did not save the hand checkpoint")
		return
	set_meta("forest_entry_room", 7)
	change_scene_to_file("res://scenes/forest_entry.tscn")
	await process_frame
	await process_frame
	var forest := current_scene
	if forest.current_room != 7 or forest.last_hand_room != 3:
		_fail("The forest lost the cave hand checkpoint")
		return
	forest._change_room(8, 4080.0)
	if not forest.transitioning:
		_fail("The forest room transition did not start")
		return
	forest.player.take_damage(forest.player.health, forest.player.global_position.x + 100.0)
	await create_timer(1.2).timeout
	await process_frame
	if current_scene == forest or current_scene.current_room != 3 or absf(current_scene.player.global_position.x - 2610.0) > 1.0:
		_fail("Lethal arrow damage during a forest transition did not return to the cave hand")
		return
	set_meta("forest_entry_room", 7)
	change_scene_to_file("res://scenes/forest_entry.tscn")
	await process_frame
	await process_frame
	forest = current_scene
	forest.bow_boss.take_hit(10.0)
	await process_frame
	forest.player.global_position = Vector2(4000.0, 570.0)
	forest._check_transition()
	if not forest.transitioning:
		_fail("Walking to the room edge did not start the transition")
		return
	await create_timer(0.5).timeout
	if forest.current_room != 8 or not forest.player.visible:
		_fail("The player did not appear in Forest Room 4")
		return
	var camera := forest.player.get_node("Camera2D") as Camera2D
	if absf(forest.player.global_position.x - camera.get_screen_center_position().x) >= forest.get_viewport_rect().size.x * 0.5:
		_fail("The player was outside the camera after entering Forest Room 4")
		return
	forest.activate_hand()
	forest.player.take_damage(forest.player.health, forest.player.global_position.x + 100.0)
	await create_timer(1.2).timeout
	if forest.current_room != 8 or absf(forest.player.global_position.x - forest.HAND_X) > 1.0 or forest.player.death_active:
		_fail("Death after using the forest hand did not respawn at that hand")
		return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame
	SLOTS.delete_slot(1, ROOT)
	remove_meta("active_save_slot")
	remove_meta("save_root")
	print("FOREST_REGRESSION_SMOKE_PASS")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
