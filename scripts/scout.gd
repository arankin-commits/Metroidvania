extends CharacterBody2D

signal defeated
signal attack_landed

const GRAVITY := 1250.0
const RUN_SPEED := 100.0
const WALK_SPEED := 50.0

var health := 2.0:
	set(value):
		if value > health:
			posture = maxf(posture, value)
		health = value
var max_health := 2.0
var posture := 2.0
var max_posture := 2.0
var origin_x := 0.0
var player: CharacterBody2D
var navigation: Node
var hit_cooldown := 0.0
var facing := -1
# Optional authored encounter bounds; defaults preserve existing forest behavior.
var patrol_bounds := Vector2(-INF, INF)
var awareness_height := INF
var spawn_grace:=0.0

func body_size() -> Vector2: return Vector2(32,34)
func combat_bounds() -> Rect2: return Rect2(global_position-Vector2(18,28),Vector2(36,56))

func _init() -> void:
	collision_layer = 2
	collision_mask = 5
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(65.0)
	floor_snap_length = 20.0

func _ready() -> void:
	max_posture = max_health
	posture = max_posture
	add_to_group("mcp_watch")
	add_to_group("combat_targets")
	add_to_group("enemies")
	origin_x = global_position.x
	var shape := RectangleShape2D.new()
	shape.size = body_size()
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)


func is_facing_wall() -> bool:
	if not is_on_wall():
		return false
	var n := get_wall_normal()
	return absf(n.y) < 0.7 and signf(n.x) == -facing

func can_see_target(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var from_pos := global_position + Vector2(0, -10)
	var to_pos := target.global_position + Vector2(0, -10)
	var diff := to_pos - from_pos

	# Sight cone covers the entire width of the playable screen (1152.0 px)
	if absf(diff.x) > 1152.0 or absf(diff.y) > 550.0 or absf(diff.y) > awareness_height:
		return false

	# Raycast check: blocked by walls and platforms that you can't pass or shoot through
	var space_state := get_world_2d().direct_space_state
	var exclude_rids: Array[RID] = [get_rid()]
	if target is CollisionObject2D:
		exclude_rids.append((target as CollisionObject2D).get_rid())

	var max_steps := 8
	while max_steps > 0:
		max_steps -= 1
		var query := PhysicsRayQueryParameters2D.create(from_pos, to_pos)
		query.collision_mask = 1 # Static terrain
		query.exclude = exclude_rids
		var hit := space_state.intersect_ray(query)
		if hit.is_empty():
			return true

		var collider: Object = hit.get("collider")
		var is_pass_through := false
		if collider is StaticBody2D:
			for child in collider.get_children():
				if (child is CollisionShape2D and child.one_way_collision) or (child is CollisionPolygon2D and child.one_way_collision):
					is_pass_through = true
					break
		if is_pass_through:
			exclude_rids.append(hit.get("rid"))
			continue

		# Solid wall or non-pass-through platform blocks line of sight
		return false

	return false

func is_edge_ahead(dir: int) -> bool:
	if not is_on_floor() or dir == 0:
		return false
	var half_width := body_size().x * 0.5
	var probe_x := global_position.x + dir * (half_width + 8.0)
	var foot_y := global_position.y + body_size().y * 0.5
	var from_pt := Vector2(probe_x, foot_y - 64.0)
	var to_pt := Vector2(probe_x, foot_y + 75.0)
	var query := PhysicsRayQueryParameters2D.create(from_pt, to_pt)
	query.collision_mask = 5
	query.exclude = [get_rid()]
	query.hit_from_inside = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty()

func _physics_process(delta: float) -> void:
	spawn_grace=maxf(0,spawn_grace-delta)
	hit_cooldown = maxf(0.0, hit_cooldown - delta)

	var direction := facing
	var visible_target: CharacterBody2D = player if can_see_target(player) else null

	if navigation != null:
		var traversal: Dictionary = navigation.update_enemy_ai_traverse(
			self,
			visible_target,
			origin_x,
			facing
		)
		direction = int(traversal.get("direction", facing))
	else:
		# Fallback behavior in case Navigation was not connected.
		if visible_target != null:
			direction = 1 if player.global_position.x > global_position.x else -1
		elif absf(global_position.x - origin_x) > 78.0:
			direction = -1 if global_position.x > origin_x else 1

	if visible_target == null:
		if is_edge_ahead(direction):
			direction *= -1
			facing = direction
		if position.x <= patrol_bounds.x + 2:
			direction = 1
		elif position.x >= patrol_bounds.y - 2:
			direction = -1
		facing = direction
	else:
		if is_edge_ahead(direction):
			direction = 0
		else:
			facing = direction

	var speed := RUN_SPEED if visible_target != null else WALK_SPEED
	velocity.x = direction * speed
	velocity.y += GRAVITY * delta

	move_and_slide()
	if visible_target == null and (is_edge_ahead(facing) or is_facing_wall()):
		facing *= -1

	var enemy_bounds := Rect2(global_position-body_size()/2,body_size())
	var player_bounds := Rect2(player.global_position - Vector2(14, 23), Vector2(28, 46)) if player != null else Rect2()
	if player != null and hit_cooldown <= 0.0 and enemy_bounds.grow(4.0).intersects(player_bounds):
		if player.get("dash_time") != null and player.dash_time > 0.0:
			pass
		else:
			var health_before: float = player.health
			if spawn_grace<=0: player.take_damage(1, global_position.x, false)
			if player.health < health_before:
				attack_landed.emit()
			hit_cooldown = 0.8
	queue_redraw()

func take_hit(amount: float = 1.0, posture_damage: float = -1.0) -> void:
	var p_dmg := amount if posture_damage < 0.0 else posture_damage
	health -= amount
	posture -= p_dmg
	if health <= 0:
		defeated.emit()
		queue_free()
	elif posture <= 0:
		posture = max_posture
		hit_cooldown = 1.8
		velocity.x = -facing * 180.0
		queue_redraw()
	else:
		queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 24, Color(0.96, 0.35, 0.36, 0.12))
	draw_colored_polygon(PackedVector2Array([Vector2(-18, 15), Vector2(-16, -9), Vector2(-7, -19), Vector2(8, -19), Vector2(18, -6), Vector2(16, 15)]), Color(0.41, 0.21, 0.35))
	draw_rect(Rect2(-12, -9, 24, 12), Color(0.85, 0.30, 0.39))
	draw_circle(Vector2(facing * 6, -5), 3, Color(1.0, 0.86, 0.55))
	draw_line(Vector2(-10, 15), Vector2(-15, 22), Color(0.18, 0.13, 0.26), 5)
	draw_line(Vector2(10, 15), Vector2(15, 22), Color(0.18, 0.13, 0.26), 5)
	draw_rect(Rect2(-19, -36, 38, 9), Color(0.04, 0.10, 0.14))
	draw_rect(Rect2(-17, -34, 34, 3), Color(0.25, 0.32, 0.36))
	draw_rect(Rect2(-17, -34, 34.0 * clampf(float(health) / float(max_health), 0.0, 1.0), 3), Color(0.91, 0.44, 0.47))
	draw_rect(Rect2(-17, -30, 34, 1), Color(0.18, 0.22, 0.25))
	draw_rect(Rect2(-17, -30, 34.0 * clampf(float(posture) / float(max_posture), 0.0, 1.0), 1), Color.WHITE)
