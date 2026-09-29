extends SceneTree
const SLOTS=preload("res://scripts/save_slots.gd")
const ART=preload("res://scripts/player_presentation.gd")
const FIXTURE="res://tests/.cave_opening_saves"
func _initialize() -> void: call_deferred("run")
func fail(message: String) -> void:
	push_error(message)
	quit(1)
func key(code: Key, down: bool) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=down
	Input.parse_input_event(event)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FIXTURE))
	SLOTS.write_slot(1,SLOTS.new_slot(),FIXTURE)
	set_meta("active_save_slot",1)
	set_meta("save_root",FIXTURE)
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await process_frame
	var world: Node2D=current_scene
	var p: CharacterBody2D=world.player
	if world.current_room!=1 or world.visited_rooms!=[1] or not p.waking_up or p.position!=world.CAVE_LAYOUT.START: fail("Fresh game did not wake in Room 1"); return
	p.set_physics_process(false)
	p.begin_waking_up()
	var start:=p.position
	key(KEY_D,true)
	key(KEY_SPACE,true)
	key(KEY_J,true)
	p.take_damage(1,p.position.x+20)
	for tick in 239: p._physics_process(1.0/60)
	if not p.waking_up or p.controls_enabled or p.position!=start or p.health!=p.max_health or p.attack_time>0: fail("Wake input/damage lock or four-second duration failed"); return
	p._physics_process(1.0/60)
	if p.waking_up or not p.controls_enabled or not world.opening_seen: fail("Wake did not finish at four seconds"); return
	for code in [KEY_D,KEY_SPACE,KEY_J]: key(code,false)
	if not SLOTS.load_slot(1,FIXTURE).opening_seen: fail("Completed opening was not saved"); return
	var image:=ART.WAKE.get_image()
	if image.is_compressed(): image.decompress()
	for index in 8:
		var frame:=image.get_region(Rect2i(Vector2i(index%4,index/4)*192,Vector2i(192,192)))
		var bounds:=frame.get_used_rect()
		if bounds.size.y<10 or bounds.position.x<=0 or bounds.end.x>=192 or absf(bounds.end.y-137)>2: fail("Missing/clipped/ungrounded wake pose %d" % index); return
		var blood:=0
		for y in 192:
			for x in 192:
				var c:=frame.get_pixel(x,y)
				if c.a>.8 and c.r>c.g*1.5 and c.r>c.b*1.2 and c.r>.12: blood+=1
		if blood<3: fail("Missing blood in pose %d" % index); return
	world.player.set_physics_process(true)
	for tick in 4: await physics_frame
	world._respawn()
	if world.current_room!=1 or p.waking_up: fail("Pre-hand death replayed opening or returned to Room 2"); return
	world._save_progress()
	reload_current_scene()
	await process_frame
	await process_frame
	world=current_scene
	if world.player.waking_up: fail("Reload replayed completed opening"); return
	var saved:=SLOTS.new_slot()
	saved.merge({"hand_activated":true,"checkpoint_x":2610.0,"checkpoint_y":570.0,"last_hand_room":3,"room":3},true)
	world.active_save_slot=0
	SLOTS.write_slot(1,saved,FIXTURE)
	reload_current_scene()
	await process_frame
	await process_frame
	world=current_scene
	if world.current_room!=3 or world.player.waking_up or world.checkpoint!=Vector2(2610,570): fail("Opening replaced saved hand"); return
	world._save_progress()
	if SLOTS.load_slot(1,FIXTURE).checkpoint_x!=2610.0: fail("Opening damaged persisted hand checkpoint"); return
	world.active_save_slot=0
	SLOTS.write_slot(1,SLOTS.new_slot(),FIXTURE)
	set_meta("cave_entry_x",2990.0)
	reload_current_scene()
	await process_frame
	await process_frame
	world=current_scene
	if world.current_room!=3 or world.player.waking_up: fail("Biome return replayed opening"); return
	key(KEY_D,true)
	var origin: float=world.player.position.x
	for tick in 10: await physics_frame
	key(KEY_D,false)
	if world.player.position.x<=origin+5: fail("Player movement did not resume after opening bypass"); return
	print("CAVE_OPENING_PASS: eight bloodied poses, exact 4s input lock, Room 1 start/death, reload persistence, hand preservation and biome return")
	quit()
