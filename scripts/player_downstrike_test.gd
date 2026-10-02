extends Node2D

const PLAYER_SCRIPT := preload("res://scripts/player.gd")
const HUD_SCRIPT := preload("res://scripts/hud.gd")

var player: CharacterBody2D
var hud: Control
var feedback := ""
var feedback_time := 0.0

func _ready() -> void:
	player = PLAYER_SCRIPT.new()
	player.name = "Player"
	player.position = Vector2(280.0, 537.0)
	player.collision_layer = 1
	player.collision_mask = 1
	add_child(player)
	player.has_downstrike = true
	player.downstrike.unlocked = true
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.position = Vector2.ZERO
		camera.position_smoothing_enabled = false
		camera.limit_left = 0
		camera.limit_right = 1280
		camera.limit_top = 0
		camera.limit_bottom = 720
	var layer := CanvasLayer.new()
	layer.name = "HUDLayer"
	layer.layer = 10
	add_child(layer)
	hud = HUD_SCRIPT.new()
	hud.name = "HUD"
	hud.prompt = "A/D Move  Space Jump  E Groundbreaker  J Attack"
	layer.add_child(hud)
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match (event as InputEventKey).keycode:
		KEY_R:
			_reset_test()
		KEY_E:
			feedback = "GROUNDBREAKER ENABLED"
			feedback_time = 0.7

func _reset_test() -> void:
	player.global_position = Vector2(280.0, 537.0)
	player.velocity = Vector2.ZERO
	player.health = player.max_health
	player.reset_movement_state()
	player.has_downstrike = true
	player.downstrike.unlocked = true
	feedback = "RESET  E IS UNLOCKED"
	feedback_time = 1.0

func _process(delta: float) -> void:
	feedback_time = maxf(0.0, feedback_time - delta)
	_update_hud()

func _update_hud() -> void:
	if hud == null or not is_instance_valid(player):
		return
	hud.health = player.health
	hud.max_health = player.max_health
	hud.healing_charges = player.healing_charges
	hud.max_healing_charges = player.max_healing_charges
	hud.equipped_weapon = player.equipped_weapon
	hud.has_dash = player.has_dash
	hud.has_heavy = player.has_heavy
	hud.notice = feedback if feedback_time > 0.0 else ("GROUNDBREAKER READY" if not player.downstrike.active() else "GROUNDBREAKER ACTIVE")
	hud.queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color("0d1822"))
	draw_rect(Rect2(48.0, 88.0, 1184.0, 472.0), Color("172c36"))
	draw_rect(Rect2(48.0, 88.0, 1184.0, 472.0), Color("3d6871"), false, 4.0)
	draw_rect(Rect2(48.0, 530.0, 1184.0, 30.0), Color("294149"))
	draw_string(ThemeDB.fallback_font, Vector2(68.0, 122.0), "PLAYER DOWNSTRIKE TEST  |  E: ability  R: reset  |  has_downstrike = true", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("bfeee7"))