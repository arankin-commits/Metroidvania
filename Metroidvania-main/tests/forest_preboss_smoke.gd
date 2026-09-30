extends SceneTree
const SLOTS=preload("res://scripts/save_slots.gd")
const SAVE_ROOT="res://tests/.forest_preboss_saves"

func _initialize() -> void: call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_ROOT))
	var data:=SLOTS.new_slot()
	data["boss_defeated"]=true
	SLOTS.write_slot(1,data,SAVE_ROOT)
	set_meta("save_root",SAVE_ROOT); set_meta("active_save_slot",1); set_meta("forest_entry_room",6)
	change_scene_to_file("res://scenes/forest_entry.tscn")
	await process_frame; await physics_frame
	var w:=current_scene
	w.player.invulnerability=1000
	var route:=preload("res://tests/forest_preboss_route.gd").new()
	w.add_child(route)
	route.world=w
	for x in [3900,4500,4980,5350,5800,6250,6740]:
		if not await route._walk(Vector2(x,w._receiving_position(6,x).y),"pre-boss Sections1/2"):
			push_error(str(route.get_meta("failure","Pre-boss approach failed"))); quit(1); return
	if not await route.run_route(): push_error(str(route.get_meta("failure","Pre-boss room route failed"))); quit(1); return
	if w.player.has_dash or w.bow_boss_defeated: push_error("Pre-boss route used an earned dash fixture"); quit(1); return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame; await process_frame
	SLOTS.delete_slot(1,SAVE_ROOT)
	print("FOREST_PREBOSS_SMOKE_PASS: Sections1–11 and return with basic dash only")
	quit()
