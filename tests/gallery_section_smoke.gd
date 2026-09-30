extends SceneTree

const SLOTS = preload("res://scripts/save_slots.gd")
const ROOT := "res://tests/.gallery_section_saves"
var world: Node2D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT))
	SLOTS.write_slot(1, SLOTS.new_slot(), ROOT)
	set_meta("active_save_slot", 1)
	set_meta("save_root", ROOT)
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await process_frame
	world = current_scene
	world.player._advance_wake(4.0)
	await world._begin_room_transition(2,world.GALLERY_LAYOUT.ENTRANCE.x)
	world.player.invulnerability = 1000.0
	# Geometry fixture traverses the post-boss shortcut; first-visit gating has its own test.
	world.player.has_heavy=true
	world._on_player_heavy_attacked(world.gallery.LAYOUT.HEAVY_WALL)
	await physics_frame
	world.ledge_sentinel.set_process(false)
	world.gallery_encounters.set_active(false)
	world.scout.set_physics_process(false)
	# Route geometry is checked after the encounter is cleared; combat behavior is
	# separately retained in cave_rooms_smoke and pause_hud_smoke.
	world.scout.collision_layer = 0
	var supporting_length: float = world.gallery.LAYOUT.supporting_length()
	if supporting_length < 2385 * 10:
		_fail("Gallery redesign lost its substantial connected supporting space")
		return
	print("GALLERY_SUPPORTING_LENGTH ", supporting_length, " RATIO ", supporting_length / 2385.0)
	# Real controller, measured takeoff/landing: shelf, gap, sentinel ledge.
	for hop in [[Vector2(320,1477), Vector2(450,1402)], [Vector2(655,1477), Vector2(880,1477)], [Vector2(990,1477), Vector2(1100,1387)]]:
		if not await _jump(hop[0], hop[1]):
			return
	for route_name in world.gallery.LAYOUT.routes():
		if route_name in ["seal_floor","heavy_mouth"]:
			# The closed seal and doorway are exercised separately as a progression
			# gate; this traversal pass must remain inside Room 2.
			continue
		if route_name == "west_shortcut":
			# Operate from its authored far side after the lower route, then walk it.
			world.player.position = world.gallery.LAYOUT.WEST_WINCH
			_interact()
			await process_frame
			await physics_frame
			if not world.gallery_west_open:
				_fail("The far-side west winch did not open its return passage")
				return
		if route_name == "east_shortcut":
			world.player.position = world.gallery.LAYOUT.EAST_WINCH
			_interact()
			await process_frame
			await physics_frame
			if not world.gallery_east_open:
				_fail("The far-side eastern winch did not open its return connection")
				return
		var points: PackedVector2Array = world.gallery.LAYOUT.routes()[route_name]
		for reverse in [false, true]:
			var route := points.duplicate()
			if reverse:
				route.reverse()
			var start_x := route[0].x + signf(route[1].x - route[0].x) * 22.0
			world.player.global_position = Vector2(start_x, world.gallery.LAYOUT.surface_y(route[0], route[1], start_x) - 25)
			world.player.reset_movement_state()
			for i in 5:
				await physics_frame
			for i in range(1, route.size()):
				if not await _walk(route[i] + Vector2(0, -23), route_name):
					return
				if route_name == "offering_ascent" and not reverse and route[i].x == 600:
					_interact()
					if not world.gallery_cache_found or world.will_amount != 12:
						_fail("The physically reached upper offering did not grant 12 Will")
						return
					_interact()
					if world.will_amount != 12:
						_fail("The offering granted its reward twice")
						return
			if route_name == "sigil_gallery" and not reverse:
				_interact()
				if not world.secret_found or not world.note_open:
					_fail("The physically reached western Sigil cannot be read")
					return
				world._close_note()
	if not await _check_optional_links():
		return
	if not world._completed_rooms().has(2):
		_fail("Sigil and offering did not complete Room 2")
		return
	if world.current_room != 2 or world.checkpoint != world.CAVE_LAYOUT.START:
		_fail("Exploring gallery levels changed rooms or the death checkpoint")
		return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame
	SLOTS.delete_slot(1, ROOT)
	print("GALLERY_SECTION_SMOKE_PASS")
	quit()

func _interact() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	world._unhandled_input(event)

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

func _jump(from: Vector2, to: Vector2) -> bool:
	world.player.position = from - Vector2(0, 2)
	world.player.reset_movement_state()
	for i in 8:
		await physics_frame
	_key(KEY_SPACE, true)
	for i in 110:
		var dx: float = to.x - world.player.position.x
		_key(KEY_D, dx > 5)
		_key(KEY_A, dx < -5)
		if i == 25:
			_key(KEY_SPACE, false)
		await physics_frame
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
	push_error(message)
	quit(1)

func _check_optional_links() -> bool:
	for hop in [[Vector2(-550,-548),Vector2(-490,-623)],[Vector2(-490,-623),Vector2(-400,-698)],[Vector2(-400,-698),Vector2(-420,-773)],
		[Vector2(1600,97),Vector2(1660,22)],[Vector2(1660,22),Vector2(1760,-23)],
		[Vector2(4460,-998),Vector2(4440,-1073)],[Vector2(4440,-1073),Vector2(4570,-1223)],
		[Vector2(4200,-1358),Vector2(4200,-1448)],[Vector2(4200,-1448),Vector2(4300,-1523)],
		[Vector2(760,1627),Vector2(770,1552)],[Vector2(770,1552),Vector2(880,1477)]]:
		if not await _jump(hop[0],hop[1]): return false
	for climb in [
		[Vector2(2520,892),Vector2(2520,802),Vector2(2520,727),Vector2(2400,652)],
		[Vector2(3540,-98),Vector2(3540,-173),Vector2(3420,-248),Vector2(3540,-323),Vector2(3420,-398),Vector2(3540,-473),Vector2(3540,-548)],
		[Vector2(4400,652),Vector2(4510,577),Vector2(4510,502),Vector2(4510,427)],
		[Vector2(3940,97),Vector2(3840,-23)],
	]:
		for i in climb.size()-1:
			if not await _jump(climb[i],climb[i+1]): return false
	world.player.position=Vector2(4867,1627)
	world.player.reset_movement_state()
	for i in range(36,0,-1):
		var target:=Vector2(4765 if i%2==0 else 4867,-1125+i*75-23)
		if not await _jump(world.player.position,target): return false
	if not await _jump(world.player.position,Vector2(4780,-1223)): return false
	return true
