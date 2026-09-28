extends "res://tests/gallery_section_smoke.gd"

const STAIR=preload("res://scripts/forest_stair_layout.gd")
const GALLERY=preload("res://scripts/forest_gallery_layout.gd")
const STAIR_SAVE_ROOT="res://tests/.forest_stair_saves"

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STAIR_SAVE_ROOT))
	var data: Dictionary=SLOTS.new_slot()
	data.merge({"hand_activated":true,"last_hand_room":3,"checkpoint_x":2610.0,"checkpoint_y":570.0,"bow_boss_defeated":true},true)
	SLOTS.write_slot(1,data,STAIR_SAVE_ROOT)
	set_meta("active_save_slot",1)
	set_meta("save_root",STAIR_SAVE_ROOT)
	set_meta("forest_entry_room",6)
	change_scene_to_file("res://scenes/forest_entry.tscn")
	await process_frame
	await physics_frame
	world=current_scene
	world.player.invulnerability=1000
	var section:=world.forest_stair.get_node("RegisteredPainting") as Sprite2D
	if not (Vector2(section.texture.get_size())*section.scale).is_equal_approx(STAIR.ART_EXTENT.size):
		_fail("Section 2 painting is stretched independently of its stair collision")
		return
	var stair_bodies:=0
	for child in world.forest_stair.get_children():
		if child is StaticBody2D: stair_bodies+=1
	if stair_bodies!=1:
		_fail("Section 2 introduced separate platforms instead of one stair mass")
		return
	var player_shape: CollisionShape2D
	for child in world.player.get_children():
		if child is CollisionShape2D: player_shape=child
	for native in [Vector2(700,790),Vector2(1100,790),Vector2(1500,700)]:
		var query:=PhysicsShapeQueryParameters2D.new()
		query.shape=player_shape.shape
		query.transform=Transform2D(0,STAIR.point(native))
		query.collision_mask=world.player.collision_mask
		query.exclude=[world.player.get_rid()]
		if world.get_world_2d().direct_space_state.intersect_shape(query).is_empty():
			_fail("A below-stair background arch became an accessible lower route: %s"%native)
			return
	for x in [3900,4400,4900,5015,5200,5350,5500,5650,5800,5950,6100,6250,6400,6550,6740,6780]:
		if not await _walk(Vector2(x,STAIR.surface_y(x)-23 if x>=5000 else 577),"Forest Room 2 stair ascent"): return
		if world.current_room!=6:
			_fail("An artwork seam changed rooms inside Forest Room 2")
			return
		if not _view_covered(): return
		if x in [5015,6550] and not await _jump_camera_covered(): return
	if world.last_hand_room!=3: _fail("Traversal before hand interaction replaced checkpoint"); return
	var route:=preload("res://tests/forest_upper_gallery_route.gd").new()
	world.add_child(route)
	if not await route.run_route(): _fail(str(route.get_meta("failure","Section 3 route failed"))); return
	for x in [6600,6450,6300,6150,6000,5850,5700,5550,5400,5250,5100,4970,4700,4100,3690]:
		if not await _walk(Vector2(x,STAIR.surface_y(x)-23 if x>=5000 else 577),"Forest Room 2 stair descent"): return
		if not _view_covered(): return
	world._save_progress()
	var saved:=SLOTS.load_slot(1,STAIR_SAVE_ROOT)
	if saved.get("last_hand_room")!=9 or not saved.get("temple_hand_activated",false) or saved.get("checkpoint_x")!=2610.0:
		_fail("Stair return lost the explicitly activated temple checkpoint")
		return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	SLOTS.delete_slot(1,STAIR_SAVE_ROOT)
	print("FOREST_STAIR_SMOKE_PASS")
	quit()

func _view_covered() -> bool:
	var camera:=world.player.get_node("Camera2D") as Camera2D
	var size: Vector2=world.get_viewport_rect().size/camera.zoom
	var view:=Rect2(camera.get_screen_center_position()-size*0.5,size)
	var first:=view.intersection(Rect2(3600,-10000,1400,20000))
	var second:=view.intersection(Rect2(5000,-10000,1800,20000))
	if first.has_area() and not GALLERY.ART_EXTENT.grow(2).encloses(first):
		_fail("Section 1 art stops before the continuous camera view")
		return false
	if second.has_area() and not STAIR.ART_EXTENT.grow(2).encloses(second):
		_fail("Section 2 art stops before the continuous camera view")
		return false
	return true

func _jump_camera_covered() -> bool:
	var start_y: float=world.player.position.y
	var min_y:=start_y
	_key(KEY_SPACE,true)
	for frame in 70:
		if frame==3: _key(KEY_SPACE,false)
		await physics_frame
		min_y=minf(min_y,world.player.position.y)
		if not _view_covered():
			_key(KEY_SPACE,false)
			return false
	_key(KEY_SPACE,false)
	if start_y-min_y<90 or not world.player.is_on_floor():
		_fail("A full jump at the Section 2 seam or high stair is obstructed")
		return false
	return true
