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
var current_climb_surface: Node = null
var last_climb_surface: Node = null
var climb_side: ClimbSide = ClimbSide.NONE
var surface_regrab_timer := 0.0
var facing := -1
var step_timer := 0.0
var jump_timer := 0.0
var pounce_timer := 0.0
var sprite: Sprite2D

func _ready() -> void:
	add_to_group("mcp_watch")
	add_to_group("combat_targets")
	if player == null and player_path != NodePath():
		player = get_node(player_path) as CharacterBody2D
	if sprite == null:
		_create_sprite()
	update_visual_state()

func _create_sprite() -> void:
	sprite = Sprite2D.new()
	sprite.texture = DEFAULT_SPRITE
	sprite.centered = true
	sprite.position = Vector2.ZERO
	sprite.name = "BossSprite"
	add_child(sprite)

func _physics_process(delta: float) -> void:
	if not active or health <= 0.0:
		return

	surface_regrab_timer = maxf(0.0, surface_regrab_timer - delta)
	if is_instance_valid(player):
		facing = 1 if player.global_position.x >= global_position.x else -1

	if current_climb_surface != null:
		_handle_climbing(delta)
		update_visual_state()
		move_and_slide()
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
		var desired_x := clamp(to_player.x, -speed, speed)
		if abs(to_player.x) > 60.0 and is_on_floor():
			velocity.x = move_toward(velocity.x, desired_x, speed * 1.8 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, speed * 2.2 * delta)

		if is_on_floor() and abs(to_player.x) > 150.0 and pounce_timer <= 0.0:
			_begin_pounce(to_player)
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

func _begin_pounce(to_player: Vector2) -> void:
	pounce_timer = 1.8
	action_state = ActionState.POUNCE
	movement_state = MovementState.ASCENDING
	visual_state = VisualState.POUNCE
	var direction := Vector2.ZERO
	if to_player.length() > 0.0:
		direction = to_player.normalized()
	else:
		direction = Vector2(facing, -0.5)
	velocity = direction * pounce_speed
	velocity.y = minf(velocity.y, -pounce_speed * 0.4)

func _try_grab_surface() -> void:
	if surface_regrab_timer > 0.0:
		return

	var closest: Node = null
	var closest_distance := INF
	for candidate in get_tree().get_nodes_in_group(climbable_group_name):
		if not is_instance_valid(candidate):
			continue
		if candidate == last_climb_surface and surface_regrab_timer > 0.0:
			continue
		if not _is_climbable(candidate):
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

func _handle_climbing(delta: float) -> void:
	if not is_instance_valid(current_climb_surface) or not _is_climbable(current_climb_surface):
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

	var climb_dir := -1.0 if climb_side == ClimbSide.LEFT else 1.0
	var horizontal_strength := direction * speed * 0.35
	var vertical_input := -1.0 if is_instance_valid(player) and player.global_position.y < global_position.y else 1.0
	var climb_velocity_y := vertical_input * climb_speed

	if abs(surface_pos.x - global_position.x) > 90.0:
		_leave_surface()
		return

	velocity.x = horizontal_strength
	velocity.y = climb_velocity_y

	if is_instance_valid(player) and abs(player.global_position.x - global_position.x) > 170.0:
		_leave_surface()
		_begin_jump()
		return

	if is_instance_valid(player) and player.global_position.y > global_position.y + 120.0:
		_leave_surface()
		_begin_pounce(player.global_position - global_position)
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
	surface_regrab_timer = 0.25
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
	if climb_side == ClimbSide.LEFT:
		sprite.flip_h = true
	elif climb_side == ClimbSide.RIGHT:
		sprite.flip_h = false
	else:
		sprite.flip_h = facing < 0

func take_hit(amount: float = 1.0) -> void:
	if health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		action_state = ActionState.IDLE
		movement_state = MovementState.GROUNDED
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
	velocity = Vector2.ZERO
	update_visual_state()

func _mcp_state() -> Dictionary:
	return {
		"health": health,
		"active": active,
		"action": action_state,
		"movement": movement_state,
		"visual": visual_state,
		"climb_side": climb_side,
		"climb_target": current_climb_surface,
	}
