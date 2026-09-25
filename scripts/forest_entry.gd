extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const HUD_SCRIPT = preload("res://scripts/hud.gd")
const SAVE_SLOTS = preload("res://scripts/save_slots.gd")
const LOADING_OVERLAY = preload("res://scripts/loading_overlay.gd")
const FOREST_BACKDROP = preload("res://assets/forest_backdrop.png")

var player: CharacterBody2D
var hud: Control
var pause_menu: CanvasLayer
var loading_overlay: CanvasLayer
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
	_save_progress()

func _add_backdrop() -> void:
	var background_layer := CanvasLayer.new()
	background_layer.layer = -10
	add_child(background_layer)
	var background := TextureRect.new()
	background.texture = FOREST_BACKDROP
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_layer.add_child(background)

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
	if not transitioning and player.global_position.x < 60.0:
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
	loading_overlay.show_room("Cave Room 4")
	await get_tree().create_timer(0.45).timeout
	get_tree().set_meta("cave_entry_x", 4100.0)
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")

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
	draw_rect(Rect2(0, 350, 52, 250), Color(0.31, 0.37, 0.34))
	draw_circle(Vector2(65, 520), 38, Color(0.35, 0.87, 0.72, 0.22))
	draw_string(ThemeDB.fallback_font, Vector2(65, 465), "TO CAVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.85, 0.94, 0.75))
