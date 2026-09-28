extends "res://tests/gallery_section_smoke.gd"

func _run() -> void:
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await physics_frame
	world=current_scene
	world.player.invulnerability=10000
	world.gallery_encounters.set_active(false)
	world.ledge_sentinel.set_process(false)
	world.scout.set_physics_process(false)
	world.scout.collision_layer=0
	# Continuous ascent, starting at the real new-game spawn.
	if not await _walk(Vector2(320,1477),"entrance"):
		return
	if not await _jump(world.player.position,Vector2(450,1402)):
		return
	if not await _walk(Vector2(650,1477),"balcony gap approach"):
		return
	if not await _jump(world.player.position,Vector2(880,1477)):
		return
	if not await _walk(Vector2(990,1477),"sentinel approach"):
		return
	if not await _jump(world.player.position,Vector2(1100,1387)):
		return
	for route_name in ["balcony_ascent","chain_well","offering_ascent","crown_walk","crown_lip"]:
		for point in world.GALLERY_LAYOUT.routes()[route_name]:
			if not await _walk(point+Vector2(0,-23),route_name):
				return
		print("REVISION_ROUTE_PASS ",route_name)
	if not await _walk(Vector2(4090,-1523),"upper gap takeoff"):
		return
	if not await _jump(world.player.position,Vector2(4300,-1523)):
		return
	if not await _walk(Vector2(4935,-1523),"upper vestibule"):
		return
	print("REVISION_CONTINUOUS_ASCENT_PASS")
	quit()
