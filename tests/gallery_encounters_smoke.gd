extends "res://tests/gallery_section_smoke.gd"

const COMBAT_ROOT := "res://tests/.gallery_encounters_saves"

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(COMBAT_ROOT))
	var slot:=SLOTS.new_slot(); slot["room"]=2; SLOTS.write_slot(1,slot,COMBAT_ROOT)
	set_meta("active_save_slot",1)
	set_meta("save_root",COMBAT_ROOT)
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await physics_frame
	world=current_scene
	world.current_room=2
	world._set_camera_room()
	await physics_frame
	world.set_process(false)
	world.player.invulnerability=1000
	world.ledge_sentinel.set_process(false)
	world.scout.set_physics_process(false)
	world.scout.collision_layer=0
	if world.gallery_encounters.targets().size()!=29:
		_fail("The authored combat zones did not create their existing-roster enemies")
		return
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(32,34)
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape
	query.collision_mask=1
	for enemy in world.gallery_encounters.targets():
		query.transform=Transform2D(0,enemy.global_position)
		query.exclude=[world.player.get_rid()]
		if enemy is CharacterBody2D:
			query.exclude.append(enemy.get_rid())
		for hit in world.get_world_2d().direct_space_state.intersect_shape(query,16):
			if hit.collider is StaticBody2D:
				_fail("Enemy spawned inside cave geometry: %s"%enemy.name)
				return
	# Let the real scouts patrol. Each must remain supported on its authored floor.
	for i in 360:
		await physics_frame
	for enemy in world.gallery_encounters.targets():
		if enemy is CharacterBody2D:
			if not enemy.is_on_floor() or enemy.position.x<enemy.patrol_bounds.x or enemy.position.x>enemy.patrol_bounds.y or enemy.position.y>1727:
				_fail("Enemy left its encounter floor or patrol: %s at %s"%[enemy.name,enemy.position])
				return
	world.gallery_encounters.set_active(false)
	# Each arena provides enough real footing for approaches and ordinary attacks
	# from both directions. Stationary fixtures isolate combat-space clearance;
	# patrol containment was checked with the actors running above.
	for enemy in world.gallery_encounters.targets():
		var floor_query:=PhysicsRayQueryParameters2D.create(enemy.position+Vector2(0,12),enemy.position+Vector2(0,40),1)
		floor_query.exclude=[world.player.get_rid()]
		if enemy is CharacterBody2D:
			floor_query.exclude.append(enemy.get_rid())
		var floor_hit: Dictionary=world.get_world_2d().direct_space_state.intersect_ray(floor_query)
		if floor_hit.is_empty():
			_fail("Encounter has no supporting terrain: %s"%enemy.name)
			return
		var floor_y: float=floor_hit.position.y
		for side in [-1,1]:
			for other in world.gallery_encounters.targets():
				if other != enemy:
					other.health = 100.0
			if enemy.get("is_asleep") != null:
				enemy.is_asleep = false
			enemy.health=2
			world.player.position=Vector2(enemy.position.x+side*100,floor_y-25)
			world.player.reset_movement_state()
			for i in 8:
				await physics_frame
			if not await _walk(Vector2(enemy.position.x+side*48,floor_y-23),str(enemy.name)):
				return
			world.player.facing=-side
			_key(KEY_J,true)
			for i in 3:
				await physics_frame
			_key(KEY_J,false)
			for i in 22:
				await physics_frame
			if enemy.health!=1:
				_fail("Encounter cannot be struck from side %s: %s"%[side,enemy.name])
				return
	# Clear an actual encounter with input; its ID and Will must survive a reload,
	# while a hand rest must restore regular encounters without losing rewards.
	_key(KEY_J,true)
	for i in 3:
		await physics_frame
	_key(KEY_J,false)
	for i in 70:
		await physics_frame
	if world.gallery_defeated!=["AscentGuard"] or world.will_amount!=5:
		_fail("Regular encounter defeat did not save its ID and exactly one Will reward")
		return
	world._save_progress()
	reload_current_scene()
	await process_frame
	await physics_frame
	world=current_scene
	world.current_room=2
	world._set_camera_room()
	await physics_frame
	if not world.gallery_defeated.has("AscentGuard") or world.gallery_encounters.targets().size()!=28 or world.will_amount!=5:
		_fail("Regular encounter state did not survive reload")
		return
	world.activate_hand()
	if not world.gallery_defeated.is_empty() or world.gallery_encounters.targets().size()!=29 or world.will_amount!=5:
		_fail("Hand rest did not restore regular encounters independently of collected Will")
		return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	SLOTS.delete_slot(1,COMBAT_ROOT)
	print("GALLERY_ENCOUNTERS_SMOKE_PASS")
	quit()
