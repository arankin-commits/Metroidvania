extends CharacterBody2D

signal attacked(hitbox: Rect2)
signal heavy_attacked(hitbox: Rect2)
signal dodged
signal healed
signal damaged
signal died

const SPEED := 255.0
const GRAVITY := 1250.0
const JUMP_SPEED := -500.0
const DASH_SPEED := 780.0
const FOOTSTEP = preload("res://assets/footstep.wav")

var health := 5
var max_health := 5
var healing_charges := 3
var max_healing_charges := 3
var _heal_was_down := false
var has_dash := false
var has_heavy := false
var heavy_charge := 0.0
var heavy_attack_time := 0.0
var heavy_cooldown := 0.0
var _heavy_was_down := false
var facing := 1
var controls_enabled := true
var invulnerability := 0.0
var attack_time := 0.0
var attack_cooldown := 0.0
var dash_time := 0.0
var dash_cooldown := 0.0
var dash_speed_current := 0.0
var coyote_time := 0.0
var jump_buffer := 0.0
var _jump_was_down := false
var _attack_was_down := false
var _dash_was_down := false
var footstep_audio: AudioStreamPlayer2D
var footstep_timer := 0.0
var footstep_count := 0

func _ready() -> void:
	add_to_group("mcp_watch")
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28, 46)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2(0, -100)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.limit_left = -1200
	camera.limit_right = 4450
	camera.limit_top = -60
	camera.limit_bottom = 720
	add_child(camera)
	camera.make_current()
	footstep_audio = AudioStreamPlayer2D.new()
	footstep_audio.stream = FOOTSTEP
	footstep_audio.volume_db = -10.0
	add_child(footstep_audio)

func _physics_process(delta: float) -> void:
	invulnerability = maxf(0.0, invulnerability - delta)
	attack_time = maxf(0.0, attack_time - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	heavy_attack_time = maxf(0.0, heavy_attack_time - delta)
	heavy_cooldown = maxf(0.0, heavy_cooldown - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	if is_on_floor():
		coyote_time = 0.10
	else:
		coyote_time = maxf(0.0, coyote_time - delta)
	var jump_down := controls_enabled and (Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	var attack_down := controls_enabled and (Input.is_physical_key_pressed(KEY_J) or Input.is_physical_key_pressed(KEY_X))
	var dash_down := controls_enabled and (Input.is_physical_key_pressed(KEY_K) or Input.is_physical_key_pressed(KEY_SHIFT))
	var heavy_down := controls_enabled and has_heavy and Input.is_physical_key_pressed(KEY_H)
	var heal_down := controls_enabled and Input.is_physical_key_pressed(KEY_F)
	if heal_down and not _heal_was_down and health > 0 and health < max_health and healing_charges > 0:
		healing_charges -= 1
		health = mini(max_health, health + 2)
		healed.emit()
	_heal_was_down = heal_down
	if jump_down and not _jump_was_down:
		jump_buffer = 0.13
	else:
		jump_buffer = maxf(0.0, jump_buffer - delta)
	if controls_enabled and attack_down and not _attack_was_down and attack_cooldown <= 0.0:
		attack_time = 0.17
		attack_cooldown = 0.30
		attacked.emit(Rect2(global_position + Vector2(10 if facing > 0 else -82, -28), Vector2(72, 56)))
	if controls_enabled and dash_down and not _dash_was_down and dash_cooldown <= 0.0:
		if has_dash:
			dash_time = 0.23
			dash_speed_current = DASH_SPEED
			dash_cooldown = 0.65
			invulnerability = maxf(invulnerability, 0.25)
		elif is_on_floor():
			dash_time = 0.17
			dash_speed_current = 450.0
			dash_cooldown = 0.75
			invulnerability = maxf(invulnerability, 0.19)
			dodged.emit()
	if heavy_down and heavy_cooldown <= 0.0:
		heavy_charge = minf(1.0, heavy_charge + delta / 0.8)
	elif _heavy_was_down:
		if heavy_charge >= 1.0 and controls_enabled:
			heavy_attack_time = 0.25
			heavy_cooldown = 0.65
			heavy_attacked.emit(Rect2(global_position + Vector2(10 if facing > 0 else -106, -40), Vector2(96, 80)))
		heavy_charge = 0.0
	_dash_was_down = dash_down
	_heavy_was_down = heavy_down
	_attack_was_down = attack_down
	_jump_was_down = jump_down
	if dash_time > 0.0:
		dash_time -= delta
		velocity = Vector2(facing * dash_speed_current, 0)
	else:
		var direction := 0.0
		if controls_enabled:
			direction = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		if direction != 0.0:
			facing = 1 if direction > 0 else -1
		velocity.x = move_toward(velocity.x, direction * SPEED, 1700.0 * delta)
		velocity.y += GRAVITY * delta
		if jump_buffer > 0.0 and coyote_time > 0.0:
			velocity.y = JUMP_SPEED
			jump_buffer = 0.0
			coyote_time = 0.0
	move_and_slide()
	if controls_enabled and is_on_floor() and absf(velocity.x) > 55.0 and dash_time <= 0.0:
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			footstep_audio.pitch_scale = 0.93 if footstep_count % 2 == 0 else 1.05
			footstep_audio.play()
			footstep_count += 1
			footstep_timer = 0.32
	else:
		footstep_timer = 0.0
	queue_redraw()

func take_damage(amount: int, from_x: float) -> void:
	if invulnerability > 0.0 or health <= 0:
		return
	health -= amount
	damaged.emit()
	invulnerability = 1.0
	velocity = Vector2(260.0 if global_position.x > from_x else -260.0, -260.0)
	if health <= 0:
		died.emit()
	queue_redraw()

func heal_full() -> void:
	health = max_health
	invulnerability = 0.0
	queue_redraw()

func _draw() -> void:
	var alpha := 0.55 if invulnerability > 0.0 and Engine.get_physics_frames() % 6 < 3 else 1.0
	var cloak := Color(0.13, 0.80, 0.79, alpha)
	var dark := Color(0.08, 0.16, 0.25, alpha)
	draw_circle(Vector2(0, -6), 24, Color(0.08, 0.79, 0.82, 0.12 * alpha))
	draw_colored_polygon(PackedVector2Array([Vector2(-13, -16), Vector2(13, -16), Vector2(18, 22), Vector2(0, 13), Vector2(-18, 22)]), cloak)
	draw_rect(Rect2(-11, -24, 22, 19), dark)
	draw_circle(Vector2(facing * 5, -16), 3, Color(1.0, 0.88, 0.45, alpha))
	draw_line(Vector2(-9, 23), Vector2(-9, 31), dark, 5)
	draw_line(Vector2(9, 23), Vector2(9, 31), dark, 5)
	if attack_time > 0.0:
		draw_arc(Vector2(facing * 18, -6), 40, -1.0 if facing > 0 else 2.1, 1.1 if facing > 0 else 4.2, 16, Color(1.0, 0.86, 0.45), 7)
	if dash_time > 0.0:
		for i in 3:
			draw_circle(Vector2(-facing * (18 + i * 13), 0), 10 - i * 2, Color(0.13, 0.80, 0.79, 0.25))
	if heavy_charge > 0.0:
		draw_arc(Vector2(0, -7), 28, -PI / 2.0, -PI / 2.0 + TAU * heavy_charge, 20, Color(1.0, 0.78, 0.36), 4)
	if heavy_attack_time > 0.0:
		draw_arc(Vector2(facing * 28, -6), 56, -1.1 if facing > 0 else 2.0, 1.1 if facing > 0 else 4.2, 18, Color(1.0, 0.75, 0.33), 10)

func _mcp_state() -> Dictionary:
	return {"health": health, "healing_charges": healing_charges, "has_dash": has_dash, "has_heavy": has_heavy, "heavy_charge": heavy_charge, "dash_cooldown": dash_cooldown, "on_floor": is_on_floor()}
