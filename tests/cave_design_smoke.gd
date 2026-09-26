extends SceneTree

const SLOTS = preload("res://scripts/save_slots.gd")
const ROOT := "res://tests/.cave_design_saves"
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT))
	SLOTS.write_slot(2, SLOTS.new_slot(), ROOT)
	set_meta("active_save_slot", 2)
	set_meta("save_root", ROOT)
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await process_frame
	var world := current_scene
	world.scout.set_physics_process(false)
	world.ledge_sentinel.set_process(false)
	world.player.invulnerability = 1000.0
	await physics_frame
	for room in range(1, 5):
		var bounds: Vector2 = world.ROOM_BOUNDS[room - 1]
		var x := (bounds.x + bounds.y) * 0.5
		var query := PhysicsRayQueryParameters2D.create(Vector2(x, 350), Vector2(x, -100))
		query.exclude = [world.player.get_rid()]
		var hit: Dictionary = world.get_world_2d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or hit.collider.name != "Room%dRoof" % room:
			_fail("Room %d's visible ceiling has no working collision" % room)
			return
	# Traverse each new ascending connection using the real movement controller.
	for hop in [
		[Vector2(520, 502), Vector2(620, 422)],
		[Vector2(675, 422), Vector2(805, 342)],
		[Vector2(865, 342), Vector2(980, 407)],
	]:
		await _jump_to(world, hop[0], hop[1])
		if failed:
			return
	world.player.global_position = world.CAVE_LAYOUT.GALLERY_CACHE
	_interact(world)
	if not world.gallery_cache_found or world.will_amount != 12:
		_fail("The upper route did not award its offering")
		return
	_interact(world)
	if world.will_amount != 12:
		_fail("The gallery offering could be collected twice")
		return
	world.current_room = 1
	world._mark_room_visited(1)
	world._set_camera_room()
	for hop in [
		[Vector2(-1010, 577), Vector2(-900, 502)],
		[Vector2(-850, 502), Vector2(-735, 422)],
		[Vector2(-640, 422), Vector2(-535, 342)],
	]:
		await _jump_to(world, hop[0], hop[1])
		if failed:
			return
	var cache_hit := Rect2(world.CAVE_LAYOUT.WATCH_CACHE - Vector2(30, 30), Vector2(60, 60))
	world._on_player_attacked(cache_hit)
	if world.watch_cache_found:
		_fail("An ordinary attack bypassed the reliquary's ability gate")
		return
	world.player.has_heavy = true
	world._on_player_heavy_attacked(cache_hit)
	world._on_player_heavy_attacked(cache_hit)
	if not world.watch_cache_found or world.will_amount != 37 or not world._completed_rooms().has(1):
		_fail("The heavy-attack return reward did not persist exactly once")
		return
	world.current_room = 3
	world._set_camera_room()
	for hop in [
		[Vector2(2690, 577), Vector2(2795, 497)],
		[Vector2(2810, 497), Vector2(2720, 417)],
		[Vector2(2760, 417), Vector2(2860, 342)],
	]:
		await _jump_to(world, hop[0], hop[1])
		if failed:
			return
	world.player.global_position = world.NOTE_POSITION
	_interact(world)
	if not world.note_found:
		_fail("The refuge alcove's note was not reachable for interaction")
		return
	world._close_note()
	world.player.global_position = world.CAVE_LAYOUT.WINCH
	_interact(world)
	if not world.cave_shortcut_open or not world.has_node("RefugeReturnBridge"):
		_fail("The far-side winch did not lower the return bridge")
		return
	world.player.global_position = Vector2(2420, 577)
	world.player.reset_movement_state()
	_key(KEY_A, true)
	await create_timer(0.65).timeout
	_key(KEY_A, false)
	if world.player.global_position.x > 2310 or world.player.global_position.y > 585:
		_fail("The lowered bridge did not support the returning player")
		return
	world._save_progress()
	change_scene_to_file("res://scenes/forest_entry.tscn")
	await process_frame
	await process_frame
	current_scene._save_progress()
	set_meta("cave_entry_x", 2610.0)
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await process_frame
	world = current_scene
	if not world.cave_shortcut_open or not world.has_node("RefugeReturnBridge") or not world.gallery_cache_found or not world.watch_cache_found:
		_fail("Cave rewards or shortcut were lost on a forest round trip")
		return
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame
	SLOTS.delete_slot(2, ROOT)
	remove_meta("active_save_slot")
	remove_meta("save_root")
	print("CAVE_DESIGN_SMOKE_PASS")
	quit()

func _jump_to(world: Node2D, from: Vector2, destination: Vector2) -> void:
	var player: CharacterBody2D = world.player
	player.global_position = from
	player.reset_movement_state()
	for i in 5:
		await physics_frame
	_key(KEY_SPACE, true)
	var landed := false
	for i in 110:
		var dx: float = destination.x - player.global_position.x
		_key(KEY_D, dx > 6)
		_key(KEY_A, dx < -6)
		if i == 3:
			_key(KEY_SPACE, false)
		await physics_frame
		if i > 10 and player.is_on_floor() and absf(dx) < 30 and absf(player.global_position.y - destination.y) < 8:
			landed = true
			break
	_key(KEY_SPACE, false)
	_key(KEY_A, false)
	_key(KEY_D, false)
	if not landed:
		_fail("Unreachable cave jump from %s to %s (ended at %s)" % [from, destination, player.global_position])

func _interact(world: Node2D) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	world._unhandled_input(event)

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _fail(message: String) -> void:
	failed = true
	push_error(message)
	quit(1)
