extends Node2D

const PLAYER = preload("res://scripts/player.gd")
const HUD = preload("res://scripts/hud.gd")
const SLOTS = preload("res://scripts/save_slots.gd")
const OVERLAY = preload("res://scripts/loading_overlay.gd")
const BACKDROP = preload("res://assets/forest_backdrop.png")
const MAP = preload("res://scripts/world_map.gd")
const AUDIO = preload("res://scripts/game_audio.gd")
const MENU = preload("res://scripts/game_menu.gd")
const HAND_MENU = preload("res://scripts/hand_menu.gd")
const HAND_ART = preload("res://assets/hand_chair.png")
const HUNTER = preload("res://scripts/bow_boss.gd")
const ARROW = preload("res://scripts/bow_arrow.gd")
const SCOUT = preload("res://scripts/scout.gd")
const BOUNDS := [Vector2(0, 1200), Vector2(1200, 2600), Vector2(2600, 4000), Vector2(4000, 5400)]
const HAND_X := 4380.0

var player: CharacterBody2D
var hud: Control
var pause_menu: CanvasLayer
var loading_overlay: CanvasLayer
var world_map: CanvasLayer
var game_audio: Node
var game_menu: CanvasLayer
var hand_menu: CanvasLayer
var hand_chair: Sprite2D
var bow_boss: Node2D
var training_scouts: Array[Node2D] = []
var arena_entrance: StaticBody2D
var arena_exit: StaticBody2D
var visited_rooms: Array[int] = [2]
var current_room := 5
var active_save_slot := 0
var save_root := "user://"
var elapsed_seconds := 0.0
var will_amount := 0
var player_level := 1
var save_timer := 0.0
var transitioning := false
var death_pending := false
var bow_boss_defeated := false
var bow_tutorial_practiced := false
var bow_hint_shown := false
var forest_hand_activated := false
var last_hand_room := 2
var saved_data: Dictionary = {}
var toast := ""
var toast_time := 0.0

func _ready() -> void:
	game_audio = AUDIO.new()
	add_child(game_audio)
	game_audio.play_forest()
	if get_tree().has_meta("active_save_slot"):
		active_save_slot = int(get_tree().get_meta("active_save_slot"))
		save_root = str(get_tree().get_meta("save_root", "user://"))
		saved_data = SLOTS.load_slot(active_save_slot, save_root)
		elapsed_seconds = float(saved_data.get("seconds", 0.0))
		will_amount = int(saved_data.get("will", 0))
		player_level = int(saved_data.get("level", 1))
		visited_rooms.assign(saved_data.get("visited_rooms", [2]))
		bow_boss_defeated = bool(saved_data.get("bow_boss_defeated", false))
		bow_tutorial_practiced = bool(saved_data.get("bow_tutorial_practiced", false))
		forest_hand_activated = bool(saved_data.get("forest_hand_activated", false))
		last_hand_room = int(saved_data.get("last_hand_room", 8 if forest_hand_activated else 3 if bool(saved_data.get("hand_activated", false)) else 2))
		if str(saved_data.get("area", "")) == "The Twisted Forest":
			current_room = clampi(int(saved_data.get("room", 5)), 5, 8)
	if get_tree().has_meta("forest_entry_room"):
		current_room = clampi(int(get_tree().get_meta("forest_entry_room")), 5, 8)
		get_tree().remove_meta("forest_entry_room")
	_mark_room_visited(current_room)
	for bounds in BOUNDS:
		_solid(Rect2(bounds.x, 600, bounds.y - bounds.x, 120))
		var backdrop := TextureRect.new()
		backdrop.position = Vector2(bounds.x, -60)
		backdrop.size = Vector2(bounds.y - bounds.x, 780)
		backdrop.z_index = -100
		backdrop.texture = BACKDROP
		backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		backdrop.stretch_mode = TextureRect.STRETCH_SCALE
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(backdrop)
	_solid(Rect2(5370, -60, 30, 660))
	player = PLAYER.new()
	player.position = Vector2(HAND_X, 570) if current_room == 8 else Vector2(120, 570) if current_room == 5 else Vector2(BOUNDS[current_room - 5].x + 90, 570)
	player.has_dash = true
	player.has_heavy = bool(saved_data.get("has_heavy", false))
	player.has_bow = bool(saved_data.get("has_bow", bow_boss_defeated))
	player.bow_ammo = int(saved_data.get("bow_ammo", 3)) if player.has_bow else 0
	player.healing_charges = int(saved_data.get("healing_charges", 3))
	add_child(player)
	player.healed.connect(func() -> void: game_audio.play_effect("heal"))
	player.healed.connect(_save_progress)
	player.attacked.connect(_on_attack)
	player.heavy_attacked.connect(_on_heavy)
	player.bow_fired.connect(_on_bow)
	player.jumped.connect(func() -> void: game_audio.play_effect("jump"))
	player.dodged.connect(func() -> void: game_audio.play_effect("dodge"))
	player.died.connect(_on_death)
	_set_camera()
	bow_boss = HUNTER.new()
	bow_boss.position = Vector2(3300, 553)
	bow_boss.player = player
	add_child(bow_boss)
	bow_boss.defeated.connect(_on_hunter_defeated)
	bow_boss.attack_cued.connect(func(_cue: String) -> void: game_audio.play_effect("enemy_attack"))
	bow_boss.visible = not bow_boss_defeated
	for x in [4750.0, 5100.0]:
		var scout := SCOUT.new()
		scout.position = Vector2(x, 579)
		scout.player = player
		add_child(scout)
		scout.attack_landed.connect(func() -> void: game_audio.play_effect("enemy_attack"))
		training_scouts.append(scout)
	hand_chair = Sprite2D.new()
	hand_chair.texture = HAND_ART
	hand_chair.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hand_chair.scale = Vector2(0.096, 0.096)
	hand_chair.position = Vector2(HAND_X, 546)
	hand_chair.z_index = 2
	add_child(hand_chair)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = HUD.new()
	layer.add_child(hud)
	pause_menu = preload("res://scripts/pause_menu.gd").new()
	add_child(pause_menu)
	loading_overlay = OVERLAY.new()
	add_child(loading_overlay)
	world_map = MAP.new()
	add_child(world_map)
	hand_menu = HAND_MENU.new()
	hand_menu.world = self
	add_child(hand_menu)
	hand_menu.title.text = "TWISTED FOREST HAND"
	game_menu = MENU.new()
	game_menu.world = self
	add_child(game_menu)
	if get_tree().has_meta("arriving_room_transition"):
		get_tree().remove_meta("arriving_room_transition")
		loading_overlay.reveal_room()
	_save_progress()

func _solid(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	return body

func _process(delta: float) -> void:
	elapsed_seconds += delta
	save_timer += delta
	toast_time = maxf(0.0, toast_time - delta)
	if save_timer >= 10.0:
		save_timer = 0.0
		_save_progress()
	if not transitioning:
		_check_transition()
		if player.global_position.y > 760.0:
			_recover_fall()
	if current_room == 7 and not bow_boss_defeated and not bow_boss.active and not transitioning:
		bow_boss.active = true
		bow_boss.state_time = 0.65
		arena_entrance = _solid(Rect2(2600, -60, 32, 660))
		arena_exit = _solid(Rect2(4000, -60, 32, 660))
		game_audio.play_boss()
		_show_toast("BOW HUNTER  ·  Close the distance between volleys", 3.5)
	if current_room == 8 and player.has_bow and not bow_tutorial_practiced and not bow_hint_shown:
		bow_hint_shown = true
		_show_toast("Press L to fire. Meditate at the hand to refill arrows.", 4.0)
	_update_hud()
	queue_redraw()

func _check_transition() -> void:
	var x := player.global_position.x
	if current_room == 5 and x <= -14.0:
		_return_to_cave()
		return
	if current_room == 7 and bow_boss.active and not bow_boss_defeated:
		return
	var bounds: Vector2 = BOUNDS[current_room - 5]
	if current_room > 5 and x <= bounds.x:
		_change_room(current_room - 1, bounds.x - 80.0)
	elif current_room < 8 and x >= bounds.y:
		_change_room(current_room + 1, bounds.y + 80.0)

func _recover_fall() -> void:
	var bounds: Vector2 = BOUNDS[current_room - 5]
	player.global_position = Vector2(clampf(player.global_position.x, bounds.x + 90.0, bounds.y - 120.0), 570)
	player.velocity = Vector2.ZERO
	player.take_damage(1, player.global_position.x + 1.0)

func _change_room(destination: int, entry_x: float) -> void:
	transitioning = true
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	await loading_overlay.cover_room()
	if death_pending:
		return
	current_room = destination
	_mark_room_visited(current_room)
	player.global_position = Vector2(entry_x, 570)
	_set_camera()
	_save_progress()
	await loading_overlay.reveal_room()
	if death_pending:
		return
	player.controls_enabled = true
	transitioning = false

func _set_camera() -> void:
	var camera := player.get_node("Camera2D") as Camera2D
	var bounds: Vector2 = BOUNDS[current_room - 5]
	camera.limit_left = int(bounds.x)
	camera.limit_right = int(bounds.y)
	camera.reset_smoothing()

func _return_to_cave() -> void:
	transitioning = true
	player.controls_enabled = false
	_save_progress()
	await loading_overlay.cover_room()
	if death_pending:
		return
	get_tree().set_meta("arriving_room_transition", true)
	get_tree().set_meta("cave_entry_x", 4370.0)
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")

func _unlock_arena() -> void:
	if is_instance_valid(arena_entrance):
		arena_entrance.queue_free()
	if is_instance_valid(arena_exit):
		arena_exit.queue_free()
	arena_entrance = null
	arena_exit = null

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_TAB:
			if not transitioning and not hand_menu.visible and not world_map.visible and not get_tree().paused:
				game_menu.open_section("status")
				get_viewport().set_input_as_handled()
		KEY_M:
			if not transitioning and not hand_menu.visible and not get_tree().paused:
				world_map.show_map(visited_rooms, _completed_rooms(), current_room, get_fast_travel_hands())
				get_viewport().set_input_as_handled()
		KEY_E:
			if current_room == 8 and not hand_menu.visible and player.meditation_state.is_empty() and player.global_position.distance_to(hand_chair.global_position) < 70.0:
				activate_hand()
				player.begin_meditation(hand_chair.global_position)
				game_audio.play_effect("hand_mount")
				hand_menu.show_menu()
				get_viewport().set_input_as_handled()

func _on_attack(hitbox: Rect2) -> void:
	game_audio.play_effect("attack")
	if bow_boss.active and not bow_boss_defeated and hitbox.intersects(Rect2(bow_boss.global_position - Vector2(42, 55), Vector2(84, 100))):
		bow_boss.take_hit(1.0)
	for scout in training_scouts:
		if is_instance_valid(scout) and not scout.is_queued_for_deletion() and hitbox.intersects(Rect2(scout.global_position - Vector2(17, 20), Vector2(34, 40))):
			scout.take_hit(1.0)

func _on_heavy(hitbox: Rect2) -> void:
	game_audio.play_effect("heavy_attack")
	if bow_boss.active and not bow_boss_defeated and hitbox.intersects(Rect2(bow_boss.global_position - Vector2(42, 55), Vector2(84, 100))):
		bow_boss.take_hit(1.5)

func _on_bow(origin: Vector2, direction: Vector2) -> void:
	game_audio.play_effect("attack")
	if current_room == 8 and not bow_tutorial_practiced:
		bow_tutorial_practiced = true
		_show_toast("Good shot. Meditate at the hand to refill arrows.", 3.0)
		_save_progress()
	var target: Node = null
	for scout in training_scouts:
		if is_instance_valid(scout) and not scout.is_queued_for_deletion() and (target == null or origin.distance_to(scout.global_position) < origin.distance_to(target.global_position)):
			target = scout
	var arrow := ARROW.new()
	add_child(arrow)
	arrow.setup(origin, direction, target)

func _on_hunter_defeated() -> void:
	bow_boss_defeated = true
	bow_boss.active = false
	bow_boss.visible = false
	game_audio.play_forest()
	_unlock_arena()
	player.has_bow = true
	player.bow_ammo = player.BOW_AMMO_MAX
	_show_toast("BOW INHERITED  ·  Press L to fire. Meditate to refill arrows.", 4.0)
	_save_progress()

func _on_death() -> void:
	if death_pending:
		return
	death_pending = true
	transitioning = true
	player.controls_enabled = false
	player.start_death_animation()
	await get_tree().create_timer(1.0).timeout
	_unlock_arena()
	if last_hand_room != 8 or not forest_hand_activated:
		_save_progress()
		get_tree().set_meta("cave_entry_x", float(saved_data.get("checkpoint_x", 120.0)) if last_hand_room == 3 and bool(saved_data.get("hand_activated", false)) else 120.0)
		get_tree().set_meta("arriving_room_transition", true)
		get_tree().change_scene_to_file("res://scenes/tutorial.tscn")
		return
	if not bow_boss_defeated:
		bow_boss.active = false
		bow_boss.health = bow_boss.max_health
		bow_boss.position = Vector2(3300, 553)
		bow_boss.state = "idle"
		bow_boss.state_time = 0.0
		bow_boss.attack_cooldown = 0.0
	game_audio.play_forest()
	current_room = 8 if forest_hand_activated else 5
	player.global_position = Vector2(HAND_X if forest_hand_activated else 120.0, 570)
	player.reset_movement_state()
	player.heal_full()
	_set_camera()
	player.controls_enabled = true
	death_pending = false
	transitioning = false
	_save_progress()

func activate_hand() -> void:
	forest_hand_activated = true
	last_hand_room = 8
	player.heal_full()
	player.healing_charges = player.max_healing_charges
	if player.has_bow:
		player.bow_ammo = player.BOW_AMMO_MAX

func save_at_hand() -> void:
	activate_hand()
	_save_progress()

func end_hand_meditation() -> void:
	game_audio.play_effect("hand_dismount")
	player.end_meditation()

func get_fast_travel_hands() -> Array[Dictionary]:
	var hands: Array[Dictionary] = []
	if bool(saved_data.get("hand_activated", false)):
		hands.append({"name": "THE OPEN HAND", "room": 3, "position": Vector2(2610, 570)})
	if forest_hand_activated:
		hands.append({"name": "TWISTED FOREST HAND", "room": 8, "position": Vector2(HAND_X, 570)})
	return hands

func fast_travel_to_hand(destination: Dictionary) -> void:
	var room := int(destination.get("room", -1))
	if room == 3:
		transitioning = true
		_save_progress()
		await loading_overlay.cover_room()
		if death_pending:
			return
		get_tree().set_meta("arriving_room_transition", true)
		get_tree().set_meta("cave_entry_x", 2610.0)
		get_tree().change_scene_to_file("res://scenes/tutorial.tscn")
	elif room == 8 and forest_hand_activated:
		transitioning = true
		await loading_overlay.cover_room()
		if death_pending:
			return
		current_room = 8
		player.global_position = Vector2(HAND_X, 570)
		_set_camera()
		_save_progress()
		await loading_overlay.reveal_room()
		if death_pending:
			return
		transitioning = false

func _mark_room_visited(room: int) -> void:
	if not visited_rooms.has(room):
		visited_rooms.append(room)
		visited_rooms.sort()

func _completed_rooms() -> Array[int]:
	var completed: Array[int] = []
	for room in [5, 6]:
		if visited_rooms.has(room):
			completed.append(room)
	if visited_rooms.has(1) and bool(saved_data.get("watch_cache_found", false)):
		completed.append(1)
	if visited_rooms.has(2) and bool(saved_data.get("secret_found", false)) and bool(saved_data.get("gallery_cache_found", false)):
		completed.append(2)
	if visited_rooms.has(3) and bool(saved_data.get("note_found", false)):
		completed.append(3)
	if visited_rooms.has(4) and bool(saved_data.get("boss_defeated", false)):
		completed.append(4)
	if visited_rooms.has(7) and bow_boss_defeated:
		completed.append(7)
	if visited_rooms.has(8) and bow_tutorial_practiced:
		completed.append(8)
	return completed

func _show_toast(message: String, duration: float) -> void:
	toast = message
	toast_time = duration

func _update_hud() -> void:
	hud.health = player.health
	hud.max_health = player.max_health
	hud.level = player_level
	hud.will_amount = will_amount
	hud.healing_charges = player.healing_charges
	hud.max_healing_charges = player.max_healing_charges
	hud.has_dash = player.has_dash
	hud.has_heavy = player.has_heavy
	hud.has_bow = player.has_bow
	hud.bow_ammo = player.bow_ammo
	hud.area = "THE TWISTED FOREST"
	hud.boss_health = bow_boss.health if bow_boss.active and not bow_boss_defeated else 0
	hud.boss_max_health = int(bow_boss.max_health)
	hud.boss_title = "BOW HUNTER"
	hud.notice = toast if toast_time > 0.0 else ""
	hud.queue_redraw()

func _save_progress() -> void:
	if active_save_slot <= 0:
		return
	var data: Dictionary = saved_data.duplicate()
	if data.is_empty():
		data = SLOTS.new_slot()
	data["area"] = "The Twisted Forest"
	data["room"] = current_room
	data["seconds"] = elapsed_seconds
	data["will"] = will_amount
	data["level"] = player_level
	data["healing_charges"] = player.healing_charges
	data["has_dash"] = player.has_dash
	data["has_heavy"] = player.has_heavy
	data["has_bow"] = player.has_bow
	data["bow_ammo"] = player.bow_ammo
	data["bow_boss_defeated"] = bow_boss_defeated
	data["bow_tutorial_practiced"] = bow_tutorial_practiced
	data["forest_hand_activated"] = forest_hand_activated
	data["last_hand_room"] = last_hand_room
	data["visited_rooms"] = visited_rooms.duplicate()
	var result: Error = SLOTS.write_slot(active_save_slot, data, save_root)
	if result != OK:
		push_error("Could not save forest progress: %s" % error_string(result))
	saved_data = data

func _exit_tree() -> void:
	if is_instance_valid(player):
		_save_progress()

func _draw() -> void:
	for bounds in BOUNDS:
		draw_rect(Rect2(bounds.x, 600, bounds.y - bounds.x, 120), Color(0.18, 0.26, 0.22))
		draw_rect(Rect2(bounds.x, 600, bounds.y - bounds.x, 10), Color(0.35, 0.51, 0.32))
	for x in [350.0, 940.0, 1500.0, 2100.0, 2880.0, 3700.0, 4600.0, 5250.0]:
		draw_rect(Rect2(x, 390, 27, 210), Color(0.16, 0.26, 0.23))
		draw_circle(Vector2(x + 13, 360), 64, Color(0.12, 0.29, 0.22, 0.72))
	for x in [1200.0, 2600.0, 4000.0]:
		draw_rect(Rect2(x - 8, 280, 16, 320), Color(0.15, 0.27, 0.26, 0.65))
	if is_instance_valid(arena_entrance) and not arena_entrance.is_queued_for_deletion():
		draw_rect(Rect2(2600, -60, 32, 660), Color(0.31, 0.44, 0.34))
	if is_instance_valid(arena_exit) and not arena_exit.is_queued_for_deletion():
		draw_rect(Rect2(4000, -60, 32, 660), Color(0.31, 0.44, 0.34))
	draw_rect(Rect2(5370, 310, 30, 290), Color(0.17, 0.31, 0.25))
	draw_line(Vector2(5385, 350), Vector2(5334, 293), Color(0.25, 0.42, 0.30), 12)
	draw_string(ThemeDB.fallback_font, Vector2(90, 450), "THE TWISTED FOREST", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color(0.82, 0.95, 0.77))
	if player.has_bow:
		draw_string(ThemeDB.fallback_font, Vector2(4280, 425), "[E] MEDITATE TO REFILL", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.91, 0.84, 0.61))
