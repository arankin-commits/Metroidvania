extends SceneTree
const SHOT = preload("res://scripts/combat_projectile.gd")
const BOSS = preload("res://scripts/forest_hunter_combat.gd")
const PLAYER = preload("res://scripts/player.gd")

class Target extends CharacterBody2D:
	var health := 5.0
	var hits := 0
	func combat_bounds() -> Rect2: return Rect2(global_position - Vector2(8, 8), Vector2(16, 16))
	func take_damage(amount: float, _from: float) -> void:
		health -= amount
		hits += 1

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var target := Target.new()
	var target_collision := CollisionShape2D.new()
	var target_shape := RectangleShape2D.new()
	target_shape.size = Vector2(16, 16)
	target_collision.shape = target_shape
	target.add_child(target_collision)
	root.add_child(target)
	var shot := SHOT.new()
	shot.target = target
	shot.homing_down = true
	shot.hover_time = 1.0
	shot.lifetime = 4.0
	shot.direction = Vector2.DOWN
	root.add_child(shot)
	shot.set_physics_process(false)
	for i in 4:
		shot._physics_process(0.25)
		assert(shot.position == Vector2.ZERO and target.hits == 0, "Hover moved or damaged the target before one second")
	assert(is_equal_approx(shot.hover_time, 0) and is_equal_approx(shot.lifetime, 3), "Hover consumed flight lifetime")
	target.position = Vector2(1000, 500)
	shot._physics_process(0.02)
	assert(shot.position.y > 0 and shot.direction.x > 0, "Release failed to track current player location")
	target.position = Vector2(-1000, -500)
	for i in 60:
		var previous_y: float = shot.position.y
		shot._physics_process(0.016)
		assert(shot.direction.y > 0 and shot.position.y >= previous_y, "Target above made the arrow travel upwards")
	assert(shot.direction.x < 0, "Released arrow stopped tracking horizontal player movement")
	shot.target = null
	var previous_y: float = shot.position.y
	shot._physics_process(0.02)
	assert(shot.position.y > previous_y, "Lost target allowed upward travel")
	shot.queue_free()
	await process_frame

	# Real attack emitters share the delay; ordinary arrows remain immediate.
	var arena := Node2D.new()
	root.add_child(arena)
	var boss := BOSS.new()
	boss.player = target
	arena.add_child(boss)
	boss.active = true
	boss.set_physics_process(false)
	boss.fire("arrow", 1, true)
	var volley = arena.get_child(arena.get_child_count() - 1)
	assert(volley.hover_time == 1 and volley.direction == Vector2.DOWN and volley.lifetime == 4)
	volley.set_physics_process(false)
	boss.active = false
	volley._physics_process(0.1)
	assert(volley.is_queued_for_deletion(), "Hover arrow survived encounter reset")
	boss.fire("arrow", 1, false)
	var ordinary = arena.get_child(arena.get_child_count() - 1)
	assert(ordinary.hover_time == 0, "Ordinary shot gained a volley delay")
	var player := PLAYER.new()
	arena.add_child(player)
	player.set_physics_process(false)
	player._friendly_shot("arrow", Vector2.DOWN, 1, true)
	var reward_arrow = arena.get_child(arena.get_child_count() - 1)
	assert(reward_arrow.hover_time == 1 and reward_arrow.homing_down and reward_arrow.direction.y > 0, "Earned volley differs from boss volley")
	# Check actual damage starts after release, with no repeated contact.
	var contact := SHOT.new()
	contact.target = target
	contact.homing_down = true
	contact.direction = Vector2.DOWN
	contact.hover_time = 1
	contact.lifetime = 4
	root.add_child(contact)
	contact.set_physics_process(false)
	target.position = Vector2.ZERO
	contact._physics_process(1)
	assert(target.hits == 0)
	target.position = Vector2(0, 50)
	await physics_frame
	await physics_frame
	contact._physics_process(0.1)
	assert(target.hits == 1 and target.health == 4 and contact.is_queued_for_deletion(), "Released volley failed to deal one normal hit")
	contact.queue_free()
	arena.queue_free()
	target.queue_free()
	await process_frame
	print("FLIPPING_VOLLEY_PASS: one-second stationary harmless hover, live targeting, never upward, release damage, lost target/reset cleanup, boss and reward ability; ordinary shots unchanged")
	quit()
