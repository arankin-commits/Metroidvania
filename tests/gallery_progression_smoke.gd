extends "res://tests/gallery_section_smoke.gd"

const PROGRESS_ROOT := "res://tests/.gallery_progression_saves"
var progress_root := PROGRESS_ROOT
var expected_will := 12

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(progress_root))
	SLOTS.write_slot(2, SLOTS.new_slot(), progress_root)
	set_meta("active_save_slot", 2)
	set_meta("save_root", progress_root)
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await process_frame
	world = current_scene
	world.player.invulnerability = 1000
	_prepare_encounters()
	# The first visit reaches the exit over the crown without the boss's ability.
	if world.player.position.distance_to(world.gallery.LAYOUT.START)>5 or world.player.has_heavy:
		_fail("The moved starting entrance or first-visit ability state is wrong")
		return
	if not await _upper_route(false):
		return
	if world.gallery_heavy_open:
		_fail("The pre-boss route incorrectly opened the heavy shortcut")
		return
	_key(KEY_D, true)
	for i in 45:
		await physics_frame
	_key(KEY_D, false)
	if world.current_room != 2 or world.seal_health != 3 or world.player.position.x > 4967:
		_fail("The seal could be bypassed before its lesson")
		return
	# The real attack input must deliver all three hits, and the opening must save.
	for hit in 3:
		_key(KEY_J, true)
		for i in 3:
			await physics_frame
		_key(KEY_J, false)
		for i in 22:
			await physics_frame
		if world.seal_health != 2 - hit:
			_fail("Seal did not respond to exactly three ordinary strikes")
			return
	# A jumping exit must use the whole doorway, not just floor-level coordinates.
	_key(KEY_D, true)
	_key(KEY_SPACE, true)
	for i in 3:
		await physics_frame
	_key(KEY_SPACE, false)
	if not await _travel_to(3):
		return
	_key(KEY_D, false)
	if absf(world.player.position.x - 1780) > 20 or world.checkpoint.x != 120:
		_fail("The moved door changed Room 3's receiving spawn or the checkpoint")
		return
	_key(KEY_A, true)
	if not await _travel_to(2):
		return
	_key(KEY_A, false)
	if absf(world.player.position.x - 4920) > 20:
		_fail("Room 3 did not return through the moved Room 2 door")
		return
	_prepare_encounters()
	if not await _upper_route(true):
		return
	if not _finish_traversal():
		return
	# Isolated state scenarios follow the complete traversal above. Optional-route
	# reachability in both directions is independently checked by the section test.
	world.player.position = world.GALLERY_LAYOUT.EAST_WINCH
	_interact()
	world.player.position = world.GALLERY_LAYOUT.WEST_WINCH
	_interact()
	world.player.position = Vector2(-300, -761)
	_interact()
	if not world.secret_found or world._completed_rooms().has(2):
		_fail("Room 2 completed without both its established reward objectives")
		return
	world._close_note()
	expected_will=world.will_amount+12
	world.player.position = Vector2(600, -1598)
	_interact()
	_interact()
	if world.will_amount != expected_will or not world._completed_rooms().has(2):
		_fail("The Sigil/offering completion or exactly-once Will reward changed")
		return
	world._save_progress()
	reload_current_scene()
	await process_frame
	await process_frame
	world = current_scene
	if not _persistent_state_ok():
		return
	world.player.health = 1
	world.player.invulnerability = 0
	world.player.take_damage(1, world.player.position.x + 40)
	for i in 80:
		await physics_frame
	if world.current_room != 2 or world.player.position.distance_to(world.gallery.LAYOUT.START)>8 or not _persistent_state_ok():
		_fail("Death before a hand did not preserve rewards and the starting checkpoint")
		return
	world.current_room = 3
	world._mark_room_visited(3)
	world.player.position = Vector2(2610, 570)
	world._set_camera_room()
	world.activate_hand()
	world._save_progress()
	world.current_room = 2
	world.player.position = Vector2(4890, -1523)
	world._set_camera_room()
	world.player.health = 1
	world.player.invulnerability = 0
	world.player.take_damage(1, world.player.position.x + 40)
	for i in 80:
		await physics_frame
	if world.current_room != 3 or absf(world.player.position.x - 2610) > 8 or not _persistent_state_ok():
		_fail("Gallery death changed the last activated hand or lost its rewards")
		return
	world._save_progress()
	change_scene_to_file("res://scenes/forest_entry.tscn")
	await process_frame
	await process_frame
	if not current_scene._completed_rooms().has(2):
		_fail("Forest map lost the expanded gallery's completion")
		return
	current_scene._save_progress()
	set_meta("cave_entry_x", 2610.0)
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await process_frame
	world = current_scene
	if not _persistent_state_ok() or world.checkpoint.x != 2610:
		return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame
	SLOTS.delete_slot(2, progress_root)
	print(_success_marker())
	quit()

func _travel_to(room: int) -> bool:
	for i in 180:
		await physics_frame
		if world.current_room == room and not world.transitioning_room:
			return true
	_key(KEY_A, false)
	_key(KEY_D, false)
	_fail("Could not traverse gallery connection to room %d" % room)
	return false

func _persistent_state_ok() -> bool:
	if not world.secret_found or not world.gallery_cache_found or not world.gallery_west_open or not world.gallery_east_open or world.will_amount != expected_will or world.seal_health != 0 or not world._completed_rooms().has(2):
		_fail("Reload, death or biome travel lost gallery rewards, seal, shortcuts or completion")
		return false
	return true

func _prepare_encounters() -> void:
	world.gallery_encounters.set_active(false)
	if is_instance_valid(world.ledge_sentinel):
		world.ledge_sentinel.set_process(false)
	if is_instance_valid(world.scout):
		world.scout.set_physics_process(false)
		world.scout.collision_layer=0

func _finish_traversal() -> bool:
	return true

func _success_marker() -> String:
	return "GALLERY_PROGRESSION_SMOKE_PASS"

func _upper_route(reverse: bool) -> bool:
	if reverse:
		if not await _walk(Vector2(4300,-1523),"vestibule return"): return false
		if not await _jump(world.player.position,Vector2(4090,-1523)): return false
		for name in ["crown_lip","crown_walk","offering_ascent","chain_well","balcony_ascent"]:
			var route: PackedVector2Array=world.GALLERY_LAYOUT.routes()[name].duplicate()
			route.reverse()
			for point in route:
				if not await _walk(point+Vector2(0,-23),name+" return"): return false
		if not await _walk(Vector2(880,1477),"balcony return"): return false
		if not await _jump(world.player.position,Vector2(650,1477)): return false
		return await _walk(Vector2(120,1477),"lower entrance return")
	if not await _walk(Vector2(320,1477),"entrance"):
		return false
	if not await _jump(world.player.position,Vector2(450,1402)):
		return false
	if not await _walk(Vector2(650,1477),"balcony gap approach"):
		return false
	if not await _jump(world.player.position,Vector2(880,1477)):
		return false
	if not await _walk(Vector2(990,1477),"sentinel approach"):
		return false
	if not await _jump(world.player.position,Vector2(1100,1387)):
		return false
	for route_name in ["balcony_ascent","chain_well","offering_ascent","crown_walk","crown_lip"]:
		for point in world.GALLERY_LAYOUT.routes()[route_name]:
			if not await _walk(point+Vector2(0,-23),route_name):
				return false
		print("REVISION_ROUTE_PASS ",route_name)
	if not await _walk(Vector2(4090,-1523),"upper gap takeoff"):
		return false
	if not await _jump(world.player.position,Vector2(4300,-1523)):
		return false
	if not await _walk(Vector2(4935,-1523),"upper vestibule"):
		return false
	return true
