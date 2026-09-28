extends Node
const L=preload("res://scripts/forest_arrival_layout.gd")
var world: Node2D
func begin() -> void:
	world=get_tree().current_scene
	assert(world.active_save_slot==0)
	if not await _walk(_feet(590,578),"arrival terrace"): return
	if not await _walk(_feet(740,781),"basin descent"): return
	if not await _walk(_feet(960,781),"stair approach"): return
	for p in [Vector2(1040,745),Vector2(1100,722),Vector2(1170,697),Vector2(1245,671),Vector2(1340,608),Vector2(1465,596),Vector2(1580,416)]:
		if not await _jump(world.player.position,L.point(p)-Vector2(0,23)): return
	if not await _walk(Vector2(1320,_feet(1580,416).y),"section seam"): return
	for p in [Vector2(380,611),Vector2(670,585),Vector2(780,561),Vector2(960,489),Vector2(1100,453),Vector2(1200,426),Vector2(1400,357),Vector2(1560,345)]:
		if not await _jump(world.player.position,L.section2_point(p)-Vector2(0,23)): return
	if not await _walk(L.section3_point(Vector2(60,415))-Vector2(0,23),"Section 2 to 3 seam"): return
	if world.current_room!=5 or world.transitioning:
		_fail("Section 3 seam triggered a room change")
		return
	for p in [Vector2(260,434),Vector2(430,603),Vector2(740,752)]:
		if not await _walk(L.section3_point(p)-Vector2(0,23),"Section 3 descent"): return
	if not await _jump(world.player.position,L.section3_point(Vector2(900,569))-Vector2(0,23)): return
	if not await _walk(L.section3_point(Vector2(990,569))-Vector2(0,23),"central takeoff"): return
	for p in [Vector2(1140,425),Vector2(1200,425),Vector2(1440,234)]:
		if not await _jump(world.player.position,L.section3_point(p)-Vector2(0,23)): return
	if not await _walk(L.section3_point(Vector2(1560,234))-Vector2(0,23),"arch crown"): return
	if not await _walk(L.section3_point(Vector2(1655,565))-Vector2(0,23),"right receiving terrace"): return
	set_meta("outward",true)
	for p in [Vector2(1450,778),Vector2(1230,778)]:
		if not await _walk(L.section3_point(p)-Vector2(0,23),"lower arch return"): return
	for p in [Vector2(1190,676),Vector2(1080,569)]:
		if not await _jump(world.player.position,L.section3_point(p)-Vector2(0,23)): return
	if not await _walk(L.section3_point(Vector2(700,752))-Vector2(0,23),"lower clearing return"): return
	for p in [Vector2(450,603),Vector2(280,434)]:
		if not await _jump(world.player.position,L.section3_point(p)-Vector2(0,23)): return
	if not await _walk(L.section3_point(Vector2(40,415))-Vector2(0,23),"Section 3 seam return"): return
	if not await _walk(L.section2_point(Vector2(1580,345))-Vector2(0,23),"Section 2 rejoin"): return

	for p in [Vector2(1400,357),Vector2(1200,426),Vector2(1100,453),Vector2(960,489),Vector2(780,561),Vector2(670,585),Vector2(380,611),Vector2(120,678)]:
		if not await _walk(L.section2_point(p)-Vector2(0,23),"section2 return"): return
	if not await _walk(_feet(1580,416),"reverse seam"): return
	if not await _walk(_feet(1465,596),"upper terrace return descent"): return
	for p in [Vector2(1340,608),Vector2(1245,671),Vector2(1170,697),Vector2(1100,722),Vector2(1040,745),Vector2(740,781)]:
		if not await _walk(L.point(p)-Vector2(0,23),"stair return"): return
	if not await _jump(world.player.position,_feet(600,578)): return
	if not await _walk(Vector2(120,_feet(600,578).y),"arrival rejoin"): return
	set_meta("complete",true)
func _feet(x: float,y: float) -> Vector2:
	return L.point(Vector2(x,y))-Vector2(0,23)

func capture(label: String,at: Vector2) -> void:
	assert(world.active_save_slot==0)
	world.player.set_physics_process(false)
	world.player.position=at
	world.player.invulnerability=0
	world.player.queue_redraw()
	world._set_camera()
	world.player.get_node("Camera2D").force_update_scroll()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var error:=get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-section1-"+label+".png")
	set_meta("capture_error",error)
	set_meta("capture",label)
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
		# A descent may land on an intermediate authored shelf. Drop again only
		# when supported by that shelf and the requested destination is below it.
		if target.y>world.player.position.y+35 and world.player.is_on_floor() and world.player.drop_region.has_point(world.player.position+Vector2(0,23)) and not world.player.drop_exception_active:
			_key(KEY_S,true)
			_key(KEY_SPACE,true)
			for f in 3: await get_tree().physics_frame
			_key(KEY_SPACE,false)
			_key(KEY_S,false)
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
	push_error(message)
	set_meta("failure",message)
