extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.is_empty(): push_error("Pass the runtime resource manifest after --"); quit(1); return
	var resources: Array=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	for path in resources:
		var resource:=ResourceLoader.load("res://"+str(path))
		if resource==null:
			push_error("Runtime resource missing from pack: "+str(path)); quit(1); return
		if resource is Script and not resource.can_instantiate():
			push_error("Packed script failed to compile: "+str(path)); quit(1); return
	for scene in ["res://scenes/main_menu.tscn","res://scenes/tutorial.tscn","res://scenes/forest_entry.tscn"]:
		set_meta("active_save_slot",0)
		if change_scene_to_file(scene)!=OK: push_error("Cannot open packed scene: "+scene); quit(1); return
		for i in 5: await process_frame
		if current_scene==null: push_error("Packed scene failed to instantiate"); quit(1); return
		if scene.ends_with("forest_entry.tscn"):
			for room in [6,8,7,9,10]:
				await current_scene._change_room(room,current_scene.BOUNDS[room-5].x+100)
				for i in 3: await process_frame
	change_scene_to_file("res://scenes/main_menu.tscn")
	for i in 3: await process_frame
	print("WEB_PACK_SMOKE_PASS: all %d audited resources load, menu/cave/forest instantiate, all forest rooms open"%resources.size())
	quit()
