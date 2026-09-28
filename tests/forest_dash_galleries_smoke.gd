extends SceneTree

const SLOTS=preload("res://scripts/save_slots.gd")
const L=preload("res://scripts/forest_dash_galleries_layout.gd")
const ROUTE=preload("res://tests/forest_dash_galleries_route.gd")
const SAVE_ROOT="res://tests/.forest_dash_gallery_saves"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_ROOT))
	var data: Dictionary=SLOTS.new_slot()
	data.merge({"hand_activated":true,"last_hand_room":3,"checkpoint_x":2610.0,"checkpoint_y":570.0,"bow_boss_defeated":true},true)
	SLOTS.write_slot(1,data,SAVE_ROOT)
	set_meta("active_save_slot",1); set_meta("save_root",SAVE_ROOT); set_meta("forest_entry_room",6)
	change_scene_to_file("res://scenes/forest_entry.tscn")
	await process_frame; await physics_frame
	var world: Node2D=current_scene
	world.player.invulnerability=1000
	await world._change_room(6,13670)
	var bodies:=0
	var terrain:=0
	for child in world.forest_dash_galleries.get_children():
		if child is StaticBody2D:
			if child.get_child(0).polygon!=L.solid_polygons()[bodies]: _fail("9/10 collision differs from registered art"); return
			bodies+=1
		if child is Polygon2D and child.name.begins_with("RegisteredTerrain"):
			if child.polygon!=L.solid_polygons()[terrain]: _fail("9/10 rendered solid differs from collision"); return
			terrain+=1
	if bodies!=6 or terrain!=6: _fail("Unexpected scenery collision or absent terrain"); return
	for x in range(13810,16200,32):
		for y in [L.FLOOR+10,L.LOWER_FLOOR+10,-600.0]:
			var query:=PhysicsPointQueryParameters2D.new()
			query.position=Vector2(x,y)
			if world.get_world_2d().direct_space_state.intersect_point(query).is_empty(): _fail("9/10 shell gap"); return
	var route:=ROUTE.new()
	world.add_child(route)
	if not await route.run_route(): _fail(str(route.get_meta("failure","New routes failed"))); return
	world._save_progress()
	var saved: Dictionary=SLOTS.load_slot(1,SAVE_ROOT)
	if not saved.temple_hand_activated or saved.last_hand_room!=9 or saved.checkpoint_x!=2610.0: _fail("New hand persistence damaged checkpoint state"); return
	# The activated side hand must remain the last checkpoint through cave travel,
	# reload and actual cave death return. Never overwrite it on room entry.
	set_meta("cave_entry_x",2610.0)
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame; await physics_frame
	world=current_scene
	if world.last_hand_room!=9 or not world.temple_hand_activated or world.get_fast_travel_hands().size()!=2: _fail("Cave travel lost the temple hand"); return
	world._respawn()
	for i in 120:
		await process_frame
		if current_scene!=world: break
	await physics_frame
	world=current_scene
	if world.current_room!=9 or world.last_hand_room!=9 or world.player.position.distance_to(L.HAND)>5: _fail("Cave death did not return to activated temple hand"); return
	await world._leave_temple_hand()
	await world.fast_travel_to_hand({"room":9})
	for i in 20: await physics_frame
	if world.current_room!=9 or absf(world.player.position.x-L.HAND.x)>1 or absf(world.player.position.y+23-600)>1: _fail("Temple fast travel did not receive safely at chair"); return
	await world._on_death()
	for i in 20: await physics_frame
	if world.current_room!=9 or world.last_hand_room!=9 or absf(world.player.position.x-L.HAND.x)>1: _fail("Forest death lost activated temple checkpoint"); return
	world._save_progress()
	change_scene_to_file("res://scenes/forest_entry.tscn")
	await process_frame; await physics_frame
	world=current_scene
	if world.current_room!=9 or world.last_hand_room!=9 or not world.temple_hand_activated: _fail("Reload lost side hand room or checkpoint"); return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame; await process_frame
	SLOTS.delete_slot(1,SAVE_ROOT)
	print("FOREST_DASH_GALLERIES_SMOKE PASS: normal jump denied both ways, dash succeeds both ways, lower corridor, return climb, door, hand, cave persistence/death")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
