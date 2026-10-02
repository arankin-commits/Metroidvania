extends Node2D

const PLAYER_SCRIPT := preload("res://scripts/player.gd")
const HUD_SCRIPT := preload("res://scripts/hud.gd")

@onready var ironback: CharacterBody2D = $Ironback
var player: CharacterBody2D
var hud: Control
var feedback_message := ""
var feedback_timer := 0.0

func _ready() -> void:
	player = PLAYER_SCRIPT.new()
	player.name = "Player"
	player.position = Vector2(860.0, 537.0)
	player.collision_layer = 4
	player.collision_mask = 1
	add_child(player)
	ironback.player = player
	ironback.active = true
	ironback.collision_layer = 2
	ironback.collision_mask = 1
	player.attacked.connect(_on_player_attacked)
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.position = Vector2.ZERO
		camera.offset = Vector2.ZERO
		camera.position_smoothing_enabled = false
		camera.limit_left = 0
		camera.limit_right = 1400
		camera.limit_top = 0
		camera.limit_bottom = 720
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "HUDLayer"
	hud_layer.layer = 10
	add_child(hud_layer)
	hud = HUD_SCRIPT.new()
	hud.name = "HUD"
	hud.boss_max_health = int(ironback.max_health)
	hud.boss_title = "IRONBACK, THE SEISMIC FIST"
	hud.prompt = "A/D Move  Space Jump  J Attack"
	hud_layer.add_child(hud)
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key_event := event as InputEventKey
	match key_event.keycode:
		KEY_F1:
			_reset_test_state()
		KEY_F2:
			ironback.call("force_attack", "smash")
		KEY_F3:
			ironback.call("force_attack", "backhand")
		KEY_F4:
			ironback.call("force_attack", "leap")
		KEY_F5:
			ironback.call("force_attack", "rush")
		KEY_F6:
			ironback.call("force_attack", "barrage")
		KEY_F7:
			ironback.phase_two = true
			ironback.health = minf(ironback.health, ironback.max_health * 0.5)
		KEY_F8:
			player.has_dash = not player.has_dash
		KEY_F9:
			player.equipped_weapon = "scimitar" if player.equipped_weapon == "starter" else "starter"
		KEY_F10:
			ironback.call("debug_walk", -1)
		KEY_F11:
			ironback.call("debug_walk", 1)

func _reset_test_state() -> void:
	player.global_position = Vector2(1080.0, 537.0)
	player.velocity = Vector2.ZERO
	player.health = player.max_health
	player.has_dash = false
	player.equipped_weapon = "starter"
	ironback.call("reset_encounter")
	feedback_message = "RESET"
	feedback_timer = 1.0

func _process(delta: float) -> void:
	feedback_timer = maxf(0.0, feedback_timer - delta)
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
	hud.has_bow = player.has_bow
	hud.bow_ammo = player.bow_ammo
	hud.boss_health = ironback.health if is_instance_valid(ironback) else 0.0
	hud.notice = feedback_message if feedback_timer > 0.0 else ""
	if is_instance_valid(ironback) and feedback_timer <= 0.0:
		hud.notice = "%s  %.2fs  FACING %s  WAVES %d" % [ironback.state.to_upper(), ironback.state_time, "R" if ironback.facing > 0 else "L", get_tree().get_nodes_in_group("ironback_shockwaves").size()]
	hud.queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color("0c1720"))
	draw_circle(Vector2(640.0, 390.0), 260.0, Color("132630"))
	draw_rect(Rect2(64.0, 72.0, 1152.0, 488.0), Color("172a31"))
	draw_rect(Rect2(64.0, 72.0, 1152.0, 488.0), Color("2e5360"), false, 4.0)
	draw_rect(Rect2(64.0, 530.0, 1152.0, 30.0), Color("263b40"))
	draw_line(Vector2(140.0, 530.0), Vector2(1140.0, 530.0), Color("bb7a38"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(82.0, 104.0), "F1 RESET  F2-F6 ATTACKS  F7 PHASE 2  F8 DASH  F9 WEAPON  F10/F11 WALK L/R", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("9bb6b9"))

func _on_player_attacked(hitbox: Rect2) -> void:
	if is_instance_valid(ironback) and hitbox.intersects(ironback.combat_bounds()):
		var previous_health: float = ironback.health
		ironback.take_hit()
		feedback_message = "IRONBACK HIT  %d / %d" % [int(ironback.health), int(ironback.max_health)] if ironback.health < previous_health else "IRONBACK BLOCKED THE HIT"
	else:
		feedback_message = "MISS"
	feedback_timer = 1.0