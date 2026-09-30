extends Node
var world: Node2D
func begin_return() -> void:
	world=get_tree().current_scene
	world.player.invulnerability=10000
	world.gallery_encounters.set_active(false)
	world.ledge_sentinel.set_process(false)
	world.scout.set_physics_process(false)
	world.scout.collision_layer=0
	world.player.has_heavy=true
	world._on_player_heavy_attacked(world.GALLERY_LAYOUT.HEAVY_WALL)
	world.player.position=world.GALLERY_LAYOUT.EXIT
	world.player.reset_movement_state()
	for p in [Vector2(4300,-1523),Vector2(4200,-1448),Vector2(4200,-1358),Vector2(4380,-1223),Vector2(4780,-1223),Vector2(4945,1627),Vector2(760,1627)]:
		if not await _walk(p,"heavy return"): return
	if not await _jump(world.player.position,Vector2(770,1552)): return
	if not await _jump(world.player.position,Vector2(650,1477)): return
	if not await _walk(Vector2(120,1477),"entrance rejoin"): return
	set_meta("complete",true)

func begin() -> void:
	world=get_tree().current_scene
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
		set_meta("route",route_name)
	if not await _walk(Vector2(4090,-1523),"upper gap takeoff"):
		return
	if not await _jump(world.player.position,Vector2(4300,-1523)):
		return
	if not await _walk(Vector2(4935,-1523),"upper vestibule"):
		return
	print("REVISION_CONTINUOUS_ASCENT_PASS")
	set_meta("complete",true)

func _walk(target: Vector2, route_name: String) -> bool:
	for frame in 3:
		await get_tree().physics_frame
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
			await get_tree().physics_frame
		_key(KEY_A, false)
		_key(KEY_D, false)
		for frame in 3:
			await get_tree().physics_frame
		feet = world.player.position + Vector2(0, 23)
	if target.y > world.player.position.y + 40 and world.player.drop_region.has_point(feet) and absf(feet.y - world.player.drop_region.position.y) < 9:
		_key(KEY_S, true)
		_key(KEY_SPACE, true)
		for frame in 3:
			await get_tree().physics_frame
		_key(KEY_SPACE, false)
		_key(KEY_S, false)
	for i in budget:
		var dx: float = target.x - world.player.position.x
		var move_right: bool = dx > 3
		var move_left: bool = dx < -3
		_key(KEY_D, move_right)
		_key(KEY_A, move_left)
		await get_tree().physics_frame
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

func _jump(from: Vector2, to: Vector2) -> bool:
	world.player.position = from - Vector2(0, 2)
	world.player.reset_movement_state()
	for i in 8:
		await get_tree().physics_frame
	_key(KEY_SPACE, true)
	for i in 110:
		var dx: float = to.x - world.player.position.x
		_key(KEY_D, dx > 5)
		_key(KEY_A, dx < -5)
		if i == 3:
			_key(KEY_SPACE, false)
		await get_tree().physics_frame
		if i > 10 and world.player.is_on_floor() and absf(dx) < 28 and absf(world.player.position.y - to.y) < 8:
			_key(KEY_A, false)
			_key(KEY_D, false)
			return true
	_key(KEY_SPACE, false)
	_key(KEY_A, false)
	_key(KEY_D, false)
	_fail("Unreachable hop %s to %s, ended %s" % [from, to, world.player.position])
	return false

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _fail(message: String) -> void:
	set_meta("failure",message)
	push_error(message)
