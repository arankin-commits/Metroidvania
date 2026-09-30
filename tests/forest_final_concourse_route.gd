extends Node
const L=preload("res://scripts/forest_final_stair_layout.gd")
const N=preload("res://scripts/forest_dash_galleries_layout.gd")
var world: Node2D
var visual:=false
var camera_step:=0.0
var camera_step_per_physics:=0.0

func begin() -> void:
	set_meta("review_complete",await run_route())

func _key(key: Key,pressed: bool) -> void:
	var e:=InputEventKey.new()
	e.physical_keycode=key
	e.keycode=key
	e.pressed=pressed
	Input.parse_input_event(e)

func _fail(message: String) -> bool:
	for key in [KEY_A,KEY_D,KEY_SPACE,KEY_J,KEY_E]: _key(key,false)
	set_meta("failure",message)
	push_error(message)
	return false

func walk(x: float) -> bool:
	for i in 1800:
		var dx: float=x-world.player.position.x
		_key(KEY_D,dx>3)
		_key(KEY_A,dx < -3)
		await get_tree().physics_frame
		if absf(dx)<5:
			_key(KEY_D,false)
			_key(KEY_A,false)
			for j in 20: await get_tree().physics_frame
			return world.player.is_on_floor()
	return _fail("Cannot walk to %s; ended %s"%[x,world.player.position])

func snap(label: String) -> void:
	if not visual: return
	for i in 40: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-final-%s.png"%label)

func stairs() -> bool:
	world=get_tree().current_scene
	if not await walk(16120): return _fail("10.2 ground approach failed")
	await snap("10-11-seam")
	for x in [16300,16570,17090,17610,17940]:
		if not await walk(x): return _fail("Stair ascent support failed")
		if world.current_room!=6 or absf(world.player.position.y+23-L.surface_y(x))>13: return _fail("Stair/floor registration failed")
	await snap("stair-crest")
	var camera:=world.player.get_node("Camera2D") as Camera2D
	var previous:=camera.get_screen_center_position()
	var camera_physics_frame:=Engine.get_physics_frames()
	var start: float=world.player.position.y
	var minimum:=start
	var trace: Array=[]
	_key(KEY_SPACE,true)
	for i in 80:
		if i==3: _key(KEY_SPACE,false)
		await get_tree().physics_frame
		minimum=minf(minimum,world.player.position.y)
		var distance:=camera.get_screen_center_position().distance_to(previous)
		camera_step=maxf(camera_step,distance)
		if distance>0.001:
			camera_step_per_physics=maxf(camera_step_per_physics,distance/maxi(1,Engine.get_physics_frames()-camera_physics_frame))
			camera_physics_frame=Engine.get_physics_frames()
		trace.append({"i":i,"camera":str(camera.get_screen_center_position()),"physics":Engine.get_physics_frames(),"render":Engine.get_process_frames(),"body_y":world.player.position.y})
		previous=camera.get_screen_center_position()
		if i==22:
			await snap("stair-jump")
			previous=camera.get_screen_center_position()
			camera_physics_frame=Engine.get_physics_frames()
	set_meta("camera_trace",trace)
	if start-minimum<90 or camera_step_per_physics>16: return _fail("Stair crest jump/camera fails")
	for x in [17610,17090,16570,16300,16120]:
		if not await walk(x): return _fail("Stair reverse failed")
	set_meta("stairs_complete",true)
	return true

func cross(destination: int,key: Key) -> bool:
	_key(key,true)
	for i in 400:
		await get_tree().physics_frame
		if world.current_room==destination and not world.transitioning:
			_key(key,false)
			for j in 20: await get_tree().physics_frame
			return world.player.is_on_floor()
	_key(key,false)
	return _fail("Door crossing failed to room%s"%destination)

func interact(destination: int) -> bool:
	_key(KEY_E,true)
	_key(KEY_E,false)
	for i in 120:
		await get_tree().physics_frame
		if world.current_room==destination and not world.transitioning:
			await get_tree().process_frame
			await get_tree().process_frame
			return true
	return _fail("Interactable doorway failed to%s"%destination)

func run_route() -> bool:
	if not await stairs(): return false
	if not await walk(17940): return false
	var checkpoint: int=world.last_hand_room
	if not await cross(8,KEY_D): return false
	if world.last_hand_room!=checkpoint: return _fail("Hand-room entry activated checkpoint")
	if not await walk(world.HAND_X): return false
	await snap("boss-hand")
	if world.interaction_prompt()!="E - Meditate": return _fail("Boss hand prompt missing")
	_key(KEY_E,true); _key(KEY_E,false)
	for i in 50: await get_tree().physics_frame
	if world.last_hand_room!=8 or not world.hand_menu.visible: return _fail("Boss hand activation failed")
	world.hand_menu.hide_menu()
	for i in 80: await get_tree().physics_frame
	if not await walk(world.BOUNDS[3].y-60): return false
	if not await cross(7,KEY_D): return false
	if not world.bow_boss_defeated:
		if not world.bow_boss.active or not is_instance_valid(world.arena_entrance): return _fail("Bow Hunter arena failed to lock")
		# Observe the live anticipation/projectile lane before combat integration.
		world.player.invulnerability=1000
		for i in 160: await get_tree().physics_frame
		await snap("boss-tell")
		if not await fight(world.bow_boss): return false
	if not world.player.has_bow: return _fail("Bow inheritance lost")
	await snap("boss-cleared")
	if not await walk(world.BOUNDS[2].x+40): return false
	if not await cross(8,KEY_A): return false
	if not await walk(world.HAND_X): return false
	world._save_progress()
	# Independent receiving fixture for the lower side branch; it cannot be
	# represented as a reverse passage through Section3's sealed drop wall.
	await world._change_room(6,13670)
	world.player.position=N.PORTAL
	world.player.reset_movement_state()
	for i in 30: await get_tree().physics_frame
	if not await interact(9): return false
	if world.last_hand_room!=8: return _fail("Temple-room entry changed boss hand checkpoint")
	if not await walk(N.HAND.x): return false
	_key(KEY_E,true); _key(KEY_E,false)
	for i in 50: await get_tree().physics_frame
	if world.last_hand_room!=9 or not world.hand_menu.visible: return _fail("Temple hand activation failed")
	world.hand_menu.hide_menu()
	for i in 80: await get_tree().physics_frame
	if not await walk(N.HAND_MINIBOSS.x): return false
	await snap("temple-door")
	if not await interact(10): return false
	if world.last_hand_room!=9: return _fail("Miniboss entry changed checkpoint")
	if not world.temple_guardian_defeated:
		if not world.temple_guardian.active: return _fail("Guardian encounter not active")
		world.player.invulnerability=1000
		for i in 250: await get_tree().physics_frame
		await snap("guardian-tell")
		if not await fight(world.temple_guardian): return false
	if not world.temple_guardian_defeated or not world._completed_rooms().has(10): return _fail("Guardian defeat/completion lost")
	await snap("guardian-cleared")
	if not await walk(23735): return false
	if world.interaction_prompt().is_empty() or not await interact(9): return _fail("Guardian return doorway failed")
	if world.last_hand_room!=9: return _fail("Guardian return changed checkpoint")
	set_meta("complete",true)
	return true

func fight(enemy: Node2D) -> bool:
	# Real input and real enemy movement/tells; invulnerability isolates room
	# integration and does not establish encounter difficulty balance.
	for i in 2400:
		world.player.invulnerability=1000
		var dx: float=enemy.position.x-world.player.position.x
		_key(KEY_D,dx>65)
		_key(KEY_A,dx < -65)
		if absf(dx)<=100:
			world.player.facing=1 if dx>0 else -1
			_key(KEY_J,i%22==0)
		else: _key(KEY_J,false)
		await get_tree().physics_frame
		if enemy.health<=0:
			_key(KEY_A,false); _key(KEY_D,false); _key(KEY_J,false)
			return true
	return _fail("Cannot defeat encounter with actual attack input")
