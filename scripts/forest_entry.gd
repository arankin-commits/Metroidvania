extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const HUD_SCRIPT = preload("res://scripts/hud.gd")
const SAVE_SLOTS = preload("res://scripts/save_slots.gd")
const LOADING_OVERLAY = preload("res://scripts/loading_overlay.gd")
const FOREST_BACKDROP = preload("res://assets/forest_backdrop.png")
const WORLD_MAP = preload("res://scripts/world_map.gd")

var player: CharacterBody2D
var hud: Control
var pause_menu: CanvasLayer
var loading_overlay: CanvasLayer
var world_map: CanvasLayer
var visited_rooms: Array[int] = [2]
var active_save_slot := 0
var save_root := "user://"
var elapsed_seconds := 0.0
var will_amount := 0
var player_level := 1
var save_timer := 0.0
var transitioning := false
var saved_data: Dictionary = {}

func _ready() -> void:
	if get_tree().has_meta("active_save_slot"):
		active_save_slot = int(get_tree().get_meta("active_save_slot"))
		save_root = str(get_tree().get_meta("save_root", "user://"))
		saved_data = SAVE_SLOTS.load_slot(active_save_slot, save_root)
		elapsed_seconds = float(saved_data.get("seconds", 0.0))
		will_amount = int(saved_data.get("will", 0))
		player_level = int(saved_data.get("level", 1))
		visited_rooms.assign(saved_data.get("visited_rooms", [2]))
	if not visited_rooms.has(5):
		visited_rooms.append(5)
		visited_rooms.sort()
	_make_solid(Rect2(0, 600, 1200, 120))
	_make_solid(Rect2(-40, 350, 40, 250))
	_make_solid(Rect2(1200, 350, 40, 250))
	player = PLAYER_SCRIPT.new()
	player.position = Vector2(120, 570)
	player.has_dash = bool(saved_data.get("has_dash", false))
	player.has_heavy = bool(saved_data.get("has_heavy", false))
	player.healing_charges = int(saved_data.get("healing_charges", 3))
	add_child(player)
	player.healed.connect(_save_progress)
	var camera := player.get_node("Camera2D") as Camera2D
	camera.limit_left = 0
	camera.limit_right = 1200
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = HUD_SCRIPT.new()
	layer.add_child(hud)
	_add_backdrop()
	pause_menu = preload("res://scripts/pause_menu.gd").new()
	add_child(pause_menu)
	loading_overlay = LOADING_OVERLAY.new()
	add_child(loading_overlay)
	world_map = WORLD_MAP.new()
	add_child(world_map)
	if get_tree().has_meta("arriving_room_transition"):
		get_tree().remove_meta("arriving_room_transition")
		loading_overlay.reveal_room()
	_save_progress()

func _add_backdrop() -> void:
	var background := TextureRect.new()
	background.position = Vector2(0, -60)
	background.size = Vector2(1200, 780)
	background.z_index = -100
	background.texture = FOREST_BACKDROP
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

func _make_solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _process(delta: float) -> void:
	elapsed_seconds += delta
	save_timer += delta
	if save_timer >= 10.0:
		save_timer = 0.0
		_save_progress()
	if not transitioning and player.global_position.x < 40.0:
		_return_to_cave()
	hud.health = player.health
	hud.max_health = player.max_health
	hud.level = player_level
	hud.will_amount = will_amount
	hud.healing_charges = player.healing_charges
	hud.max_healing_charges = player.max_healing_charges
	hud.has_dash = player.has_dash
	hud.has_heavy = player.has_heavy
	hud.area = "FOREST EDGE"
	hud.prompt = "The forest begins here. Return through the stone arch to the cave."
	hud.queue_redraw()
	queue_redraw()

func _return_to_cave() -> void:
	transitioning = true
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	_save_progress()
	await loading_overlay.cover_room()
	get_tree().set_meta("arriving_room_transition", true)
	get_tree().set_meta("cave_entry_x", 4370.0)
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_M, KEY_TAB]:
		if not transitioning and not get_tree().paused:
			world_map.show_map(visited_rooms, _completed_rooms(), 5)
			get_viewport().set_input_as_handled()

func _completed_rooms() -> Array[int]:
	var completed: Array[int] = []
	if visited_rooms.has(1):
		completed.append(1)
	if visited_rooms.has(2) and bool(saved_data.get("secret_found", false)):
		completed.append(2)
	if visited_rooms.has(3) and bool(saved_data.get("note_found", false)) and player.has_dash:
		completed.append(3)
	if visited_rooms.has(4) and bool(saved_data.get("boss_defeated", false)):
		completed.append(4)
	completed.append(5)
	return completed

func _save_progress() -> void:
	if active_save_slot <= 0:
		return
	var data: Dictionary = saved_data.duplicate()
	if data.is_empty():
		data = SAVE_SLOTS.new_slot()
	data["area"] = "Forest Edge"
	data["room"] = 5
	data["seconds"] = elapsed_seconds
	data["will"] = will_amount
	data["level"] = player_level
	data["healing_charges"] = player.healing_charges
	data["checkpoint_x"] = 120.0
	data["has_dash"] = player.has_dash
	data["has_heavy"] = player.has_heavy
	data["visited_rooms"] = visited_rooms.duplicate()
	var result: Error = SAVE_SLOTS.write_slot(active_save_slot, data, save_root)
	if result != OK:
		push_error("Could not save forest progress: %s" % error_string(result))
	saved_data = data

func _exit_tree() -> void:
	if is_instance_valid(player):
		_save_progress()

func _draw() -> void:
	draw_rect(Rect2(0, 600, 1200, 120), Color(0.18, 0.26, 0.22))
	draw_rect(Rect2(0, 600, 1200, 10), Color(0.35, 0.51, 0.32))
	draw_rect(Rect2(0, 390, 15, 210), Color(0.27, 0.36, 0.37))
	draw_rect(Rect2(66, 390, 15, 210), Color(0.27, 0.36, 0.37))
	draw_rect(Rect2(0, 380, 81, 18), Color(0.38, 0.49, 0.47))
	draw_rect(Rect2(15, 398, 51, 202), Color(0.07, 0.19, 0.18, 0.6))
	draw_string(ThemeDB.fallback_font, Vector2(96, 450), "TO CAVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.85, 0.94, 0.75))
