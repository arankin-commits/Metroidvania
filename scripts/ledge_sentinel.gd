extends Node2D

signal defeated
signal attack_landed

const GOBLIN_FRAMES = preload("res://assets/characters/enemies/goblin.tres")

var sprite: AnimatedSprite2D
var player: CharacterBody2D
var health := 4.0
var max_health := 4.0
var hit_cooldown := 0.0
var hurt_time := 0.0
var facing := -1
var is_asleep := true
var time_since_last_seen := 0.0
var wake_delay := 0.0
var attack_cooldown := 0.0
var attack_time := 0.0
var attack_index := 0
var has_dealt_attack_damage := false
const ATTACKS = ["horizontal_slash", "upward_slash", "downward_slam"]
const RUN_SPEED := 115.0

func _ready() -> void:
	add_to_group("combat_targets")
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = GOBLIN_FRAMES
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.position = Vector2(-128, -199)
	sprite.play("sleep")
	add_child(sprite)

func combat_bounds() -> Rect2:
	return Rect2(global_position - Vector2(20, 27), Vector2(40, 54))

func is_facing_wall(dir: int) -> bool:
	if get_world_2d() == null:
		return false
	var from_pt := global_position + Vector2(0, -10)
	var to_pt := global_position + Vector2(dir * 25.0, -10)
	var query := PhysicsRayQueryParameters2D.create(from_pt, to_pt)
	query.collision_mask = 1
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return not hit.is_empty()

func is_edge_ahead(dir: int) -> bool:
	if get_world_2d() == null or dir == 0:
		return false
	var probe_x: float = global_position.x + dir * 24.0
	var foot_y: float = global_position.y + 27.0
	var from_pt := Vector2(probe_x, foot_y - 30.0)
	var to_pt := Vector2(probe_x, foot_y + 80.0)
	var query := PhysicsRayQueryParameters2D.create(from_pt, to_pt)
	query.collision_mask = 5
	query.hit_from_inside = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var normal: Vector2 = hit.get("normal", Vector2.UP)
	if normal.y > -0.35:
		return true
	return false

func can_see_player() -> bool:
	if player == null or not is_instance_valid(player):
		return false
	var from_pos := global_position + Vector2(0, -20)
	var to_pos := player.global_position + Vector2(0, -14)
	var diff := to_pos - from_pos
	if absf(diff.x) > 1152.0 or absf(diff.y) > 550.0:
		return false
	var space_state := get_world_2d().direct_space_state
	var exclude_rids: Array[RID] = []
	if player is CollisionObject2D:
		exclude_rids.append(player.get_rid())

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

func _process(delta: float) -> void:
	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	wake_delay = maxf(0.0, wake_delay - delta)

	if hurt_time > 0.0:
		hurt_time = maxf(0.0, hurt_time - delta)
		if hurt_time <= 0.0 and health > 0 and is_instance_valid(sprite):
			if is_asleep:
				sprite.play("sleep")
			else:
				sprite.play("idle")

	if not is_asleep and health > 0:
		var sees := can_see_player()
		if sees:
			time_since_last_seen = 0.0
			if is_instance_valid(player):
				facing = 1 if player.global_position.x > global_position.x else -1
				if is_instance_valid(sprite):
					sprite.scale.x = facing
		else:
			time_since_last_seen += delta
			if time_since_last_seen >= 10.0:
				is_asleep = true
				time_since_last_seen = 0.0
				attack_time = 0.0
				if is_instance_valid(sprite) and hurt_time <= 0.0:
					sprite.play("sleep")

		# Active combat begins 0.5s after wake-up
		if wake_delay <= 0.0 and hurt_time <= 0.0 and sees and is_instance_valid(player):
			var dist := player.global_position.x - global_position.x
			if attack_time > 0.0:
				attack_time = maxf(0.0, attack_time - delta)
				if not has_dealt_attack_damage and attack_time <= 0.35:
					has_dealt_attack_damage = true
					var attack_box := Rect2(global_position + Vector2(10 if facing > 0 else -60, -50), Vector2(50, 50))
					var target_body := Rect2(player.global_position - Vector2(14, 23), Vector2(28, 46))
					if attack_box.intersects(target_body):
						var health_before: float = player.health
						player.take_damage(1.0, global_position.x, true)
						if player.health < health_before:
							attack_landed.emit()
				if attack_time <= 0.0 and is_instance_valid(sprite):
					sprite.play("idle")
			else:
				if absf(dist) > 75.0:
					if not is_edge_ahead(facing) and not is_facing_wall(facing):
						position.x += facing * RUN_SPEED * delta
						if is_instance_valid(sprite) and sprite.animation != "run":
							sprite.play("run")
					else:
						if is_instance_valid(sprite) and sprite.animation != "idle":
							sprite.play("idle")
				elif attack_cooldown <= 0.0:
					var attack_name: String = ATTACKS[attack_index % ATTACKS.size()]
					attack_index += 1
					attack_cooldown = 1.3
					attack_time = 0.55
					has_dealt_attack_damage = false
					if is_instance_valid(sprite):
						sprite.play(attack_name)
				else:
					if is_instance_valid(sprite) and sprite.animation != "idle":
						sprite.play("idle")

	if player == null or health <= 0:
		return
	var bounds := combat_bounds()
	var player_bounds := Rect2(player.global_position - Vector2(14, 23), Vector2(28, 46))
	if player.dash_time > 0.0:
		return
	if hit_cooldown <= 0.0 and bounds.intersects(player_bounds):
		var health_before: float = player.health
		player.take_damage(1, global_position.x, false) # contact damage preserves i-frames
		if player.health < health_before:
			attack_landed.emit()
		hit_cooldown = 0.8
	queue_redraw()

func take_hit(amount: float = 1.0) -> void:
	if health <= 0:
		return
	if is_asleep:
		amount *= 2.0
		is_asleep = false
		time_since_last_seen = 0.0
		wake_delay = 0.5
	health -= amount
	hurt_time = 0.35
	attack_time = 0.0
	if is_instance_valid(sprite) and sprite.sprite_frames.has_animation("posture_break"):
		sprite.play("posture_break")
	queue_redraw()
	if health <= 0:
		defeated.emit()
		queue_free()

func _draw() -> void:
	# Sleeping goblin health bar
	if health > 0:
		draw_rect(Rect2(-19, -37, 38, 7), Color(0.04, 0.10, 0.14))
		draw_rect(Rect2(-17, -35, 34, 3), Color(0.25, 0.32, 0.36))
		draw_rect(Rect2(-17, -35, 34.0 * float(health) / float(max_health), 3), Color(0.96, 0.59, 0.42))
