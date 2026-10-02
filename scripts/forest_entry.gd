extends Node2D

const PLAYER = preload("res://scripts/player.gd")
const HUD = preload("res://scripts/hud.gd")
const SLOTS = preload("res://scripts/save_slots.gd")
const OVERLAY = preload("res://scripts/loading_overlay.gd")
const BACKDROP = preload("res://assets/forest_backdrop.png")
const ARRIVAL = preload("res://scripts/forest_arrival.gd")
const ARRIVAL_LAYOUT = preload("res://scripts/forest_arrival_layout.gd")
const GALLERY = preload("res://scripts/forest_gallery.gd")
const GALLERY_LAYOUT = preload("res://scripts/forest_gallery_layout.gd")
const STAIR = preload("res://scripts/forest_stair.gd")
const STAIR_LAYOUT = preload("res://scripts/forest_stair_layout.gd")
const UPPER = preload("res://scripts/forest_upper_gallery.gd")
const UPPER_LAYOUT = preload("res://scripts/forest_upper_gallery_layout.gd")
const SMASH_CORRIDOR = preload("res://scripts/forest_smash_corridor.gd")
const SMASH_LAYOUT = preload("res://scripts/forest_smash_corridor_layout.gd")
const STEPPED_GALLERY = preload("res://scripts/forest_stepped_gallery.gd")
const STEPPED_LAYOUT = preload("res://scripts/forest_stepped_gallery_layout.gd")
const ELEVATED_GALLERY=preload("res://scripts/forest_elevated_gallery.gd")
const ELEVATED_LAYOUT=preload("res://scripts/forest_elevated_gallery_layout.gd")
const RETURN_GALLERY=preload("res://scripts/forest_return_gallery.gd")
const RETURN_LAYOUT=preload("res://scripts/forest_return_gallery_layout.gd")
const SPLIT_HALL=preload("res://scripts/forest_split_hall.gd")
const SPLIT_LAYOUT=preload("res://scripts/forest_split_hall_layout.gd")
const DASH_GALLERIES=preload("res://scripts/forest_dash_galleries.gd")
const DASH_LAYOUT=preload("res://scripts/forest_dash_galleries_layout.gd")
const FINAL_STAIR=preload("res://scripts/forest_final_stair.gd")
const FINAL_LAYOUT=preload("res://scripts/forest_final_stair_layout.gd")
const CHAMBER=preload("res://scripts/forest_chamber.gd")
const GUARDIAN=preload("res://scripts/forest_temple_guardian.gd")
const TEMPLE_HAND=preload("res://scripts/forest_temple_hand.gd")
const MAP = preload("res://scripts/world_map.gd")
const AUDIO = preload("res://scripts/game_audio.gd")
const MENU = preload("res://scripts/game_menu.gd")
const HAND_MENU = preload("res://scripts/hand_menu.gd")
const HAND_ART = preload("res://assets/hand_chair.png")
const HUNTER = preload("res://scripts/bow_boss.gd")
const ARROW = preload("res://scripts/bow_arrow.gd")
const SCOUT = preload("res://scripts/scout.gd")
const WILL_ORB = preload("res://scripts/will_orb.gd")
const FOREST_ENCOUNTERS = preload("res://scripts/forest_encounters.gd")
const WORLD_LAYOUT = preload("res://scripts/forest_world_layout.gd")
const BOUNDS = WORLD_LAYOUT.BOUNDS
const HAND_X = WORLD_LAYOUT.HAND_X

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
var temple_hand_activated := false
var temple_guardian: Node2D
var temple_guardian_defeated:=false
var forest_final_stair: Node2D
var temple_hand: Node2D
var forest_dash_galleries: Node2D
var last_hand_room := 2
var saved_data: Dictionary = {}
var toast := ""
var toast_time := 0.0
var arrival: Node2D
var forest_gallery: Node2D
var forest_stair: Node2D
var forest_upper_gallery: Node2D
var forest_smash_corridor: Node2D
var forest_stepped_gallery: Node2D
var forest_elevated_gallery: Node2D
var forest_return_gallery: Node2D
var forest_split_hall: Node2D
var forest_encounters: Node2D
var forest_defeated: Array = []

func _ready() -> void:
	game_audio = AUDIO.new()
	add_child(game_audio)
	game_audio.play_forest()
	if get_tree().has_meta("active_save_slot"):
		active_save_slot = int(get_tree().get_meta("active_save_slot"))
		save_root = str(get_tree().get_meta("save_root", "user://"))
	if active_save_slot > 0:
		saved_data = SLOTS.load_slot(active_save_slot, save_root)
		elapsed_seconds = float(saved_data.get("seconds", 0.0))
		will_amount = int(saved_data.get("will", 0))
		player_level = int(saved_data.get("level", 1))
		visited_rooms.assign(saved_data.get("visited_rooms", [2]))
		bow_boss_defeated = bool(saved_data.get("bow_boss_defeated", false))
		bow_tutorial_practiced = bool(saved_data.get("bow_tutorial_practiced", false))
		forest_hand_activated = bool(saved_data.get("forest_hand_activated", false))
		temple_hand_activated = bool(saved_data.get("temple_hand_activated", false))
		temple_guardian_defeated=bool(saved_data.get("temple_guardian_defeated",false))
		last_hand_room = int(saved_data.get("last_hand_room", 8 if forest_hand_activated else 3 if bool(saved_data.get("hand_activated", false)) else 1))
		forest_defeated.assign(saved_data.get("forest_defeated", []))
		if get_tree().has_meta("forest_entry_room"):
			current_room = clampi(int(get_tree().get_meta("forest_entry_room")), 5, 10)
			get_tree().remove_meta("forest_entry_room")
		elif get_tree().has_meta("arriving_room_transition"):
			current_room = 5
		else:
			if last_hand_room == 9 and temple_hand_activated:
				current_room = 9
			elif last_hand_room == 8 and forest_hand_activated:
				current_room = 8
			elif temple_hand_activated:
				current_room = 9
			elif forest_hand_activated:
				current_room = 8
			else:
				current_room = clampi(int(saved_data.get("room", 5)), 5, 10)
	_mark_room_visited(current_room)
	arrival=ARRIVAL.new()
	add_child(arrival)
	forest_gallery=GALLERY.new()
	add_child(forest_gallery)
	forest_stair=STAIR.new()
	add_child(forest_stair)
	forest_upper_gallery=UPPER.new()
	add_child(forest_upper_gallery)
	forest_smash_corridor=SMASH_CORRIDOR.new()
	add_child(forest_smash_corridor)
	forest_stepped_gallery=STEPPED_GALLERY.new()
	add_child(forest_stepped_gallery)
	forest_elevated_gallery=ELEVATED_GALLERY.new()
	add_child(forest_elevated_gallery)
	forest_return_gallery=RETURN_GALLERY.new()
	add_child(forest_return_gallery)
	forest_split_hall=SPLIT_HALL.new()
	add_child(forest_split_hall)
	forest_dash_galleries=DASH_GALLERIES.new()
	add_child(forest_dash_galleries)
	temple_hand=TEMPLE_HAND.new()
	add_child(temple_hand)
	forest_final_stair=FINAL_STAIR.new()
	add_child(forest_final_stair)
	forest_encounters = FOREST_ENCOUNTERS.new()
	forest_encounters.world = self
	add_child(forest_encounters)
	for config in [[7,preload("res://assets/forest_bow_arena_environment.png"),606.0],[8,preload("res://assets/forest_boss_hand_environment.png"),657.0],[10,preload("res://assets/forest_temple_guardian_environment.png"),634.0]]:
		var chamber:=CHAMBER.new()
		chamber.name="ForestChamber%d"%config[0]
		chamber.bounds=BOUNDS[int(config[0])-5]
		chamber.art=config[1]
		chamber.source_floor=config[2]
		chamber.close_left=int(config[0])==10
		chamber.close_right=int(config[0]) in [7,10]
		add_child(chamber)
	player = PLAYER.new()
	player.position = Vector2(HAND_X, 570) if current_room == 8 else ARRIVAL_LAYOUT.entry() if current_room == 5 else Vector2(BOUNDS[current_room - 5].x + 90, 570)
	if current_room==9: player.position=DASH_LAYOUT.HAND
	player.has_dash = bool(saved_data.get("has_dash", true))
	player.set_injured(bool(saved_data.get("is_injured", false)))
	player.has_heavy = bool(saved_data.get("has_heavy", false))
	player.has_bow = bool(saved_data.get("has_bow", bow_boss_defeated))
	player.bow_ammo = int(saved_data.get("bow_ammo", 3)) if player.has_bow else 0
	player.load_combat_progress(saved_data)
	player.has_air_dash = bool(saved_data.get("has_air_dash", bow_boss_defeated))
	var loaded_charges := int(saved_data.get("healing_charges", 3))
	player.healing_charges = player.max_healing_charges if loaded_charges <= 0 else loaded_charges
	player.z_index = 3
	add_child(player)
	player.drop_platform=forest_split_hall.drop_platform
	player.drop_region=Rect2(SPLIT_LAYOUT.DROP.position-Vector2(0,8),Vector2(SPLIT_LAYOUT.DROP.size.x,26))
	player.drop_depth=SPLIT_LAYOUT.DROP.size.y
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
	bow_boss.position = Vector2(BOUNDS[2].x+700, 553)
	bow_boss.player = player
	add_child(bow_boss)
	bow_boss.defeated.connect(_on_hunter_defeated)
	bow_boss.attack_cued.connect(func(_cue: String) -> void: game_audio.play_effect("enemy_attack"))
	bow_boss.visible = not bow_boss_defeated
	temple_guardian=GUARDIAN.new()
	temple_guardian.position=Vector2(23390,553)
	temple_guardian.player=player
	add_child(temple_guardian)
	temple_guardian.defeated.connect(_on_guardian_defeated)
	temple_guardian.attack_cued.connect(func(_cue: String) -> void: game_audio.play_effect("enemy_attack"))
	temple_guardian.visible=not temple_guardian_defeated
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
	if current_room==10 and not temple_guardian_defeated and not temple_guardian.active and not transitioning:
		temple_guardian.active=true
		temple_guardian.state_time=0.85
		game_audio.play_temple_boss()
		_show_toast("TEMPLE GUARDIAN",3)
	if current_room!=10: temple_guardian.active=false
	if current_room == 7 and not bow_boss_defeated and not bow_boss.active and not transitioning:
		bow_boss.active = true
		bow_boss.state_time = 0.65
		arena_entrance = _solid(Rect2(BOUNDS[2].x, -60, 32, 660))
		arena_exit = _solid(Rect2(BOUNDS[2].y, -60, 32, 660))
		game_audio.play_forest_boss()
		_show_toast("FOREST GUARDIAN  ·  Close the distance between volleys", 3.5)
	if current_room == 8 and player.has_bow and not bow_tutorial_practiced and not bow_hint_shown:
		bow_hint_shown = true
		_show_toast("Press L to fire. Meditate at the hand to refill arrows.", 4.0)
	_update_hud()
	queue_redraw()

func _check_transition() -> void:
	if transitioning or current_room in [9,10]: return
	var x:=player.position.x
	if current_room==5 and x<=-14:
		_return_to_cave()
		return
	if current_room==7 and bow_boss.active and not bow_boss_defeated: return
	match current_room:
		5:
			if x>=BOUNDS[0].y: _change_room(6,3680)
		6:
			if x<=3615: _change_room(5,3520)
			elif x>=FINAL_LAYOUT.END: _change_room(8,BOUNDS[3].x+80)
		8:
			if x<=BOUNDS[3].x+15: _change_room(6,FINAL_LAYOUT.END-80)
			elif x>=BOUNDS[3].y: _change_room(7,BOUNDS[2].x+80)
		7:
			if x<=BOUNDS[2].x+15: _change_room(8,BOUNDS[3].y-80)

func _change_room(destination: int, entry_x: float) -> void:
	transitioning = true
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	await loading_overlay.cover_room()
	if death_pending:
		return
	current_room = destination
	_mark_room_visited(current_room)
	if is_instance_valid(forest_encounters):
		forest_encounters.set_active(current_room == 6)
	player.global_position = Vector2(entry_x,570) if destination in [9,10] else _receiving_position(destination,entry_x)
	player.reset_movement_state()
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
	camera.zoom=Vector2(0.96,0.96) if current_room in [5,6] else Vector2.ONE
	camera.position=Vector2.ZERO if current_room in [5,6] else Vector2(0,-100)
	camera.limit_top=ARRIVAL_LAYOUT.CAMERA_TOP if current_room==5 else SMASH_LAYOUT.CAMERA_TOP if current_room==6 else -60
	camera.limit_bottom=ceili(ARRIVAL_LAYOUT.EXTENT.end.y) if current_room==5 else SPLIT_LAYOUT.CAMERA_BOTTOM if current_room==6 else 720
	# Tracking smoothing alone still hard-clamps at the upper gallery's jump apex.
	camera.limit_smoothed=current_room==6
	camera.reset_smoothing()
	if is_instance_valid(arrival): arrival.visible = current_room == 5
	if is_instance_valid(temple_hand): temple_hand.visible = current_room == 9
	if is_instance_valid(bow_boss): bow_boss.visible = current_room == 7 and not bow_boss_defeated
	if is_instance_valid(temple_guardian): temple_guardian.visible = current_room == 10 and not temple_guardian_defeated
	if is_instance_valid(hand_chair): hand_chair.visible = current_room == 8
	for r in [7, 8, 10]:
		var ch := get_node_or_null("ForestChamber%d" % r)
		if ch != null:
			ch.visible = current_room == r

func _receiving_position(destination: int,entry_x: float) -> Vector2:
	if destination==9: return DASH_LAYOUT.HAND
	if destination==10: return Vector2(23735,570)
	if destination==6 and entry_x>=FINAL_LAYOUT.X: return Vector2(entry_x,FINAL_LAYOUT.surface_y(entry_x)-27)
	if destination==5: return ARRIVAL_LAYOUT.receiving(entry_x)
	if destination==6 and entry_x>=12600: return Vector2(entry_x,SPLIT_LAYOUT.EXIT_Y-27)
	if destination==6 and entry_x>=11400:
		# The temporary outer receiving anchor otherwise straddles the solid pedestal.
		var receiving_x:=maxf(entry_x,RETURN_LAYOUT.cap(2).end.x+30) if entry_x>=RETURN_LAYOUT.cap(2).position.x-14 else entry_x
		return Vector2(receiving_x,RETURN_LAYOUT.EXIT_Y-27)
	if destination==6 and entry_x>=10200: return Vector2(entry_x,ELEVATED_LAYOUT.EXIT_Y-27)
	if destination==6 and entry_x>=9000: return Vector2(entry_x,STEPPED_LAYOUT.EXIT_Y-27)
	if destination==6 and entry_x>=7800: return Vector2(entry_x,SMASH_LAYOUT.surface_y(entry_x)-27)
	if destination==6 and entry_x>=6800: return Vector2(entry_x,UPPER_LAYOUT.EXIT_Y-27)
	if destination==6 and entry_x>5000: return Vector2(entry_x,STAIR_LAYOUT.surface_y(entry_x)-27)
	return Vector2(entry_x,570)

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
			if transitioning or hand_menu.visible or world_map.visible or not player.meditation_state.is_empty() or get_tree().paused: return
			if current_room==6 and player.position.distance_to(DASH_LAYOUT.PORTAL)<70:
				_enter_temple_hand()
			elif current_room==9 and player.position.distance_to(DASH_LAYOUT.HAND_MINIBOSS)<70:
				_enter_temple_guardian()
			elif current_room==10 and player.position.distance_to(Vector2(23735,570))<70 and temple_guardian_defeated:
				_change_room(9,DASH_LAYOUT.HAND_MINIBOSS.x)
			elif current_room==9 and player.position.distance_to(DASH_LAYOUT.HAND_RETURN)<70:
				_leave_temple_hand()
			elif (current_room==8 and player.position.distance_to(Vector2(HAND_X,570))<70) or (current_room==9 and player.position.distance_to(DASH_LAYOUT.HAND)<70):
				var chair_position: Vector2=temple_hand.chair.position if current_room==9 else hand_chair.position
				activate_hand()
				player.begin_meditation(chair_position)
				game_audio.play_effect("hand_mount")
				hand_menu.title.text="TEMPLE HAND" if current_room==9 else "TWISTED FOREST HAND"
				hand_menu.show_menu()
			else: return
			get_viewport().set_input_as_handled()

func interaction_prompt() -> String:
	if transitioning or hand_menu.visible or world_map.visible: return ""
	if current_room==6 and player.position.distance_to(DASH_LAYOUT.PORTAL)<70: return "E - Enter"
	if current_room==8 and player.position.distance_to(Vector2(HAND_X,570))<70: return "E - Meditate"
	if current_room==9 and player.position.distance_to(DASH_LAYOUT.HAND_MINIBOSS)<70: return "E - Enter temple"
	if current_room==10 and temple_guardian_defeated and player.position.distance_to(Vector2(23735,570))<70: return "E - Return to hand"
	if current_room==9 and player.position.distance_to(DASH_LAYOUT.HAND_RETURN)<70: return "E - Return to gallery"
	if current_room==9 and player.position.distance_to(DASH_LAYOUT.HAND)<70: return "E - Meditate"
	return ""

func _enter_temple_guardian() -> void:
	await _change_room(10,23735)

func _on_guardian_defeated() -> void:
	temple_guardian_defeated=true
	temple_guardian.active=false
	temple_guardian.visible=false
	player.has_gauntlet=true
	player.equipped_weapon="gauntlet"
	_show_toast("STONE GAUNTLET - J punch; U beam; hold U for charged rapid fire",5)
	game_audio.play_forest()
	_save_progress()

func _enter_temple_hand() -> void:
	await _change_room(9,DASH_LAYOUT.HAND_RETURN.x)

func _leave_temple_hand() -> void:
	transitioning=true
	player.controls_enabled=false
	player.reset_movement_state()
	await loading_overlay.cover_room()
	if death_pending: return
	current_room=6
	if is_instance_valid(forest_encounters):
		forest_encounters.set_active(true)
	player.position=DASH_LAYOUT.PORTAL
	_set_camera()
	_save_progress()
	await loading_overlay.reveal_room()
	if death_pending: return
	transitioning=false
	player.controls_enabled=true

func _on_attack(hitbox: Rect2) -> void:
	var p_dmg: float = player.current_posture_damage(false)
	if is_instance_valid(forest_encounters):
		forest_encounters.strike(hitbox, 1.0 * player.damage_multiplier(), p_dmg)
	for enemy in get_tree().get_nodes_in_group("forest_boss_summons"):
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and hitbox.intersects(enemy.combat_bounds()): enemy.take_hit(player.damage_multiplier(), p_dmg)
	game_audio.play_effect("attack")
	if bow_boss.active and not bow_boss_defeated and hitbox.intersects(bow_boss.combat_bounds()):
		bow_boss.take_hit(1.0*player.damage_multiplier(), p_dmg)
	if current_room==10 and temple_guardian.active and hitbox.intersects(temple_guardian.combat_bounds()): temple_guardian.take_hit(1.0*player.damage_multiplier(), p_dmg)
	for scout in training_scouts:
		if is_instance_valid(scout) and not scout.is_queued_for_deletion() and hitbox.intersects(Rect2(scout.global_position - Vector2(17, 20), Vector2(34, 40))):
			scout.take_hit(1.0*player.damage_multiplier(), p_dmg)

func _on_heavy(hitbox: Rect2) -> void:
	var p_dmg: float = player.current_posture_damage(true)
	if is_instance_valid(forest_encounters):
		forest_encounters.strike(hitbox, 1.5 * player.damage_multiplier(), p_dmg)
	for enemy in get_tree().get_nodes_in_group("forest_boss_summons"):
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and hitbox.intersects(enemy.combat_bounds()): enemy.take_hit(1.5*player.damage_multiplier(), p_dmg)
	if current_room==10 and temple_guardian.active and hitbox.intersects(temple_guardian.combat_bounds()): temple_guardian.take_hit(1.5*player.damage_multiplier(), p_dmg)
	game_audio.play_effect("heavy_attack")
	if bow_boss.active and not bow_boss_defeated and hitbox.intersects(bow_boss.combat_bounds()):
		bow_boss.take_hit(1.5*player.damage_multiplier(), p_dmg)

func _on_bow(origin: Vector2, direction: Vector2) -> void:
	game_audio.play_effect("attack")
	if current_room == 8 and not bow_tutorial_practiced:
		bow_tutorial_practiced = true
		_show_toast("Good shot. Meditate at the hand to refill arrows.", 3.0)
		_save_progress()
	var target: Node = null
	if is_instance_valid(forest_encounters):
		for enemy in forest_encounters.targets():
			if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and (target == null or origin.distance_to(enemy.global_position) < origin.distance_to(target.global_position)):
				target = enemy
	for scout in training_scouts:
		if is_instance_valid(scout) and not scout.is_queued_for_deletion() and (target == null or origin.distance_to(scout.global_position) < origin.distance_to(target.global_position)):
			target = scout
	if current_room==10 and temple_guardian.active: target=temple_guardian
	var arrow := ARROW.new()
	add_child(arrow)
	arrow.setup(origin, direction, target, player.damage_multiplier())

func _on_hunter_defeated() -> void:
	bow_boss_defeated = true
	bow_boss.active = false
	bow_boss.visible = false
	game_audio.play_forest()
	_unlock_arena()
	player.has_bow = true
	player.has_air_dash = true
	player.bow_ammo = player.BOW_AMMO_MAX
	_show_toast("BOW & AIR DASH INHERITED - 2 equip bow; U flipping volley; Dash in air", 5.0)
	_save_progress()

func _on_death() -> void:
	if death_pending:
		return
	death_pending = true
	transitioning = true
	player.controls_enabled = false
	player.start_death_animation()
	player.healing_charges = player.max_healing_charges
	player.health = player.max_health
	await get_tree().create_timer(1.0).timeout
	_unlock_arena()
	if not temple_guardian_defeated:
		temple_guardian.reset_encounter()
		temple_guardian.health=temple_guardian.max_health
		temple_guardian.state="idle"
		temple_guardian.state_time=0.85
		temple_guardian.attack_count=0
		temple_guardian.position=Vector2(23390,553)
	player.healing_charges = player.max_healing_charges
	player.health = player.max_health
	if not ((last_hand_room==8 and forest_hand_activated) or (last_hand_room==9 and temple_hand_activated)):
		_save_progress()
		get_tree().set_meta("cave_entry_x", float(saved_data.get("checkpoint_x", 120.0)) if last_hand_room == 3 and bool(saved_data.get("hand_activated", false)) else 120.0)
		get_tree().set_meta("arriving_room_transition", true)
		get_tree().change_scene_to_file("res://scenes/tutorial.tscn")
		return
	if not bow_boss_defeated:
		bow_boss.reset_encounter()
		bow_boss.active = false
		bow_boss.health = bow_boss.max_health
		bow_boss.position = Vector2(BOUNDS[2].x+700, 553)
		bow_boss.state = "idle"
		bow_boss.state_time = 0.0
	game_audio.play_forest()
	current_room = last_hand_room
	player.global_position = DASH_LAYOUT.HAND if current_room==9 else Vector2(HAND_X,570)
	player.reset_movement_state()
	player.set_injured(false)
	player.has_dash = true
	player.heal_full()
	player.healing_charges = player.max_healing_charges
	_set_camera()
	player.controls_enabled = true
	death_pending = false
	transitioning = false
	if is_instance_valid(forest_encounters):
		forest_encounters.reset_at_hand()
		forest_encounters.set_active(current_room == 6)
	_save_progress()

func activate_hand() -> void:
	if current_room==9:
		temple_hand_activated=true
		last_hand_room=9
	else:
		forest_hand_activated = true
		last_hand_room = 8
	player.set_injured(false)
	player.has_dash = true
	player.heal_full()
	player.healing_charges = player.max_healing_charges
	if player.has_bow:
		player.bow_ammo = player.BOW_AMMO_MAX
	if player.has_gauntlet:
		player.gauntlet_charges = player.GAUNTLET_CHARGES_MAX
	if is_instance_valid(forest_encounters):
		forest_encounters.reset_at_hand()
		forest_encounters.set_active(current_room == 6)

func _spawn_will_orb(origin: Vector2, amount: int) -> void:
	var orb := WILL_ORB.new()
	orb.amount = amount
	orb.target = player
	orb.collected.connect(_on_will_collected)
	add_child(orb)
	orb.global_position = origin

func _on_will_collected(amount: int) -> void:
	will_amount += amount
	_save_progress()

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
	if temple_hand_activated:
		hands.append({"name":"TEMPLE HAND", "room":9, "position":DASH_LAYOUT.HAND})
	return hands

func fast_travel_to_hand(destination: Dictionary) -> void:
	var room := int(destination.get("room", -1))
	if room == 3:
		transitioning = true
		player.reset_movement_state()
		player.controls_enabled = false
		_save_progress()
		await loading_overlay.cover_room()
		if death_pending:
			return
		get_tree().set_meta("arriving_room_transition", true)
		get_tree().set_meta("cave_entry_x", 2610.0)
		get_tree().change_scene_to_file("res://scenes/tutorial.tscn")
	elif room == 9 and temple_hand_activated:
		transitioning = true
		player.controls_enabled = false
		player.velocity = Vector2.ZERO
		await loading_overlay.cover_room()
		if death_pending:
			return
		current_room = 9
		_mark_room_visited(current_room)
		if is_instance_valid(forest_encounters):
			forest_encounters.set_active(false)
		player.global_position = DASH_LAYOUT.HAND
		player.reset_movement_state()
		_set_camera()
		_save_progress()
		await loading_overlay.reveal_room()
		if death_pending:
			return
		player.controls_enabled = true
		transitioning = false
	elif room == 8 and forest_hand_activated:
		transitioning = true
		player.controls_enabled = false
		player.velocity = Vector2.ZERO
		await loading_overlay.cover_room()
		if death_pending:
			return
		current_room = 8
		_mark_room_visited(current_room)
		if is_instance_valid(forest_encounters):
			forest_encounters.set_active(false)
		player.global_position = Vector2(HAND_X, 570)
		player.reset_movement_state()
		_set_camera()
		_save_progress()
		await loading_overlay.reveal_room()
		if death_pending:
			return
		player.controls_enabled = true
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
	if visited_rooms.has(1):
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
	if visited_rooms.has(9) and temple_hand_activated:
		completed.append(9)
	if visited_rooms.has(10) and temple_guardian_defeated: completed.append(10)
	return completed

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
	hud.area = "THE TWISTED FOREST"
	hud.boss_health = bow_boss.health if bow_boss.active and not bow_boss_defeated else 0
	hud.boss_max_health = int(bow_boss.max_health)
	hud.boss_posture = bow_boss.posture if bow_boss.active and not bow_boss_defeated else 0.0
	hud.boss_max_posture = bow_boss.max_posture
	hud.boss_title = "FOREST GUARDIAN"
	if current_room==10 and temple_guardian.active and not temple_guardian_defeated:
		hud.boss_health=temple_guardian.health
		hud.boss_max_health=int(temple_guardian.max_health)
		hud.boss_posture=temple_guardian.posture
		hud.boss_max_posture=temple_guardian.max_posture
		hud.boss_title="TEMPLE GUARDIAN"
	hud.notice = interaction_prompt() if not interaction_prompt().is_empty() else toast if toast_time > 0.0 else ""
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
	data["is_injured"] = player.is_injured
	data["has_dash"] = player.has_dash
	data.merge(player.combat_save_data(),true)
	data["has_heavy"] = player.has_heavy
	data["has_bow"] = player.has_bow
	data["bow_ammo"] = player.bow_ammo
	data["bow_boss_defeated"] = bow_boss_defeated
	data["bow_tutorial_practiced"] = bow_tutorial_practiced
	data["forest_hand_activated"] = forest_hand_activated
	data["temple_hand_activated"] = temple_hand_activated
	data["temple_guardian_defeated"] = temple_guardian_defeated
	data["last_hand_room"] = last_hand_room
	data["forest_defeated"] = forest_defeated.duplicate()
	data["visited_rooms"] = visited_rooms.duplicate()
	var result: Error = SLOTS.write_slot(active_save_slot, data, save_root)
	if result != OK:
		push_error("Could not save forest progress: %s" % error_string(result))
	saved_data = data

func _exit_tree() -> void:
	if is_instance_valid(player):
		_save_progress()

func _draw() -> void:
	for gate in [arena_entrance,arena_exit]:
		if is_instance_valid(gate) and not gate.is_queued_for_deletion():
			draw_rect(Rect2(gate.position-Vector2(16,330),Vector2(32,660)),Color("315057"))

func gallery_map_state() -> Dictionary:
	return {"heavy_open":bool(saved_data.get("gallery_heavy_open",false))}
