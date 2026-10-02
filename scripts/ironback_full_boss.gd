extends CharacterBody2D

signal defeated
signal attack_cued(cue: String)

const SPRITE_ROOT := "res://assets/ironback-boss-handoff/ironback-full-boss-integration-v2/sprites/"
const SHOCKWAVE_SCRIPT := preload("res://scripts/ironback_v2_shockwave.gd")
const FX_SCRIPT := preload("res://scripts/ironback_v2_fx.gd")
const SPRITES := {
	"idle": ["idle_01.png", "idle_02.png"], "walk": ["walk_01.png", "walk_02.png", "walk_03.png", "walk_04.png"],
	"smash_tell": ["smash_crouch.png", "smash_rise.png", "smash_overhead.png"], "smash_down": ["smash_downstroke.png"],
	"smash_impact": ["smash_impact.png"], "smash_recovery": ["smash_recovery.png"], "leap_crouch": ["leap_crouch.png"],
	"leap_air": ["leap_takeoff.png", "leap_airborne.png", "leap_descend.png"], "leap_impact": ["leap_impact.png"],
	"leap_recovery": ["leap_recovery.png"], "backhand_tell": ["backhand_tell.png"], "backhand_active": ["backhand_active.png"],
	"backhand_recovery": ["backhand_recovery.png"], "rush_tell": ["rush_tell.png"], "rush_active": ["rush_active.png"],
	"rush_brake": ["rush_brake.png"], "phase_change": ["phase_change.png"], "defeat": ["defeat_kneel.png", "defeat_final.png"]
}

var player: CharacterBody2D
var health := 24.0
var max_health := 24.0
var active := false
var state := "idle"
var state_time := 0.5
var attack_name := ""
var facing := 1
var hurt_flash := 0.0
var invulnerability := 0.0
var home_y := 560.0
var arena_left := 100.0
var arena_right := 1300.0
var phase_two := false
var phase_change_seen := false
var phase_change_pending := false
var attack_count := 0
var random_seed := 17
var rng := RandomNumberGenerator.new()
var cooldowns: Dictionary = {}
var history: Array[String] = []
var next_decision_at := 0.0
var elapsed := 0.0
var event_id := 0
var damaged_event_ids: Dictionary = {}
var impact_emitted := false
var barrage_index := 0
var leap_target_x := 0.0
var rush_distance := 0.0
var current_pose := "idle"
var pose_clock := 0.0
var sprite: Sprite2D
var pose_frames: Array[String] = []
var pose_index := 0
var hurt_override_time := 0.0
var hurt_restore_pose := "idle"
var owned_fx: Array[Node] = []
var walk_debug_direction := 0
var walk_debug_time := 0.0
var effect_flags: Dictionary = {}

func _ready() -> void:
	add_to_group("mcp_watch")
	add_to_group("combat_targets")
	home_y = position.y
	rng.seed = random_seed
	_reset_policy()
	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.scale = Vector2(0.72, 0.72)
	sprite.position = Vector2(-192.0, -340.0) * 0.72
	add_child(sprite)
	_set_pose("idle")

func _physics_process(delta: float) -> void:
	elapsed += delta
	pose_clock += delta
	hurt_flash = maxf(0.0, hurt_flash - delta)
	hurt_override_time = maxf(0.0, hurt_override_time - delta)
	invulnerability = maxf(0.0, invulnerability - delta)
	if not active or health <= 0.0 or not is_instance_valid(player):
		_update_sprite()
		return
	if health <= max_health * 0.5 and not phase_change_seen:
		phase_change_pending = true
	if state == "idle":
		if walk_debug_time > 0.0:
			walk_debug_time = maxf(0.0, walk_debug_time - delta)
			velocity.x = float(walk_debug_direction) * 90.0
			move_and_slide()
		elif not _waves_alive() and state_time > 0.15 and _body_edge_gap() > 240.0:
			var walk_direction := 1 if player.global_position.x > global_position.x else -1
			velocity.x = float(walk_direction) * 90.0
			facing = walk_direction
			move_and_slide()
		else:
			velocity.x = 0.0
		state_time -= delta
		if state_time <= 0.0:
			_try_choose_attack()
	else:
		state_time -= delta
		_tick_state(delta)
		if state_time <= 0.0:
			_advance_state()
	_update_sprite()

func _tick_state(delta: float) -> void:
	match state:
		"smash_tell", "barrage_tell", "smash_down", "smash_impact", "smash_recovery", "barrage_down", "barrage_impact", "barrage_reset":
			velocity = Vector2.ZERO
			if state == "smash_tell" or state == "barrage_tell":
				if state_time <= 0.25: _spawn_fx_once("vent", "vent", global_position + Vector2(0.0, -80.0), 0.25)
			if state == "smash_impact" or state == "barrage_impact": _emit_impact_once()
		"leap_crouch": velocity = Vector2.ZERO
		"leap_air":
			var progress := clampf(1.0 - state_time / 0.78, 0.0, 1.0)
			position.x = lerpf(position.x, leap_target_x, minf(1.0, delta * 8.0))
			position.y = home_y - sin(progress * PI) * 150.0
		"leap_impact":
			velocity = Vector2.ZERO
			if not impact_emitted: _emit_landing_once()
		"rush_active":
			var step := minf(absf(rush_distance), 340.0 * delta)
			if not impact_emitted: _emit_rush_once()
			position.x = clampf(position.x + float(facing) * step, arena_left + 90.0, arena_right - 90.0)
			rush_distance -= step
			if rush_distance <= 0.0: state_time = 0.0
		"backhand_active":
			if not impact_emitted: _emit_backhand_once()
		"phase_change": velocity = Vector2.ZERO

func _advance_state() -> void:
	match state:
		"smash_tell": _enter_state("smash_down", 0.15)
		"barrage_tell": _enter_state("barrage_down", 0.15)
		"smash_down": _enter_state("smash_impact", 0.10)
		"smash_impact": _enter_state("smash_recovery", 0.95)
		"smash_recovery": _finish_attack(0.50, "smash")
		"barrage_down": _enter_state("barrage_impact", 0.10)
		"barrage_impact":
			barrage_index += 1
			if barrage_index < 3: _enter_state("barrage_reset", 0.30)
			else: _enter_state("smash_recovery", 1.10)
		"barrage_reset": _enter_state("barrage_down", 0.15)
		"leap_crouch": _enter_state("leap_air", 0.78)
		"leap_air": _enter_state("leap_impact", 0.10)
		"leap_impact": _enter_state("leap_recovery", 0.90)
		"leap_recovery": _finish_attack(0.50, "leap")
		"backhand_tell": _enter_state("backhand_active", 0.15)
		"backhand_active": _enter_state("backhand_recovery", 0.75)
		"backhand_recovery": _finish_attack(0.50, "backhand")
		"rush_tell": _enter_state("rush_active", 0.70)
		"rush_active": _enter_state("rush_brake", 0.20)
		"rush_brake": _enter_state("rush_recovery", 0.80)
		"rush_recovery": _finish_attack(0.50, "rush")
		"phase_change":
			phase_two = true
			phase_change_seen = true
			phase_change_pending = false
			_finish_attack(0.35, "phase_change")

func _enter_state(next_state: String, duration: float) -> void:
	state = next_state
	state_time = duration
	impact_emitted = false
	pose_clock = 0.0
	effect_flags.clear()
	if next_state == "leap_air":
		_spawn_fx("leap_dust", "dust", global_position + Vector2(-float(facing) * 40.0, 0.0), 0.30)
		_spawn_fx("leap_trail", "trail", global_position + Vector2(-float(facing) * 35.0, -40.0), 0.45)
	if next_state == "rush_active":
		_spawn_fx("rush_trail", "rush_dust", global_position + Vector2(-float(facing) * 45.0, 0.0), 0.70)
	if next_state == "rush_brake":
		_spawn_fx("rush_brake", "brake", global_position + Vector2(-float(facing) * 35.0, 0.0), 0.20)
	if next_state == "phase_change":
		_spawn_fx("phase_sparks", "sparks", global_position + Vector2(0.0, -80.0), 0.80)
		_spawn_fx("phase_steam", "vent", global_position + Vector2(0.0, -70.0), 0.80)
	attack_cued.emit("ironback_" + next_state)

func _finish_attack(breathing_time: float, completed_attack: String) -> void:
	state = "idle"
	state_time = breathing_time
	next_decision_at = elapsed + breathing_time
	attack_name = completed_attack
	impact_emitted = false
	velocity = Vector2.ZERO
	if completed_attack != "phase_change": cooldowns[completed_attack] = elapsed + _cooldown_for(completed_attack)

func _try_choose_attack() -> void:
	if phase_change_pending and not _waves_alive():
		_begin_attack("phase_change")
		return
	if elapsed < next_decision_at or _waves_alive(): return
	var gap := _body_edge_gap()
	var options: Array[String] = []
	var weights: Array[float] = []
	if history.is_empty(): options = ["smash"]; weights = [1.0]
	elif gap < 100.0: options = ["smash", "backhand"]; weights = [65.0, 35.0]
	elif gap <= 300.0: options = ["smash", "rush"]; weights = [75.0, 25.0]
	else: options = ["leap", "rush"]; weights = [70.0, 30.0]
	if phase_two and gap <= 300.0 and not history.is_empty(): options.append("barrage"); weights.append(22.0)
	var eligible: Array[String] = []
	var eligible_weights: Array[float] = []
	for index in options.size():
		var option := options[index]
		if elapsed < float(cooldowns.get(option, 0.0)): continue
		if option == "smash" and history.size() >= 2 and history[-2] == "smash" and history[-1] == "smash": continue
		if option != "smash" and not history.is_empty() and history[-1] == option: continue
		if option == "leap" and not _leap_safe(): continue
		eligible.append(option); eligible_weights.append(weights[index])
	if eligible.is_empty(): state_time = 0.35; return
	var total := 0.0
	for weight in eligible_weights: total += weight
	var roll := rng.randf() * total
	var selected: String = eligible.back()
	for index in eligible.size():
		roll -= eligible_weights[index]
		if roll < 0.0: selected = eligible[index]; break
	_begin_attack(selected)

func _begin_attack(name: String) -> void:
	if name != "phase_change":
		attack_count += 1; attack_name = name; history.append(name)
		if history.size() > 8: history.pop_front()
		cooldowns[name] = elapsed + _cooldown_for(name)
	else: attack_name = name
	facing = 1 if player.global_position.x >= global_position.x else -1
	if name == "leap": leap_target_x = clampf(player.global_position.x, arena_left + 130.0, arena_right - 130.0)
	if name == "rush": rush_distance = minf(absf(player.global_position.x - global_position.x), 238.0)
	if name == "barrage": barrage_index = 0
	match name:
		"phase_change": _enter_state("phase_change", 0.80)
		"smash": _enter_state("smash_tell", 0.80)
		"barrage": _enter_state("barrage_tell", 0.90)
		"leap": _enter_state("leap_crouch", 0.65)
		"backhand": _enter_state("backhand_tell", 0.50)
		"rush": _enter_state("rush_tell", 0.65)

func _cooldown_for(name: String) -> float:
	return {"smash": 2.5, "barrage": 12.0, "leap": 6.0, "backhand": 3.5, "rush": 7.0}.get(name, 1.0)

func _body_edge_gap() -> float: return maxf(0.0, absf(player.global_position.x - global_position.x) - 80.0)
func _leap_safe() -> bool: return player.global_position.x > arena_left + 100.0 and player.global_position.x < arena_right - 100.0
func _waves_alive() -> bool: return not get_tree().get_nodes_in_group("ironback_v2_waves").is_empty()

func _spawn_fx_once(key: String, kind: String, fx_position: Vector2, duration: float) -> void:
	if effect_flags.has(key):
		return
	effect_flags[key] = true
	_spawn_fx(key, kind, fx_position, duration)

func _spawn_fx(key: String, kind: String, fx_position: Vector2, duration: float) -> void:
	var effect := FX_SCRIPT.new()
	effect.kind = kind
	effect.lifetime = duration
	effect.direction = facing
	effect.global_position = fx_position
	effect.name = "IronbackFX_" + key
	add_child(effect)
	owned_fx.append(effect)

func _clear_owned_fx() -> void:
	for effect in owned_fx:
		if is_instance_valid(effect):
			effect.queue_free()
	owned_fx.clear()

func _emit_impact_once() -> void:
	if impact_emitted: return
	impact_emitted = true; event_id += 1; damaged_event_ids.clear()
	var profile := {"horizontal": 260.0, "upward": 260.0, "lock": 0.20, "direction": _player_direction()}
	if attack_name == "barrage":
		profile = {"horizontal": 310.0 if barrage_index >= 2 else 240.0, "upward": 280.0 if barrage_index >= 2 else 240.0, "lock": 0.22 if barrage_index >= 2 else 0.18, "direction": _player_direction()}
	_apply_attack_damage(Rect2(global_position + Vector2(-110.0, -60.0), Vector2(220.0, 60.0)), event_id, profile)
	_spawn_fx("impact_%d" % event_id, "impact", global_position + Vector2(0.0, 0.0), 0.30)
	_spawn_fx("chips_%d" % event_id, "chips", global_position + Vector2(0.0, 0.0), 0.35)
	_spawn_fx("dust_%d" % event_id, "dust", global_position + Vector2(0.0, 0.0), 0.45)
	_spawn_wave_pair(event_id, 360.0, 50.0, {"horizontal": 190.0, "upward": 150.0, "lock": 0.14})

func _emit_landing_once() -> void:
	if impact_emitted: return
	impact_emitted = true; event_id += 1; damaged_event_ids.clear()
	var profile := {"horizontal": 220.0, "upward": 230.0, "lock": 0.18, "direction": _player_direction()}
	_apply_attack_damage(Rect2(global_position + Vector2(-100.0, -50.0), Vector2(200.0, 50.0)), event_id, profile)
	_spawn_fx("landing_impact_%d" % event_id, "impact", global_position, 0.25)
	_spawn_fx("landing_dust_%d" % event_id, "dust", global_position, 0.40)
	_spawn_wave_pair(event_id, 300.0, 36.0, {"horizontal": 130.0, "upward": 100.0, "lock": 0.10})

func _emit_backhand_once() -> void:
	impact_emitted = true; event_id += 1; damaged_event_ids.clear()
	var local_x := 48.0 if facing > 0 else -143.0
	_spawn_fx("backhand_arc_%d" % event_id, "arc", global_position + Vector2(float(facing) * 52.0, -42.0), 0.20)
	_apply_attack_damage(Rect2(global_position + Vector2(local_x, -72.0), Vector2(95.0, 72.0)), event_id, {"horizontal": 240.0, "upward": 130.0, "lock": 0.16, "direction": facing})

func _emit_rush_once() -> void:
	impact_emitted = true; event_id += 1; damaged_event_ids.clear()
	_spawn_fx("rush_streak_%d" % event_id, "trail", global_position, 0.25)
	_apply_attack_damage(Rect2(global_position + Vector2(20.0 if facing > 0 else -116.0, -70.0), Vector2(96.0, 70.0)), event_id, {"horizontal": 280.0, "upward": 120.0, "lock": 0.18, "direction": facing})

func _player_direction() -> int:
	if absf(player.global_position.x - global_position.x) < 0.1:
		return facing
	return 1 if player.global_position.x > global_position.x else -1

func _apply_attack_damage(hitbox: Rect2, damage_event: int, profile: Dictionary) -> void:
	if not is_instance_valid(player) or damaged_event_ids.has(damage_event): return
	if hitbox.intersects(Rect2(player.global_position - Vector2(14.0, 23.0), Vector2(28.0, 46.0))):
		var health_before: float = player.health
		player.take_damage(1.0, global_position.x, true, profile)
		if player.health < health_before:
			damaged_event_ids[damage_event] = true
			_spawn_fx("hurt_%d" % damage_event, "sparks", player.global_position + Vector2(0.0, -24.0), 0.20)

func apply_wave_damage(damage_event: int, wave_position: float, profile: Dictionary) -> void:
	if damaged_event_ids.has(damage_event): return
	var wave_profile := profile.duplicate()
	wave_profile["direction"] = 1 if wave_position > global_position.x else -1
	_apply_attack_damage(Rect2(Vector2(wave_position - 14.0, global_position.y - 48.0), Vector2(28.0, 48.0)), damage_event, wave_profile)

func _spawn_wave_pair(damage_event: int, wave_speed: float, crest_height: float, profile: Dictionary) -> void:
	for direction in [-1, 1]:
		var wave := SHOCKWAVE_SCRIPT.new()
		wave.direction = direction; wave.target = player; wave.owner_boss = self; wave.damage_event = damage_event
		wave.speed = wave_speed; wave.crest_height = crest_height; wave.impact_profile = profile; wave.global_position = global_position + Vector2(direction * 114.0, 0.0)
		wave.arena_left = arena_left; wave.arena_right = arena_right; get_parent().add_child(wave)

func combat_bounds() -> Rect2: return Rect2(global_position - Vector2(66.0, 132.0), Vector2(132.0, 108.0))

func take_hit(amount: float = 1.0) -> void:
	if not active or health <= 0.0 or invulnerability > 0.0: return
	health = maxf(0.0, health - amount); hurt_flash = 0.16; invulnerability = 0.12
	hurt_restore_pose = current_pose
	hurt_override_time = 0.14
	_spawn_fx("boss_hurt_%d" % event_id, "sparks", global_position + Vector2(0.0, -80.0), 0.20)
	if health <= 0.0:
		active = false; state = "defeated"; velocity = Vector2.ZERO; _clear_shockwaves(); _clear_owned_fx()
		_spawn_fx("defeat_smoke", "smoke", global_position + Vector2(0.0, -50.0), 1.0)
		_spawn_fx("defeat_sparks", "sparks", global_position + Vector2(0.0, -80.0), 0.45)
		defeated.emit()

func force_attack(name: String) -> void:
	_clear_shockwaves(); state = "idle"; state_time = 0.0
	if name == "barrage" and not phase_two: phase_two = true
	_begin_attack(name)

func debug_walk(direction: int) -> void:
	_clear_shockwaves()
	state = "idle"
	state_time = 3.0
	walk_debug_direction = clampi(direction, -1, 1)
	walk_debug_time = 2.5
	facing = walk_debug_direction if walk_debug_direction != 0 else facing

func begin_attack(name: String = "smash") -> void:
	if name == "seismic_smash":
		name = "smash"
	force_attack(name)

func reset_encounter() -> void:
	_clear_shockwaves(); _clear_owned_fx(); health = max_health; active = true; state = "idle"; state_time = 0.75; attack_name = ""
	phase_two = false; phase_change_seen = false; phase_change_pending = false; attack_count = 0; position.y = home_y; velocity = Vector2.ZERO
	_reset_policy(); _set_pose("idle")

func _reset_policy() -> void:
	cooldowns.clear(); history.clear(); next_decision_at = 0.0; elapsed = 0.0; event_id = 0; damaged_event_ids.clear(); rng.seed = random_seed

func _clear_shockwaves() -> void:
	for wave in get_tree().get_nodes_in_group("ironback_v2_waves"): wave.queue_free()

func _set_pose(pose: String) -> void:
	if current_pose == pose and sprite.texture != null: return
	current_pose = pose; pose_clock = 0.0; pose_index = 0
	var frame_values: Array = SPRITES.get(pose, SPRITES["idle"])
	pose_frames.clear()
	for frame_value in frame_values:
		pose_frames.append(str(frame_value))
	sprite.texture = load(SPRITE_ROOT + pose_frames[0]); sprite.flip_h = facing < 0

func _update_sprite() -> void:
	if hurt_override_time > 0.0:
		if current_pose != "hurt": _set_pose("hurt")
		return
	var pose := "walk" if state == "idle" and absf(velocity.x) > 8.0 else "idle"
	match state:
		"smash_tell", "barrage_tell": pose = "smash_tell"
		"smash_down", "barrage_down": pose = "smash_down"
		"smash_impact", "barrage_impact": pose = "smash_impact"
		"smash_recovery", "barrage_reset": pose = "smash_recovery"
		"leap_crouch": pose = "leap_crouch"
		"leap_air": pose = "leap_air"
		"leap_impact": pose = "leap_impact"
		"leap_recovery": pose = "leap_recovery"
		"backhand_tell": pose = "backhand_tell"
		"backhand_active": pose = "backhand_active"
		"backhand_recovery": pose = "backhand_recovery"
		"rush_tell": pose = "rush_tell"
		"rush_active": pose = "rush_active"
		"rush_brake": pose = "rush_brake"
		"phase_change": pose = "phase_change"
		"defeated": pose = "defeat"
	if current_pose != pose: _set_pose(pose)
	if pose_frames.size() > 1:
		var frame_duration := 0.2 if pose in ["idle", "walk"] else 0.12
		if pose_clock >= frame_duration:
			pose_clock = 0.0
			pose_index += 1
			if pose_index >= pose_frames.size():
				pose_index = 0 if pose in ["idle", "walk"] else pose_frames.size() - 1
			sprite.texture = load(SPRITE_ROOT + pose_frames[pose_index])
	if sprite != null: sprite.flip_h = facing < 0