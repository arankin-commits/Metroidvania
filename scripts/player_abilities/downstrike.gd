extends Node2D
## Call begin(), before_move(), and after_move() from the controller.
## This component never calls move_and_slide() or grants invulnerability.
signal animation_requested(clip: StringName)
signal impacted(point: Vector2)
signal finished
signal damage_requested(receiver: Node, payload: Dictionary)

enum Phase { IDLE, WINDUP, PLUNGE, RECOVERY }
@export var player: CharacterBody2D
@export var foot_offset := Vector2(0, 23)
@export_flags_2d_physics var enemy_mask: int = 4
@export_flags_2d_physics var terrain_mask: int = 1
@export var unlocked := true
@export var auto_dispatch_damage := true
@export var windup_seconds := 0.14
@export var recovery_seconds := 0.30
@export var cooldown_seconds := 0.65
@export var plunge_speed := 650.0
@export var maximum_plunge_seconds := 3.0
@export var shockwave_radius := 72.0
@export var shockwave_height := 30.0
@export var damage_multiplier := 1.0
var phase: Phase = Phase.IDLE
var phase_time := 0.0
var cooldown := 0.0
var attack_serial := 0
var _seen: Dictionary = {}
var _old_foot := Vector2.ZERO
var _ground_start := false
const FX = preload("res://scripts/player_abilities/downstrike_fx.gd")

func _ready() -> void:
	if player == null:
		player = get_parent() as CharacterBody2D

func active() -> bool:
	return phase != Phase.IDLE

func begin() -> bool:
	if not unlocked or player == null or active() or cooldown > 0.0:
		return false
	attack_serial += 1
	_seen.clear()
	_ground_start = player.is_on_floor()
	phase = Phase.WINDUP
	phase_time = 0.0
	player.velocity = Vector2.ZERO
	animation_requested.emit(&"slam_windup")
	return true

func before_move(delta: float) -> bool:
	cooldown = maxf(0.0, cooldown - delta)
	if not active():
		return false
	phase_time += delta
	_old_foot = player.global_position + foot_offset
	match phase:
		Phase.WINDUP:
			player.velocity = Vector2.ZERO
			if phase_time >= windup_seconds:
				phase = Phase.PLUNGE
				phase_time = 0.0
				player.velocity = Vector2(0, plunge_speed)
				animation_requested.emit(&"slam_plunge")
		Phase.PLUNGE:
			player.velocity = Vector2(0, plunge_speed)
			if phase_time >= maximum_plunge_seconds:
				cancel()
		Phase.RECOVERY:
			player.velocity.x = 0.0
			player.velocity.y += 1250.0 * delta
			if phase_time >= recovery_seconds:
				phase = Phase.IDLE
				finished.emit()
	return true # Own this tick even when finishing; resume controller next tick.

func after_move() -> void:
	if phase != Phase.PLUNGE:
		return
	var foot := player.global_position + foot_offset
	# A swept rectangle spans actual resolved motion, not the intended motion.
	# This catches thin hurtboxes at high descent speeds without hitting below floors.
	var distance := maxf(0.0, foot.y - _old_foot.y)
	var sweep := Rect2(Vector2(foot.x - 17.0, _old_foot.y - 4.0), Vector2(34.0, distance + 4.0))
	_damage_rect(sweep, 1.0 * damage_multiplier, &"plunge", Vector2(0, 100), false)
	if player.is_on_floor():
		var point := foot
		var floor_body: Object = null
		for i in range(player.get_slide_collision_count()):
			var collision := player.get_slide_collision(i)
			if collision.get_normal().dot(player.up_direction) > cos(player.floor_max_angle):
				point = collision.get_position()
				floor_body = collision.get_collider()
				break
		_land(point, floor_body)

func _land(point: Vector2, floor_body: Object) -> void:
	phase = Phase.RECOVERY # Set before effects so callbacks cannot re-impact.
	phase_time = 0.0
	cooldown = cooldown_seconds
	player.velocity = Vector2.ZERO
	animation_requested.emit(&"slam_land")
	impacted.emit(point)
	var fx := FX.new()
	get_tree().current_scene.add_child(fx)
	fx.global_position = point
	fx.radius = shockwave_radius
	# Shared _seen prevents plunge + landing from doubling one target's damage.
	_damage_rect(Rect2(point + Vector2(-shockwave_radius, -shockwave_height),
		Vector2(shockwave_radius * 2.0, shockwave_height + 2.0)),
		1.5 * damage_multiplier, &"shockwave", Vector2(180, -130), true, point)
	# Only the contacted floor breaks, never nearby cracked tiles via the AoE.
	if is_instance_valid(floor_body) and floor_body.has_method("break_from_downstrike"):
		floor_body.call("break_from_downstrike", point, attack_serial)

func _damage_rect(rect: Rect2, amount: float, kind: StringName, impulse: Vector2,
		check_walls: bool, origin := Vector2.ZERO) -> void:
	if rect.size.y <= 0.0:
		return
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, rect.get_center())
	query.collision_mask = enemy_mask
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [player.get_rid()]
	for result in get_world_2d().direct_space_state.intersect_shape(query, 128):
		var receiver := _receiver(result.collider)
		if receiver == null:
			continue
		var id := receiver.get_instance_id()
		if _seen.has(id):
			continue
		var target_position: Vector2 = (result.collider as Node2D).global_position
		# Do not damage through a solid wall. Raise ray above contact to avoid self-floor.
		var ray_from := origin - Vector2(0, 6) if check_walls else _old_foot - Vector2(0, 4)
		var ray := PhysicsRayQueryParameters2D.create(ray_from, target_position, terrain_mask)
		ray.exclude = [player.get_rid()]
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		_seen[id] = true # One attempt per cast, including an invulnerable rejection.
		var applied_impulse := impulse
		if kind == &"shockwave":
			applied_impulse.x *= -1.0 if target_position.x < origin.x else 1.0
		var payload := {"amount": amount, "source": player, "attack_id": attack_serial,
			"kind": kind, "impulse": applied_impulse, "origin": ray_from}
		damage_requested.emit(receiver, payload)
		if auto_dispatch_damage:
			if receiver.has_method("receive_downstrike"):
				receiver.call("receive_downstrike", payload)
			elif receiver.has_method("take_hit"):
				receiver.call("take_hit", amount) # Project-compatible fallback; receiver owns recoil.

func _receiver(collider: Node) -> Node:
	var cursor := collider
	while cursor != null and cursor != get_tree().current_scene:
		if cursor.has_method("receive_downstrike") or cursor.has_method("take_hit"):
			return cursor
		cursor = cursor.get_parent()
	return null

func cancel() -> void:
	if not active():
		return
	phase = Phase.IDLE
	phase_time = 0.0
	cooldown = maxf(cooldown, cooldown_seconds)
	_seen.clear()
	finished.emit()

func reset() -> void:
	cancel()
	cooldown = 0.0
