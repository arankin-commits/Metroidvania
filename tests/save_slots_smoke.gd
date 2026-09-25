extends SceneTree

const SAVE_SLOTS = preload("res://scripts/save_slots.gd")
const TEST_ROOT := "res://tests/.smoke_saves"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_path := ProjectSettings.globalize_path(TEST_ROOT)
	if DirAccess.make_dir_recursive_absolute(root_path) != OK:
		push_error("Could not create temporary save test directory")
		quit(1)
		return
	var data: Dictionary = SAVE_SLOTS.new_slot()
	data["seconds"] = 3671.0
	data["checkpoint_x"] = 2760.0
	data["has_dash"] = true
	if SAVE_SLOTS.write_slot(1, data, TEST_ROOT) != OK:
		push_error("Save write failed")
		quit(1)
		return
	var restored: Dictionary = SAVE_SLOTS.load_slot(1, TEST_ROOT)
	if restored.get("seconds") != 3671.0 or restored.get("checkpoint_x") != 2760.0 or not restored.get("has_dash"):
		push_error("Save data did not round trip")
		quit(1)
		return
	if SAVE_SLOTS.delete_slot(1, TEST_ROOT) != OK or not SAVE_SLOTS.load_slot(1, TEST_ROOT).is_empty():
		push_error("Save deletion failed")
		quit(1)
		return
	print("SAVE_SLOTS_SMOKE_PASS")
	quit()
