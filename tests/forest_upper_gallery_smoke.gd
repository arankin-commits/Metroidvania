extends "res://tests/gallery_section_smoke.gd"

const ROUTE=preload("res://tests/forest_upper_gallery_route.gd")
const U=preload("res://scripts/forest_upper_gallery_layout.gd")
const C=preload("res://scripts/forest_smash_corridor_layout.gd")
const P=preload("res://scripts/forest_stepped_gallery_layout.gd")
const E=preload("res://scripts/forest_elevated_gallery_layout.gd")
const R=preload("res://scripts/forest_return_gallery_layout.gd")
const H=preload("res://scripts/forest_split_hall_layout.gd")
const SAVE_ROOT="res://tests/.forest_upper_gallery_saves"

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_ROOT))
	var data: Dictionary=SLOTS.new_slot()
	data.merge({"hand_activated":true,"last_hand_room":3,"checkpoint_x":2610.0,"checkpoint_y":570.0,"bow_boss_defeated":true},true)
	SLOTS.write_slot(1,data,SAVE_ROOT)
	set_meta("active_save_slot",1)
	set_meta("save_root",SAVE_ROOT)
	set_meta("forest_entry_room",6)
	change_scene_to_file("res://scenes/forest_entry.tscn")
	await process_frame
	await physics_frame
	world=current_scene
	world.player.invulnerability=1000
	for x in [3900,4500,4980,5350,5800,6250,6740]:
		if not await _walk(Vector2(x,world.STAIR_LAYOUT.surface_y(x)-23 if x>=5000 else 577),"continuous Room 2 ascent"): return
	var route:=ROUTE.new()
	world.add_child(route)
	if not await route.run_route(): _fail(str(route.get_meta("failure","Section 3 route failed"))); return
	var hall_bodies:=0
	var hall_terrain:=0
	for child in world.forest_split_hall.get_children():
		if child is StaticBody2D and child.name!="PurpleDropFloor":
			if child.get_child(0).polygon!=H.solid_polygons()[hall_bodies]: _fail("Section 8 collision registration mismatch"); return
			hall_bodies+=1
		if child is Polygon2D and child.name.begins_with("RegisteredTerrain"):
			if child.polygon!=H.solid_polygons()[hall_terrain]: _fail("Section 8 terrain registration mismatch"); return
			hall_terrain+=1
	if hall_bodies!=13 or hall_terrain!=13: _fail("Section 8 has unexpected scenery collision or missing shell"); return
	var panel:=world.forest_split_hall.get_node("PurpleDropFloor").get_child(0) as CollisionShape2D
	if not panel.one_way_collision or panel.shape.size!=H.DROP.size: _fail("Purple floor is not the registered one-way panel"); return
	for x in range(12610,13800,32):
		var query:=PhysicsPointQueryParameters2D.new()
		query.position=Vector2(x,H.LOWER_Y+10)
		if world.get_world_2d().direct_space_state.intersect_point(query).is_empty(): _fail("Lower hall floor has a shell gap"); return
	for y in range(220,855,32):
		for x in [12655,16185]:
			var query:=PhysicsPointQueryParameters2D.new()
			query.position=Vector2(x,y)
			if world.get_world_2d().direct_space_state.intersect_point(query).is_empty(): _fail("Lower hall wall has a shell gap"); return
	var bodies:=0
	for child in world.forest_upper_gallery.get_children():
		if child is StaticBody2D: bodies+=1
	if bodies!=6: _fail("Section 3 must contain only four ledges, floor and wall"); return
	var body_shape: CollisionShape2D
	for child in world.player.get_children():
		if child is CollisionShape2D: body_shape=child
	var corridor_bodies:=0
	var corridor_terrain:=0
	for child in world.forest_smash_corridor.get_children():
		if child is StaticBody2D:
			corridor_bodies+=1
			if child.get_child(0).polygon!=C.solid_polygons()[corridor_bodies-1]:
				_fail("Section 4 collision differs from registered ground"); return
		if child is Polygon2D:
			if child.polygon!=C.solid_polygons()[corridor_terrain]:
				_fail("Section 4 terrain differs from collision"); return
			corridor_terrain+=1
	if corridor_bodies!=3 or corridor_terrain!=3:
		_fail("Section 4 introduced background colliders or lost sealed ground"); return
	for native in [Vector2(350,600),Vector2(900,600),Vector2(100,600)]:
		var clear:=PhysicsShapeQueryParameters2D.new()
		clear.shape=body_shape.shape
		clear.transform=Transform2D(0,C.point(native))
		clear.exclude=[world.player.get_rid()]
		if not world.get_world_2d().direct_space_state.intersect_shape(clear).is_empty():
			_fail("Section 4 background pier/plant became a wall"); return
	for native_x in range(15,1276,24):
		var solid:=PhysicsPointQueryParameters2D.new()
		var x: float=C.point(Vector2(native_x,0)).x
		solid.position=Vector2(x,C.surface_y(x)+10)
		if world.get_world_2d().direct_space_state.intersect_point(solid).is_empty():
			_fail("Section 4 ground shell has a gap"); return
	var stepped_count:=0
	var terrain_count:=0
	for child in world.forest_stepped_gallery.get_children():
		if child is StaticBody2D:
			if child.get_child(0).polygon!=P.solid_polygons()[stepped_count]:
				_fail("Section 5 collider differs from registered terrain"); return
			stepped_count+=1
		if child is Polygon2D and child.name.begins_with("RegisteredTerrain"):
			if child.polygon!=P.solid_polygons()[terrain_count]:
				_fail("Section 5 terrain differs from collider"); return
			terrain_count+=1
	if stepped_count!=4 or terrain_count!=4:
		_fail("Section 5 must contain only three marked objects and ground collision"); return
	for at in [P.point(Vector2(310,550)),P.point(Vector2(820,600)),
		Vector2(P.cap(1).get_center().x,P.cap(1).end.y+35),Vector2(P.cap(2).get_center().x,P.cap(2).end.y+35)]:
		var clear:=PhysicsShapeQueryParameters2D.new()
		clear.shape=body_shape.shape
		clear.transform=Transform2D(0,at)
		clear.exclude=[world.player.get_rid()]
		if not world.get_world_2d().direct_space_state.intersect_shape(clear).is_empty():
			_fail("Section 5 background pier or hanging plants became solid"); return
	for x in range(9010,10200,32):
		var solid:=PhysicsPointQueryParameters2D.new()
		solid.position=Vector2(x,P.EXIT_Y+15)
		if world.get_world_2d().direct_space_state.intersect_point(solid).is_empty():
			_fail("Section 5 floor shell has a gap"); return
	var elevated_bodies:=0
	var elevated_terrain:=0
	for child in world.forest_elevated_gallery.get_children():
		if child is StaticBody2D:
			if child.get_child(0).polygon!=E.solid_polygons()[elevated_bodies]:
				_fail("Section 6 collision differs from painted stone"); return
			elevated_bodies+=1
		if child is Polygon2D and child.name.begins_with("RegisteredTerrain"):
			if child.polygon!=E.solid_polygons()[elevated_terrain]:
				_fail("Section 6 terrain differs from collider"); return
			elevated_terrain+=1
	if elevated_bodies!=4 or elevated_terrain!=4:
		_fail("Section 6 must contain three floating solids and ground only"); return
	for c in [E.cap(0),E.cap(1),E.cap(2)]:
		var clear:=PhysicsShapeQueryParameters2D.new()
		clear.shape=body_shape.shape
		clear.transform=Transform2D(0,Vector2(c.get_center().x,c.end.y+35))
		clear.exclude=[world.player.get_rid()]
		if not world.get_world_2d().direct_space_state.intersect_shape(clear).is_empty():
			_fail("Section 6 hanging vines became solid"); return
		if E.EXIT_Y-c.position.y<200:
			_fail("Section 6 cap violates intended floor access exclusion"); return
	for x in range(10210,11400,32):
		var solid:=PhysicsPointQueryParameters2D.new()
		solid.position=Vector2(x,E.EXIT_Y+15)
		if world.get_world_2d().direct_space_state.intersect_point(solid).is_empty():
			_fail("Section 6 floor shell has a gap"); return
	var return_bodies:=0
	var return_terrain:=0
	for child in world.forest_return_gallery.get_children():
		if child is StaticBody2D:
			if child.get_child(0).polygon!=R.solid_polygons()[return_bodies]:
				_fail("Section 7 collider differs from registered stone"); return
			return_bodies+=1
		if child is Polygon2D and child.name.begins_with("RegisteredTerrain"):
			if child.polygon!=R.solid_polygons()[return_terrain]:
				_fail("Section 7 terrain differs from collision"); return
			return_terrain+=1
	if return_bodies!=4 or return_terrain!=4:
		_fail("Section 7 must contain only three objects and ground"); return
	var clear_points: Array[Vector2]=[]
	for i in 2: clear_points.append(Vector2(R.cap(i).get_center().x,R.cap(i).end.y+35))
	var pedestal:=R.cap(2)
	clear_points.append(Vector2(pedestal.position.x-18,pedestal.position.y+35))
	clear_points.append(Vector2(pedestal.end.x+18,pedestal.position.y+35))
	for at in clear_points:
		var clear:=PhysicsShapeQueryParameters2D.new()
		clear.shape=body_shape.shape
		clear.transform=Transform2D(0,at)
		clear.exclude=[world.player.get_rid()]
		if not world.get_world_2d().direct_space_state.intersect_shape(clear).is_empty():
			_fail("Section 7 foliage or pedestal side blocks visible opening"); return
	for x in range(11410,12600,32):
		var solid:=PhysicsPointQueryParameters2D.new()
		solid.position=Vector2(x,R.EXIT_Y+15)
		if world.get_world_2d().direct_space_state.intersect_point(solid).is_empty():
			_fail("Section 7 floor shell has a gap"); return
	for x in range(int(pedestal.position.x)+12,int(pedestal.end.x)-12,32):
		var solid:=PhysicsPointQueryParameters2D.new()
		solid.position=Vector2(x,R.EXIT_Y-25)
		if world.get_world_2d().direct_space_state.intersect_point(solid).is_empty():
			_fail("Section 7 blue pedestal is not solid to ground"); return
	for at in [Vector2(295,634),Vector2(600,733),Vector2(940,813),Vector2(960,545)]:
		var query:=PhysicsShapeQueryParameters2D.new()
		query.shape=body_shape.shape
		query.transform=Transform2D(0,U.point(at))
		query.collision_mask=world.player.collision_mask
		query.exclude=[world.player.get_rid()]
		if not world.get_world_2d().direct_space_state.intersect_shape(query).is_empty():
			_fail("Section 3 recessed foliage/architecture became solid: %s"%at); return
	for x in [6400,6000,5500,4970,4500,3690]:
		if not await _walk(Vector2(x,world.STAIR_LAYOUT.surface_y(x)-23 if x>=5000 else 577),"continuous Room 2 return"): return
	world._save_progress()
	var saved:=SLOTS.load_slot(1,SAVE_ROOT)
	if saved.get("last_hand_room")!=9 or saved.get("checkpoint_x")!=2610.0:
		_fail("Section 3 traversal replaced last activated hand"); return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	SLOTS.delete_slot(1,SAVE_ROOT)
	print("FOREST_UPPER_GALLERY_SMOKE_PASS")
	quit()
