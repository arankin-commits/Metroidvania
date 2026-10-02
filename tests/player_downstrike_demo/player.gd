extends CharacterBody2D
const ABILITY = preload("res://scripts/player_abilities/downstrike.gd")
const VISUAL = preload("res://scripts/player_abilities/downstrike_visual.gd")
var slam: Node2D
var art: Sprite2D
var facing := 1
var _slam_down := false
var _jump_down := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 46)
	shape.shape = rect
	add_child(shape)
	slam = ABILITY.new()
	add_child(slam)
	art = VISUAL.new()
	add_child(art)
	# Updated by separation script with measured contact offsets and scale.
	var file := FileAccess.open("res://assets/player_downstrike/manifest.json", FileAccess.READ)
	if file:
		var manifest: Dictionary = JSON.parse_string(file.get_as_text())
		art.scale = Vector2.ONE * float(manifest.demo_scale)
		art.position = Vector2(0, 23 - float(manifest.contact_y_offset) * float(manifest.demo_scale))
	slam.animation_requested.connect(art.request)
	slam.finished.connect(art.finish)

func _physics_process(delta: float) -> void:
	var pressed := Input.is_physical_key_pressed(KEY_E)
	var jumping := Input.is_physical_key_pressed(KEY_SPACE)
	if pressed and not _slam_down:
		slam.begin()
	_slam_down = pressed
	if slam.before_move(delta):
		move_and_slide()
		slam.after_move()
	else:
		var direction := float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
		if direction != 0:
			facing = int(signf(direction))
		velocity.x = move_toward(velocity.x, direction * 255, 1700 * delta)
		velocity.y += 1250 * delta
		if jumping and not _jump_down and is_on_floor():
			velocity.y = -500
		move_and_slide()
	_jump_down = jumping
	art.flip_h = facing < 0
	if global_position.y > 700:
		slam.reset()
		global_position = Vector2(120, 350)
		velocity = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	if not art.visible:
		draw_rect(Rect2(-14, -23, 28, 46), Color(0.15, 0.65, 0.85))
