extends "res://tests/gallery_section_smoke.gd"

func _run() -> void:
	var fixture := "res://tests/.gallery_joints_saves"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(fixture))
	SLOTS.write_slot(3,SLOTS.new_slot(),fixture)
	set_meta("active_save_slot",3)
	set_meta("save_root",fixture)
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await physics_frame
	world=current_scene
	world.set_process(false)
	world.gallery_encounters.set_active(false)
	world.ledge_sentinel.set_process(false)
	world.scout.set_physics_process(false)
	world.scout.collision_layer=0
	world.player.has_heavy=true
	world._on_player_heavy_attacked(world.gallery.LAYOUT.HEAVY_WALL)
	world.player.invulnerability=1000
	world.player.position=world.gallery.LAYOUT.EAST_WINCH
	_interact()
	await physics_frame
	if not world.gallery_east_open:
		_fail("Exit return links require the operated far-side shortcut")
		return
	if not await _check_optional_links():
		return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	SLOTS.delete_slot(3,fixture)
	print("GALLERY_JOINTS_SMOKE_PASS")
	quit()
