extends Node2D

const PLAYER_SCRIPT := preload("res://scripts/player.gd")
const HUD_SCRIPT := preload("res://scripts/hud.gd")
@onready var gloamweaver: CharacterBody2D = $Gloamweaver
var player: CharacterBody2D
var hud: Control

func _ready() -> void:
	player = PLAYER_SCRIPT.new(); player.name = "Player"; player.position = Vector2(300.0, 567.0); player.collision_layer = 4; player.collision_mask = 1; add_child(player)
	gloamweaver.player = player; gloamweaver.active = true; gloamweaver.collision_layer = 2; gloamweaver.collision_mask = 1
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null: camera.position = Vector2.ZERO; camera.position_smoothing_enabled = false; camera.limit_left = 0; camera.limit_right = 1400; camera.limit_top = 0; camera.limit_bottom = 720
	var layer := CanvasLayer.new(); layer.name = "HUDLayer"; add_child(layer); hud = HUD_SCRIPT.new(); hud.name = "HUD"; hud.boss_max_health = 24; hud.boss_title = "GLOAMWEAVER, THE SILK HUNGER"; hud.prompt = "A/D Move  Space Jump  J Attack"; layer.add_child(hud)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match (event as InputEventKey).keycode:
		KEY_F1: gloamweaver.reset_encounter(); player.clear_gloamweaver_slow()
		KEY_F2: gloamweaver.force_attack("swing")
		KEY_F3: gloamweaver.force_attack("zip")
		KEY_F4: gloamweaver.force_attack("trap")
		KEY_F5: gloamweaver.force_attack("drop")
		KEY_F6: gloamweaver.force_attack("bite")
		KEY_F7: gloamweaver.force_attack("double_swing")
		KEY_F8: gloamweaver.debug_walk(-1)
		KEY_F9: gloamweaver.debug_walk(1)
		KEY_F10: player.has_dash = not player.has_dash

func _process(_delta: float) -> void:
	if hud == null: return
	hud.health = player.health; hud.max_health = player.max_health; hud.boss_health = gloamweaver.health; hud.boss_max_health = int(gloamweaver.max_health); hud.has_dash = player.has_dash
	hud.notice = "%s  %.2fs  %s  TRAPS %d" % [gloamweaver.state.to_upper(), gloamweaver.state_time, gloamweaver.support.to_upper(), get_tree().get_nodes_in_group("gloamweaver_traps").size()]
	hud.queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1400.0, 720.0), Color("111526")); draw_rect(Rect2(64.0, 60.0, 1272.0, 560.0), Color("1b2038")); draw_rect(Rect2(64.0, 60.0, 1272.0, 560.0), Color("594d78"), false, 4.0); draw_rect(Rect2(64.0, 60.0, 1272.0, 22.0), Color("343553")); draw_rect(Rect2(64.0, 596.0, 1272.0, 24.0), Color("302d44")); draw_string(ThemeDB.fallback_font, Vector2(84.0, 110.0), "F1 RESET  F2 SWING  F3 ZIP  F4 TRAP  F5 DROP  F6 BITE  F7 DOUBLE SWING  F8/F9 CRAWL  F10 DASH", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("d1c4e4"))