class_name TraversalPlayer
extends CharacterBody2D

const RUN_SPEED := 260.0
const RUN_ACCELERATION := 1800.0
const AIR_ACCELERATION := 1100.0
const FRICTION := 2200.0
const GRAVITY := 1500.0
const JUMP_VELOCITY := -560.0
const MAX_FALL_SPEED := 800.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER_TIME := 0.12

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var spawn_position := Vector2.ZERO
var facing := 1.0
var respawn_flash := 0.0

func _ready() -> void:
	spawn_position = global_position
	queue_redraw()

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	if not is_zero_approx(direction):
		facing = sign(direction)
		var acceleration := RUN_ACCELERATION if is_on_floor() else AIR_ACCELERATION
		velocity.x = move_toward(velocity.x, direction * RUN_SPEED, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	if Input.is_action_just_released("jump") and velocity.y < -180.0:
		velocity.y = -180.0

	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	move_and_slide()
	respawn_flash = maxf(respawn_flash - delta, 0.0)
	queue_redraw()

func respawn(at: Vector2 = spawn_position) -> void:
	global_position = at
	velocity = Vector2.ZERO
	respawn_flash = 0.35

func _draw() -> void:
	var body_color := Color("#f5c451") if respawn_flash <= 0.0 else Color("#ffffff")
	draw_circle(Vector2(0, 2), 17.0, Color("#101827"))
	draw_rect(Rect2(-13, -13, 26, 29), body_color, true)
	draw_rect(Rect2(-13, 8, 26, 8), Color("#dd6a4e"), true)
	draw_circle(Vector2(6 * facing, -5), 3.0, Color("#101827"))
	draw_line(Vector2(-9, 18), Vector2(-9, 24), Color("#101827"), 4.0)
	draw_line(Vector2(9, 18), Vector2(9, 24), Color("#101827"), 4.0)
