extends CharacterBody2D

signal defeated
signal attack_cued(cue: String)

const SPRITE_ROOT := "res://assets/gloamweaver-full-boss-integration/sprites/"
const VFX_SCRIPT := preload("res://scripts/gloamweaver_vfx.gd")
const TRAP_SCRIPT := preload("res://scripts/gloamweaver_trap.gd")
const BODY_KEYS := {
	"ceiling_idle": ["ceiling_idle_01", "ceiling_idle_02"],
	"crawl": ["ceiling_crawl_01", "ceiling_crawl_02", "ceiling_crawl_03", "ceiling_crawl_04"],
	"swing": ["swing_prepare", "swing_hang", "swing_rake", "swing_rise", "swing_recovery"],
	"zip": ["zip_aim", "zip_release", "zip_compress", "zip_travel", "zip_arrival", "zip_recovery"],
	"reattach": ["zip_aim", "zip_release", "zip_compress", "zip_travel", "reattach_catch", "zip_recovery"],
	"trap": ["trap_prepare", "trap_release", "trap_recovery"],
	"drop": ["drop_gather", "drop_airborne", "drop_impact", "floor_idle"],
	"floor": ["floor_idle"],
	"bite": ["bite_tell", "bite_active", "floor_idle"],
	"hurt": ["hurt"], "phase": ["phase_change"], "defeat": ["defeat"]
}

var player: CharacterBody2D
var health := 24.0
var max_health := 24.0
var active := false
var state := "ceiling_ready"
var state_time := 0.6
var attack_name := ""
var support := "ceiling"
var facing := -1
var random_seed := 7
var rng := RandomNumberGenerator.new()
var elapsed := 0.0
var cooldowns: Dictionary = {}
var history: Array[String] = []
var phase_two := false
var phase_pending := false
var phase_seen := false
var next_decision_at := 0.0
var event_id := 0
var hit_events: Dictionary = {}
var pose_name := "ceiling_idle"
var pose_index := 0
var pose_clock := 0.0
var sprite: Sprite2D
var owned_fx: Array[Node] = []
var owned_traps: Array[Node] = []
var anchor_a := Vector2(220.0, 90.0)
var anchor_b := Vector2(1380.0, 90.0)
var swing_anchor := Vector2.ZERO
var swing_angle := 0.0
var swing_direction := 1.0
var zip_target := Vector2.ZERO
var drop_target_x := 0.0
var impact_emitted := false
var hurt_time := 0.0
const FLOOR_ANCHOR_Y := 545.0

func _ready() -> void:
	add_to_group("mcp_watch")
	add_to_group("combat_targets")
	rng.seed = random_seed
	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.scale = Vector2(0.72, 0.72)
	sprite.position = Vector2(-192.0, -192.0) * 0.72
	add_child(sprite)
	_set_pose("ceiling_idle")

func _physics_process(delta: float) -> void:
	elapsed += delta
	state_time -= delta
	pose_clock += delta
	hurt_time = maxf(0.0, hurt_time - delta)
	if not active or health <= 0.0 or not is_instance_valid(player):
		_update_pose()
		return
	if health <= max_health * 0.5 and not phase_seen:
		phase_pending = true
	if state in ["ceiling_ready", "floor_ready"]:
		_tick_ready(delta)
	else:
		_tick_state(delta)
	if state_time <= 0.0:
		_advance_state()
	_update_pose()
	queue_redraw()

func _tick_ready(delta: float) -> void:
	if state == "ceiling_ready" and absf(velocity.x) > 8.0:
		_set_pose("crawl")
	if state == "ceiling_ready" and not _waves_or_traps_block():
		if absf(player.global_position.x - global_position.x) > 260.0:
			velocity.x = float(1 if player.global_position.x > global_position.x else -1) * 90.0
			facing = 1 if velocity.x > 0.0 else -1
			move_and_slide()
		else:
			velocity.x = 0.0
	if state_time <= 0.0:
		_choose_attack()

func _tick_state(_delta: float) -> void:
	match state:
		"swing_prepare", "swing_hang", "swing_rake", "swing_rise", "swing_recovery", "double_reset":
			velocity = Vector2.ZERO
			if state in ["swing_hang", "swing_rake", "swing_rise"]:
				var swing_progress := clampf(1.0 - state_time / (1.10 if state != "swing_rise" else 0.28), 0.0, 1.0)
				var swing_angle := lerpf(-0.72 * float(facing), 0.72 * float(facing), swing_progress)
				global_position = swing_anchor + Vector2(sin(swing_angle) * 420.0, cos(swing_angle) * 420.0)
			if state == "swing_rake" and not impact_emitted: _emit_swing_hit()
		"zip_aim": velocity = Vector2.ZERO
		"zip_travel":
			var travel := global_position.direction_to(zip_target) * 600.0
			velocity = travel
			move_and_slide()
			if global_position.distance_to(zip_target) < 20.0: state_time = 0.0
		"trap_prepare", "trap_release", "trap_recovery": velocity = Vector2.ZERO
		"drop_gather": velocity = Vector2.ZERO
		"drop_airborne":
			velocity.y += 1250.0 / 60.0
			move_and_slide()
			if is_on_floor(): state_time = 0.0
		"drop_impact":
			velocity = Vector2.ZERO
			if not impact_emitted: _emit_drop_hit()
		"floor_recovery": velocity = Vector2.ZERO
		"bite_tell": velocity = Vector2.ZERO
		"bite_active":
			if not impact_emitted: _emit_bite_hit()
		"phase_change": velocity = Vector2.ZERO

func _advance_state() -> void:
	match state:
		"swing_prepare": _enter("swing_hang", 0.25)
		"swing_hang": _enter("swing_rake", 1.10)
		"swing_rake": _enter("swing_rise", 0.28)
		"swing_rise": _enter("swing_recovery", 0.90)
		"swing_recovery": _finish("swing", 0.60)
		"double_reset": _enter("swing_rake", 1.25)
		"zip_aim": _enter("zip_travel", 2.20)
		"zip_travel": _enter("zip_arrival", 0.20)
		"zip_arrival": _enter("zip_recovery", 0.80)
		"zip_recovery": _finish("zip", 0.60)
		"trap_prepare": _enter("trap_release", 0.10)
		"trap_release":
			_spawn_trap()
			_enter("trap_recovery", 0.80)
		"trap_recovery": _finish("trap", 0.60)
		"drop_gather": _enter("drop_airborne", 1.50)
		"drop_airborne": _enter("drop_impact", 0.12)
		"drop_impact": _enter("floor_recovery", 1.15)
		"floor_recovery": _finish("drop", 0.60, "floor_ready")
		"bite_tell": _enter("bite_active", 0.14)
		"bite_active": _enter("floor_recovery", 0.85)
		"phase_change":
			phase_two = true; phase_seen = true; phase_pending = false; _finish("phase_change", 0.55)

func _enter(next_state: String, duration: float) -> void:
	state = next_state; state_time = duration; pose_clock = 0.0; pose_index = 0; impact_emitted = false
	attack_cued.emit("gloamweaver_" + next_state)
	if next_state == "swing_hang":
		swing_anchor = Vector2(global_position.x, 90.0)
		_spawn_fx("anchor_rosette", global_position, 0.55)
	if next_state == "zip_aim": _spawn_fx("anchor_rosette", zip_target, 0.85)
	if next_state == "zip_travel":
		_spawn_fx("hook_head", global_position, 0.35)
		_spawn_fx("cable_segment", global_position, 2.2)
	if next_state == "drop_airborne": _spawn_fx("landing_dust", global_position, 0.35)
	if next_state == "trap_release": _spawn_fx("trap_unfold", player.global_position, 0.35)
	if next_state == "phase_change": _spawn_fx("hit_fray", global_position, 0.85)

func _finish(completed: String, breathing: float, next_support: String = "ceiling_ready") -> void:
	attack_name = completed; state = next_support; support = "floor" if next_support == "floor_ready" else "ceiling"; state_time = breathing; velocity = Vector2.ZERO
	if support == "floor":
		position.y = FLOOR_ANCHOR_Y
	cooldowns[completed] = elapsed + _cooldown(completed)
	next_decision_at = elapsed + breathing

func _choose_attack() -> void:
	if phase_pending and support == "ceiling": _begin("phase_change"); return
	if elapsed < next_decision_at: return
	var gap := maxf(0.0, absf(player.global_position.x - global_position.x) - 90.0)
	var choices: Array[String] = []
	if support == "floor":
		choices.append("bite" if gap <= 120.0 else "reattach")
		if gap <= 120.0: choices.append("reattach")
	elif history.is_empty(): choices.append("swing")
	elif gap > 360.0:
		choices.append("swing"); choices.append("zip"); choices.append("drop")
	else:
		choices.append("swing"); choices.append("zip"); choices.append("trap")
	if phase_two and gap <= 360.0 and not history.is_empty(): choices.append("double_swing")
	var selected := "swing"
	var valid: Array[String] = []
	for choice in choices:
		if elapsed < float(cooldowns.get(choice, 0.0)): continue
		if choice != "swing" and not history.is_empty() and history[-1] == choice: continue
		if choice in ["trap", "reattach"] and _active_traps() >= (3 if phase_two else 2): continue
		valid.append(choice)
	if valid.is_empty(): state_time = 0.4; return
	selected = valid[rng.randi_range(0, valid.size() - 1)]
	_begin(selected)

func _begin(name: String) -> void:
	attack_name = name; facing = 1 if player.global_position.x > global_position.x else -1
	if name != "phase_change": history.append(name)
	if history.size() > 8: history.pop_front()
	if name == "zip": zip_target = anchor_a if facing > 0 else anchor_b
	if name == "drop": drop_target_x = clampf(player.global_position.x, 220.0, 1380.0)
	match name:
		"swing": _enter("swing_prepare", 0.90)
		"double_swing": _enter("swing_prepare", 1.0)
		"zip", "reattach": _enter("zip_aim", 0.85)
		"trap": _enter("trap_prepare", 0.80)
		"drop": _enter("drop_gather", 0.90)
		"bite": _enter("bite_tell", 0.55)
		"phase_change": _enter("phase_change", 0.85)

func _cooldown(name: String) -> float:
	return {"swing": 4.0, "double_swing": 11.0, "zip": 6.5, "reattach": 1.0, "trap": 8.0, "drop": 6.0, "bite": 3.5}.get(name, 1.0)

func _emit_swing_hit() -> void:
	impact_emitted = true; event_id += 1; hit_events.clear()
	_spawn_fx("swing_streak", global_position + Vector2(float(facing) * 42.0, 20.0), 0.22)
	_apply_hit(Rect2(global_position + Vector2(-90.0, 0.0), Vector2(180.0, 60.0)), event_id, {"horizontal": 250.0 if attack_name == "double_swing" else 220.0, "upward": 180.0 if attack_name == "double_swing" else 150.0, "lock": 0.17, "direction": facing})
	if attack_name == "double_swing": _enter("double_reset", 0.45)

func _emit_drop_hit() -> void:
	impact_emitted = true; event_id += 1; hit_events.clear()
	_spawn_fx("landing_dust", global_position, 0.35)
	_apply_hit(Rect2(global_position + Vector2(-80.0, -20.0), Vector2(160.0, 50.0)), event_id, {"horizontal": 210.0, "upward": 240.0, "lock": 0.19, "direction": _player_direction()})

func _emit_bite_hit() -> void:
	impact_emitted = true; event_id += 1; hit_events.clear()
	_spawn_fx("bite_streak", global_position + Vector2(float(facing) * 55.0, -15.0), 0.18)
	_apply_hit(Rect2(global_position + Vector2(20.0 if facing > 0 else -100.0, -40.0), Vector2(80.0, 45.0)), event_id, {"horizontal": 150.0, "upward": 90.0, "lock": 0.10, "direction": facing})

func _player_direction() -> int: return facing if absf(player.global_position.x - global_position.x) < 1.0 else (1 if player.global_position.x > global_position.x else -1)

func _apply_hit(hitbox: Rect2, source_event: int, profile: Dictionary) -> void:
	if hit_events.has(source_event) or not hitbox.intersects(player.combat_bounds()): return
	var before: float = player.health
	player.take_damage(1.0, global_position.x, true, profile)
	if player.health < before:
		hit_events[source_event] = true
		_spawn_fx("hit_fray", player.global_position, 0.20)

func combat_bounds() -> Rect2: return Rect2(global_position - Vector2(70.0, 70.0), Vector2(140.0, 120.0))

func take_hit(amount: float = 1.0) -> void:
	if not active or health <= 0.0: return
	health = maxf(0.0, health - amount); hurt_time = 0.14; _spawn_fx("hit_fray", global_position, 0.20)
	if health <= 0.0:
		active = false; state = "defeated"; _clear_owned(); _spawn_fx("web_dissolve", global_position, 0.8); defeated.emit()

func force_attack(name: String) -> void:
	_clear_owned()
	if name == "bite" and support == "ceiling":
		support = "floor"
		state = "floor_ready"
		position.y = FLOOR_ANCHOR_Y
		state_time = 0.1
	_begin(name)

func debug_walk(direction: int) -> void:
	support = "ceiling"; state = "ceiling_ready"; state_time = 3.0; velocity.x = float(direction) * 90.0

func reset_encounter() -> void:
	_clear_owned(); health = max_health; active = true; state = "ceiling_ready"; support = "ceiling"; state_time = 0.8; position = Vector2(850.0, 160.0); velocity = Vector2.ZERO; phase_two = false; phase_seen = false; phase_pending = false; history.clear(); cooldowns.clear(); rng.seed = random_seed

func _spawn_fx(key: String, at: Vector2, duration: float) -> void:
	var fx := VFX_SCRIPT.new(); fx.key = key; fx.lifetime = duration; fx.direction = facing; fx.global_position = at; add_child(fx); owned_fx.append(fx)

func spawn_trap_trigger(at: Vector2) -> void:
	_spawn_fx("trap_trigger", at, 0.30)

func _spawn_trap() -> void:
	if _active_traps() >= (3 if phase_two else 2): return
	var trap := TRAP_SCRIPT.new(); trap.boss_owner = self; trap.global_position = Vector2(clampf(player.global_position.x, 220.0, 1380.0), 620.0); get_parent().add_child(trap); owned_traps.append(trap); _spawn_fx("trap_seed", trap.global_position + Vector2(0.0, -160.0), 0.45); await get_tree().physics_frame; trap.arm(); _spawn_fx("trap_active", trap.global_position, 8.0)

func _active_traps() -> int:
	var count := 0
	for trap in owned_traps:
		if is_instance_valid(trap): count += 1
	return count

func _waves_or_traps_block() -> bool: return false

func _clear_owned() -> void:
	for fx in owned_fx:
		if is_instance_valid(fx): fx.queue_free()
	for trap in owned_traps:
		if is_instance_valid(trap): trap.queue_free()
	owned_fx.clear(); owned_traps.clear()
	if is_instance_valid(player) and player.has_method("clear_gloamweaver_slow"): player.clear_gloamweaver_slow()

func _set_pose(name: String) -> void:
	pose_name = name; pose_index = 0; pose_clock = 0.0
	var keys: Array = BODY_KEYS.get(name, BODY_KEYS["ceiling_idle"])
	sprite.texture = load(SPRITE_ROOT + str(keys[0] + ".png")); sprite.flip_h = facing < 0

func _update_pose() -> void:
	var desired := "ceiling_idle"
	match state:
		"ceiling_ready": desired = "crawl" if absf(velocity.x) > 8.0 else "ceiling_idle"
		"swing_prepare", "swing_hang", "swing_rake", "swing_rise", "swing_recovery", "double_reset": desired = "swing"
		"zip_aim", "zip_travel", "zip_arrival", "zip_recovery": desired = "zip"
		"trap_prepare", "trap_release", "trap_recovery": desired = "trap"
		"drop_gather", "drop_airborne", "drop_impact": desired = "drop"
		"floor_ready", "floor_recovery": desired = "floor"
		"bite_tell", "bite_active": desired = "bite"
		"phase_change": desired = "phase"
		"defeated": desired = "defeat"
	if hurt_time > 0.0: desired = "hurt"
	if desired != pose_name: _set_pose(desired)
	var keys: Array = BODY_KEYS.get(pose_name, BODY_KEYS["ceiling_idle"])
	var step := 0.2 if pose_name in ["ceiling_idle", "crawl"] else 0.14
	if pose_clock >= step and keys.size() > 1:
		pose_clock = 0.0; pose_index = (pose_index + 1) % keys.size(); sprite.texture = load(SPRITE_ROOT + str(keys[pose_index] + ".png"))
	sprite.flip_h = facing < 0

func _draw() -> void:
	if support == "ceiling" and state in ["swing_hang", "swing_rake", "swing_rise"]:
		draw_line(Vector2(0.0, -80.0), to_local(swing_anchor), Color("e7d4ef"), 2.0)
	if state == "zip_travel" or state == "zip_aim":
		draw_line(Vector2(0.0, -80.0), to_local(zip_target), Color("e7d4ef"), 2.0)