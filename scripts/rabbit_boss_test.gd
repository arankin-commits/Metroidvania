extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const HUD_SCRIPT = preload("res://scripts/hud.gd")

@onready var rabbit_boss: RabbitBoss = $RabbitBoss
var player: CharacterBody2D
var hud: Control
var feedback_message := ""
var feedback_timer := 0.0

func _ready() -> void:
	player = PLAYER_SCRIPT.new()
	player.name = "Player"
	player.position = Vector2(620.0, 537.0)
	player.collision_layer = 4
	player.collision_mask = 1
	add_child(player)
	rabbit_boss.player = player
	rabbit_boss.active = true
	rabbit_boss.collision_layer = 2
	rabbit_boss.collision_mask = 1
	rabbit_boss.global_position = Vector2(340.0, 504.0)
	player.attacked.connect(_on_player_attacked)
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.position = Vector2.ZERO
		camera.offset = Vector2.ZERO
		camera.position_smoothing_enabled = false
		camera.limit_left = 0
		camera.limit_right = 1280
		camera.limit_top = 0
		camera.limit_bottom = 720
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "HUDLayer"
	hud_layer.layer = 10
	add_child(hud_layer)
	hud = HUD_SCRIPT.new()
	hud.name = "HUD"
	hud.boss_max_health = int(rabbit_boss.max_health)
	hud.boss_title = "RABBIT, THE WALL-CLINGER"
	hud.prompt = "A/D Move  Space Jump  J Attack"
	hud_layer.add_child(hud)
	_update_hud()

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
	hud.boss_health = rabbit_boss.health if is_instance_valid(rabbit_boss) else 0.0
	hud.notice = feedback_message if feedback_timer > 0.0 else ""
	if is_instance_valid(rabbit_boss) and rabbit_boss.is_telegraphing and feedback_timer <= 0.0:
		hud.notice = "P O U N C E  W A R N I N G"
	hud.queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color("101a20"))
	draw_rect(Rect2(64.0, 72.0, 1152.0, 488.0), Color("1a2a30"))
	draw_rect(Rect2(64.0, 72.0, 1152.0, 488.0), Color("34464a"), false, 4.0)
	for x in [160.0, 360.0, 560.0, 760.0, 960.0, 1120.0]:
		draw_rect(Rect2(x, 112.0, 8.0, 400.0), Color("22363b"))
	draw_rect(Rect2(64.0, 530.0, 1152.0, 30.0), Color("27383b"))

func _on_player_attacked(hitbox: Rect2) -> void:
	if is_instance_valid(rabbit_boss) and hitbox.intersects(rabbit_boss.combat_bounds()):
		var previous_health := rabbit_boss.health
		rabbit_boss.take_hit()
		if rabbit_boss.health < previous_health:
			feedback_message = "BOSS HIT  %d / %d" % [int(rabbit_boss.health), int(rabbit_boss.max_health)]
		else:
			feedback_message = "BOSS BLOCKED THE HIT"
	else:
		feedback_message = "MISS"
	feedback_timer = 1.0
