extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const SCOUT_SCRIPT = preload("res://scripts/scout.gd")
const NAVIGATION_SYSTEM = preload("res://scripts/nav_system.gd")
const INHERITANCE_STATE = preload("res://scripts/inheritance_state.gd")
const BOSS_SCRIPT = preload("res://scripts/boss.gd")
const BOW_ARROW_SCRIPT = preload("res://scripts/bow_arrow.gd")
const HUD_SCRIPT = preload("res://scripts/hud.gd")
const SAVE_SLOTS = preload("res://scripts/save_slots.gd")
const LOADING_OVERLAY = preload("res://scripts/loading_overlay.gd")
const GALLERY_BACKGROUND = preload("res://assets/split_gallery_background.png")
const CAVE_ROOM_BACKDROPS := [
	preload("res://assets/cave_room1_opening.png"),
	GALLERY_BACKGROUND,
	preload("res://assets/cave_room3.png"),
	preload("res://assets/cave_room4.png"),
]
const WILL_ORB = preload("res://scripts/will_orb.gd")
const WORLD_MAP = preload("res://scripts/world_map.gd")
const HAND_CHAIR = preload("res://assets/hand_chair.png")
const HAND_MENU = preload("res://scripts/hand_menu.gd")
const LEDGE_SENTINEL = preload("res://scripts/ledge_sentinel.gd")
const GAME_AUDIO = preload("res://scripts/game_audio.gd")
const GAME_MENU = preload("res://scripts/game_menu.gd")
const CAVE_LAYOUT = preload("res://scripts/cave_layout.gd")
const CAVE_SCENERY = preload("res://scripts/cave_scenery.gd")
const GALLERY_ENCOUNTERS = preload("res://scripts/gallery_encounters.gd")
const SPLIT_GALLERY = preload("res://scripts/split_gallery.gd")
const GALLERY_LAYOUT = preload("res://scripts/split_gallery_layout.gd")

const FLOOR_Y := 600.0
const LEVEL_END := 7250.0
const ROOM_BOUNDS = CAVE_LAYOUT.BOUNDS
const SECRET_POSITION = GALLERY_LAYOUT.SIGIL
const NOTE_POSITION = CAVE_LAYOUT.NOTE

var player: CharacterBody2D
var scout: CharacterBody2D
var navigation_system: Node
var inheritance = INHERITANCE_STATE.new()
var ledge_sentinel: Node2D
var boss: Node2D
var hud: Control
var background_rect: TextureRect
var room_backgrounds: Array[TextureRect] = []
var pause_menu: CanvasLayer
var loading_overlay: CanvasLayer
var world_map: CanvasLayer
var hand_chair: Sprite2D
var hand_menu: CanvasLayer
var game_audio: Node
var game_menu: CanvasLayer
var visited_rooms: Array[int] = [1]
var platforms: Array[Rect2] = []
var ledge_wall: StaticBody2D
var drop_platform_body: StaticBody2D
var seal_body: StaticBody2D
var exit_barrier: StaticBody2D
var arena_barrier: StaticBody2D
var seal_health := 3
var checkpoint := CAVE_LAYOUT.START
var hand_activated := false
var last_hand_room := 1
var opening_seen := false
var boss_defeated := false
var artificer_rescued := false
var complete := false
var respawning := false
var toast := ""
var toast_time := 0.0
var active_save_slot := 0
var save_root := "user://"
var elapsed_seconds := 0.0
var will_amount := 0
var player_level := 1
var saved_healing_charges := 3
var save_timer := 0.0
var saved_aerial_practiced := false
var saved_boss_defeated := false
var saved_bow_boss_defeated := false
var saved_has_bow := false
var saved_bow_ammo := 3
var saved_is_injured := true
var saved_has_dash := false
var saved_has_air_dash := false
var bow_boss_defeated := false
var bow_tutorial_practiced := false
var forest_hand_activated := false
var temple_hand_activated := false
var temple_guardian_defeated:=false
var saved_heavy := false
var data_equipped_weapon:="starter"
var saved_seal_broken := false
var saved_scout_defeated := false
var sentinel_defeated := false
var saved_data: Dictionary = {}
var current_room := 1
var transitioning_room := false
var wall_broken := false
var secret_found := false
var note_found := false
var note_open := false
var note_panel: Control
var note_text: Label
var sigil_icon: Label
var end_gate_hint_shown := false
var aerial_practiced := false
var ledge_practiced := false
var drop_practiced := false
var dodge_practiced := false
var jump_practiced := false
var heal_practiced := false
var dash_gap_practiced := false
var heal_hint_shown := false
var cave_shortcut_open := false
var gallery_cache_found := false
var watch_cache_found := false
var gallery: Node2D
var gallery_encounters: Node2D
var gallery_defeated: Array = []
var legacy_bodies: Array[StaticBody2D] = []
var enemy_blockers: Array[StaticBody2D] = []
var gallery_west_open := false
var gallery_east_open := false
var gallery_heavy_open := false

func _ready() -> void:
	navigation_system = NAVIGATION_SYSTEM.new()
	navigation_system.name = "NavigationSystem"
	add_child(navigation_system)
	game_audio = GAME_AUDIO.new()
	game_audio.name = "GameAudio"
	add_child(game_audio)
	game_audio.play_cave()
	if get_tree().has_meta("active_save_slot"):
		active_save_slot = int(get_tree().get_meta("active_save_slot"))
		save_root = str(get_tree().get_meta("save_root", "user://"))
	if active_save_slot > 0:
		saved_data = SAVE_SLOTS.load_slot(active_save_slot, save_root)
		var data: Dictionary = saved_data
		if not data.is_empty():
			opening_seen=bool(data.get("opening_seen",true))
			hand_activated = bool(data.get("hand_activated", false))
			forest_hand_activated = bool(data.get("forest_hand_activated", false))
			temple_hand_activated = bool(data.get("temple_hand_activated", false))
			var any_hand := hand_activated or forest_hand_activated or temple_hand_activated
			last_hand_room = int(data.get("last_hand_room", 3 if hand_activated else 1))

			if not get_tree().has_meta("cave_entry_x"):
				if not any_hand:
					current_room = 1
					checkpoint = CAVE_LAYOUT.START
				elif hand_activated and last_hand_room == 3:
					current_room = 3
					checkpoint = Vector2(2610.0, 570.0)
				elif hand_activated:
					current_room = 3
					checkpoint = Vector2(2610.0, 570.0)
				else:
					current_room = 1
					checkpoint = CAVE_LAYOUT.START
			else:
				current_room = clampi(int(data.get("room", 2)), 1, 4)
				checkpoint = Vector2(float(data.get("checkpoint_x", 2610.0)), float(data.get("checkpoint_y", 570.0))) if hand_activated else CAVE_LAYOUT.START
			elapsed_seconds = float(data.get("seconds", 0.0))
			will_amount = int(data.get("will", 0))
			player_level = clampi(maxi(int(data.get("level", 1)), 1 + int(will_amount / 25)), 1, 999)
			saved_healing_charges = int(data.get("healing_charges", 3))
			saved_aerial_practiced = bool(data.get("aerial_practiced", false))
			sentinel_defeated = bool(data.get("sentinel_defeated", saved_aerial_practiced))
			jump_practiced = bool(data.get("jump_practiced", false))
			dodge_practiced = bool(data.get("dodge_practiced", false))
			drop_practiced = bool(data.get("drop_practiced", false))
			ledge_practiced = bool(data.get("ledge_practiced", false))
			heal_practiced = bool(data.get("heal_practiced", false))
			dash_gap_practiced = bool(data.get("dash_gap_practiced", false))
			saved_boss_defeated = bool(data.get("boss_defeated", false))
			artificer_rescued = bool(data.get("artificer_rescued", false))
			saved_heavy = bool(data.get("has_heavy", saved_boss_defeated))
			saved_bow_boss_defeated = bool(data.get("bow_boss_defeated", false))
			saved_is_injured = bool(data.get("is_injured", not hand_activated))
			saved_has_dash = bool(data.get("has_dash", hand_activated))
			saved_has_air_dash = bool(data.get("has_air_dash", saved_bow_boss_defeated))
			data_equipped_weapon=str(data.get("equipped_weapon","scimitar" if bool(data.get("boss_defeated",false)) else "starter"))
			saved_has_bow = bool(data.get("has_bow", saved_bow_boss_defeated))
			saved_bow_ammo = int(data.get("bow_ammo", 3))
			bow_tutorial_practiced = bool(data.get("bow_tutorial_practiced", false))
			forest_hand_activated = bool(data.get("forest_hand_activated", false))
			temple_hand_activated = bool(data.get("temple_hand_activated", false))
			temple_guardian_defeated=bool(data.get("temple_guardian_defeated",false))
			saved_seal_broken = bool(data.get("seal_broken", false))
			saved_scout_defeated = bool(data.get("scout_defeated", false))
			wall_broken = bool(data.get("wall_broken", false))
			secret_found = bool(data.get("secret_found", false))
			note_found = bool(data.get("note_found", false))
			cave_shortcut_open = bool(data.get("cave_shortcut_open", false))
			gallery_cache_found = bool(data.get("gallery_cache_found", false))
			watch_cache_found = bool(data.get("watch_cache_found", false))
			gallery_defeated = data.get("gallery_defeated", []).duplicate()
			gallery_west_open = bool(data.get("gallery_west_open", false))
			gallery_east_open = bool(data.get("gallery_east_open", false))
			gallery_heavy_open = bool(data.get("gallery_heavy_open",false))
			visited_rooms.assign(data.get("visited_rooms", [2]))
	var spawn_position := checkpoint
	var arriving_via_entry:=get_tree().has_meta("cave_entry_x")
	if hand_activated or arriving_via_entry: opening_seen=true
	if get_tree().has_meta("cave_entry_x"):
		var entry_x := float(get_tree().get_meta("cave_entry_x"))
		spawn_position = Vector2(entry_x,GALLERY_LAYOUT.START.y if entry_x>=0 and entry_x<1700 else 570)
		get_tree().remove_meta("cave_entry_x")
	current_room = _room_for_x(spawn_position.x)
	_mark_room_visited(current_room)
	platforms = CAVE_LAYOUT.platforms()
	for rect in platforms:
		var body := _make_solid(rect, rect.position.x == 1350.0)
		if rect.position.x == 1350.0:
			drop_platform_body = body
		if rect.position.x == 2010.0:
			ledge_wall = body
	for room in range(1, 5):
		var roof := StaticBody2D.new()
		roof.name = "Room%dRoof" % room
		var collision := CollisionPolygon2D.new()
		collision.polygon = CAVE_LAYOUT.roof_polygon(room)
		roof.add_child(collision)
		add_child(roof)
		legacy_bodies.append(roof)
	if cave_shortcut_open:
		_add_shortcut_bridge()
	if saved_aerial_practiced:
		aerial_practiced = true
	_make_solid(Rect2(1330, 540, 20, 60))
	_make_solid(Rect2(1510, 350, 32, 190))
	_make_solid(Rect2(-1160, 380, 32, 220))
	if saved_seal_broken:
		seal_health = 0
	exit_barrier = _make_solid(CAVE_LAYOUT.EXIT_WALL)
	if wall_broken:
		exit_barrier.queue_free()
	gallery = SPLIT_GALLERY.new()
	gallery.world = self
	add_child(gallery)
	drop_platform_body = gallery.drop_body
	player = PLAYER_SCRIPT.new()
	player.inheritance = inheritance
	player.name = "Player"
	player.z_index = 3
	player.position = spawn_position
	player.set_injured(saved_is_injured)
	player.has_dash = saved_has_dash
	player.has_air_dash = saved_has_air_dash
	player.has_heavy = saved_heavy
	player.has_bow = saved_has_bow
	player.bow_ammo = saved_bow_ammo if saved_has_bow else 0
	player.load_combat_progress({"bow_boss_defeated":saved_bow_boss_defeated,"boss_defeated":saved_boss_defeated,"temple_guardian_defeated":temple_guardian_defeated,"equipped_weapon":str(data_equipped_weapon),"has_dash":player.has_dash,"has_air_dash":saved_has_air_dash})
	player.healing_charges = player.max_healing_charges if saved_healing_charges <= 0 else saved_healing_charges
	player.drop_platform = drop_platform_body
	player.drop_region = Rect2(GALLERY_LAYOUT.DROP.position - Vector2(0, 8), Vector2(GALLERY_LAYOUT.DROP.size.x, 26))
	add_child(player)
	player.wake_finished.connect(func() -> void:
		opening_seen=true
		_show_toast(CAVE_LAYOUT.NAMES[0],3.0)
		_save_progress())
	if not opening_seen and not hand_activated and not arriving_via_entry:
		player.begin_waking_up()
	player.attacked.connect(_on_player_attacked)
	player.heavy_attacked.connect(_on_player_heavy_attacked)
	player.bow_fired.connect(_on_player_bow_fired)
	player.dodged.connect(_on_player_dodged)
	player.jumped.connect(_on_player_jumped)
	player.ledge_climbed.connect(_on_player_ledge_climbed)
	player.platform_dropped.connect(_on_player_platform_dropped)
	player.healed.connect(_on_player_healed)
	player.damaged.connect(_on_player_damaged)
	player.died.connect(_on_player_died)
	scout = SCOUT_SCRIPT.new()
	scout.name = "Scout"
	scout.position = GALLERY_LAYOUT.SCOUT
	scout.player = player
	scout.navigation = navigation_system
	add_child(scout)
	scout.defeated.connect(_on_scout_defeated)
	scout.attack_landed.connect(func() -> void: game_audio.play_effect("enemy_attack"))
	if saved_scout_defeated:
		scout.queue_free()
	ledge_sentinel = LEDGE_SENTINEL.new()
	ledge_sentinel.name = "LedgeSentinel"
	ledge_sentinel.position = GALLERY_LAYOUT.SENTINEL
	ledge_sentinel.player = player
	add_child(ledge_sentinel)
	ledge_sentinel.defeated.connect(_on_ledge_sentinel_defeated)
	ledge_sentinel.attack_landed.connect(func() -> void: game_audio.play_effect("enemy_attack"))
	if sentinel_defeated:
		ledge_sentinel.queue_free()
	gallery_encounters = GALLERY_ENCOUNTERS.new()
	gallery_encounters.world = self
	add_child(gallery_encounters)
	boss = BOSS_SCRIPT.new()
	boss.name = "HollowWarden"
	boss.position = Vector2(3510, 553)
	boss.player = player
	add_child(boss)
	boss.defeated.connect(_on_boss_defeated)
	boss.attack_cued.connect(game_audio.play_effect)
	if saved_boss_defeated:
		boss_defeated = true
		_disable_defeated_boss(boss)
	bow_boss_defeated = saved_bow_boss_defeated
	var layer := CanvasLayer.new()
	layer.name = "HUDLayer"
	add_child(layer)
	hud = HUD_SCRIPT.new()
	hud.name = "HUD"
	layer.add_child(hud)
	_add_backdrop()
	var scenery := CAVE_SCENERY.new()
	scenery.name = "CaveScenery"
	scenery.world = self
	add_child(scenery)
	_add_hand_chair()
	pause_menu = preload("res://scripts/pause_menu.gd").new()
	add_child(pause_menu)
	loading_overlay = LOADING_OVERLAY.new()
	add_child(loading_overlay)
	world_map = WORLD_MAP.new()
	add_child(world_map)
	hand_menu = HAND_MENU.new()
	hand_menu.world = self
	add_child(hand_menu)
	game_menu = GAME_MENU.new()
	game_menu.world = self
	add_child(game_menu)
	_build_note_panel(layer)
	_set_camera_room()
	if get_tree().has_meta("arriving_room_transition"):
		get_tree().remove_meta("arriving_room_transition")
		loading_overlay.reveal_room()
	_show_toast(CAVE_LAYOUT.NAMES[current_room - 1], 3.0)
	if player.waking_up: toast_time=0.0
	queue_redraw()
	

func _add_backdrop() -> void:
	for i in ROOM_BOUNDS.size():
		var bounds: Vector2 = ROOM_BOUNDS[i]
		var backdrop := TextureRect.new()
		backdrop.name = "Room%dBackdrop" % (i + 1)
		backdrop.z_index = -100
		backdrop.position = Vector2(bounds.x, -60)
		backdrop.size = Vector2(bounds.y - bounds.x, 780)
		if i==0:
			# Preserve aspect ratio and register the supplied floor edge to collision.
			backdrop.position.y=600.0-780.0*1200.0/1651.0
			backdrop.size=Vector2(1200,953.0*1200.0/1651.0)
		backdrop.texture = CAVE_ROOM_BACKDROPS[i]
		backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		backdrop.stretch_mode = TextureRect.STRETCH_SCALE
		if i == 1:
			backdrop.position = GALLERY_LAYOUT.EXTENT.position
			backdrop.size = GALLERY_LAYOUT.EXTENT.size
			backdrop.texture = GALLERY_BACKGROUND
			backdrop.stretch_mode = TextureRect.STRETCH_SCALE
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(backdrop)
		room_backgrounds.append(backdrop)
	background_rect = room_backgrounds[current_room - 1]

func _add_hand_chair() -> void:
	hand_chair = Sprite2D.new()
	hand_chair.name = "HandChairCheckpoint"
	hand_chair.texture = HAND_CHAIR
	hand_chair.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hand_chair.scale = Vector2(0.096, 0.096)
	hand_chair.position = Vector2(2610, 546)
	hand_chair.z_index = 2
	add_child(hand_chair)

func _mark_room_visited(room: int) -> void:
	if not visited_rooms.has(room):
		visited_rooms.append(room)
		visited_rooms.sort()

func _completed_rooms() -> Array[int]:
	var completed: Array[int] = []
	if visited_rooms.has(1) and watch_cache_found:
		completed.append(1)
	if visited_rooms.has(2) and secret_found and gallery_cache_found:
		completed.append(2)
	if visited_rooms.has(3) and note_found:
		completed.append(3)
	if visited_rooms.has(4) and boss_defeated:
		completed.append(4)
	for room in [5, 6]:
		if visited_rooms.has(room):
			completed.append(room)
	if visited_rooms.has(7) and bow_boss_defeated:
		completed.append(7)
	if visited_rooms.has(8) and bow_tutorial_practiced:
		completed.append(8)
	if visited_rooms.has(9) and temple_hand_activated:
		completed.append(9)
	if visited_rooms.has(10) and temple_guardian_defeated: completed.append(10)
	return completed

func _make_solid(rect: Rect2, one_way: bool = false) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.one_way_collision = one_way
	body.add_child(collision)
	add_child(body)
	legacy_bodies.append(body)
	if one_way:
		var enemy_body := StaticBody2D.new()
		enemy_body.position = body.position
		enemy_body.collision_layer = 4
		enemy_body.collision_mask = 0
		var enemy_col := CollisionShape2D.new()
		enemy_col.shape = shape
		enemy_body.add_child(enemy_col)
		add_child(enemy_body)
		enemy_blockers.append(enemy_body)
	return body

func _add_shortcut_bridge() -> void:
	platforms.append(CAVE_LAYOUT.BRIDGE)
	var bridge := _make_solid(CAVE_LAYOUT.BRIDGE)
	bridge.name = "RefugeReturnBridge"
	queue_redraw()

func _process(delta: float) -> void:
	elapsed_seconds += delta
	save_timer += delta
	if save_timer >= 10.0:
		save_timer = 0.0
		_save_progress()
	toast_time = maxf(0.0, toast_time - delta)
	if transitioning_room or note_open or player.waking_up:
		_update_hud()
		return
	if _check_room_transition():
		_update_hud()
		return
	if current_room == 3 and player.global_position.x > 2490.0 and not dash_gap_practiced:
		dash_gap_practiced = true
		_save_progress()
	if current_room == 1 and player.global_position.x < -1020.0 and not end_gate_hint_shown:
		end_gate_hint_shown = true
		_show_toast("The End Area entrance is sealed for now", 3.0)
	if current_room == 4 and not boss.active and not boss_defeated and not respawning and player.global_position.x > 3070.0:
		boss.active = true
		boss.state_time = 0.9
		game_audio.play_boss()
		_lock_arena()
		_show_toast("THE HOLLOW WARDEN  ·  Watch the red charge tell", 3.0)
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
		if not note_open and not transitioning_room and not hand_menu.visible and not world_map.visible and not get_tree().paused:
			game_menu.open_section("status")
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		if not note_open and not transitioning_room and not hand_menu.visible and not get_tree().paused:
			world_map.show_map(visited_rooms, _completed_rooms(), current_room, get_fast_travel_hands())
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
		if respawning or transitioning_room or not player.meditation_state.is_empty():
			return
		if note_open:
			_close_note()
		elif current_room == 2 and gallery.try_open_shortcut(player.position):
			_show_toast("The gallery passage opens. The return route is clear.", 3.0)
			_save_progress()
		elif current_room == 2 and not gallery_cache_found and player.global_position.distance_to(CAVE_LAYOUT.GALLERY_CACHE) < 55.0:
			gallery_cache_found = true
			add_will(12)
			_show_toast("A traveller's offering. +12 Will", 2.5)
			queue_redraw()
		elif current_room == 3 and not cave_shortcut_open and player.global_position.distance_to(CAVE_LAYOUT.WINCH) < 55.0:
			cave_shortcut_open = true
			_add_shortcut_bridge()
			_show_toast("The old bridge lowers. The way back is open.", 3.0)
			_save_progress()
		elif current_room == 2 and not secret_found and player.global_position.distance_to(SECRET_POSITION) < 65.0:
			_open_sigil()
		elif current_room == 3 and not note_found and player.global_position.distance_to(NOTE_POSITION) < 65.0:
			_open_note()
		elif current_room == 3 and player.meditation_state.is_empty() and player.global_position.distance_to(hand_chair.global_position) < 70.0:
			var active_hand := hand_chair
			activate_hand()
			player.begin_meditation(active_hand.global_position)
			game_audio.play_effect("hand_mount")
			hand_menu.show_menu()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()

func _check_room_transition() -> bool:
	var x := player.global_position.x
	if current_room == 4 and boss.active and not boss_defeated and x < 3070.0:
		player.global_position.x = 3120.0
		player.velocity.x = 0.0
		return false
	match current_room:
		1:
			if x >= 14.0:
				_begin_room_transition(2, GALLERY_LAYOUT.ENTRANCE.x)
				return true
		2:
			if x <= -14.0 and GALLERY_LAYOUT.ENTRANCE_DOOR.has_point(player.global_position):
				_begin_room_transition(1, -80.0)
				return true
			if x >= 5014.0 and GALLERY_LAYOUT.EXIT_DOOR.has_point(player.global_position) and seal_health <= 0:
				_begin_room_transition(3, 1780.0)
				return true
		3:
			if x <= 1686.0:
				_begin_room_transition(2, GALLERY_LAYOUT.EXIT.x)
				return true
			if x >= 3084.0:
				_begin_room_transition(4, 3150.0)
				return true
		4:
			if x <= 3056.0:
				_begin_room_transition(3, 2990.0)
				return true
			if x >= 4464.0 and wall_broken:
				_leave_for_forest()
				return true
	return false

func _begin_room_transition(destination: int, entry_x: float) -> void:
	transitioning_room = true
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	await loading_overlay.cover_room()
	current_room = destination
	_mark_room_visited(current_room)
	player.reset_movement_state()
	player.global_position = (GALLERY_LAYOUT.ENTRANCE if entry_x==GALLERY_LAYOUT.ENTRANCE.x else GALLERY_LAYOUT.EXIT) if destination==2 else Vector2(entry_x,570)
	_set_camera_room()
	_show_toast(CAVE_LAYOUT.NAMES[current_room - 1], 2.4)
	_save_progress()
	await loading_overlay.reveal_room()
	player.controls_enabled = true
	transitioning_room = false

func _leave_for_forest() -> void:
	transitioning_room = true
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	_save_progress()
	await loading_overlay.cover_room()
	get_tree().set_meta("arriving_room_transition", true)
	get_tree().change_scene_to_file("res://scenes/forest_entry.tscn")

func _set_camera_room() -> void:
	var camera := player.get_node("Camera2D") as Camera2D
	var bounds: Vector2 = ROOM_BOUNDS[current_room - 1]
	var in_gallery := current_room == 2
	# Frame 96px of the continuous outer rock, including the western wall and roof.
	camera.limit_left = int(GALLERY_LAYOUT.EXTENT.position.x - 96) if in_gallery else int(bounds.x)
	camera.limit_right = int(GALLERY_LAYOUT.EXIT_DOOR.position.x + 96) if in_gallery else int(bounds.y)
	camera.limit_top = int(GALLERY_LAYOUT.EXTENT.position.y - 96) if in_gallery else -60
	camera.limit_bottom = int(GALLERY_LAYOUT.EXTENT.end.y) if in_gallery else 720
	gallery.set_active(in_gallery)
	for body in legacy_bodies:
		if is_instance_valid(body) and not body.is_queued_for_deletion():
			body.collision_layer = 0 if in_gallery else 1
			body.collision_mask = 0 if in_gallery else 1
	for blocker in enemy_blockers:
		if is_instance_valid(blocker) and not blocker.is_queued_for_deletion():
			blocker.collision_layer = 0 if in_gallery else 4
			blocker.collision_mask = 0
	for backdrop in room_backgrounds:
		backdrop.visible = backdrop == room_backgrounds[current_room - 1]
	hand_chair.visible = not in_gallery
	boss.visible = not in_gallery and not boss_defeated
	_set_gallery_enemies_active(in_gallery)
	gallery_encounters.set_active(in_gallery)
	camera.reset_smoothing()
	background_rect = room_backgrounds[current_room - 1]
	queue_redraw()

func _set_gallery_enemies_active(active: bool) -> void:
	if is_instance_valid(scout) and not scout.is_queued_for_deletion():
		scout.patrol_bounds = Vector2(3450, 3620)
		scout.awareness_height = 80
		scout.visible = active
		scout.collision_layer = 2 if active else 0
		scout.collision_mask = 5 if active else 0
		scout.set_physics_process(active)
	if is_instance_valid(ledge_sentinel) and not ledge_sentinel.is_queued_for_deletion():
		ledge_sentinel.visible = active
		ledge_sentinel.set_process(active)

func _lock_arena() -> void:
	if is_instance_valid(arena_barrier):
		return
	arena_barrier = _make_solid(Rect2(3070, -60, 32, 660))
	queue_redraw()

func _unlock_arena() -> void:
	if is_instance_valid(arena_barrier):
		arena_barrier.queue_free()
	arena_barrier = null

func _build_note_panel(layer: CanvasLayer) -> void:
	note_panel = Control.new()
	note_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(note_panel)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.08, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	note_panel.add_child(shade)
	note_text = Label.new()
	note_text.text = ""
	note_text.add_theme_font_size_override("font_size", 25)
	note_text.add_theme_color_override("font_color", Color("f5e9bf"))
	note_text.anchor_left = 0.16
	note_text.anchor_right = 0.84
	note_text.anchor_top = 0.27
	note_text.anchor_bottom = 0.78
	note_panel.add_child(note_text)
	sigil_icon = Label.new()
	sigil_icon.text = "◆"
	sigil_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sigil_icon.add_theme_font_size_override("font_size", 76)
	sigil_icon.add_theme_color_override("font_color", Color("f8d879"))
	sigil_icon.anchor_left = 0.40
	sigil_icon.anchor_right = 0.60
	sigil_icon.anchor_top = 0.09
	sigil_icon.anchor_bottom = 0.24
	note_panel.add_child(sigil_icon)
	note_panel.visible = false

func _open_note() -> void:
	note_open = true
	note_found = true
	note_text.text = "A WEATHERED NOTE\n\nThe four lands were once joined by the Heartroot.\nWhen its light was sealed, the paths grew hollow.\nThe Warden keeps the first gate.\n\nPress E to close"
	sigil_icon.visible = false
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	note_panel.visible = true
	_save_progress()
	queue_redraw()

func _open_sigil() -> void:
	note_open = true
	if not secret_found:
		secret_found = true
		player.heal_full()
	note_text.text = "THE CAVE SIGIL\n\nThe Heartroot once touched even the deepest stone.\nIts light marked the path between the four lands.\nWhen that light was sealed, the gates forgot their way.\n\nPress E to close"
	sigil_icon.visible = true
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	note_panel.visible = true
	_save_progress()
	queue_redraw()

func _close_note() -> void:
	note_open = false
	note_panel.visible = false
	sigil_icon.visible = false
	player.controls_enabled = true

func _on_player_attacked(hitbox: Rect2) -> void:
	game_audio.play_effect("attack")
	var p_dmg: float = player.current_posture_damage(false)
	if current_room == 2 and is_instance_valid(ledge_sentinel) and not ledge_sentinel.is_queued_for_deletion() and hitbox.intersects(Rect2(ledge_sentinel.global_position - Vector2(20, 27), Vector2(40, 54))):
		ledge_sentinel.take_hit(1.0*player.damage_multiplier(), p_dmg)
	if current_room == 2 and is_instance_valid(scout) and hitbox.intersects(Rect2(scout.global_position - Vector2(17, 20), Vector2(34, 40))):
		scout.take_hit(1.0*player.damage_multiplier(), p_dmg)
	if current_room == 2 and seal_health > 0 and hitbox.intersects(GALLERY_LAYOUT.SEAL):
		seal_health -= 1
		if seal_health <= 0:
			seal_body.queue_free()
			_show_toast("The seal breaks. Press onward.", 2.7)
			_save_progress()
	if current_room == 4 and boss.active and not boss_defeated and hitbox.intersects(boss.combat_bounds()):
		boss.take_hit(1.0*player.damage_multiplier(), p_dmg)
	if current_room == 2:
		gallery_encounters.strike(hitbox, 1.0*player.damage_multiplier(), p_dmg)
	queue_redraw()

func _on_player_bow_fired(origin: Vector2, direction: Vector2) -> void:
	game_audio.play_effect("attack")
	var candidates: Array[Node] = []
	if current_room == 2 and is_instance_valid(scout) and not scout.is_queued_for_deletion():
		candidates.append(scout)
	if current_room == 2 and is_instance_valid(ledge_sentinel) and not ledge_sentinel.is_queued_for_deletion():
		candidates.append(ledge_sentinel)
	if current_room == 4 and is_instance_valid(boss) and boss.active and not boss_defeated:
		candidates.append(boss)
	if current_room == 2:
		candidates.append_array(gallery_encounters.targets())
	var shot_target: Node = null
	var closest_distance: float = INF
	for candidate in candidates:
		var candidate_distance: float = origin.distance_to(candidate.global_position)
		if candidate_distance < closest_distance:
			closest_distance = candidate_distance
			shot_target = candidate
	var arrow := BOW_ARROW_SCRIPT.new()
	add_child(arrow)
	arrow.setup(origin, direction, shot_target, player.damage_multiplier())

func _on_player_dodged() -> void:
	game_audio.play_effect("dodge")
	if not dodge_practiced and current_room == 2 and Rect2(0,1340,690,180).has_point(player.global_position):
		dodge_practiced = true
		_show_toast("Good dodge. You can avoid danger before striking.", 2.8)
		_save_progress()

func _on_player_jumped() -> void:
	game_audio.play_effect("jump")
	if not jump_practiced:
		jump_practiced = true
		_save_progress()

func _on_player_healed() -> void:
	game_audio.play_effect("heal")
	heal_practiced = true
	_save_progress()

func _on_player_ledge_climbed() -> void:
	if not ledge_practiced:
		ledge_practiced = true
		_show_toast("Ledge climb learned. Press Jump or Up while hanging.", 3.0)
		_save_progress()

func _on_player_platform_dropped() -> void:
	if not drop_practiced:
		drop_practiced = true
		_show_toast("Drop through platforms with S + Jump.", 2.8)
		_save_progress()

func _on_player_heavy_attacked(hitbox: Rect2) -> void:
	game_audio.play_effect("heavy_attack")
	var p_dmg: float = player.current_posture_damage(true)
	if current_room == 2 and is_instance_valid(ledge_sentinel) and not ledge_sentinel.is_queued_for_deletion() and hitbox.intersects(Rect2(ledge_sentinel.global_position - Vector2(20, 27), Vector2(40, 54))):
		ledge_sentinel.take_hit(1.5*player.damage_multiplier(), p_dmg)
	if current_room == 2 and is_instance_valid(scout) and hitbox.intersects(Rect2(scout.global_position - Vector2(17, 20), Vector2(34, 40))):
		scout.take_hit(1.5*player.damage_multiplier(), p_dmg)
	if current_room == 4 and boss.active and not boss_defeated and hitbox.intersects(boss.combat_bounds()):
		boss.take_hit(1.5*player.damage_multiplier(), p_dmg)
	if current_room == 4 and inheritance.has_ability("heavy_break") and not wall_broken and navigation_system.can_break_cave_exit(artificer_rescued, player.has_heavy) and hitbox.intersects(CAVE_LAYOUT.EXIT_WALL):
		wall_broken = true
		exit_barrier.queue_free()
		_show_toast("The cracked wall shatters. The forest lies ahead.", 3.5)
		_save_progress()
	if current_room == 2:
		gallery_encounters.strike(hitbox, 1.5*player.damage_multiplier(), p_dmg)
		if player.has_heavy and gallery.try_break_heavy_wall(hitbox):
			_show_toast("The charged attack opens the gallery passage.",3.0)
			_save_progress()
	queue_redraw()

func _on_scout_defeated() -> void:
	saved_scout_defeated = true
	_spawn_will_orb(scout.global_position, 5)
	_show_toast("The scout falls. Its Will drifts toward you.", 2.6)
	_save_progress()

func _on_ledge_sentinel_defeated() -> void:
	aerial_practiced = true
	sentinel_defeated = true
	_spawn_will_orb(ledge_sentinel.global_position, 5)
	_show_toast("The ledge is clear. Jump up and continue.", 2.8)
	_save_progress()

func _on_boss_defeated() -> void:
	inheritance.on_boss_defeated("hollow_warden")
	boss_defeated = true
	game_audio.play_cave()
	_unlock_arena()
	_spawn_will_orb(boss.global_position, 50)
	_disable_defeated_boss(boss)
	player.has_heavy = true
	player.has_scimitar=true
	player.has_wrath=true
	player.equipped_weapon="scimitar"
	_show_toast("GOBLIN SCIMITAR + WRATH - U thrust; charged H breaks cracked stone", 5.0)
	artificer_rescued = true
	_save_progress()
	queue_redraw()

func _disable_defeated_boss(b: Node) -> void:
	if not is_instance_valid(b):
		return
	b.visible = false
	if "active" in b:
		b.active = false
	if "health" in b:
		b.health = 0.0
	if b is CollisionObject2D:
		b.collision_layer = 0
		b.collision_mask = 0
	for child in b.get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
			child.disabled = true
	for g in ["combat_targets", "bosses", "enemies", "mcp_watch"]:
		if b.is_in_group(g):
			b.remove_from_group(g)
	b.set_process(false)
	b.set_physics_process(false)
	if "position" in b:
		b.position = Vector2(-99999, -99999)

func _spawn_will_orb(origin: Vector2, amount: int) -> void:
	var orb := WILL_ORB.new()
	orb.amount = amount
	orb.target = player
	orb.collected.connect(_on_will_collected)
	add_child(orb)
	orb.global_position = origin

func _on_will_collected(amount: int) -> void:
	add_will(amount)

func add_will(amount: int) -> void:
	will_amount += amount
	var target_level := 1 + int(will_amount / 25)
	if target_level > player_level:
		player_level = target_level
		_show_toast("LEVEL UP! Level %d" % player_level, 3.5)
		if is_instance_valid(game_audio):
			game_audio.play_effect("menu_confirm")
	_save_progress()

func _on_player_damaged() -> void:
	if not heal_hint_shown and player.health > 0 and player.healing_charges > 0:
		heal_hint_shown = true
		_show_toast("Hurt? Press F to use a healing charge.", 3.0)

func activate_hand() -> void:
	checkpoint = Vector2(2610, 570)
	hand_activated = true
	last_hand_room = 3
	_respawn_regular_enemies()
	player.set_injured(false)
	player.has_dash = true
	player.heal_full()
	player.healing_charges = player.max_healing_charges
	if player.has_bow:
		player.bow_ammo = player.BOW_AMMO_MAX
	if player.has_gauntlet:
		player.gauntlet_charges = player.GAUNTLET_CHARGES_MAX

func save_at_hand() -> void:
	if not hand_activated:
		activate_hand()
	else:
		_respawn_regular_enemies()
	player.set_injured(false)
	player.has_dash = true
	player.heal_full()
	player.healing_charges = player.max_healing_charges
	if player.has_bow:
		player.bow_ammo = player.BOW_AMMO_MAX
	if player.has_gauntlet:
		player.gauntlet_charges = player.GAUNTLET_CHARGES_MAX
	_save_progress()

func end_hand_meditation() -> void:
	if not player.meditation_state.is_empty() and player.meditation_state != "exit":
		game_audio.play_effect("hand_dismount")
	player.end_meditation()

func get_fast_travel_hands() -> Array[Dictionary]:
	var hands: Array[Dictionary] = []
	if hand_activated:
		hands.append({"name": "THE OPEN HAND", "room": 3, "position": Vector2(2610, 570)})
	if forest_hand_activated:
		hands.append({"name": "TWISTED FOREST HAND", "room": 8, "position": Vector2(preload("res://scripts/forest_world_layout.gd").HAND_X, 570)})
	if temple_hand_activated:
		hands.append({"name":"TEMPLE HAND", "room":9, "position":preload("res://scripts/forest_dash_galleries_layout.gd").HAND})
	return hands

func fast_travel_to_hand(destination: Dictionary) -> void:
	var destination_room: int = int(destination.get("room", -1))
	if (destination_room == 3 and not hand_activated) or (destination_room == 8 and not forest_hand_activated) or (destination_room==9 and not temple_hand_activated) or not (destination_room in [3, 8, 9]):
		return
	transitioning_room = true
	player.reset_movement_state()
	player.controls_enabled = false
	await loading_overlay.cover_room()
	if destination_room in [8,9]:
		_save_progress()
		get_tree().set_meta("arriving_room_transition", true)
		get_tree().set_meta("forest_entry_room", destination_room)
		get_tree().change_scene_to_file("res://scenes/forest_entry.tscn")
		return
	current_room = destination_room
	player.global_position = destination.position
	_set_camera_room()
	_save_progress()
	await loading_overlay.reveal_room()
	player.controls_enabled = true
	transitioning_room = false

func _respawn_regular_enemies() -> void:
	saved_scout_defeated = false
	sentinel_defeated = false
	if is_instance_valid(scout) and not scout.is_queued_for_deletion():
		scout.health = scout.max_health
		scout.posture = scout.max_posture
		scout.global_position = GALLERY_LAYOUT.SCOUT
		scout.velocity = Vector2.ZERO
		scout.hit_cooldown = 0.0
		scout.queue_redraw()
	else:
		scout = SCOUT_SCRIPT.new()
		scout.name = "Scout"
		scout.position = GALLERY_LAYOUT.SCOUT
		scout.player = player
		add_child(scout)
		scout.navigation = navigation_system
		scout.defeated.connect(_on_scout_defeated)
		scout.attack_landed.connect(func() -> void: game_audio.play_effect("enemy_attack"))
	if is_instance_valid(ledge_sentinel) and not ledge_sentinel.is_queued_for_deletion():
		ledge_sentinel.health = ledge_sentinel.max_health
		ledge_sentinel.posture = ledge_sentinel.max_posture
		ledge_sentinel.position = GALLERY_LAYOUT.SENTINEL
		ledge_sentinel.hit_cooldown = 0.0
		ledge_sentinel.is_asleep = true
		ledge_sentinel.time_since_last_seen = 0.0
		if is_instance_valid(ledge_sentinel.sprite):
			ledge_sentinel.sprite.play("sleep")
		ledge_sentinel.queue_redraw()
	else:
		ledge_sentinel = LEDGE_SENTINEL.new()
		ledge_sentinel.name = "LedgeSentinel"
		ledge_sentinel.position = GALLERY_LAYOUT.SENTINEL
		ledge_sentinel.player = player
		add_child(ledge_sentinel)
		ledge_sentinel.defeated.connect(_on_ledge_sentinel_defeated)
		ledge_sentinel.attack_landed.connect(func() -> void: game_audio.play_effect("enemy_attack"))

	gallery_encounters.reset_at_hand()
	gallery_encounters.set_active(current_room == 2)
	_set_gallery_enemies_active(current_room == 2)

func _save_progress() -> void:
	if active_save_slot <= 0:
		return
	var data: Dictionary = SAVE_SLOTS.new_slot()
	data["seconds"] = elapsed_seconds
	data["will"] = will_amount
	data["level"] = player_level
	data["healing_charges"] = player.healing_charges
	data["area"] = "Forgotten Passage"
	data["room"] = current_room
	data["checkpoint_x"] = checkpoint.x
	data["checkpoint_y"] = checkpoint.y
	data["hand_activated"] = hand_activated
	data["opening_seen"] = opening_seen
	data["last_hand_room"] = last_hand_room
	data["has_dash"] = player.has_dash
	data.merge(player.combat_save_data(),true)
	data["aerial_practiced"] = aerial_practiced
	data["sentinel_defeated"] = sentinel_defeated
	data["jump_practiced"] = jump_practiced
	data["dodge_practiced"] = dodge_practiced
	data["drop_practiced"] = drop_practiced
	data["ledge_practiced"] = ledge_practiced
	data["heal_practiced"] = heal_practiced
	data["dash_gap_practiced"] = dash_gap_practiced
	data["seal_broken"] = seal_health <= 0
	data["scout_defeated"] = saved_scout_defeated or not is_instance_valid(scout) or scout.is_queued_for_deletion()
	data["boss_defeated"] = boss_defeated
	data["artificer_rescued"] = artificer_rescued
	data["has_heavy"] = player.has_heavy
	data["bow_boss_defeated"] = bow_boss_defeated
	data["has_bow"] = player.has_bow
	data["bow_ammo"] = player.bow_ammo
	data["bow_tutorial_practiced"] = bow_tutorial_practiced
	data["forest_hand_activated"] = forest_hand_activated
	data["temple_hand_activated"] = temple_hand_activated
	data["temple_guardian_defeated"]=temple_guardian_defeated
	data["is_injured"] = player.is_injured
	data["has_dash"] = player.has_dash
	data["has_air_dash"] = player.has_air_dash
	data["wall_broken"] = wall_broken
	data["secret_found"] = secret_found
	data["note_found"] = note_found
	data["cave_shortcut_open"] = cave_shortcut_open
	data["gallery_defeated"] = gallery_defeated.duplicate()
	data["gallery_cache_found"] = gallery_cache_found
	data["gallery_west_open"] = gallery_west_open
	data["gallery_east_open"] = gallery_east_open
	data["gallery_heavy_open"] = gallery_heavy_open
	data["watch_cache_found"] = watch_cache_found
	if not saved_data.is_empty():
		for key in ["forest_smash_open", "forest_sec4_cache_found", "forest_sec9_cache_found", "forest_hand_activated", "temple_hand_activated", "temple_guardian_defeated", "rabbit_boss_defeated", "ironback_boss_defeated", "has_heavy_smash", "forest_defeated"]:
			if saved_data.has(key):
				data[key] = saved_data[key]
	data["visited_rooms"] = visited_rooms.duplicate()
	var result: Error = SAVE_SLOTS.write_slot(active_save_slot, data, save_root)
	if result != OK:
		push_error("Could not save slot %d: %s" % [active_save_slot, error_string(result)])

func _exit_tree() -> void:
	if is_instance_valid(player):
		_save_progress()

func _on_player_died() -> void:
	if respawning or complete:
		return
	respawning = true
	player.controls_enabled = false
	player.start_death_animation()
	_show_toast("The passage remembers you...", 2.0)
	get_tree().create_timer(1.0).timeout.connect(_respawn)

func _respawn() -> void:
	_unlock_arena()
	game_audio.play_cave()
	player.healing_charges = player.max_healing_charges
	player.health = player.max_health
	if (last_hand_room==8 and forest_hand_activated) or (last_hand_room==9 and temple_hand_activated):
		_save_progress()
		get_tree().set_meta("forest_entry_room", last_hand_room)
		get_tree().set_meta("arriving_room_transition", true)
		get_tree().change_scene_to_file("res://scenes/forest_entry.tscn")
		return
	player.global_position = checkpoint
	current_room = _room_for_x(checkpoint.x)
	_set_camera_room()
	player.reset_movement_state()
	if not hand_activated:
		player.set_injured(true)
		player.health = player.injured_max_health
		player.healing_charges = 1
		player.has_dash = false
	else:
		player.set_injured(false)
		player.heal_full()
		player.healing_charges = player.max_healing_charges
		player.has_dash = true
	_respawn_regular_enemies()
	player.controls_enabled = true
	respawning = false
	if boss.active and not boss_defeated:
		boss.active = false
		boss.state = "idle"
		boss.state_time = 0.0
		boss.health = boss.max_health
		boss.position = Vector2(3510, 553)
		boss.reset_encounter()
		boss.attack_count = 0
	_show_toast("Try again. Read the enemy's tell.", 2.4)
	_save_progress()

func _room_for_x(x: float) -> int:
	if x < 0.0:
		return 1
	if x < 1700.0:
		return 2
	if x < 3070.0:
		return 3
	return 4

func _show_toast(message: String, duration: float) -> void:
	toast = message
	toast_time = duration

func _update_hud() -> void:
	hud.health = player.health
	hud.max_health = player.max_health
	hud.is_injured = player.is_injured
	hud.level = player_level
	hud.will_amount = will_amount
	hud.healing_charges = player.healing_charges
	hud.max_healing_charges = player.max_healing_charges
	hud.has_dash = player.has_dash
	hud.equipped_weapon=player.equipped_weapon
	hud.has_heavy = player.has_heavy
	hud.has_bow = player.has_bow
	hud.bow_ammo = player.bow_ammo
	hud.gauntlet_charges = player.gauntlet_charges
	hud.boss_health = boss.health if boss.active and not boss_defeated else 0
	hud.boss_max_health = int(boss.max_health)
	hud.boss_posture = boss.posture if boss.active and not boss_defeated else 0.0
	hud.boss_max_posture = boss.max_posture
	hud.boss_title = "GOBLIN SCIMITAR LORD"
	hud.finished = complete
	hud.prompt = _cave_prompt() if not note_open and not respawning and not transitioning_room else ""
	hud.notice = toast if toast_time > 0.0 else ""

func _cave_prompt() -> String:
	if player.waking_up: return ""
	var position := player.global_position
	if not player.meditation_state.is_empty():
		return ""
	if current_room == 1:
		if position.x < -1000.0:
			return "The gate beyond the Watch is sealed."
	if current_room == 2:
		if not gallery_cache_found and position.distance_to(CAVE_LAYOUT.GALLERY_CACHE) < 80.0:
			return "[E] Take the traveller's offering"
		if not secret_found and position.distance_to(SECRET_POSITION) < 90.0:
			return "[E] Read the Cave Sigil"
		if not gallery_west_open and position.distance_to(GALLERY_LAYOUT.WEST_WINCH) < 80:
			return "[E] Open the entrance return passage"
		if not gallery_east_open and position.distance_to(GALLERY_LAYOUT.EAST_WINCH) < 80:
			return "[E] Open the eastern gallery return passage"
		if not gallery_heavy_open and GALLERY_LAYOUT.HEAVY_WALL.grow(100).has_point(position):
			return "Hold [H], then release to break the cracked stone" if player.has_heavy else "Cracked stone. Return after defeating the goblin."
		if GALLERY_LAYOUT.SMASH_FLOOR.grow(70).has_point(position):
			return "A fractured floor. A downward force is needed."
		if not jump_practiced and (GALLERY_LAYOUT.ENTRANCE_DOOR.grow(180).has_point(position) or Rect2(0,1340,380,180).has_point(position)):
			return "[A / D] Move    [SPACE] Jump"
		if not dodge_practiced and Rect2(300,1340,320,180).has_point(position):
			return "[K / SHIFT] Dodge"
		if not aerial_practiced and Rect2(910,1280,280,240).has_point(position):
			return "[J / X] Strike    Strike in the air or approach from behind"
		if not drop_practiced and Rect2(3620, -110, 180, 160).has_point(position):
			return "Hold [S / DOWN] and press [SPACE] to drop"
		if seal_health > 0 and GALLERY_LAYOUT.SEAL.grow(180).has_point(position):
			return "[J / X] Break the seal"
	if current_room == 3:
		if not cave_shortcut_open and position.distance_to(CAVE_LAYOUT.WINCH) < 75.0:
			return "[E] Lower the return bridge"
		if position.distance_to(hand_chair.global_position) < 80.0:
			return "[E] Rest at the hand"
		if not note_found and position.distance_to(NOTE_POSITION) < 85.0:
			return "[E] Read the weathered note"
		if not ledge_practiced and position.x > 1870.0 and position.x < 2110.0:
			return "Jump to the edge, then press [SPACE / UP] to climb"
		if not dash_gap_practiced and position.x > 2090.0 and position.x < 2450.0:
			return "[SPACE] Jump, then [K / SHIFT] dash across" if player.has_dash else "[SPACE] Jump across the basin ledges"
	if current_room == 4 and inheritance.has_ability("heavy_break") and not wall_broken and position.x > 3700.0:
		return "Hold [H], then release to break the cracked stone"
	if not heal_practiced and player.health < player.max_health and player.healing_charges > 0:
		return "[F] Heal when you have space"
	return ""

func _draw() -> void:
	if current_room == 2:
		gallery.draw_objects(self)
		return
	for room in range(1, 5):
		draw_colored_polygon(CAVE_LAYOUT.roof_polygon(room), Color(0.045, 0.075, 0.105))
		var edge := CAVE_LAYOUT.roof_edge(room)
		draw_polyline(edge, Color(0.14, 0.21, 0.24), 4)
		for i in range(0, edge.size() - 2, 6):
			var tip: Vector2 = edge[i]
			draw_rect(Rect2(tip + Vector2(6, -20), Vector2(28, 5)), Color(0.075, 0.12, 0.15))
			draw_polyline(PackedVector2Array([tip + Vector2(8, -62), tip + Vector2(8, -44), tip + Vector2(24, -44), tip + Vector2(24, -30)]), Color(0.025, 0.045, 0.065), 4)
	for rect in platforms:
		if rect==Rect2(-1200,600,1200,120): continue
		_draw_cave_terrain(rect)
	_draw_room_objects()
	draw_rect(Rect2(2567, 594, 86, 6), Color(0.035, 0.075, 0.10, 0.62))
	if is_instance_valid(arena_barrier) and not arena_barrier.is_queued_for_deletion():
		draw_rect(Rect2(3070, -60, 32, 660), Color(0.12, 0.18, 0.23))
		for y in range(-48, 600, 32):
			draw_rect(Rect2(3076, y, 20, 12), Color(0.33, 0.73, 0.72))
			draw_rect(Rect2(3081, y + 4, 10, 4), Color(0.72, 0.98, 0.83))
	for x in [0.0, 1700.0, 3070.0, 4450.0]:
		draw_rect(Rect2(x - 8, 280, 16, 320), Color(0.17, 0.24, 0.31, 0.65))
		draw_rect(Rect2(x - 28, 270, 56, 18), Color(0.31, 0.45, 0.48))
	draw_rect(Rect2(-1160, 380, 32, 220), Color(0.33, 0.30, 0.41))
	draw_rect(Rect2(-1152, 405, 16, 170), Color(0.11, 0.17, 0.26))
	draw_circle(Vector2(-1144, 490), 11, Color(0.81, 0.65, 0.38))
	if not secret_found:
		draw_rect(Rect2(499, 467, 22, 20), Color(0.24, 0.24, 0.30))
		draw_circle(SECRET_POSITION, 6, Color(0.96, 0.79, 0.39))
		draw_circle(SECRET_POSITION, 13, Color(0.96, 0.79, 0.39, 0.15))
	_draw_cave_terrain(Rect2(1330, 540, 20, 60))
	_draw_cave_terrain(Rect2(1510, 350, 32, 190))
	if not note_found:
		draw_rect(Rect2(NOTE_POSITION - Vector2(12, 5), Vector2(24, 20)), Color(0.20, 0.27, 0.29))
		draw_rect(Rect2(NOTE_POSITION + Vector2(-6, -1), Vector2(12, 13)), Color(0.88, 0.79, 0.57))
	if seal_health > 0:
		draw_rect(Rect2(1680, 300, 32, 300), Color(0.28, 0.51, 0.57))
		draw_rect(Rect2(1687, 316, 18, 268), Color(0.15, 0.23, 0.32))
		for i in seal_health:
			draw_circle(Vector2(1696, 521 + i * 23), 5, Color(0.95, 0.78, 0.44))
	if not wall_broken:
		_draw_cracked_stone(CAVE_LAYOUT.EXIT_WALL)
	for x in [3120.0, 3800.0]:
		draw_rect(Rect2(x, 380, 35, 220), Color(0.17, 0.20, 0.28))
		draw_rect(Rect2(x - 8, 370, 51, 18), Color(0.29, 0.31, 0.39))
	draw_rect(Rect2(4370, 390, 15, 210), Color(0.27, 0.36, 0.37))
	draw_rect(Rect2(4436, 390, 15, 210), Color(0.27, 0.36, 0.37))
	draw_rect(Rect2(4370, 380, 81, 18), Color(0.38, 0.49, 0.47))
	draw_rect(Rect2(4385, 398, 51, 202), Color(0.07, 0.19, 0.18, 0.6))
	for leaf in 5:
		draw_rect(Rect2(4390 + leaf * 10, 416 + posmod(leaf * 13, 4) * 15, 6, 13), Color(0.24, 0.49, 0.33))

func _draw_room_objects() -> void:
	if current_room == 3 and artificer_rescued:
		_draw_artificer()
	if not gallery_cache_found:
		var at := CAVE_LAYOUT.GALLERY_CACHE
		draw_circle(at, 20, Color(0.44, 0.94, 0.76, 0.10))
		draw_rect(Rect2(at - Vector2(10, 11), Vector2(20, 25)), Color(0.22, 0.43, 0.40))
		draw_rect(Rect2(at - Vector2(4, 7), Vector2(8, 12)), Color(0.81, 1.0, 0.78))
	var winch := CAVE_LAYOUT.WINCH
	draw_rect(Rect2(winch + Vector2(-11, 7), Vector2(22, 34)), Color(0.26, 0.31, 0.31))
	draw_circle(winch, 16, Color(0.10, 0.16, 0.18))
	draw_arc(winch, 14, 0, TAU, 12, Color(0.67, 0.59, 0.38), 4)
	draw_line(winch - Vector2(14, 0), winch + Vector2(14, 0), Color(0.67, 0.59, 0.38), 4)
	if cave_shortcut_open:
		for x in range(2165, 2450, 24):
			draw_rect(Rect2(x, 600, 18, 8), Color(0.54, 0.46, 0.32))
		draw_line(Vector2(2160, 618), Vector2(2450, 618), Color(0.20, 0.24, 0.24), 4)
	else:
		# Stowed vertically, so the inactive bridge cannot be mistaken for a floor.
		for y in range(626, 760, 22):
			draw_rect(Rect2(2450, y, 12, 16), Color(0.28, 0.26, 0.22))

func _draw_artificer() -> void:
	# Stand beside the Hand without adding collision or interaction behavior.
	var at := Vector2(2690, 546)
	var coat := Color(0.28, 0.39, 0.42)
	var brass := Color(0.78, 0.61, 0.35)
	draw_rect(Rect2(at + Vector2(-13, 15), Vector2(10, 38)), coat)
	draw_rect(Rect2(at + Vector2(3, 15), Vector2(10, 38)), coat)
	draw_rect(Rect2(at + Vector2(-16, -15), Vector2(32, 43)), coat)
	draw_rect(Rect2(at + Vector2(-10, -7), Vector2(20, 33)), brass)
	draw_circle(at + Vector2(0, -25), 11, Color(0.72, 0.63, 0.51))
	draw_rect(Rect2(at + Vector2(-13, -33), Vector2(26, 8)), coat)
	draw_rect(Rect2(at + Vector2(-9, -27), Vector2(18, 5)), brass)
	draw_line(at + Vector2(17, -7), at + Vector2(23, 18), brass, 5)
	draw_rect(Rect2(at + Vector2(18, 13), Vector2(16, 8)), Color(0.52, 0.58, 0.59))
	draw_string(ThemeDB.fallback_font, at + Vector2(-28, -45), "Artificer", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.88, 0.79, 0.57))

func _draw_cracked_stone(rect: Rect2) -> void:
	draw_rect(rect, Color(0.30, 0.35, 0.37))
	draw_rect(rect.grow(-4), Color(0.20, 0.25, 0.28))
	var crack := PackedVector2Array()
	for i in range(7):
		crack.append(Vector2(rect.position.x + rect.size.x * (0.32 if i % 2 == 0 else 0.68), rect.position.y + 4 + (rect.size.y - 8) * i / 6.0))
	draw_polyline(crack, Color(0.76, 0.59, 0.35), 3)

func _draw_cave_terrain(rect: Rect2) -> void:
	_draw_cave_terrain_on(self, rect)

func _draw_cave_terrain_on(canvas: Node2D, rect: Rect2) -> void:
	var stone := Color(0.14, 0.20, 0.24)
	var dark := Color(0.08, 0.13, 0.18)
	var mid := Color(0.19, 0.27, 0.30)
	var light := Color(0.39, 0.56, 0.55)
	canvas.draw_rect(rect, stone)
	var tile_count := ceili(rect.size.x / 16.0)
	var row_count := ceili(rect.size.y / 16.0)
	for column in tile_count:
		var x := rect.position.x + column * 16.0
		var tile_width := minf(16.0, rect.end.x - x)
		var seed := int(x / 16.0)
		var cap_height := 5.0 + float(posmod(seed * 7, 3)) * 2.0
		canvas.draw_rect(Rect2(x, rect.position.y, tile_width, cap_height), light)
		canvas.draw_rect(Rect2(x + 3, rect.position.y + cap_height, minf(9.0, tile_width - 3.0), 3), mid)
		for row in row_count:
			var y := rect.position.y + row * 16.0
			if y + 2.0 >= rect.end.y:
				continue
			if posmod(seed * 11 + row * 7, 5) == 0:
				canvas.draw_rect(Rect2(x + 2, y + 10, 5, 3), dark)
				canvas.draw_rect(Rect2(x + 8, y + 6, 4, 3), mid)
			elif posmod(seed * 3 + row * 13, 7) == 0:
				canvas.draw_rect(Rect2(x + 7, y + 12, 7, 2), light)
			elif posmod(seed * 7 + row * 3, 11) == 0:
				canvas.draw_rect(Rect2(x + 11, y + 8, 3, 3), mid)
		if rect.size.y > 20.0 and posmod(seed, 6) == 0:
			canvas.draw_rect(Rect2(x + 13, rect.position.y + 8, 2, 20), dark)

func gallery_map_state() -> Dictionary:
	return {"heavy_open":gallery_heavy_open}
