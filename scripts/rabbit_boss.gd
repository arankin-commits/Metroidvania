extends CharacterBody2D
class_name RabbitBoss

signal defeated

enum ActionState {
	IDLE,
	WALK,
	JUMP,
	CLIMB,
	POUNCE,
}

enum MovementState {
	GROUNDED,
	ASCENDING,
	DESCENDING,
	CLIMBING,
}

enum VisualState {
	DEFAULT,
	STEP,
	JUMP,
	FALL,
	CLIMB,
	POUNCE,
}

enum ClimbSide {
	NONE,
	LEFT,
	RIGHT,
}

const DEFAULT_SPRITE := preload("res://assets/rabbit_boss/rabbit_default.png")
const STEP_SPRITE := preload("res://assets/rabbit_boss/rabbit_step.png")
const JUMP_SPRITE := preload("res://assets/rabbit_boss/rabbit_jump.png")
const FALL_SPRITE := preload("res://assets/rabbit_boss/rabbit_fall.png")
const CLIMB_SPRITE := preload("res://assets/rabbit_boss/rabbit_climb.png")
const POUNCE_SPRITE := preload("res://assets/rabbit_boss/rabbit_pounce.png")

@export_group("Boss")
@export var active := true
@export var max_health := 12.0
@export var player_path: NodePath = NodePath()
@export var player: CharacterBody2D

@export_group("Movement")
@export var speed := 120.0
@export var gravity := 1350.0
@export var jump_velocity := -520.0
@export var climb_speed := 120.0
@export var pounce_speed := 360.0
@export var detection_radius := 220.0
@export var climbable_group_name := "climbable_surface"

var health := max_health
var action_state: ActionState = ActionState.IDLE
var movement_state: MovementState = MovementState.GROUNDED
var visual_state: VisualState = VisualState.DEFAULT
var current_climb_surface: Node2D = null
var last_climb_surface: Node2D = null
var climb_side: ClimbSide = ClimbSide.NONE
var surface_regrab_timer := 0.0
var climb_cooldown := 0.0
var facing := -1
var step_timer := 0.0
var jump_timer := 0.0
var pounce_timer := 0.0
var climb_timer := 0.0
var telegraph_timer := 0.0
var is_telegraphing := false
var telegraph_length := 0.45
var attack_warning_length := 120.0
var hurt_flash := 0.0
var invulnerability := 0.0
var sprite: Sprite2D

func _ready() -> void:
	add_to_group("mcp_watch")
	add_to_group("combat_targets")
	if player == null and player_path != NodePath():
		player = get_node(player_path) as CharacterBody2D
	if sprite == null:
		_create_sprite()
	_ensure_collision_shape()
	update_visual_state()

func _create_sprite() -> void:
	sprite = Sprite2D.new()
	sprite.texture = DEFAULT_SPRITE
	sprite.centered = true
	sprite.position = Vector2.ZERO
	sprite.name = "BossSprite"
	add_child(sprite)

func _ensure_collision_shape() -> void:
	if get_node_or_null("CollisionShape2D") != null:
		return
	var shape := RectangleShape2D.new()
	shape.size = Vector2(104.0, 112.0)
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = shape
	add_child(collision)

func combat_bounds() -> Rect2:
	return Rect2(global_position - Vector2(52, 56), Vector2(104, 112))

func _physics_process(delta: float) -> void:
	if not active or health <= 0.0:
		return

	hurt_flash = maxf(0.0, hurt_flash - delta)
	invulnerability = maxf(0.0, invulnerability - delta)
	surface_regrab_timer = maxf(0.0, surface_regrab_timer - delta)
	climb_cooldown = maxf(0.0, climb_cooldown - delta)
	if is_instance_valid(player):
		facing = 1 if player.global_position.x >= global_position.x else -1

	if is_telegraphing:
		velocity = Vector2.ZERO
		telegraph_timer = maxf(0.0, telegraph_timer - delta)
		if telegraph_timer <= 0.0:
			is_telegraphing = false
			_begin_pounce(player.global_position - global_position)
		else:
			visual_state = VisualState.DEFAULT if is_on_floor() else VisualState.FALL
		update_visual_state()
		queue_redraw()
		return

	if current_climb_surface != null:
		_handle_climbing(delta)
		update_visual_state()
		move_and_slide()
		return

	if pounce_timer > 0.0:
		if not is_on_floor():
			velocity.y += gravity * delta
			movement_state = MovementState.DESCENDING if velocity.y > 0.0 else MovementState.ASCENDING
		update_visual_state()
		move_and_slide()
		pounce_timer = maxf(0.0, pounce_timer - delta)
		if is_on_floor():
			pounce_timer = 0.0
		return

	if not is_on_floor():
		velocity.y += gravity * delta
		movement_state = MovementState.DESCENDING if velocity.y > 0.0 else MovementState.ASCENDING
	else:
		if movement_state != MovementState.GROUNDED:
			movement_state = MovementState.GROUNDED
		velocity.y = 0.0
		if abs(velocity.x) > 5.0:
			action_state = ActionState.WALK
			visual_state = VisualState.STEP
		else:
			action_state = ActionState.IDLE
			visual_state = VisualState.DEFAULT

	if is_instance_valid(player):
		var to_player := player.global_position - global_position
		var climb_target := _find_climb_target()
		var seeking_climb_surface := false
		if climb_target != null and is_on_floor():
			var to_surface := climb_target.global_position - global_position
			var jump_distance := minf(detection_radius, 160.0)
			if absf(to_surface.x) <= jump_distance:
				seeking_climb_surface = true
				if jump_timer <= 0.0:
					_begin_surface_jump(to_surface)
				else:
					velocity.x = move_toward(velocity.x, 0.0, speed * delta)
			else:
				seeking_climb_surface = true
				var wall_speed := signf(to_surface.x) * speed
				velocity.x = move_toward(velocity.x, wall_speed, speed * 1.8 * delta)
				action_state = ActionState.WALK
				visual_state = VisualState.STEP

		if not seeking_climb_surface:
			var desired_x: float = clampf(to_player.x, -speed, speed)
			if abs(to_player.x) > 60.0 and is_on_floor():
				velocity.x = move_toward(velocity.x, desired_x, speed * 1.8 * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, speed * 2.2 * delta)

			if is_on_floor() and abs(to_player.x) > 150.0 and pounce_timer <= 0.0:
				_begin_telegraph(to_player)
			elif is_on_floor() and abs(to_player.x) < 70.0 and jump_timer <= 0.0:
				_begin_jump()
			elif not is_on_floor() and velocity.y > 0.0 and movement_state == MovementState.DESCENDING:
				visual_state = VisualState.FALL
			elif not is_on_floor() and movement_state == MovementState.ASCENDING:
				visual_state = VisualState.JUMP

	if not is_on_floor() and current_climb_surface == null:
		_try_grab_surface()

	if is_on_floor() and not is_instance_valid(player):
		velocity.x = move_toward(velocity.x, 0.0, speed * delta)

	pounce_timer = maxf(0.0, pounce_timer - delta)
	jump_timer = maxf(0.0, jump_timer - delta)
	step_timer = maxf(0.0, step_timer - delta)
	update_visual_state()
	move_and_slide()

func _begin_jump() -> void:
	jump_timer = 1.0
	velocity.y = jump_velocity
	movement_state = MovementState.ASCENDING
	action_state = ActionState.JUMP
	visual_state = VisualState.JUMP

func _begin_surface_jump(to_surface: Vector2) -> void:
	jump_timer = 1.15
	velocity.x = signf(to_surface.x) * speed * 1.6
	velocity.y = jump_velocity
	movement_state = MovementState.ASCENDING
	action_state = ActionState.JUMP
	visual_state = VisualState.JUMP

func _begin_telegraph(to_player: Vector2) -> void:
	if not is_instance_valid(player):
		return
	is_telegraphing = true
	telegraph_timer = telegraph_length
	action_state = ActionState.POUNCE
	movement_state = MovementState.GROUNDED
	visual_state = VisualState.DEFAULT
	velocity = Vector2.ZERO
	queue_redraw()

func _begin_pounce(to_player: Vector2) -> void:
	pounce_timer = 1.1
	action_state = ActionState.POUNCE
	movement_state = MovementState.ASCENDING
	visual_state = VisualState.POUNCE
	var direction := Vector2.ZERO
	if to_player.length() > 0.0:
		direction = to_player.normalized()
	else:
		direction = Vector2(facing, -0.5)
	velocity = direction * pounce_speed
	velocity.y = minf(velocity.y, -210.0)
	is_telegraphing = false
	telegraph_timer = 0.0
	queue_redraw()

func _find_climb_target() -> Node2D:
	if climb_cooldown > 0.0:
		return null
	var closest: Node2D = null
	var closest_distance := INF
	for candidate in get_tree().get_nodes_in_group(climbable_group_name):
		if not is_instance_valid(candidate) or candidate == current_climb_surface:
			continue
		if candidate == last_climb_surface and surface_regrab_timer > 0.0:
			continue
		if not _is_climbable(candidate):
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance < closest_distance:
			closest = candidate
			closest_distance = distance
	return closest

func _try_grab_surface() -> void:
	if surface_regrab_timer > 0.0 or climb_cooldown > 0.0:
		return

	var closest: Node2D = null
	var closest_distance := INF
	for candidate in get_tree().get_nodes_in_group(climbable_group_name):
		if not is_instance_valid(candidate):
			continue
		if candidate == last_climb_surface and surface_regrab_timer > 0.0:
			continue
		if not _is_climbable(candidate):
			continue
		if absf(global_position.x - candidate.global_position.x) > 125.0:
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance <= detection_radius and distance < closest_distance:
			closest = candidate
			closest_distance = distance
	if closest == null:
		return
	_attach_to_surface(closest)

func _is_climbable(node: Node) -> bool:
	if node.has_method("is_climbable"):
		return bool(node.call("is_climbable"))
	if node is CollisionObject2D:
		return true
	return node is Node2D

func _attach_to_surface(surface: Node) -> void:
	current_climb_surface = surface
	last_climb_surface = surface
	climb_side = ClimbSide.RIGHT if global_position.x <= surface.global_position.x else ClimbSide.LEFT
	movement_state = MovementState.CLIMBING
	action_state = ActionState.CLIMB
	visual_state = VisualState.CLIMB
	velocity = Vector2.ZERO
	surface_regrab_timer = 0.35
	climb_timer = 0.85
	climb_cooldown = 4.5

func _handle_climbing(delta: float) -> void:
	if not is_instance_valid(current_climb_surface) or not _is_climbable(current_climb_surface):
		_leave_surface()
		return
	climb_timer = maxf(0.0, climb_timer - delta)
	if climb_timer <= 0.0:
		_leave_surface()
		return

	var surface_pos := current_climb_surface.global_position
	var direction := 0.0
	if is_instance_valid(player):
		direction = sign(player.global_position.x - global_position.x)
		if direction == 0:
			direction = 1.0 if climb_side == ClimbSide.RIGHT else -1.0
	else:
		direction = 1.0 if climb_side == ClimbSide.RIGHT else -1.0

	var horizontal_strength := clampf((surface_pos.x - global_position.x) * 2.0, -speed * 0.35, speed * 0.35)
	var vertical_input := -1.0 if climb_timer > 0.45 or (is_instance_valid(player) and player.global_position.y < global_position.y) else 1.0
	var climb_velocity_y := vertical_input * climb_speed

	if abs(surface_pos.x - global_position.x) > 130.0:
		_leave_surface()
		return

	velocity.x = horizontal_strength
	velocity.y = climb_velocity_y

	if is_instance_valid(player) and abs(player.global_position.x - global_position.x) > 170.0:
		_leave_surface()
		_begin_jump()
		return

	if is_instance_valid(player) and player.global_position.y < global_position.y - 70.0 and movement_state == MovementState.CLIMBING:
		velocity.y = -climb_speed

	if current_climb_surface is CollisionObject2D:
		var climb_distance := absf(global_position.x - surface_pos.x)
		if climb_distance > 200.0:
			_leave_surface()

	move_and_slide()

func _leave_surface() -> void:
	if current_climb_surface != null:
		last_climb_surface = current_climb_surface
	current_climb_surface = null
	climb_side = ClimbSide.NONE
	surface_regrab_timer = 1.6
	movement_state = MovementState.DESCENDING
	action_state = ActionState.JUMP
	visual_state = VisualState.FALL

func update_visual_state() -> void:
	if sprite == null:
		return
	var texture_to_use := DEFAULT_SPRITE
	match visual_state:
		VisualState.DEFAULT:
			texture_to_use = DEFAULT_SPRITE
		VisualState.STEP:
			texture_to_use = STEP_SPRITE
		VisualState.JUMP:
			texture_to_use = JUMP_SPRITE
		VisualState.FALL:
			texture_to_use = FALL_SPRITE
		VisualState.CLIMB:
			texture_to_use = CLIMB_SPRITE
		VisualState.POUNCE:
			texture_to_use = POUNCE_SPRITE

	sprite.texture = texture_to_use
	sprite.scale = Vector2.ONE * (112.0 / float(texture_to_use.get_height()))
	sprite.position.y = -8.0 if visual_state == VisualState.POUNCE else 0.0
	sprite.modulate = Color(1.0, 0.48, 0.48) if hurt_flash > 0.0 else Color.WHITE
	if climb_side == ClimbSide.LEFT:
		sprite.flip_h = true
	elif climb_side == ClimbSide.RIGHT:
		sprite.flip_h = false
	else:
		sprite.flip_h = facing < 0

func take_hit(amount: float = 1.0) -> void:
	if health <= 0.0 or invulnerability > 0.0:
		return
	health = maxf(0.0, health - amount)
	hurt_flash = 0.16
	invulnerability = 0.12
	if health <= 0.0:
		action_state = ActionState.IDLE
		movement_state = MovementState.GROUNDED
		active = false
		defeated.emit()
		queue_free()

func reset_encounter() -> void:
	health = max_health
	action_state = ActionState.IDLE
	movement_state = MovementState.GROUNDED
	visual_state = VisualState.DEFAULT
	current_climb_surface = null
	last_climb_surface = null
	climb_side = ClimbSide.NONE
	surface_regrab_timer = 0.0
	climb_timer = 0.0
	climb_cooldown = 0.0
	is_telegraphing = false
	telegraph_timer = 0.0
	velocity = Vector2.ZERO
	update_visual_state()

func _draw() -> void:
	if not is_telegraphing or not is_instance_valid(player):
		return
	var direction := Vector2.ZERO
	if player.global_position.x >= global_position.x:
		direction = Vector2(1.0, 0.0)
	else:
		direction = Vector2(-1.0, 0.0)
	var line_end := Vector2(direction.x * attack_warning_length, 0.0)
	draw_line(Vector2.ZERO, line_end, Color(0.98, 0.18, 0.18), 4.0)
	draw_line(Vector2.ZERO, line_end, Color(1.0, 0.45, 0.45, 0.45), 9.0, true)
	var warning_box_origin := 0.0
	if direction.x < 0.0:
		warning_box_origin = -attack_warning_length
	var warning_box := Rect2(warning_box_origin, -24.0, attack_warning_length, 48.0)
	draw_rect(warning_box, Color(1.0, 0.22, 0.22, 0.15), false, 2.0)

func _mcp_state() -> Dictionary:
	return {
		"health": health,
		"active": active,
		"action": action_state,
		"movement": movement_state,
		"visual": visual_state,
		"climb_side": climb_side,
		"climb_target": current_climb_surface,
		"telegraphing": is_telegraphing,
	}
