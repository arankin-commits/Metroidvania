extends Node2D

const PLAYER_SCRIPT := preload("res://scripts/player.gd")
const HUD_SCRIPT := preload("res://scripts/hud.gd")
@onready var gloamweaver: CharacterBody2D = $Gloamweaver
var player: CharacterBody2D
var hud: Control
var feedback_message := ""
var feedback_time := 0.0

func _ready() -> void:
	player = PLAYER_SCRIPT.new(); player.name = "Player"; player.position = Vector2(300.0, 567.0); player.collision_layer = 4; player.collision_mask = 1; add_child(player)
	gloamweaver.player = player; gloamweaver.active = true; gloamweaver.collision_layer = 2; gloamweaver.collision_mask = 1
	player.attacked.connect(_on_player_attacked)
	player.heavy_attacked.connect(_on_player_attacked)
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null: camera.position = Vector2.ZERO; camera.position_smoothing_enabled = false; camera.limit_left = 0; camera.limit_right = 1400; camera.limit_top = 0; camera.limit_bottom = 720
	var layer := CanvasLayer.new(); layer.name = "HUDLayer"; add_child(layer); hud = HUD_SCRIPT.new(); hud.name = "HUD"; hud.boss_max_health = 24; hud.boss_title = "GLOAMWEAVER, THE SILK HUNGER"; hud.prompt = "A/D Move  Space Jump  J Attack"; layer.add_child(hud)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match (event as InputEventKey).keycode:
		KEY_F1: gloamweaver.reset_encounter(); player.clear_gloamweaver_slow()
		KEY_F2: gloamweaver.force_attack("bite")
		KEY_F3: gloamweaver.force_attack("charge")
		KEY_F4: gloamweaver.force_attack("trap")
		KEY_F5: gloamweaver.take_hit(1.0)
		KEY_F6: gloamweaver.take_hit(99.0)
		KEY_F8: gloamweaver.debug_walk(-1)
		KEY_F9: gloamweaver.debug_walk(1)
		KEY_F10: player.has_dash = not player.has_dash

func _process(_delta: float) -> void:
	if hud == null: return
	feedback_time = maxf(0.0, feedback_time - _delta)
	hud.health = player.health; hud.max_health = player.max_health; hud.boss_health = gloamweaver.health; hud.boss_max_health = int(gloamweaver.max_health); hud.has_dash = player.has_dash
	var slow_multiplier := 0.70 if player.gloamweaver_slow_until > Time.get_ticks_msec() / 1000.0 and player.is_on_floor() else 1.0
	hud.notice = feedback_message if feedback_time > 0.0 else "%s  %.2fs  %s  TRAPS %d  SPEED %.1f (x%.2f)" % [gloamweaver.state.to_upper(), gloamweaver.state_time, gloamweaver.support_state.to_upper(), get_tree().get_nodes_in_group("gloamweaver_traps").size(), absf(player.velocity.x), slow_multiplier]
	hud.queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1400.0, 720.0), Color("111526")); draw_rect(Rect2(64.0, 72.0, 1272.0, 524.0), Color("1b2038")); draw_rect(Rect2(64.0, 72.0, 1272.0, 524.0), Color("594d78"), false, 4.0); draw_rect(Rect2(64.0, 596.0, 1272.0, 24.0), Color("302d44")); draw_string(ThemeDB.fallback_font, Vector2(84.0, 110.0), "F1 RESET  F2 BITE  F3 CHARGE  F4 SNARE  F5 HURT  F6 DEFEAT  F8/F9 CRAWL  F10 DASH", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("d1c4e4"))
	if is_instance_valid(gloamweaver):
		var boss_bounds: Rect2 = gloamweaver.combat_bounds()
		draw_rect(Rect2(boss_bounds.position, boss_bounds.size), Color(0.95, 0.35, 0.65, 0.55), false, 2.0)
		draw_circle(gloamweaver._spinneret_world(), 4.0, Color("f5d8ff"))
		draw_circle(gloamweaver.anchor_a, 4.0, Color("c8b1e9")); draw_circle(gloamweaver.anchor_b, 4.0, Color("c8b1e9"))
	for trap in get_tree().get_nodes_in_group("gloamweaver_traps"):
		if is_instance_valid(trap): draw_rect(Rect2(trap.global_position - Vector2(50.0, 24.0), Vector2(100.0, 24.0)), Color(0.72, 0.35, 0.86, 0.65), false, 2.0)

func _on_player_attacked(hitbox: Rect2) -> void:
	if not is_instance_valid(gloamweaver) or not hitbox.intersects(gloamweaver.combat_bounds()):
		return
	var health_before: float = gloamweaver.health
	gloamweaver.take_hit(1.0)
	if gloamweaver.health < health_before:
		feedback_message = "GLOAMWEAVER HIT  %d / %d" % [int(gloamweaver.health), int(gloamweaver.max_health)]
	else:
		feedback_message = "GLOAMWEAVER HIT BLOCKED"
	feedback_time = 1.0