class_name BowBoss
extends Node2D

signal defeated
signal attack_cued(cue: String)

const ARROW_SCRIPT = preload("res://scripts/bow_arrow.gd")
const BOW_TEXTURE = preload("res://32x32pixelart_assets02_weapons_png/weapon06bow.png")

var player: CharacterBody2D
var health := 10.0
var max_health := 10.0
var active := false
var state := "idle"
var state_time := 0.0
var attack_cooldown := 0.0
var invulnerability := 0.0
var facing := -1
var bow_sprite: Sprite2D

func _ready() -> void:
	add_to_group("mcp_watch")
	add_to_group("bow_targets")
	bow_sprite = Sprite2D.new()
	bow_sprite.texture = BOW_TEXTURE
	bow_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bow_sprite.scale = Vector2(1.35, 1.35)
	bow_sprite.position = Vector2(24, -8)
	add_child(bow_sprite)
	queue_redraw()

func _process(delta: float) -> void:
	if health <= 0 or not active or player == null:
		return
	state_time = maxf(0.0, state_time - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	invulnerability = maxf(0.0, invulnerability - delta)
	var distance := absf(player.global_position.x - global_position.x)
	facing = 1 if player.global_position.x > global_position.x else -1
	bow_sprite.flip_h = facing < 0
	if state == "idle":
		if distance < 235.0:
			position.x = move_toward(position.x, player.global_position.x - facing * 330.0, 180.0 * delta)
		elif distance > 380.0:
			position.x = move_toward(position.x, player.global_position.x - facing * 300.0, 120.0 * delta)
		if attack_cooldown <= 0.0 and distance <= 430.0:
			state = "telegraph"
			state_time = 0.65
			attack_cued.emit("bow_charge")
	elif state == "telegraph":
		if state_time <= 0.0:
			state = "recover"
			state_time = 0.28
			attack_cooldown = 1.0
			_fire_arrow()
	elif state == "recover":
		if state_time <= 0.0:
			state = "idle"
	queue_redraw()

func _fire_arrow() -> void:
	var arrow := ARROW_SCRIPT.new()
	var direction := (player.global_position - global_position).normalized()
	get_parent().add_child(arrow)
	arrow.setup(global_position + direction * 30.0, direction, player)

func take_hit(amount: float = 1.0) -> void:
	if health <= 0 or invulnerability > 0.0:
		return
	health -= amount
	invulnerability = 0.12
	if health <= 0:
		state = "defeated"
		defeated.emit()
	queue_redraw()

func _draw() -> void:
	var body_color := Color(1.0, 0.83, 0.59) if invulnerability > 0.0 else Color("#365c67")
	draw_rect(Rect2(-30, -64, 60, 7), Color("#09131a"), true)
	draw_rect(Rect2(-28, -62, 56.0 * float(health) / float(max_health), 3), Color("#e67b64"), true)
	draw_circle(Vector2.ZERO, 42, Color(0.30, 0.60, 0.64, 0.12))
	draw_colored_polygon(PackedVector2Array([Vector2(-30, 35), Vector2(-26, -32), Vector2(-12, -51), Vector2(16, -48), Vector2(31, -20), Vector2(28, 35)]), body_color)
	draw_rect(Rect2(-18, -28, 36, 22), Color("#1c2934"), true)
	draw_circle(Vector2(12.0 * facing, -17), 4, Color("#ffd77a"))
	if state == "telegraph":
		draw_line(Vector2(24.0 * facing, -6), Vector2(220.0 * facing, -6), Color(0.95, 0.32, 0.38, 0.45), 3.0, true)

func _mcp_state() -> Dictionary:
	return {"health": health, "active": active, "state": state}
