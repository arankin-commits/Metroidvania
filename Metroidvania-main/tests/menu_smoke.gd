extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var result := change_scene_to_file("res://scenes/main_menu.tscn")
	if result != OK:
		push_error("Menu scene could not load")
		quit(1)
		return
	await process_frame
	await process_frame
	var menu := current_scene
	if menu == null or menu.slot_buttons.size() != 3:
		push_error("Menu or save slot buttons did not initialize")
		quit(1)
		return
	menu._open(menu.slots_screen)
	if not menu.slots_screen.visible or menu.menu_screen.visible:
		push_error("Save slot screen did not open")
		quit(1)
		return
	menu._open(menu.options_screen)
	menu._open(menu.achievements_screen)
	menu._open(menu.menu_screen)
	if not menu.menu_screen.visible:
		push_error("Menu navigation failed")
		quit(1)
		return
	print("MENU_SMOKE_PASS")
	quit()
