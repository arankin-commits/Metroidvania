extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const SCOUT_SCRIPT = preload("res://scripts/scout.gd")
const BOSS_SCRIPT = preload("res://scripts/boss.gd")
const HUD_SCRIPT = preload("res://scripts/hud.gd")
const SAVE_SLOTS = preload("res://scripts/save_slots.gd")
const LOADING_OVERLAY = preload("res://scripts/loading_overlay.gd")
const CAVE_BACKDROP = preload("res://assets/cave_backdrop.png")
const CAVE_ROOM_BACKDROPS := [
	preload("res://assets/cave_room1.png"),
	CAVE_BACKDROP,
	preload("res://assets/cave_room3.png"),
	preload("res://assets/cave_room4.png"),
]
const WILL_ORB = preload("res://scripts/will_orb.gd")

const FLOOR_Y := 600.0
const LEVEL_END := 4450.0
const ROOM_BOUNDS := [Vector2(-1200, 0), Vector2(0, 1700), Vector2(1700, 3070), Vector2(3070, 4450)]
const ROOM_NAMES := ["Cave Room 1", "Cave Room 2", "Cave Room 3", "Cave Room 4"]
const SECRET_POSITION := Vector2(510, 475)
const NOTE_POSITION := Vector2(2870, 485)

var player: CharacterBody2D
var scout: CharacterBody2D
var boss: Node2D
var hud: Control
var background_rect: TextureRect
var room_backgrounds: Array[TextureRect] = []
var pause_menu: CanvasLayer
var loading_overlay: CanvasLayer
var platforms: Array[Rect2] = []
var seal_body: StaticBody2D
var exit_barrier: StaticBody2D
var arena_barrier: StaticBody2D
var seal_health := 3
var checkpoint := Vector2(120, 570)
var dash_orb_active := true
var boss_defeated := false
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
var saved_dash := false
var saved_boss_defeated := false
var saved_heavy := false
var saved_seal_broken := false
var saved_scout_defeated := false
var current_room := 2
var transitioning_room := false
var wall_broken := false
var secret_found := false
var note_found := false
var note_open := false
var note_panel: Control
var note_text: Label
var sigil_icon: Label
var end_gate_hint_shown := false
var practice_target_hit := false
var dodge_practiced := false
var last_safe_position := Vector2(120, 570)
var heal_hint_shown := false

func _ready() -> void:
	if get_tree().has_meta("active_save_slot"):
		active_save_slot = int(get_tree().get_meta("active_save_slot"))
		save_root = str(get_tree().get_meta("save_root", "user://"))
		var data: Dictionary = SAVE_SLOTS.load_slot(active_save_slot, save_root)
		if not data.is_empty():
			current_room = clampi(int(data.get("room", 2)), 1, 4)
			checkpoint = Vector2(float(data.get("checkpoint_x", 120.0)), 570)
			elapsed_seconds = float(data.get("seconds", 0.0))
			will_amount = int(data.get("will", 0))
			player_level = int(data.get("level", 1))
			saved_healing_charges = int(data.get("healing_charges", 3))
			saved_dash = bool(data.get("has_dash", false))
			saved_boss_defeated = bool(data.get("boss_defeated", false))
			saved_heavy = bool(data.get("has_heavy", saved_boss_defeated))
			saved_seal_broken = bool(data.get("seal_broken", false))
			saved_scout_defeated = bool(data.get("scout_defeated", false))
			wall_broken = bool(data.get("wall_broken", false))
			secret_found = bool(data.get("secret_found", false))
			note_found = bool(data.get("note_found", false))
	if get_tree().has_meta("cave_entry_x"):
		checkpoint = Vector2(float(get_tree().get_meta("cave_entry_x")), 570)
		current_room = 4
		get_tree().remove_meta("cave_entry_x")
	else:
		current_room = _room_for_x(checkpoint.x)
	last_safe_position = checkpoint
	platforms = [
		Rect2(-1200, FLOOR_Y, 1200, 120),
		Rect2(0, FLOOR_Y, 690, 120),
		Rect2(840, FLOOR_Y, 1320, 120),
		Rect2(2450, FLOOR_Y, 2000, 120),
		Rect2(380, 525, 155, 18),
		Rect2(1350, 520, 170, 18),
		Rect2(2730, 520, 150, 18),
	]
	for rect in platforms:
		_make_solid(rect)
	_make_solid(Rect2(-1160, 380, 32, 220))
	seal_body = _make_solid(Rect2(1680, 300, 32, 300))
	if saved_seal_broken:
		seal_health = 0
		seal_body.queue_free()
	exit_barrier = _make_solid(Rect2(3850, 465, 32, 135))
	if wall_broken:
		exit_barrier.queue_free()
	player = PLAYER_SCRIPT.new()
	player.name = "Player"
	player.position = checkpoint
	player.has_dash = saved_dash
	player.has_heavy = saved_heavy
	player.healing_charges = saved_healing_charges
	dash_orb_active = not saved_dash
	add_child(player)
	player.attacked.connect(_on_player_attacked)
	player.heavy_attacked.connect(_on_player_heavy_attacked)
	player.dodged.connect(_on_player_dodged)
	player.healed.connect(_save_progress)
	player.damaged.connect(_on_player_damaged)
	player.died.connect(_on_player_died)
	scout = SCOUT_SCRIPT.new()
	scout.name = "Scout"
	scout.position = Vector2(1175, 579)
	scout.player = player
	add_child(scout)
	scout.defeated.connect(_on_scout_defeated)
	if saved_scout_defeated:
		scout.queue_free()
	boss = BOSS_SCRIPT.new()
	boss.name = "HollowWarden"
	boss.position = Vector2(3510, 553)
	boss.player = player
	add_child(boss)
	boss.defeated.connect(_on_boss_defeated)
	if saved_boss_defeated:
		boss_defeated = true
		boss.visible = false
	var layer := CanvasLayer.new()
	layer.name = "HUDLayer"
	add_child(layer)
	hud = HUD_SCRIPT.new()
	hud.name = "HUD"
	layer.add_child(hud)
	_add_backdrop()
	pause_menu = preload("res://scripts/pause_menu.gd").new()
	add_child(pause_menu)
	loading_overlay = LOADING_OVERLAY.new()
	add_child(loading_overlay)
	_build_note_panel(layer)
	_set_camera_room()
	_show_toast("Find your way through the forgotten passage", 3.5)
	queue_redraw()

func _add_backdrop() -> void:
	for i in ROOM_BOUNDS.size():
		var bounds: Vector2 = ROOM_BOUNDS[i]
		var backdrop := TextureRect.new()
		backdrop.name = "Room%dBackdrop" % (i + 1)
		backdrop.z_index = -100
		backdrop.position = Vector2(bounds.x, -60)
		backdrop.size = Vector2(bounds.y - bounds.x, 780)
		backdrop.texture = CAVE_ROOM_BACKDROPS[i]
		backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		backdrop.stretch_mode = TextureRect.STRETCH_SCALE
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(backdrop)
		room_backgrounds.append(backdrop)
	background_rect = room_backgrounds[current_room - 1]

func _make_solid(rect: Rect2) -> StaticBody2D:
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
	if save_timer >= 10.0:
		save_timer = 0.0
		_save_progress()
	toast_time = maxf(0.0, toast_time - delta)
	if transitioning_room or note_open:
		_update_hud()
		return
	if player.is_on_floor() and player.global_position.y < 650.0:
		last_safe_position = player.global_position
	if player.global_position.y > 790.0 and not respawning:
		_on_player_fell()
		_update_hud()
		return
	if _check_room_transition():
		_update_hud()
		return
	if current_room == 1 and player.global_position.x < -1020.0 and not end_gate_hint_shown:
		end_gate_hint_shown = true
		_show_toast("The End Area entrance is sealed for now", 3.0)
	if player.global_position.x > 1750.0 and checkpoint.x < 1800.0:
		checkpoint = Vector2(1810, 570)
		_show_toast("A new checkpoint awakens", 2.5)
		_save_progress()
	if player.global_position.x > 2710.0 and checkpoint.x < 2700.0:
		checkpoint = Vector2(2760, 570)
		_show_toast("Checkpoint before the Warden", 2.5)
		_save_progress()
	if dash_orb_active and player.global_position.distance_to(Vector2(1945, 550)) < 44.0:
		dash_orb_active = false
		player.has_dash = true
		player.heal_full()
		_save_progress()
		_show_toast("DASH UNLOCKED  ·  Press K or Shift in midair", 4.0)
	if current_room == 4 and not boss.active and not boss_defeated and not respawning and player.global_position.x > 3070.0:
		boss.active = true
		boss.state_time = 0.9
		_lock_arena()
		_show_toast("THE HOLLOW WARDEN  ·  Watch the red charge tell", 3.0)
	_update_hud()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
		if note_open:
			_close_note()
		elif current_room == 2 and player.global_position.distance_to(SECRET_POSITION) < 65.0:
			_open_sigil()
		elif current_room == 3 and player.global_position.distance_to(NOTE_POSITION) < 65.0:
			_open_note()
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
			if x >= 0.0:
				_begin_room_transition(2, 80.0)
				return true
		2:
			if x < 0.0:
				_begin_room_transition(1, -80.0)
				return true
			if x >= 1700.0:
				_begin_room_transition(3, 1780.0)
				return true
		3:
			if x < 1700.0:
				_begin_room_transition(2, 1620.0)
				return true
			if x >= 3070.0:
				_begin_room_transition(4, 3150.0)
				return true
		4:
			if x < 3070.0:
				_begin_room_transition(3, 2990.0)
				return true
			if x >= 4200.0 and wall_broken:
				_leave_for_forest()
				return true
	return false

func _begin_room_transition(destination: int, entry_x: float) -> void:
	transitioning_room = true
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	loading_overlay.show_room(ROOM_NAMES[destination - 1])
	await get_tree().create_timer(0.45).timeout
	current_room = destination
	player.global_position = Vector2(entry_x, 570)
	last_safe_position = player.global_position
	_set_camera_room()
	_save_progress()
	await get_tree().process_frame
	loading_overlay.hide_room()
	player.controls_enabled = true
	transitioning_room = false

func _leave_for_forest() -> void:
	transitioning_room = true
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	_save_progress()
	loading_overlay.show_room("Forest Edge")
	await get_tree().create_timer(0.45).timeout
	get_tree().change_scene_to_file("res://scenes/forest_entry.tscn")

func _set_camera_room() -> void:
	var camera := player.get_node("Camera2D") as Camera2D
	var bounds: Vector2 = ROOM_BOUNDS[current_room - 1]
	camera.limit_left = int(bounds.x)
	camera.limit_right = int(bounds.y)
	background_rect = room_backgrounds[current_room - 1]

func _lock_arena() -> void:
	if is_instance_valid(arena_barrier):
		return
	arena_barrier = _make_solid(Rect2(3070, -60, 32, 660))
	queue_redraw()

func _unlock_arena() -> void:
	if is_instance_valid(arena_barrier):
		arena_barrier.queue_free()
		arena_barrier = null
	queue_redraw()

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

func _close_note() -> void:
	note_open = false
	note_panel.visible = false
	sigil_icon.visible = false
	player.controls_enabled = true

func _on_player_attacked(hitbox: Rect2) -> void:
	if not practice_target_hit and hitbox.intersects(Rect2(560, 515, 32, 85)):
		practice_target_hit = true
		_show_toast("Clean strike. The training post cannot hurt you.", 2.8)
	if is_instance_valid(scout) and hitbox.intersects(Rect2(scout.global_position - Vector2(17, 20), Vector2(34, 40))):
		scout.take_hit()
	if seal_health > 0 and hitbox.intersects(Rect2(1680, 300, 32, 300)):
		seal_health -= 1
		if seal_health <= 0:
			seal_body.queue_free()
			_show_toast("The seal breaks. Press onward.", 2.7)
			_save_progress()
	if boss.active and not boss_defeated and hitbox.intersects(Rect2(boss.global_position - Vector2(55, 78), Vector2(110, 120))):
		boss.take_hit()
	queue_redraw()

func _on_player_dodged() -> void:
	if not dodge_practiced and current_room == 2 and player.global_position.x < 690.0:
		dodge_practiced = true
		_show_toast("Good dodge. You can avoid danger before striking.", 2.8)

func _on_player_heavy_attacked(hitbox: Rect2) -> void:
	if boss.active and not boss_defeated and hitbox.intersects(Rect2(boss.global_position - Vector2(55, 78), Vector2(110, 120))):
		boss.take_hit()
		boss.take_hit()
	if boss_defeated and not wall_broken and hitbox.intersects(Rect2(3850, 465, 32, 135)):
		wall_broken = true
		exit_barrier.queue_free()
		_show_toast("The cracked wall shatters. The forest lies ahead.", 3.5)
		_save_progress()
	queue_redraw()

func _on_scout_defeated() -> void:
	saved_scout_defeated = true
	_spawn_will_orb(scout.global_position, 5)
	_show_toast("The scout falls. Its Will drifts toward you.", 2.6)
	_save_progress()

func _on_boss_defeated() -> void:
	boss_defeated = true
	_unlock_arena()
	_spawn_will_orb(boss.global_position, 50)
	player.has_heavy = true
	player.heal_full()
	_show_toast("HEAVY ATTACK UNLOCKED - Hold H, release when charged", 4.0)
	_save_progress()
	queue_redraw()

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

func _on_player_damaged() -> void:
	if not heal_hint_shown and player.health > 0 and player.healing_charges > 0:
		heal_hint_shown = true
		_show_toast("Hurt? Press F to use a healing charge.", 3.0)

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
	data["has_dash"] = player.has_dash
	data["seal_broken"] = seal_health <= 0
	data["scout_defeated"] = saved_scout_defeated or not is_instance_valid(scout) or scout.is_queued_for_deletion()
	data["boss_defeated"] = boss_defeated
	data["has_heavy"] = player.has_heavy
	data["wall_broken"] = wall_broken
	data["secret_found"] = secret_found
	data["note_found"] = note_found
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
	_show_toast("The passage remembers you...", 2.0)
	get_tree().create_timer(1.0).timeout.connect(_respawn)

func _on_player_fell() -> void:
	if respawning:
		return
	respawning = true
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	var damage := maxi(1, ceili(float(player.max_health) * 0.20))
	player.health = maxi(1, player.health - damage)
	_show_toast("The fall costs %d health. Press F to heal." % damage, 3.0)
	get_tree().create_timer(0.65).timeout.connect(_respawn_after_fall)

func _respawn_after_fall() -> void:
	player.global_position = last_safe_position
	player.velocity = Vector2.ZERO
	player.invulnerability = 1.0
	player.controls_enabled = true
	respawning = false
	_save_progress()

func _respawn() -> void:
	_unlock_arena()
	player.global_position = checkpoint
	last_safe_position = checkpoint
	current_room = _room_for_x(checkpoint.x)
	_set_camera_room()
	player.velocity = Vector2.ZERO
	player.heal_full()
	player.healing_charges = player.max_healing_charges
	player.controls_enabled = true
	respawning = false
	if boss.active and not boss_defeated:
		boss.active = false
		boss.state = "idle"
		boss.state_time = 0.0
		boss.health = boss.max_health
		boss.position = Vector2(3510, 553)
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
	hud.level = player_level
	hud.will_amount = will_amount
	hud.healing_charges = player.healing_charges
	hud.max_healing_charges = player.max_healing_charges
	hud.has_dash = player.has_dash
	hud.has_heavy = player.has_heavy
	hud.boss_health = boss.health if boss.active and not boss_defeated else 0
	hud.finished = complete
	var x := player.global_position.x
	match current_room:
		1:
			hud.area = "CAVE 01  ·  THE OLD ENTRANCE"
			hud.prompt = "The sealed entrance at the far left leads to the End Area."
		2:
			hud.area = "CAVE 02  ·  FIRST STEPS"
			if x < 300.0:
				hud.prompt = "Move with A / D. Jump with Space. The open hand marks your respawn point."
			elif x < 700.0:
				hud.prompt = "Dodge with K or Shift. Strike the training post with J. Search above."
			elif x < 1400.0:
				hud.prompt = "Dodge on the ground with K or Shift. Strike with J."
			else:
				hud.prompt = "Strike the old seal three times to reach the next room."
		3:
			hud.area = "CAVE 03  ·  THE HIDDEN WORD"
			if player.global_position.distance_to(NOTE_POSITION) < 65.0:
				hud.prompt = "Press E to read the weathered note."
			elif x < 2110.0:
				hud.prompt = "Touch the turquoise light to upgrade your dodge to an air dash."
			elif x < 2650.0:
				hud.prompt = "Jump, then dodge through the chasm with K or Shift."
			else:
				hud.prompt = "A checkpoint. Search the stone before the Warden."
		4:
			hud.area = "CAVE 04  ·  THE HOLLOW WARDEN"
			if not boss_defeated:
				hud.prompt = "Watch the red charge tell. Strike during recovery."
			elif not wall_broken:
				hud.prompt = "Hold H, then release a charged attack at the cracked wall."
			else:
				hud.prompt = "The forest exit is beyond the broken wall."
	if toast_time > 0.0:
		hud.prompt = toast
	elif current_room == 2 and player.global_position.distance_to(SECRET_POSITION) < 65.0:
		hud.prompt = "Press E to inspect the Cave Sigil."
	elif current_room == 2 and player.health < player.max_health and player.healing_charges > 0:
		hud.prompt = "Press F to spend a healing charge and restore health."
	hud.queue_redraw()

func _draw() -> void:
	for rect in platforms:
		_draw_cave_terrain(rect)
	_draw_hand_bench(Vector2(77, 600))
	if is_instance_valid(arena_barrier) and not arena_barrier.is_queued_for_deletion():
		draw_rect(Rect2(3070, -60, 32, 660), Color(0.12, 0.18, 0.23))
		for y in range(-48, 600, 32):
			draw_rect(Rect2(3076, y, 20, 12), Color(0.33, 0.73, 0.72))
			draw_rect(Rect2(3081, y + 4, 10, 4), Color(0.72, 0.98, 0.83))
	for x in [1780.0, 2740.0]:
		draw_line(Vector2(x, 600), Vector2(x, 508), Color(0.22, 0.72, 0.71), 5)
		draw_circle(Vector2(x, 505), 12, Color(0.35, 0.95, 0.85))
		draw_circle(Vector2(x, 505), 25, Color(0.35, 0.95, 0.85, 0.14))
	for x in [0.0, 1700.0, 3070.0]:
		draw_rect(Rect2(x - 8, 280, 16, 320), Color(0.17, 0.24, 0.31, 0.65))
		draw_rect(Rect2(x - 28, 270, 56, 18), Color(0.31, 0.45, 0.48))
	draw_rect(Rect2(-1160, 380, 32, 220), Color(0.33, 0.30, 0.41))
	draw_rect(Rect2(-1152, 405, 16, 170), Color(0.11, 0.17, 0.26))
	draw_circle(Vector2(-1144, 490), 11, Color(0.81, 0.65, 0.38))
	draw_rect(Rect2(499, 467, 22, 20), Color(0.24, 0.24, 0.30))
	draw_circle(SECRET_POSITION, 6, Color(0.52, 0.88, 0.79) if secret_found else Color(0.96, 0.79, 0.39))
	draw_circle(SECRET_POSITION, 13, Color(0.96, 0.79, 0.39, 0.15))
	draw_rect(Rect2(572, 515, 9, 85), Color(0.54, 0.38, 0.26))
	draw_rect(Rect2(560, 515, 33, 37), Color(0.71, 0.51, 0.31) if not practice_target_hit else Color(0.47, 0.70, 0.59))
	draw_circle(Vector2(576, 533), 10, Color(0.29, 0.22, 0.24))
	draw_rect(Rect2(2858, 480, 24, 20), Color(0.20, 0.27, 0.29))
	draw_rect(Rect2(2864, 484, 12, 13), Color(0.74, 0.66, 0.48))
	if seal_health > 0:
		draw_rect(Rect2(1680, 300, 32, 300), Color(0.28, 0.51, 0.57))
		draw_rect(Rect2(1687, 316, 18, 268), Color(0.15, 0.23, 0.32))
		for i in seal_health:
			draw_circle(Vector2(1696, 521 + i * 23), 5, Color(0.95, 0.78, 0.44))
	if dash_orb_active:
		draw_circle(Vector2(1945, 550), 27, Color(0.20, 0.91, 0.86, 0.13))
		draw_circle(Vector2(1945, 550), 13, Color(0.36, 0.98, 0.87))
		draw_colored_polygon(PackedVector2Array([Vector2(1940, 540), Vector2(1953, 548), Vector2(1942, 563), Vector2(1946, 550)]), Color(0.96, 0.97, 0.77))
	if not wall_broken:
		draw_rect(Rect2(3850, 465, 32, 135), Color(0.38, 0.43, 0.46))
		draw_line(Vector2(3855, 481), Vector2(3872, 514), Color(0.09, 0.12, 0.17), 3)
		draw_line(Vector2(3872, 514), Vector2(3857, 547), Color(0.09, 0.12, 0.17), 3)
		draw_line(Vector2(3857, 547), Vector2(3876, 579), Color(0.09, 0.12, 0.17), 3)
	for x in [3120.0, 3800.0]:
		draw_rect(Rect2(x, 380, 35, 220), Color(0.17, 0.20, 0.28))
		draw_rect(Rect2(x - 8, 370, 51, 18), Color(0.29, 0.31, 0.39))
	draw_circle(Vector2(4200, 520), 43, Color(0.26, 0.91, 0.81, 0.12))
	draw_circle(Vector2(4200, 520), 19, Color(0.51, 0.96, 0.81, 0.75))
	draw_arc(Vector2(4200, 520), 42, 0, TAU, 32, Color(0.48, 0.91, 0.81, 0.8), 4)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(310, 455), "JUMP", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.62, 0.82, 0.81))
	draw_string(font, Vector2(1060, 500), "STRIKE", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.84, 0.72, 0.69))
	draw_string(font, Vector2(1840, 480), "TAKE THE LIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.61, 0.91, 0.84))
	draw_string(font, Vector2(2200, 490), "DASH ACROSS", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.61, 0.91, 0.84))
	draw_string(font, Vector2(-1075, 455), "END AREA", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.88, 0.73, 0.50))
	draw_string(font, Vector2(4090, 455), "TO THE FOREST", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.61, 0.91, 0.84))

func _draw_cave_terrain(rect: Rect2) -> void:
	var stone := Color(0.14, 0.20, 0.24)
	var dark := Color(0.08, 0.13, 0.18)
	var mid := Color(0.24, 0.34, 0.38)
	var light := Color(0.39, 0.56, 0.55)
	draw_rect(rect, stone)
	var tile_count := ceili(rect.size.x / 16.0)
	var row_count := ceili(rect.size.y / 16.0)
	for column in tile_count:
		var x := rect.position.x + column * 16.0
		var tile_width := minf(16.0, rect.end.x - x)
		var seed := int(x / 16.0)
		var cap_height := 5.0 + float(posmod(seed * 7, 3)) * 2.0
		draw_rect(Rect2(x, rect.position.y, tile_width, cap_height), light)
		draw_rect(Rect2(x + 3, rect.position.y + cap_height, minf(9.0, tile_width - 3.0), 3), mid)
		for row in row_count:
			var y := rect.position.y + row * 16.0
			if y + 2.0 >= rect.end.y:
				continue
			if posmod(seed * 11 + row * 7, 5) == 0:
				draw_rect(Rect2(x + 2, y + 10, 5, 3), dark)
				draw_rect(Rect2(x + 8, y + 6, 4, 3), mid)
			elif posmod(seed * 3 + row * 13, 7) == 0:
				draw_rect(Rect2(x + 7, y + 12, 7, 2), light)
			else:
				draw_rect(Rect2(x + 11, y + 8, 3, 3), mid)
		if rect.size.y > 20.0 and posmod(seed, 6) == 0:
			draw_rect(Rect2(x + 13, rect.position.y + 8, 2, 20), dark)

func _draw_hand_bench(base: Vector2) -> void:
	var outline := Color(0.06, 0.14, 0.19)
	var stone := Color(0.43, 0.58, 0.58)
	var highlight := Color(0.77, 0.86, 0.74)
	var glow := Color(0.32, 0.95, 0.83, 0.20)
	draw_circle(base + Vector2(0, -50), 46, glow)
	draw_rect(Rect2(base + Vector2(-25, -65), Vector2(50, 55)), outline)
	draw_rect(Rect2(base + Vector2(-21, -60), Vector2(42, 46)), stone)
	for finger in 4:
		var height := 21.0 + float((finger + 1) % 3) * 7.0
		draw_rect(Rect2(base + Vector2(-20 + finger * 11, -60 - height), Vector2(9, height + 5)), outline)
		draw_rect(Rect2(base + Vector2(-18 + finger * 11, -57 - height), Vector2(5, height)), highlight)
	draw_rect(Rect2(base + Vector2(-36, -48), Vector2(15, 34)), outline)
	draw_rect(Rect2(base + Vector2(-31, -44), Vector2(11, 23)), stone)
	draw_rect(Rect2(base + Vector2(-31, -25), Vector2(62, 12)), outline)
	draw_rect(Rect2(base + Vector2(-27, -23), Vector2(54, 6)), highlight)
	draw_rect(Rect2(base + Vector2(-14, -13), Vector2(28, 13)), stone)
	draw_rect(Rect2(base + Vector2(-18, -4), Vector2(36, 4)), outline)
