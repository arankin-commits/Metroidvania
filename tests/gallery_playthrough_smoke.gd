extends "res://tests/gallery_progression_smoke.gd"

func _run() -> void:
	progress_root="res://tests/.gallery_playthrough_saves"
	await super._run()

func _prepare_encounters() -> void:
	world.gallery_encounters.set_active(true)
	world._set_gallery_enemies_active(true)

func _finish_traversal() -> bool:
	_key(KEY_J,false)
	# The continuous ascent includes the central well and crown encounters.
	for id in ["WellApproach","WellJunction","FallenGuard","DeepPatrol","CrownThreshold","CrownPatrolWest","CrownPatrolEast"]:
		if not world.gallery_defeated.has(id):
			_fail("Continuous combat route missed its authored encounter: %s"%id)
			return false
	print("GALLERY_LIVE_COMBAT_ROUTE_PASS defeated=",world.gallery_defeated)
	super._prepare_encounters()
	return true

func _success_marker() -> String:
	return "GALLERY_PLAYTHROUGH_SMOKE_PASS"

func _walk(target: Vector2, route_name: String) -> bool:
	for frame in 3:
		await physics_frame
	var budget := int(absf(target.x - world.player.position.x) / 255.0 * 60) + 120
	# Choosing the lower branch at a suspended switchback uses the same drop input
	# as the player, rather than teleporting through an overlapping upper gallery.
	var feet: Vector2 = world.player.position + Vector2(0, 23)
	if target.y > world.player.position.y + 40 and absf(feet.y - world.player.drop_region.position.y) < 20:
		# Step away from the sloping junction onto the flat before dropping.
		_key(KEY_D, target.x > world.player.position.x)
		_key(KEY_A, target.x < world.player.position.x)
		for frame in 12:
			var r: Rect2=world.player.drop_region
			if r.size.x<180 and ((target.x<world.player.position.x and world.player.position.x<r.position.x+32) or (target.x>world.player.position.x and world.player.position.x>r.end.x-32)):
				break
			await physics_frame
		_key(KEY_A, false)
		_key(KEY_D, false)
		for frame in 3:
			await physics_frame
		feet = world.player.position + Vector2(0, 23)
	if target.y > world.player.position.y + 40 and world.player.drop_region.has_point(feet) and absf(feet.y - world.player.drop_region.position.y) < 9:
		_key(KEY_S, true)
		_key(KEY_SPACE, true)
		for frame in 3:
			await physics_frame
		_key(KEY_SPACE, false)
		_key(KEY_S, false)
	for i in budget:
		# A descent may land on an intermediate authored shelf. Drop again only
		# when supported by that shelf and the requested destination is below it.
		if target.y>world.player.position.y+35 and world.player.is_on_floor() and world.player.drop_region.has_point(world.player.position+Vector2(0,23)) and not world.player.drop_exception_active:
			_key(KEY_S,true)
			_key(KEY_SPACE,true)
			for f in 3: await physics_frame
			_key(KEY_SPACE,false)
			_key(KEY_S,false)
		# Fight on supported footing using real attack input; then resume movement.
		if world.current_room==2 and world.player.is_on_floor():
			var actors: Array=world.gallery_encounters.targets()
			if is_instance_valid(world.ledge_sentinel):
				actors.append(world.ledge_sentinel)
			if is_instance_valid(world.scout):
				actors.append(world.scout)
			for enemy in actors:
				if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or not enemy.visible or enemy.position.distance_to(world.player.position)>100 or absf(enemy.position.y-world.player.position.y)>55:
					continue
				_key(KEY_A,false)
				_key(KEY_D,false)
				for combat_hit in 4:
					if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
						break
					world.player.facing=1 if enemy.position.x>world.player.position.x else -1
					_key(KEY_J,true)
					for attack_frame in 3:
						await physics_frame
					_key(KEY_J,false)
					for attack_frame in 22:
						await physics_frame
		var dx: float = target.x - world.player.position.x
		var move_right: bool = dx > 3
		var move_left: bool = dx < -3
		_key(KEY_D, move_right)
		_key(KEY_A, move_left)
		await physics_frame
		# A 28px body straddles ramp corners; its supporting edge can be up to
		# 11px above the centerline at the measured maximum slope.
		if absf(dx) <= 18 and absf(world.player.position.y - target.y) < 20 and world.player.is_on_floor():
			_key(KEY_A, false)
			_key(KEY_D, false)
			return true
	_key(KEY_A, false)
	_key(KEY_D, false)
	_fail("Blocked %s to %s, ended %s" % [route_name, target, world.player.position])
	return false

