extends CharacterBody2D

signal defeated
signal attack_cued(cue: String)

const SPRITE_ROOT := "res://assets/gloamweaver-full-boss-integration/sprites/"
const VFX_SCRIPT := preload("res://scripts/gloamweaver_vfx.gd")
const TRAP_SCRIPT := preload("res://scripts/gloamweaver_trap.gd")
const FLOOR_Y := 567.0
const LEFT_WALL := 96.0
const RIGHT_WALL := 1304.0
const BODY_HALF_WIDTH := 70.0
const BODY_KEYS := {
	"floor": ["floor_idle"],
	"bite": ["bite_tell", "bite_active", "floor_idle"],
	"charge": ["zip_aim", "zip_release", "zip_compress", "zip_travel", "zip_arrival", "zip_recovery"],
	"snare": ["trap_prepare", "trap_release", "trap_recovery"],
	"hurt": ["hurt"], "phase": ["phase_change"], "defeat": ["defeat"]
}

var player: CharacterBody2D
var health := 24.0
var max_health := 24.0
var active := false
var state := "floor_idle"
var state_time := 0.8
var attack_name := ""
var facing := -1
var phase_two := false
var phase_pending := false
var phase_seen := false
var random_seed := 7
var rng := RandomNumberGenerator.new()
var elapsed := 0.0
var cooldowns: Dictionary = {}
var history: Array[String] = []
var nontrap_actions := 0
var next_decision_at := 0.0
var event_id := 0
var impact_emitted := false
var hit_events: Dictionary = {}
var pose_name := "floor"
var pose_index := 0
var pose_clock := 0.0
var hurt_time := 0.0
var sprite: Sprite2D
var owned_fx: Array[Node] = []
var owned_traps: Array[Node] = []
var charge_anchor := Vector2.ZERO
var charge_end_x := 0.0
var charge_distance := 0.0
var charge_direction := 1
var cable_active := false
var trail_clock := 0.0
var support_state := "floor_contact"
var anchor_a := Vector2(96.0, FLOOR_Y - 38.0)
var anchor_b := Vector2(1304.0, FLOOR_Y - 38.0)

func _ready() -> void:
	add_to_group("mcp_watch")
	add_to_group("combat_targets")
	rng.seed = random_seed
	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.scale = Vector2(0.72, 0.72)
	sprite.position = Vector2(-192.0, -223.0) * 0.72
	add_child(sprite)
	_set_pose("floor")

func _physics_process(delta: float) -> void:
	elapsed += delta
	state_time -= delta
	pose_clock += delta
	hurt_time = maxf(0.0, hurt_time - delta)
	trail_clock = maxf(0.0, trail_clock - delta)
	if not active or health <= 0.0 or not is_instance_valid(player):
		_update_pose()
		return
	if health <= max_health * 0.5 and not phase_seen:
		phase_pending = true
	if state == "floor_idle":
		_tick_idle(delta)
	else:
		_tick_state(delta)
	if state_time <= 0.0:
		_advance_state()
	_update_pose()
	queue_redraw()

func _tick_idle(delta: float) -> void:
	var gap := _body_edge_gap()
	if gap > 200.0:
		var walk_direction := 1 if player.global_position.x > global_position.x else -1
		velocity.x = move_toward(velocity.x, float(walk_direction) * 80.0, 900.0 * delta)
		facing = walk_direction
		move_and_slide()
	else:
		velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
		move_and_slide()
	if phase_pending and elapsed >= next_decision_at:
		_begin("phase_change")
	elif state_time <= 0.0:
		_choose_attack()

func _tick_state(delta: float) -> void:
	match state:
		"bite_tell", "bite_recovery", "snare_tell", "snare_release", "snare_recovery", "charge_tell", "charge_hook", "charge_skid", "charge_recovery", "phase_change":
			velocity.x = move_toward(velocity.x, 0.0, 1600.0 * delta)
			move_and_slide()
		"bite_active":
			if not impact_emitted: _emit_bite_hit()
		"charge_travel":
			velocity.x = float(charge_direction) * 420.0
			if trail_clock <= 0.0:
				_spawn_fx("swing_streak", global_position - Vector2(float(charge_direction) * 34.0, 0.0), 0.16)
				trail_clock = 0.08
			move_and_slide()
			if not impact_emitted: _emit_charge_hit()
			if absf(global_position.x - charge_end_x) < 18.0 or absf(charge_distance) >= 650.0 or is_on_wall():
				state_time = 0.0
				velocity.x = 0.0
		"snare_release":
			velocity.x = 0.0
		"phase_change": velocity.x = 0.0

func _advance_state() -> void:
	match state:
		"bite_tell": _enter("bite_active", 0.14)
		"bite_active": _enter("bite_recovery", 0.90)
		"bite_recovery": _finish("bite", 0.60)
		"charge_tell": _enter("charge_hook", 0.20)
		"charge_hook":
			cable_active = true
			_spawn_fx("hook_head", charge_anchor, 0.25)
			_spawn_fx("anchor_rosette", charge_anchor, 0.70)
			_enter("charge_travel", 1.55)
		"charge_travel": _enter("charge_skid", 0.20)
		"charge_skid":
			cable_active = true
			_spawn_fx("landing_dust", global_position, 0.35)
			_enter("charge_recovery", 1.15)
		"charge_recovery":
			cable_active = false
			_finish("charge", 0.60)
		"snare_tell": _enter("snare_release", 0.10)
		"snare_release":
			_spawn_trap()
			_enter("snare_recovery", 0.85)
		"snare_recovery": _finish("trap", 0.60)
		"phase_change":
			phase_two = true
			phase_seen = true
			phase_pending = false
			_finish("phase_change", 0.55)

func _enter(next_state: String, duration: float) -> void:
	state = next_state
	state_time = duration
	pose_clock = 0.0
	pose_index = 0
	impact_emitted = false
	attack_cued.emit("gloamweaver_" + next_state)
	if next_state == "charge_tell":
		charge_direction = 1 if player.global_position.x >= global_position.x else -1
		facing = charge_direction
		charge_anchor = Vector2(RIGHT_WALL if charge_direction > 0 else LEFT_WALL, FLOOR_Y - 76.0)
		charge_end_x = clampf(charge_anchor.x - float(charge_direction) * 48.0, LEFT_WALL + BODY_HALF_WIDTH, RIGHT_WALL - BODY_HALF_WIDTH)
		charge_distance = 0.0
		_spawn_fx("anchor_rosette", charge_anchor, 1.0)
	if next_state == "charge_travel":
		_spawn_fx("cable_segment", _spinneret_world(), 2.0)
		cable_active = true
	if next_state == "phase_change": _spawn_fx("hit_fray", global_position, 0.85)

func _finish(completed: String, breathing: float) -> void:
	attack_name = completed
	state = "floor_idle"
	state_time = breathing
	next_decision_at = elapsed + breathing
	velocity.x = 0.0
	cooldowns[completed] = elapsed + _cooldown(completed)

func _choose_attack() -> void:
	if elapsed < next_decision_at: return
	var gap := _body_edge_gap()
	var trap_cap := 3 if phase_two else 2
	var trap_ready := _active_traps() < trap_cap and elapsed >= float(cooldowns.get("trap", 0.0))
	var choices: Array[String] = []
	if phase_pending:
		_begin("phase_change")
		return
	if nontrap_actions >= 3 and trap_ready:
		choices.append("trap")
	elif gap <= 120.0:
		choices.append("bite"); if trap_ready: choices.append("trap")
	elif gap < 180.0:
		if trap_ready: choices.append("trap")
	else:
		if _charge_safe() and elapsed >= float(cooldowns.get("charge", 0.0)): choices.append("charge")
		if trap_ready: choices.append("trap")
	if choices.is_empty():
		state_time = 0.40
		return
	var selected: String = choices[rng.randi_range(0, choices.size() - 1)]
	if not history.is_empty() and selected == history[-1] and selected in ["charge", "trap"]:
		selected = "bite" if gap <= 120.0 else "trap"
	_begin(selected)

func _begin(name: String) -> void:
	attack_name = name
	if name != "phase_change":
		history.append(name)
		if history.size() > 8: history.pop_front()
	if name == "trap": nontrap_actions = 0
	elif name != "phase_change": nontrap_actions += 1
	match name:
		"bite": _enter("bite_tell", 0.60)
		"charge": _enter("charge_tell", 1.0)
		"trap": _enter("snare_tell", 0.80)
		"phase_change": _enter("phase_change", 0.85)

func _cooldown(name: String) -> float:
	return {"bite": 3.5, "charge": 7.0, "trap": 8.0}.get(name, 1.0)

func _charge_safe() -> bool:
	return _body_edge_gap() >= 180.0 and absf(player.global_position.x - global_position.x) <= 650.0 and not is_on_wall()

func _body_edge_gap() -> float:
	return maxf(0.0, absf(player.global_position.x - global_position.x) - BODY_HALF_WIDTH - 14.0)

func _emit_bite_hit() -> void:
	impact_emitted = true
	event_id += 1
	hit_events.clear()
	_spawn_fx("bite_streak", global_position + Vector2(float(facing) * 55.0, -22.0), 0.18)
	_apply_hit(Rect2(global_position + Vector2(20.0 if facing > 0 else -100.0, -50.0), Vector2(80.0, 45.0)), event_id, {"horizontal": 150.0, "upward": 90.0, "lock": 0.10, "direction": facing})

func _emit_charge_hit() -> void:
	if impact_emitted: return
	impact_emitted = true
	event_id += 1
	hit_events.clear()
	_apply_hit(Rect2(global_position + Vector2(20.0 if charge_direction > 0 else -100.0, -48.0), Vector2(80.0, 48.0)), event_id, {"horizontal": 260.0, "upward": 120.0, "lock": 0.17, "direction": charge_direction})

func _apply_hit(hitbox: Rect2, source_event: int, profile: Dictionary) -> void:
	if hit_events.has(source_event) or not hitbox.intersects(player.combat_bounds()): return
	var before: float = player.health
	player.take_damage(1.0, global_position.x, true, profile)
	if player.health < before:
		hit_events[source_event] = true
		_spawn_fx("hit_fray", player.global_position, 0.20)

func combat_bounds() -> Rect2:
	return Rect2(global_position - Vector2(70.0, 70.0), Vector2(140.0, 120.0))

func take_hit(amount: float = 1.0) -> void:
	if not active or health <= 0.0: return
	health = maxf(0.0, health - amount)
	hurt_time = 0.15
	_spawn_fx("hit_fray", global_position, 0.20)
	if health <= 0.0:
		active = false
		state = "defeat"
		_clear_owned()
		_spawn_fx("web_dissolve", global_position, 0.80)
		defeated.emit()

func force_attack(name: String) -> void:
	_clear_owned()
	if name in ["swing", "double_swing", "zip", "drop", "reattach"]: return
	if name == "bite" or name == "charge" or name == "trap": _begin(name)

func reset_encounter() -> void:
	_clear_owned()
	health = max_health
	active = true
	state = "floor_idle"
	position = Vector2(850.0, FLOOR_Y)
	velocity = Vector2.ZERO
	phase_two = false
	phase_pending = false
	phase_seen = false
	nontrap_actions = 0
	history.clear()
	cooldowns.clear()
	rng.seed = random_seed

func debug_walk(direction: int) -> void:
	state = "floor_idle"
	state_time = 3.0
	velocity.x = float(clampi(direction, -1, 1)) * 80.0

func _spawn_fx(key: String, at: Vector2, duration: float) -> void:
	var fx := VFX_SCRIPT.new()
	fx.key = key
	fx.lifetime = duration
	fx.direction = facing
	fx.global_position = at
	add_child(fx)
	owned_fx.append(fx)

func _spawn_trap() -> void:
	if _active_traps() >= (3 if phase_two else 2): return
	var target_x := clampf(player.global_position.x + float(facing) * 140.0, LEFT_WALL + 120.0, RIGHT_WALL - 120.0)
	var trap := TRAP_SCRIPT.new()
	trap.boss_owner = self
	trap.global_position = Vector2(target_x, 596.0)
	get_parent().add_child(trap)
	owned_traps.append(trap)
	_spawn_fx("trap_seed", trap.global_position + Vector2(0.0, -160.0), 0.45)
	await get_tree().physics_frame
	trap.arm()
	_spawn_fx("trap_active", trap.global_position, 8.0)

func spawn_trap_trigger(at: Vector2) -> void:
	_spawn_fx("trap_trigger", at, 0.30)

func _active_traps() -> int:
	var count := 0
	for trap in owned_traps:
		if is_instance_valid(trap): count += 1
	return count

func _clear_owned() -> void:
	for fx in owned_fx:
		if is_instance_valid(fx): fx.queue_free()
	for trap in owned_traps:
		if is_instance_valid(trap): trap.queue_free()
	owned_fx.clear()
	owned_traps.clear()
	if is_instance_valid(player) and player.has_method("clear_gloamweaver_slow"):
		player.clear_gloamweaver_slow()
	cable_active = false

func _set_pose(name: String) -> void:
	pose_name = name
	pose_index = 0
	pose_clock = 0.0
	var keys: Array = BODY_KEYS.get(name, BODY_KEYS["floor"])
	sprite.texture = load(SPRITE_ROOT + str(keys[0] + ".png"))
	sprite.flip_h = facing < 0

func _update_pose() -> void:
	var desired := "floor"
	match state:
		"bite_tell": desired = "bite"
		"bite_active": desired = "bite"
		"bite_recovery": desired = "floor"
		"charge_tell", "charge_hook", "charge_travel", "charge_skid", "charge_recovery": desired = "charge"
		"snare_tell", "snare_release", "snare_recovery": desired = "snare"
		"phase_change": desired = "phase"
		"defeat": desired = "defeat"
	if hurt_time > 0.0 and state != "defeat": desired = "hurt"
	if desired != pose_name: _set_pose(desired)
	var keys: Array = BODY_KEYS.get(pose_name, BODY_KEYS["floor"])
	var step := 0.20 if pose_name == "floor" else 0.14
	if pose_clock >= step and keys.size() > 1:
		pose_clock = 0.0
		pose_index = (pose_index + 1) % keys.size()
		sprite.texture = load(SPRITE_ROOT + str(keys[pose_index] + ".png"))
	sprite.flip_h = facing < 0

func _spinneret_world() -> Vector2:
	return global_position + Vector2(float(facing) * 8.0, -38.0)

func _draw() -> void:
	if cable_active:
		draw_line(to_local(_spinneret_world()), to_local(charge_anchor), Color("e7d4ef"), 2.0)