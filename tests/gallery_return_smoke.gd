extends "res://tests/gallery_progression_smoke.gd"

func _run() -> void:
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await physics_frame
	world=current_scene
	world.player.invulnerability=10000
	_prepare_encounters()
	world.player.position=world.GALLERY_LAYOUT.EXIT
	world.player.reset_movement_state()
	var start:=Engine.get_physics_frames()
	if not await _upper_route(true): return
	var ordinary:=Engine.get_physics_frames()-start
	world.player.has_heavy=true
	world._on_player_heavy_attacked(world.GALLERY_LAYOUT.HEAVY_WALL)
	world.player.position=world.GALLERY_LAYOUT.EXIT
	world.player.reset_movement_state()
	start=Engine.get_physics_frames()
	for p in [Vector2(4300,-1523),Vector2(4200,-1448),Vector2(4200,-1358),Vector2(4380,-1223),Vector2(4780,-1223)]:
		if not await _walk(p,"heavy return approach"): return
	# Clear the ledges along the outer descent lane; the shaft has a physical floor.
	if not await _walk(Vector2(4945,1627),"service shaft descent"): return
	if not await _walk(Vector2(760,1627),"basal return"): return
	if not await _jump(world.player.position,Vector2(770,1552)): return
	if not await _jump(world.player.position,Vector2(650,1477)): return
	if not await _walk(Vector2(120,1477),"entrance rejoin"): return
	var express:=Engine.get_physics_frames()-start
	print("GALLERY_RETURN_SECONDS ordinary=",ordinary/60.0," heavy=",express/60.0," ratio=",float(express)/ordinary)
	if express>ordinary*0.5:
		_fail("Heavy return did not halve the traversed main-route return time")
		return
	print("GALLERY_RETURN_SMOKE_PASS")
	quit()
