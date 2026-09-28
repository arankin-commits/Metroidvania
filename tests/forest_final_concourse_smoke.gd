extends SceneTree
const SLOTS=preload("res://scripts/save_slots.gd")
const L=preload("res://scripts/forest_final_stair_layout.gd")
const N=preload("res://scripts/forest_dash_galleries_layout.gd")
const SAVE_ROOT="res://tests/.forest_final_saves"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_ROOT))
	var data: Dictionary=SLOTS.new_slot()
	data.merge({"hand_activated":true,"last_hand_room":3,"checkpoint_x":2610.0,"checkpoint_y":570.0,"has_heavy":true},true)
	SLOTS.write_slot(1,data,SAVE_ROOT)
	set_meta("active_save_slot",1); set_meta("save_root",SAVE_ROOT); set_meta("forest_entry_room",6)
	change_scene_to_file("res://scenes/forest_entry.tscn")
	await process_frame; await physics_frame
	var world: Node2D=current_scene
	world.player.invulnerability=1000
	world.player.position=Vector2(16120,L.FLOOR-23)
	world.player.reset_movement_state()
	world._set_camera()
	for i in 40: await physics_frame
	var polygons:=L.polygons()
	var index:=0
	for child in world.forest_final_stair.get_children():
		if child is StaticBody2D:
			if child.get_child(0).polygon!=polygons[index]: fail("Stair terrain/collision mismatch"); return
			index+=1
	if index!=3: fail("Unexpected Section11 colliders/platforms"); return
	for x in range(16210,18000,32):
		var q:=PhysicsPointQueryParameters2D.new()
		q.position=Vector2(x,L.surface_y(x)+25)
		if world.get_world_2d().direct_space_state.intersect_point(q).is_empty(): fail("Stair underside penetrable"); return
	var q:=PhysicsPointQueryParameters2D.new()
	q.position=L.CROWN_WALL.get_center()
	if world.get_world_2d().direct_space_state.intersect_point(q).is_empty(): fail("Highest10.2 wall absent"); return
	# Independent wall fixture, then a continuous floor-to-stair route below it.
	world.player.position=Vector2(16110,N.HIGH-23)
	world.player.reset_movement_state()
	var wall_driver:=preload("res://tests/forest_final_concourse_route.gd").new()
	world.add_child(wall_driver)
	wall_driver._key(KEY_D,true)
	for i in 80: await physics_frame
	wall_driver._key(KEY_D,false)
	if world.player.position.x>16157 or world.current_room!=6: fail("Highest gallery wall permits passage"); return
	wall_driver._key(KEY_D,true); wall_driver._key(KEY_SPACE,true)
	for i in 80:
		if i==3: wall_driver._key(KEY_SPACE,false)
		await physics_frame
	wall_driver._key(KEY_D,false)
	if world.player.position.x>16157: fail("Highest gallery wall can be jumped around"); return
	world.player.position=Vector2(16120,L.FLOOR-23)
	world.player.reset_movement_state()
	for i in 20: await physics_frame
	var route:=preload("res://tests/forest_final_concourse_route.gd").new()
	world.add_child(route)
	if not await route.run_route(): fail(str(route.get_meta("failure","Final route failed"))); return
	world._save_progress()
	data=SLOTS.load_slot(1,SAVE_ROOT)
	if not data.temple_guardian_defeated or not data.bow_boss_defeated or data.last_hand_room!=9 or data.checkpoint_x!=2610: fail("Encounter/checkpoint persistence lost"); return
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame; await physics_frame
	world=current_scene
	if not world.temple_guardian_defeated or world.last_hand_room!=9 or not world._completed_rooms().has(10): fail("Cave round trip lost temple defeat/completion"); return
	world._respawn()
	for i in 120: await process_frame
	world=current_scene
	if world.current_room!=9 or absf(world.player.position.x-N.HAND.x)>1 or absf(world.player.position.y+23-600)>1: fail("Cave death lost relocated hand"); return
	await world._change_room(10,23735)
	for i in 10: await physics_frame
	if world.temple_guardian.active or world.temple_guardian.visible: fail("Defeated guardian respawned"); return
	await world._on_death()
	if world.current_room!=9 or world.last_hand_room!=9: fail("Miniboss death checkpoint lost"); return
	await world.fast_travel_to_hand({"room":8})
	for i in 20: await physics_frame
	if world.current_room!=8 or absf(world.player.position.x-world.HAND_X)>1 or world.last_hand_room!=9: fail("Boss hand fast travel changed checkpoint"); return
	world._save_progress()
	change_scene_to_file("res://scenes/forest_entry.tscn")
	await process_frame; await physics_frame
	world=current_scene
	if not world.temple_guardian_defeated or not world.bow_boss_defeated or world.last_hand_room!=9: fail("Reload lost progression"); return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame; await process_frame
	SLOTS.delete_slot(1,SAVE_ROOT)
	print("FOREST_FINAL_CONCOURSE_SMOKE PASS: stair both ways, crown wall, hands, both encounters, bow, cave travel, death, reload and fast travel")
	quit()

func fail(message: String) -> void:
	push_error(message)
	quit(1)
