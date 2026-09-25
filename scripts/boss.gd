extends Node2D

signal defeated
signal attack_cued(cue: String)

var player: CharacterBody2D
var health := 8.0
var max_health := 8.0
var active := false
var state := "idle"
var state_time := 0.0
var attack_direction := -1
var hurt_flash := 0.0
var _hit_this_charge := false
var attack_count := 0
var _hit_this_slam := false

func _ready() -> void:
	add_to_group("mcp_watch")

func _process(delta: float) -> void:
	if health <= 0 or not active:
		return
	hurt_flash = maxf(0.0, hurt_flash - delta)
	state_time -= delta
	match state:
		"idle":
			if state_time <= 0.0:
				if attack_count % 2 == 0:
					state = "telegraph"
					state_time = 0.85
					attack_direction = 1 if player.global_position.x > global_position.x else -1
					attack_cued.emit("warden_charge_tell")
				else:
					state = "telegraph_slam"
					state_time = 0.9
					attack_cued.emit("warden_slam_tell")
				attack_count += 1
		"telegraph":
			if state_time <= 0.0:
				state = "charge"
				state_time = 0.42
				_hit_this_charge = false
				attack_cued.emit("warden_charge")
		"charge":
			position.x = clampf(position.x + attack_direction * 520.0 * delta, 3150.0, 3760.0)
			if state_time <= 0.0:
				state = "recover"
				state_time = 1.2
		"telegraph_slam":
			if state_time <= 0.0:
				state = "slam"
				state_time = 0.24
				_hit_this_slam = false
				attack_cued.emit("warden_slam")
		"slam":
			if not _hit_this_slam and absf(player.global_position.x - global_position.x) < 190.0 and player.global_position.y > 490.0:
				player.take_damage(1, global_position.x)
				_hit_this_slam = true
			if state_time <= 0.0:
				state = "recover"
				state_time = 1.2
		"recover":
			if state_time <= 0.0:
				state = "idle"
				state_time = 0.4
	var boss_bounds := Rect2(global_position - Vector2(48, 55), Vector2(96, 100))
	var player_bounds := Rect2(player.global_position - Vector2(14, 23), Vector2(28, 46))
	if boss_bounds.grow(4.0).intersects(player_bounds):
		player.take_damage(1, global_position.x)
	queue_redraw()

func take_hit(amount: float = 1.0) -> void:
	if health <= 0 or not active:
		return
	health -= amount
	hurt_flash = 0.16
	if health <= 0:
		state = "defeated"
		defeated.emit()
	queue_redraw()

func _draw() -> void:
	if health <= 0:
		return
	if state == "telegraph":
		draw_rect(Rect2(-30 if attack_direction > 0 else -250, 34, 280, 8), Color(1.0, 0.28, 0.32, 0.55))
	if state == "telegraph_slam":
		draw_rect(Rect2(-190, 42, 380, 8), Color(1.0, 0.66, 0.20, 0.62))
		for x in range(-180, 181, 30):
			draw_rect(Rect2(x, 34, 12, 8), Color(1.0, 0.78, 0.30, 0.78))
	if state == "slam":
		draw_rect(Rect2(-190, 31, 380, 19), Color(1.0, 0.45, 0.14, 0.73))
	var body_color := Color(1.0, 0.83, 0.59) if hurt_flash > 0.0 else Color(0.58, 0.29, 0.48)
	draw_circle(Vector2.ZERO, 64, Color(0.90, 0.28, 0.44, 0.11))
	draw_colored_polygon(PackedVector2Array([Vector2(-48, 35), Vector2(-43, -30), Vector2(-20, -55), Vector2(20, -55), Vector2(43, -30), Vector2(48, 35)]), body_color)
	draw_colored_polygon(PackedVector2Array([Vector2(-45, -35), Vector2(-60, -78), Vector2(-13, -52)]), Color(0.26, 0.17, 0.30))
	draw_colored_polygon(PackedVector2Array([Vector2(45, -35), Vector2(60, -78), Vector2(13, -52)]), Color(0.26, 0.17, 0.30))
	draw_rect(Rect2(-31, -31, 62, 26), Color(0.20, 0.15, 0.29))
	draw_circle(Vector2(-15, -20), 5, Color(1.0, 0.68, 0.40))
	draw_circle(Vector2(15, -20), 5, Color(1.0, 0.68, 0.40))
	draw_line(Vector2(-37, 32), Vector2(-50, 43), Color(0.17, 0.13, 0.25), 10)
	draw_line(Vector2(37, 32), Vector2(50, 43), Color(0.17, 0.13, 0.25), 10)
	if state == "charge":
		draw_arc(Vector2.ZERO, 57, 0, TAU, 32, Color(1.0, 0.40, 0.38, 0.65), 5)
	if state == "slam":
		draw_arc(Vector2.ZERO, 75, 0, TAU, 32, Color(1.0, 0.67, 0.25, 0.7), 7)

func _mcp_state() -> Dictionary:
	return {"health": health, "active": active, "state": state}
