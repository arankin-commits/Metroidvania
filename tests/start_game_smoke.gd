extends SceneTree

const SAVE_SLOTS = preload("res://scripts/save_slots.gd")
const TEST_ROOT := "res://tests/.smoke_saves"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_ROOT)) != OK:
		push_error("Could not create temporary save test directory")
		quit(1)
		return
	var data: Dictionary = SAVE_SLOTS.new_slot()
	data["seconds"] = 3610.0
	data["checkpoint_x"] = 1810.0
	data["room"] = 3
	data["has_dash"] = true
	data["seal_broken"] = true
	data["scout_defeated"] = true
	if SAVE_SLOTS.write_slot(2, data, TEST_ROOT) != OK:
		push_error("Could not set up test slot")
		quit(1)
		return
	if change_scene_to_file("res://scenes/main_menu.tscn") != OK:
		push_error("Could not open menu")
		quit(1)
		return
	await process_frame
	await process_frame
	var menu := current_scene
	menu.save_root = TEST_ROOT
	menu._refresh_slots()
	if not menu.slot_buttons[1].text.contains("01:00:10"):
		push_error("Occupied slot did not show saved time")
		quit(1)
		return
	menu._start_slot(2)
	await create_timer(0.7).timeout
	await process_frame
	var world := current_scene
	if world == null or world.name != "TutorialWorld":
		push_error("Slot selection did not enter the cave")
		quit(1)
		return
	if absf(world.player.position.x - 1810.0) > 2.0 or not world.player.has_dash or world.seal_health != 0:
		push_error("Save progress was not restored")
		quit(1)
		return
	world._save_progress()
	if SAVE_SLOTS.load_slot(2, TEST_ROOT).get("seconds", 0.0) < 3610.0:
		push_error("Cave progress was not written")
		quit(1)
		return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame
	SAVE_SLOTS.delete_slot(2, TEST_ROOT)
	print("START_GAME_SMOKE_PASS")
	quit()
