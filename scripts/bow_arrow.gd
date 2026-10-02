class_name BowArrow
extends "res://scripts/combat_projectile.gd"

static var _arrow_pool: Array = []

static func acquire_arrow() -> BowArrow:
	while not _arrow_pool.is_empty():
		var candidate = _arrow_pool.pop_back()
		if is_instance_valid(candidate) and not candidate.is_queued_for_deletion():
			candidate.reset_state()
			return candidate
	return BowArrow.new()

static func clear_arrow_pool() -> void:
	for item in _arrow_pool:
		if is_instance_valid(item):
			item.queue_free()
	_arrow_pool.clear()

func deactivate_and_recycle() -> void:
	if _arrow_pool.size() < MAX_POOL_SIZE and is_inside_tree():
		set_physics_process(false)
		visible = false
		hit_targets.clear()
		target = null
		owner_actor = null
		var p := get_parent()
		if p != null:
			p.remove_child(self)
		_arrow_pool.append(self)
	else:
		queue_free()

func setup(start_position: Vector2,shot_direction: Vector2,shot_target: Node,amount:=1.0) -> void:
	global_position=start_position
	direction=shot_direction.normalized()
	target=shot_target
	friendly=shot_target==null or shot_target.has_method("take_hit")
	damage=amount
	radius=5
	rotation=direction.angle()

