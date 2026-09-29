extends "res://tests/gallery_section_smoke.gd"

const FIXTURE := "res://tests/.gallery_gates_saves"

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FIXTURE))
	SLOTS.write_slot(3,SLOTS.new_slot(),FIXTURE)
	set_meta("active_save_slot",3)
	set_meta("save_root",FIXTURE)
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await physics_frame
	world=current_scene
	world.player._advance_wake(4.0)
	await world._begin_room_transition(2,world.GALLERY_LAYOUT.ENTRANCE.x)
	_freeze_encounters()
	# The old low doorway is sealed; the replacement still connects to Room 1.
	world.player.position=Vector2(-16,570)
	world._check_room_transition()
	if world.transitioning_room:
		_fail("The removed entrance still transitions")
		return
	world.player.position=Vector2(-16,1473)
	world._check_room_transition()
	for i in 90:
		await physics_frame
	if world.current_room!=1 or absf(world.player.position.y-577)>10 or world.checkpoint!=world.CAVE_LAYOUT.START:
		_fail("The moved entrance changed its neighbor or death checkpoint")
		return
	world.player.position=Vector2(16,570)
	world._check_room_transition()
	for i in 90:
		await physics_frame
	if world.current_room!=2 or world.player.position.distance_to(world.GALLERY_LAYOUT.ENTRANCE)>12:
		_fail("Room 1 did not receive the player at the new lower doorway")
		return
	_freeze_encounters()
	world.player.position=Vector2(4610,-1223)
	world.player.reset_movement_state()
	world.player.facing=1
	for i in 8:
		await physics_frame
	_key(KEY_J,true)
	for i in 3:
		await physics_frame
	_key(KEY_J,false)
	_key(KEY_H,true)
	for i in 55:
		await physics_frame
	_key(KEY_H,false)
	for i in 20:
		await physics_frame
	if world.gallery_heavy_open or not is_instance_valid(world.gallery.heavy_wall):
		_fail("The new wall opened without the boss ability")
		return
	_key(KEY_D,true)
	for i in 30:
		await physics_frame
	_key(KEY_D,false)
	if world.player.position.x>4647:
		_fail("The blue wall does not block traversal")
		return
	world.player.has_heavy=true
	_key(KEY_H,true)
	for i in 55:
		await physics_frame
	_key(KEY_H,false)
	for i in 20:
		await physics_frame
	if not world.gallery_heavy_open or is_instance_valid(world.gallery.heavy_wall):
		_fail("A real charged Warden strike did not open the blue wall")
		return
	if not await _walk(Vector2(4790,-1223),"opened heavy passage"):
		return
	if not await _walk(Vector2(4610,-1223),"opened heavy passage return"):
		return
	world._save_progress()
	reload_current_scene()
	await process_frame
	await physics_frame
	world=current_scene
	_freeze_encounters()
	if not world.gallery_heavy_open or not world.gallery_map_state().heavy_open:
		_fail("Heavy shortcut opening was lost on reload or map state")
		return
	# The upper receiving gallery and red future floor both resist S+Jump.
	for at in [Vector2(4890,-1523),Vector2(3660,922)]:
		world.player.position=at
		world.player.reset_movement_state()
		for i in 8:
			await physics_frame
		world._on_player_attacked(Rect2(at-Vector2(50,30),Vector2(100,80)))
		world._on_player_heavy_attacked(world.GALLERY_LAYOUT.SMASH_FLOOR)
		_key(KEY_S,true)
		_key(KEY_SPACE,true)
		for i in 3:
			await physics_frame
		_key(KEY_S,false)
		_key(KEY_SPACE,false)
		for i in 75:
			await physics_frame
		if not world.player.is_on_floor() or absf(world.player.position.y-at.y)>5 or world.player.drop_exception_active:
			_fail("The upper or future-smash floor can be dropped through")
			return
	if not is_instance_valid(world.gallery.smash_floor) or world.gallery.smash_floor.get_child(0).one_way_collision:
		_fail("The future smash floor lost solid collision")
		return
	# Neither a jump nor a ledge catch can bypass the floor from its lower side.
	world.player.position=Vector2(3700,1207)
	world.player.reset_movement_state()
	for i in 8:
		await physics_frame
	_key(KEY_SPACE,true)
	for i in 70:
		if i==3:
			_key(KEY_SPACE,false)
		await physics_frame
		if world.player.position.y<1016:
			_fail("Current movement bypassed the future downward-smash floor")
			return
	world._save_progress()
	change_scene_to_file("res://scenes/forest_entry.tscn")
	await process_frame
	await process_frame
	if not current_scene.gallery_map_state().heavy_open:
		_fail("Forest travel lost the heavy shortcut")
		return
	current_scene._save_progress()
	set_meta("cave_entry_x",2610.0)
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await physics_frame
	world=current_scene
	if not world.gallery_heavy_open or not is_instance_valid(world.gallery.smash_floor):
		_fail("Biome round trip changed either ability gate")
		return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	SLOTS.delete_slot(3,FIXTURE)
	print("GALLERY_GATES_SMOKE_PASS")
	quit()

func _freeze_encounters() -> void:
	world.set_process(false)
	# Reload now starts in Room 1 until a hand is activated; this fixture tests Room 2.
	world.current_room=2
	world._set_camera_room()
	world.gallery_encounters.set_active(false)
	if is_instance_valid(world.ledge_sentinel):
		world.ledge_sentinel.set_process(false)
	if is_instance_valid(world.scout):
		world.scout.set_physics_process(false)
		world.scout.collision_layer=0
	world.player.invulnerability=1000
