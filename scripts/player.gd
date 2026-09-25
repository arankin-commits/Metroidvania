extends CharacterBody2D

signal attacked(hitbox: Rect2)
signal heavy_attacked(hitbox: Rect2)
signal dodged
signal healed
signal damaged
signal died
signal ledge_climbed
signal platform_dropped
signal jumped

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
var heal_time := 0.0
const HEAL_DURATION := 0.65
var has_dash := true
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
var ledge_grabbed := false
var ledge_climb_time := 0.0
var ledge_climb_from := Vector2.ZERO
var ledge_climb_to := Vector2.ZERO
var ledge_top := Vector2.ZERO
var drop_platform: StaticBody2D
var drop_region := Rect2()
var drop_ignore_timer := 0.0
var drop_exception_active := false
var meditation_state := ""
var meditation_time := 0.0
var meditation_duration := 0.0
var meditation_from := Vector2.ZERO
var meditation_to := Vector2.ZERO
var meditation_chair := Vector2.ZERO

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
	if not meditation_state.is_empty():
		_advance_meditation(delta)
		return
	if drop_ignore_timer > 0.0:
		drop_ignore_timer = maxf(0.0, drop_ignore_timer - delta)
	if drop_exception_active and drop_ignore_timer <= 0.0 and global_position.y - 23.0 > drop_region.end.y + 2.0 and is_instance_valid(drop_platform):
		remove_collision_exception_with(drop_platform)
		floor_block_on_wall = true
		drop_exception_active = false
	if ledge_climb_time > 0.0:
		ledge_climb_time = maxf(0.0, ledge_climb_time - delta)
		var climb_progress := 1.0 - ledge_climb_time / 0.32
		var rise := minf(1.0, climb_progress * 1.55)
		var cross := maxf(0.0, (climb_progress - 0.45) / 0.55)
		global_position = Vector2(lerpf(ledge_climb_from.x, ledge_climb_to.x, cross), lerpf(ledge_climb_from.y, ledge_climb_to.y, rise))
		velocity = Vector2.ZERO
		if ledge_climb_time <= 0.0:
			ledge_climbed.emit()
		queue_redraw()
		return
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
	if heal_time > 0.0:
		heal_time = maxf(0.0, heal_time - delta)
		velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
		velocity.y += GRAVITY * delta
		move_and_slide()
		if heal_time <= 0.0:
			healing_charges -= 1
			health = mini(max_health, health + 2)
			healed.emit()
		_heal_was_down = heal_down
		_jump_was_down = jump_down
		_attack_was_down = attack_down
		_dash_was_down = dash_down
		queue_redraw()
		return
	if ledge_grabbed:
		velocity = Vector2.ZERO
		var forward_down := controls_enabled and ((facing > 0 and (Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))) or (facing < 0 and (Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))))
		if (jump_down and not _jump_was_down) or forward_down:
			ledge_grabbed = false
			ledge_climb_from = global_position
			ledge_climb_to = ledge_top
			ledge_climb_time = 0.32
		_jump_was_down = jump_down
		queue_redraw()
		return
	var drop_down := controls_enabled and jump_down and not _jump_was_down and (Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))
	var dropping := false
	var on_drop_surface := drop_region.has_point(global_position + Vector2(0, 23)) and absf(global_position.y + 23.0 - drop_region.position.y) <= 9.0
	if drop_down and on_drop_surface and is_instance_valid(drop_platform):
		add_collision_exception_with(drop_platform)
		drop_exception_active = true
		drop_ignore_timer = 0.40
		floor_block_on_wall = false
		global_position.y += 1.0
		velocity.y = maxf(0.0, velocity.y)
		jump_buffer = 0.0
		dropping = true
		platform_dropped.emit()
	if heal_down and not _heal_was_down and health > 0 and health < max_health and healing_charges > 0:
		heal_time = HEAL_DURATION
		velocity.x = 0.0
		queue_redraw()
	_heal_was_down = heal_down
	if jump_down and not _jump_was_down and not dropping:
		jump_buffer = 0.13
	else:
		jump_buffer = maxf(0.0, jump_buffer - delta)
	if controls_enabled and attack_down and not _attack_was_down and attack_cooldown <= 0.0:
		attack_time = 0.17
		attack_cooldown = 0.30
		attacked.emit(Rect2(global_position + Vector2(10 if facing > 0 else -82, -28), Vector2(72, 56)))
	if controls_enabled and dash_down and not _dash_was_down and dash_cooldown <= 0.0:
		if is_on_floor():
			dash_time = 0.17
			dash_speed_current = 450.0
			dash_cooldown = 0.75
			invulnerability = maxf(invulnerability, 0.19)
			dodged.emit()
		elif has_dash:
			dash_time = 0.23
			dash_speed_current = DASH_SPEED
			dash_cooldown = 0.65
			invulnerability = maxf(invulnerability, 0.25)
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
			jumped.emit()
			jump_buffer = 0.0
			coyote_time = 0.0
	move_and_slide()
	_try_grab_ledge()
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

func _try_grab_ledge() -> void:
	if ledge_grabbed or ledge_climb_time > 0.0 or drop_exception_active or is_on_floor() or not is_on_wall() or not controls_enabled:
		return
	var wall_normal := get_wall_normal()
	if absf(wall_normal.x) < 0.8 or int(signf(-wall_normal.x)) != facing:
		return
	var head_y := global_position.y - 23.0
	var probe_x := global_position.x + facing * 22.0
	var query := PhysicsRayQueryParameters2D.create(Vector2(probe_x, head_y - 22.0), Vector2(probe_x, head_y + 20.0))
	query.exclude = [get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var top_y: float = hit.position.y
	if absf(top_y - head_y) > 18.0 or global_position.y <= top_y + 4.0:
		return
	var landing_position := Vector2(global_position.x + facing * 34.0, top_y - 23.0)
	var clearance_shape := RectangleShape2D.new()
	clearance_shape.size = Vector2(26, 44)
	var clearance := PhysicsShapeQueryParameters2D.new()
	clearance.shape = clearance_shape
	clearance.transform = Transform2D(0.0, landing_position + Vector2(0, -1))
	clearance.exclude = [get_rid()]
	if not get_world_2d().direct_space_state.intersect_shape(clearance, 4).is_empty():
		return
	ledge_grabbed = true
	ledge_top = landing_position
	dash_time = 0.0
	velocity = Vector2.ZERO
	queue_redraw()

func take_damage(amount: int, from_x: float) -> void:
	if invulnerability > 0.0 or health <= 0:
		return
	health -= amount
	heal_time = 0.0
	ledge_grabbed = false
	ledge_climb_time = 0.0
	damaged.emit()
	invulnerability = 1.0
	velocity = Vector2(260.0 if global_position.x > from_x else -260.0, -260.0)
	if health <= 0:
		died.emit()
	queue_redraw()

func heal_full() -> void:
	heal_time = 0.0
	health = max_health
	invulnerability = 0.0
	queue_redraw()

func reset_movement_state() -> void:
	velocity = Vector2.ZERO
	meditation_state = ""
	dash_time = 0.0
	dash_cooldown = 0.0
	jump_buffer = 0.0
	ledge_grabbed = false
	ledge_climb_time = 0.0
	heal_time = 0.0
	if drop_exception_active and is_instance_valid(drop_platform):
		remove_collision_exception_with(drop_platform)
	drop_exception_active = false
	drop_ignore_timer = 0.0
	floor_block_on_wall = true
	queue_redraw()

func begin_meditation(chair_position: Vector2) -> void:
	reset_movement_state()
	controls_enabled = false
	meditation_chair = chair_position
	meditation_from = global_position
	meditation_to = chair_position + Vector2(0, -35)
	meditation_duration = 0.36
	meditation_time = meditation_duration
	meditation_state = "enter"
	queue_redraw()

func end_meditation() -> void:
	if meditation_state.is_empty() or meditation_state == "exit":
		return
	meditation_from = global_position
	meditation_to = Vector2(meditation_chair.x + 85.0, 570.0)
	meditation_duration = 0.32
	meditation_time = meditation_duration
	meditation_state = "exit"
	queue_redraw()

func _advance_meditation(delta: float) -> void:
	velocity = Vector2.ZERO
	if meditation_state == "meditate":
		queue_redraw()
		return
	meditation_time = maxf(0.0, meditation_time - delta)
	var progress := 1.0 - meditation_time / meditation_duration
	global_position = meditation_from.lerp(meditation_to, progress) + Vector2(0, -sin(PI * progress) * 20.0)
	if meditation_time <= 0.0:
		if meditation_state == "enter":
			meditation_state = "meditate"
		else:
			meditation_state = ""
			controls_enabled = true
	queue_redraw()

func _draw() -> void:
	var alpha := 0.55 if invulnerability > 0.0 and Engine.get_physics_frames() % 6 < 3 else 1.0
	var cloak := Color(0.13, 0.80, 0.79, alpha)
	var dark := Color(0.08, 0.16, 0.25, alpha)
	if not meditation_state.is_empty():
		var pulse := 0.24 + 0.08 * sin(float(Engine.get_physics_frames()) * 0.12)
		draw_circle(Vector2(0, -4), 30, Color(0.28, 0.95, 0.83, pulse))
		draw_rect(Rect2(-13, -15, 26, 30), cloak)
		draw_rect(Rect2(-11, -28, 22, 18), dark)
		draw_rect(Rect2(-5, -21, 4, 3), Color(1.0, 0.87, 0.52, alpha))
		draw_rect(Rect2(3, -21, 4, 3), Color(1.0, 0.87, 0.52, alpha))
		draw_rect(Rect2(-18, 11, 36, 8), dark)
		draw_rect(Rect2(-21, 2, 14, 6), cloak)
		draw_rect(Rect2(7, 2, 14, 6), cloak)
		return
	draw_circle(Vector2(0, -6), 24, Color(0.08, 0.79, 0.82, 0.12 * alpha))
	draw_colored_polygon(PackedVector2Array([Vector2(-13, -16), Vector2(13, -16), Vector2(18, 22), Vector2(0, 13), Vector2(-18, 22)]), cloak)
	draw_rect(Rect2(-11, -24, 22, 19), dark)
	draw_circle(Vector2(facing * 5, -16), 3, Color(1.0, 0.88, 0.45, alpha))
	draw_line(Vector2(-9, 23), Vector2(-9, 31), dark, 5)
	draw_line(Vector2(9, 23), Vector2(9, 31), dark, 5)
	if ledge_grabbed or ledge_climb_time > 0.0:
		var reach := 0.0 if ledge_grabbed else 1.0 - ledge_climb_time / 0.32
		draw_rect(Rect2(8, -26 - reach * 5.0, 7, 18), dark)
		draw_rect(Rect2(13, -32 - reach * 5.0, 8, 7), Color(0.78, 0.85, 0.67, alpha))
		draw_rect(Rect2(-12, -24 - reach * 5.0, 7, 17), dark)
		draw_rect(Rect2(-13, -31 - reach * 5.0, 8, 7), Color(0.78, 0.85, 0.67, alpha))
		if ledge_climb_time > 0.0:
			draw_rect(Rect2(-13, 18 - reach * 9.0, 27, 7), cloak)
	if heal_time > 0.0:
		var pulse := 1.0 - heal_time / HEAL_DURATION
		var glow := Color(0.53, 1.0, 0.73, 0.22 + 0.46 * pulse)
		draw_rect(Rect2(-19, -29, 38, 44), glow)
		draw_rect(Rect2(-12, -12, 24, 6), Color(0.71, 1.0, 0.77, alpha))
		draw_rect(Rect2(-3, -21, 6, 24), Color(0.71, 1.0, 0.77, alpha))
		draw_rect(Rect2(-21 - pulse * 8.0, -8, 5, 5), glow)
		draw_rect(Rect2(16 + pulse * 8.0, -17, 5, 5), glow)
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
