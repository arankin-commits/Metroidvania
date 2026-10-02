extends CharacterBody2D

# Navigation reads this shared Inheritance-owned state; it never grants abilities.
var inheritance = preload("res://scripts/inheritance_state.gd").new()

signal attacked(hitbox: Rect2)
signal heavy_attacked(hitbox: Rect2)
signal heavy_smashed(hitbox: Rect2)
signal bow_fired(origin: Vector2, direction: Vector2)
signal dodged
signal healed
signal damaged
signal died
signal ledge_climbed
signal platform_dropped
signal jumped
signal wake_finished

const SPEED := 255.0
const WALK_SPEED := SPEED * 0.5
const HEAVY_CHARGE_SPEED_MULTIPLIER := 0.5
const GRAVITY := 1250.0
const JUMP_SPEED := -500.0
const MIN_JUMP_SPEED := -320.0
const DASH_SPEED := 780.0
const PRESENTATION = preload("res://scripts/player_presentation.gd")
const FOOTSTEP = preload("res://assets/footstep.wav")

var visual_time := 0.0
var visual_state := ""
var visual_state_time := 0.0
var weapon_visible_time := 0.0

var health := 5.0
var max_health := 5.0
var base_max_health := 5.0
var injured_max_health := 2.5
var is_injured := false
var healing_charges := 3
var max_healing_charges := 3
var _heal_was_down := false
var heal_time := 0.0
const HEAL_DURATION := 0.65
var has_dash := false
var has_air_dash := false
var has_scimitar:=false
var has_gauntlet:=false
var has_heavy_smash := false
const GAUNTLET_CHARGES_MAX := 12
var gauntlet_charges := 12
var has_wrath:=false
var equipped_weapon:="starter"

func _init() -> void:
	collision_layer = 1
	collision_mask = 3
var wrath_time:=0.0
const WRATH_DURATION:=4.0
const WRATH_MULTIPLIER:=1.25
const FRIENDLY_PROJECTILE=preload("res://scripts/combat_projectile.gd")
var ability_charge:=0.0
var ability_cooldown:=0.0
var _ability_was_down:=false
var volley_time:=0.0
var volley_start:=Vector2.ZERO
var volley_shots:=0
var beam_remaining:=0
var beam_interval:=0.0
var has_heavy := false
var has_bow := false
var bow_ammo := 0
const BOW_AMMO_MAX := 3
var heavy_charge := 0.0
var heavy_ready_time := 0.0
var heavy_attack_time := 0.0
var heavy_cooldown := 0.0
var _heavy_was_down := false
var facing := 1
var controls_enabled := true
var invulnerability := 0.0
var combat_hitstun := 0.0
var combat_impact_velocity := Vector2.ZERO
var attack_time := 0.0
var attack_style:="swing"
var sword_combo_step := -1
var sword_combo_window := 0.0
var sword_combo_weapon := ""
var sword_hit_delay := -1.0
var attack_cooldown := 0.0
var _dash_collision_exceptions: Array = []

func _apply_dash_collision_exceptions() -> void:
	collision_layer = 0
	collision_mask = 1
	_dash_collision_exceptions.clear()
	if is_inside_tree():
		for group_name in ["combat_targets", "enemies", "bosses"]:
			for target in get_tree().get_nodes_in_group(group_name):
				if is_instance_valid(target) and target != self and not _dash_collision_exceptions.has(target):
					if target is CollisionObject2D:
						add_collision_exception_with(target)
						target.add_collision_exception_with(self)
						_dash_collision_exceptions.append(target)
					elif target.has_node("Collision"):
						var col = target.get_node("Collision")
						if col is CollisionObject2D:
							add_collision_exception_with(col)
							col.add_collision_exception_with(self)
							_dash_collision_exceptions.append(col)

func _clear_dash_collision_exceptions() -> void:
	collision_layer = 1
	collision_mask = 3
	for target in _dash_collision_exceptions:
		if is_instance_valid(target):
			remove_collision_exception_with(target)
			if target is CollisionObject2D:
				target.remove_collision_exception_with(self)
	_dash_collision_exceptions.clear()

var dash_time := 0.0:
	set(value):
		var was_dashing := dash_time > 0.0
		dash_time = maxf(0.0, value)
		var is_now_dashing := dash_time > 0.0
		if is_now_dashing != was_dashing:
			if is_now_dashing:
				_apply_dash_collision_exceptions()
			else:
				_clear_dash_collision_exceptions()

var dash_cooldown := 0.0
var dash_speed_current := 0.0
var coyote_time := 0.0
var jump_buffer := 0.0
var is_jumping := false
var jump_hold_timer := 0.0
const TAP_JUMP_SPEED := -353.55
const JUMP_HOLD_ACCEL := 763.5
const MAX_JUMP_HOLD_TIME := 0.25
const MAX_HOLD_TIME := 0.5
const MAX_DASH_HOLD_TIME := 0.5
const TAP_DASH_DURATION := 0.0625
const TAP_DASH_SPEED := 670.0
const DASH_DECEL := 2625.0
const DASH_HOLD_ACCEL := 552075.0 / 406.0 # Yields exactly 160.0 px hold dash at 0.5s hold time
var is_dashing := false
var is_ground_dash := false
var is_dash_holding := false
var dash_just_triggered := false
var dash_hold_timer := 0.0
var dash_tap_duration := 0.0
var dash_tap_distance := 0.0
var dash_y := 0.0
var dash_z := 0.0
var dash_start_x := 0.0
var recorded_dash_distance := 0.0
var is_crouching := false
var crouch_time := 0.0
var _jump_was_down := false
var _attack_was_down := false
var _dash_was_down := false
var _bow_was_down := false
var footstep_audio: AudioStreamPlayer2D
var footstep_timer := 0.0
var footstep_count := 0
var ledge_grabbed := false
var ledge_climb_time := 0.0
var ledge_climb_from := Vector2.ZERO
var ledge_climb_to := Vector2.ZERO
var ledge_top := Vector2.ZERO
var drop_platform: StaticBody2D
var drop_region := Rect2()
var drop_depth := 32.0
var drop_ignore_timer := 0.0
var drop_exception_active := false
var meditation_state := ""
var meditation_time := 0.0
var meditation_duration := 0.0
var meditation_from := Vector2.ZERO
var meditation_to := Vector2.ZERO
var meditation_chair := Vector2.ZERO
const DEATH_DURATION := 0.85
var death_active := false
var death_time := 0.0
const WAKE_DURATION := 4.0
var waking_up := false
var wake_elapsed := 0.0

func begin_waking_up() -> void:
	reset_movement_state()
	waking_up=true
	wake_elapsed=0.0
	controls_enabled=false
	facing=1

func _advance_wake(delta: float) -> void:
	wake_elapsed=minf(WAKE_DURATION,wake_elapsed+delta)
	velocity=Vector2.ZERO
	if wake_elapsed>=WAKE_DURATION-.000001:
		waking_up=false
		controls_enabled=true
		visual_state=""
		visual_state_time=0.0
		wake_finished.emit()
	queue_redraw()

func _ready() -> void:
	collision_layer = 1
	collision_mask = 3
	z_index = 3
	add_to_group("mcp_watch")
	var charge_material := ShaderMaterial.new()
	charge_material.shader = PRESENTATION.CHARGE_FLASH
	material = charge_material
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28, 46)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2(0, -100)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.limit_left = -1200
	camera.limit_right = 4450
	camera.limit_top = -60
	camera.limit_bottom = 720
	add_child(camera)
	camera.make_current()
	footstep_audio = AudioStreamPlayer2D.new()
	footstep_audio.stream = FOOTSTEP
	footstep_audio.volume_db = -10.0
	add_child(footstep_audio)

func load_combat_progress(data: Dictionary) -> void:
	if data.has("has_dash"):
		has_dash=bool(data.get("has_dash",false))
	has_air_dash=bool(data.get("has_air_dash", data.get("bow_boss_defeated", false)))
	has_scimitar=bool(data.get("boss_defeated",false))
	has_gauntlet=bool(data.get("temple_guardian_defeated",false))
	has_heavy_smash=bool(data.get("has_heavy_smash", data.get("ironback_boss_defeated", false)))
	if data.has("gauntlet_charges"):
		gauntlet_charges = clampi(int(data.get("gauntlet_charges", GAUNTLET_CHARGES_MAX)), 0, GAUNTLET_CHARGES_MAX)
	else:
		gauntlet_charges = GAUNTLET_CHARGES_MAX
	has_wrath=has_scimitar
	equipped_weapon=str(data.get("equipped_weapon","scimitar" if has_scimitar else "starter"))
	if (equipped_weapon=="bow" and not has_bow) or (equipped_weapon=="gauntlet" and not has_gauntlet) or (equipped_weapon=="scimitar" and not has_scimitar):
		equipped_weapon="scimitar" if has_scimitar else "starter"

func combat_save_data() -> Dictionary:
	return {"has_scimitar":has_scimitar,"has_gauntlet":has_gauntlet,"has_heavy_smash":has_heavy_smash,"has_wrath":has_wrath,"equipped_weapon":equipped_weapon,"has_dash":has_dash,"has_air_dash":has_air_dash,"gauntlet_charges":gauntlet_charges}

func damage_multiplier() -> float:
	return WRATH_MULTIPLIER if has_wrath and wrath_time>0 else 1.0

func current_posture_damage(is_heavy: bool = false) -> float:
	var base_dmg := 1.5 * damage_multiplier() if is_heavy else 1.0 * damage_multiplier()
	var p_mult := 1.0
	if is_heavy:
		p_mult *= 2.0
	elif sword_combo_step == 2:
		p_mult *= 1.5
	if not is_on_floor():
		p_mult *= 0.5
	return base_dmg * p_mult

func _normal_attack() -> void:
	attack_style="punch" if equipped_weapon=="gauntlet" else "bow" if equipped_weapon=="bow" else "swing"
	if attack_style == "swing":
		if sword_combo_window <= 0.0 or sword_combo_weapon != equipped_weapon:
			sword_combo_step = 0
		else:
			sword_combo_step = (sword_combo_step + 1) % 3
		sword_combo_weapon = equipped_weapon
		sword_combo_window = 0.8
		# Contact belongs to the active sword frame, after the supplied windup.
		sword_hit_delay = 0.075 if sword_combo_step == 1 else 0.15
	else:
		_reset_sword_combo()
	attack_time=.3 if attack_style == "swing" else .17
	attack_cooldown=.3
	if equipped_weapon=="bow" and has_bow:
		if bow_ammo>0:
			bow_ammo-=1
			bow_fired.emit(global_position+Vector2(facing*18,-8),Vector2(facing,0))
		return
	if attack_style != "swing":
		attacked.emit(Rect2(global_position+Vector2(10 if facing>0 else -82,-28),Vector2(72,56)))

func _reset_sword_combo() -> void:
	sword_combo_step = -1
	sword_combo_window = 0.0
	sword_combo_weapon = ""
	sword_hit_delay = -1.0

func _tick_weapon_ability(delta: float) -> void:
	var down:=controls_enabled and not ledge_grabbed and heal_time<=0 and Input.is_physical_key_pressed(KEY_U)
	if equipped_weapon=="gauntlet" and has_gauntlet:
		if down and ability_cooldown<=0:
			if gauntlet_charges > 0:
				ability_charge = minf(1.0, ability_charge + delta / 1.6)
			else:
				ability_charge = 0.0
		elif _ability_was_down and ability_cooldown<=0:
			if ability_charge>=1.0 and gauntlet_charges > 0:
				gauntlet_charges -= 1
				beam_remaining=4
				beam_interval=0.0
				ability_cooldown=.85
			ability_charge=0.0
	elif down and not _ability_was_down and ability_cooldown<=0:
		if equipped_weapon=="scimitar" and has_scimitar:
			attack_style="thrust"
			attack_time=.22
			ability_cooldown=.75
			attacked.emit(Rect2(global_position+Vector2(10 if facing>0 else -140,-18),Vector2(130,28)))
		elif equipped_weapon=="bow" and has_bow and bow_ammo>0:
			bow_ammo-=1
			volley_start=global_position
			volley_time=.65
			volley_shots=0
			ability_cooldown=1.8
	_ability_was_down=down

func _friendly_shot(kind: String,direction: Vector2,amount: float,down:=false) -> void:
	var shot: Node2D = FRIENDLY_PROJECTILE.acquire()
	shot.kind=kind
	shot.friendly=true
	shot.damage=amount*damage_multiplier()
	shot.radius=13 if kind=="beam" else 6
	shot.direction=direction
	shot.global_position=global_position+Vector2(facing*18,-8)
	if down:
		shot.homing_down=true
		shot.forest_magic=true
		shot.hover_time=1.0
		shot.lifetime+=shot.hover_time
		shot.direction=Vector2.DOWN
		var nearest:=INF
		for candidate in get_tree().get_nodes_in_group("combat_targets"):
			if candidate.get("health")!=null and candidate.health<=0: continue
			if candidate.get("active")!=null and not candidate.active: continue
			var distance:=global_position.distance_to(candidate.global_position)
			if distance<nearest:
				nearest=distance
				shot.target=candidate
	get_parent().add_child(shot)

func _physics_process(delta: float) -> void:
	if waking_up:
		_advance_wake(delta)
		return
	visual_time += delta
	PRESENTATION.advance(self, delta)
	sword_combo_window = maxf(0.0, sword_combo_window - delta)
	if sword_combo_window <= 0.0 or sword_combo_weapon != equipped_weapon:
		_reset_sword_combo()
	weapon_visible_time = maxf(0.0, weapon_visible_time - delta)
	if attack_time > 0 or heavy_charge > 0 or heavy_attack_time > 0:
		weapon_visible_time = 3.0
	if heavy_charge > 0 or heavy_attack_time > 0 or (attack_time > 0 and attack_style != "swing"):
		_reset_sword_combo()
	if death_active:
		death_time = maxf(0.0, death_time - delta)
		velocity = Vector2.ZERO
		queue_redraw()
		return
	if sword_hit_delay >= 0.0:
		sword_hit_delay -= delta
		if sword_hit_delay <= 0.00001:
			sword_hit_delay = -1.0
			attacked.emit(Rect2(global_position+Vector2(10 if facing>0 else -82,-28),Vector2(72,56)))
	if not meditation_state.is_empty():
		_advance_meditation(delta)
		return
	if drop_ignore_timer > 0.0:
		drop_ignore_timer = maxf(0.0, drop_ignore_timer - delta)
	# A closed cave can catch a drop before the whole body clears the shelf.
	# Use actual shelf depth. Landing wholly below can release early; side/upper
	# separation waits for the timer so switchbacks cannot reattach prematurely.
	var drop_bounds := Rect2(drop_region.position+Vector2(0,8),Vector2(drop_region.size.x,drop_depth))
	var body_bounds := Rect2(global_position-Vector2(14,23),Vector2(28,46))
	if drop_exception_active and (drop_ignore_timer <= 0.0 or (is_on_floor() and body_bounds.position.y>=drop_bounds.end.y)) and not body_bounds.intersects(drop_bounds) and is_instance_valid(drop_platform):
		remove_collision_exception_with(drop_platform)
		floor_block_on_wall = true
		drop_exception_active = false
	if ledge_climb_time > 0.0:
		ledge_climb_time = maxf(0.0, ledge_climb_time - delta)
		var climb_progress := 1.0 - ledge_climb_time / 0.32
		var rise := minf(1.0, climb_progress * 1.55)
		var cross := maxf(0.0, (climb_progress - 0.45) / 0.55)
		global_position = Vector2(lerpf(ledge_climb_from.x, ledge_climb_to.x, cross), lerpf(ledge_climb_from.y, ledge_climb_to.y, rise))
		velocity = Vector2.ZERO
		if ledge_climb_time <= 0.0:
			ledge_climbed.emit()
		queue_redraw()
		return
	invulnerability = maxf(0.0, invulnerability - delta)
	if combat_hitstun > 0.0:
		combat_hitstun = maxf(0.0, combat_hitstun - delta)
		velocity.y += GRAVITY * delta
		move_and_slide()
		queue_redraw()
		return
	attack_time = maxf(0.0, attack_time - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	heavy_attack_time = maxf(0.0, heavy_attack_time - delta)
	heavy_cooldown = maxf(0.0, heavy_cooldown - delta)
	wrath_time=maxf(0,wrath_time-delta)
	ability_cooldown=maxf(0,ability_cooldown-delta)
	if controls_enabled:
		if Input.is_physical_key_pressed(KEY_1) and has_scimitar: equipped_weapon="scimitar"
		if Input.is_physical_key_pressed(KEY_2) and has_bow: equipped_weapon="bow"
		if Input.is_physical_key_pressed(KEY_3) and has_gauntlet: equipped_weapon="gauntlet"
	_tick_weapon_ability(delta)
	if beam_remaining>0:
		beam_interval-=delta
		if beam_interval<=0:
			_friendly_shot("beam",Vector2(facing,0),2.0)
			beam_remaining-=1
			beam_interval=.14
	if volley_time>0:
		volley_time=maxf(0,volley_time-delta)
		var t:=1-volley_time/.65
		var destination:=volley_start+Vector2(facing*150,0)
		var next:=volley_start.lerp(destination,t)-Vector2(0,sin(t*PI)*80)
		move_and_collide(next-global_position)
		velocity=Vector2.ZERO
		if volley_shots<3 and t>=.25+volley_shots*.18:
			_friendly_shot("arrow",Vector2(facing*.5,1).normalized(),1.0,true)
			volley_shots+=1
		queue_redraw()
		return
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	if is_on_floor():
		coyote_time = 0.10
	else:
		coyote_time = maxf(0.0, coyote_time - delta)
	var jump_down := controls_enabled and (Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	var attack_down := controls_enabled and (Input.is_physical_key_pressed(KEY_J) or Input.is_physical_key_pressed(KEY_X))
	var dash_down := controls_enabled and (Input.is_physical_key_pressed(KEY_K) or Input.is_physical_key_pressed(KEY_SHIFT))
	var heavy_down := controls_enabled and has_heavy and Input.is_physical_key_pressed(KEY_H)
	var bow_down := controls_enabled and has_bow and Input.is_physical_key_pressed(KEY_L)
	var heal_down := controls_enabled and Input.is_physical_key_pressed(KEY_F)
	if bow_down and not _bow_was_down:
		if bow_ammo > 0:
			bow_ammo -= 1
			bow_fired.emit(global_position + Vector2(18.0 * facing, -8.0), Vector2(facing, 0.0))
	if heal_time > 0.0:
		if controls_enabled and ((jump_down and not _jump_was_down) or (dash_down and not _dash_was_down and dash_cooldown <= 0.0)):
			heal_time = 0.0
		else:
			heal_time = maxf(0.0, heal_time - delta)
			velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
			velocity.y += GRAVITY * delta
			move_and_slide()
			if heal_time <= 0.0:
				healing_charges -= 1
				health = minf(max_health, health + 2)
				healed.emit()
			_heal_was_down = heal_down
			_jump_was_down = jump_down
			_attack_was_down = attack_down
			_dash_was_down = dash_down
			queue_redraw()
			return
	if ledge_grabbed:
		velocity = Vector2.ZERO
		if controls_enabled and attack_down and not _attack_was_down and attack_cooldown <= 0.0:
			_normal_attack()
		var forward_down := controls_enabled and ((facing > 0 and (Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))) or (facing < 0 and (Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))))
		if (jump_down and not _jump_was_down) or forward_down:
			ledge_grabbed = false
			ledge_climb_from = global_position
			ledge_climb_to = ledge_top
			ledge_climb_time = 0.32
		_jump_was_down = jump_down
		_attack_was_down = attack_down
		queue_redraw()
		return
	var drop_down := controls_enabled and jump_down and not _jump_was_down and (Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))
	var dropping := false
	var on_drop_surface := drop_region.has_point(global_position + Vector2(0, 23)) and absf(global_position.y + 23.0 - drop_region.position.y) <= 9.0
	if drop_down and on_drop_surface and is_instance_valid(drop_platform):
		add_collision_exception_with(drop_platform)
		drop_exception_active = true
		drop_ignore_timer = 0.40
		floor_block_on_wall = false
		global_position.y += 1.0
		velocity.y = maxf(0.0, velocity.y)
		jump_buffer = 0.0
		dropping = true
		platform_dropped.emit()
	if heal_down and not _heal_was_down and health > 0 and healing_charges > 0:
		heal_time = HEAL_DURATION
		invulnerability = 0.0
		velocity.x = 0.0
		queue_redraw()
	_heal_was_down = heal_down
	if jump_down and not _jump_was_down and not dropping:
		jump_buffer = 0.13
	else:
		jump_buffer = maxf(0.0, jump_buffer - delta)
	if controls_enabled and attack_down and not _attack_was_down and attack_cooldown <= 0.0:
		var is_down_pressed := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
		if has_heavy_smash and is_down_pressed and not is_on_floor():
			velocity.y = 850.0
			velocity.x = 0.0
			attack_time = 0.35
			attack_cooldown = 0.45
			var smash_box := Rect2(global_position.x - 70, global_position.y - 10, 140, 70)
			heavy_smashed.emit(smash_box)
		else:
			_normal_attack()
	if controls_enabled and dash_down and not _dash_was_down and dash_cooldown <= 0.0:
		dash_hold_timer = 0.0
		dash_z = 0.0
		dash_start_x = global_position.x
		recorded_dash_distance = 0.0
		if is_on_floor():
			if not has_dash:
				is_ground_dash = false
				is_dash_holding = false
				is_dashing = false
				dash_speed_current = 225.0
				dash_time = 0.17
				velocity = Vector2(facing * 225.0, 0)
				dash_cooldown = 0.75
				invulnerability = maxf(invulnerability, 0.30)
				dodged.emit()
			else:
				is_ground_dash = true
				is_dash_holding = true
				is_dashing = true
				dash_just_triggered = true
				dash_speed_current = TAP_DASH_SPEED
				velocity.x = facing * TAP_DASH_SPEED
				velocity.y = 0.0
				dash_time = 0.75
				dash_cooldown = 0.65
				invulnerability = maxf(invulnerability, 0.35)
				dodged.emit()
		elif inheritance.has_ability("air_dash"):
			is_ground_dash = false
			is_dash_holding = false
			is_dashing = true
			dash_speed_current = 780.0
			velocity = Vector2(facing * 780.0, 0)
			dash_time = 0.23
			dash_cooldown = 0.65
			invulnerability = maxf(invulnerability, 0.25)
			dodged.emit()
	if heavy_down and heavy_cooldown <= 0.0:
		var was_ready := heavy_charge >= 1.0
		heavy_charge = minf(1.0, heavy_charge + delta / 0.8)
		heavy_ready_time = heavy_ready_time + delta if was_ready else 0.0
	elif _heavy_was_down:
		if heavy_charge >= 1.0 and controls_enabled:
			heavy_attack_time = 0.25
			heavy_cooldown = 0.65
			var heavy_box := Rect2(global_position + Vector2(10 if facing > 0 else -106, -40), Vector2(96, 80))
			heavy_attacked.emit(heavy_box)
			var is_down_pressed := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
			if has_heavy_smash and is_down_pressed:
				var smash_box := Rect2(global_position.x - 70, global_position.y - 20, 140, 80)
				heavy_smashed.emit(smash_box)
		heavy_charge = 0.0
		heavy_ready_time = 0.0
	_dash_was_down = dash_down
	_bow_was_down = bow_down
	_heavy_was_down = heavy_down
	_attack_was_down = attack_down
	_jump_was_down = jump_down
	var was_dashing_start := dash_time > 0.0
	if dash_time > 0.0:
		if is_ground_dash:
			velocity.y = 0.0
			velocity.x = move_toward(velocity.x, 0.0, DASH_DECEL * delta)
			if is_dash_holding:
				if not dash_down or dash_hold_timer >= MAX_DASH_HOLD_TIME or absf(velocity.x) <= 0.0:
					is_dash_holding = false
				elif not dash_just_triggered:
					dash_hold_timer += delta
					dash_z = dash_hold_timer
					velocity.x += facing * DASH_HOLD_ACCEL * delta
			dash_just_triggered = false
			if absf(velocity.x) <= 0.0:
				dash_time = 0.0
				velocity.x = 0.0
				is_ground_dash = false
				is_dash_holding = false
				is_dashing = false
			else:
				dash_time = maxf(0.05, dash_time - delta)
		else:
			dash_time -= delta
			velocity = Vector2(facing * dash_speed_current, 0)
			if dash_time <= 0.0:
				velocity.x = 0.0
				is_dashing = false
		invulnerability = maxf(invulnerability, 0.25)
	else:
		var crouch_down := controls_enabled and is_on_floor() and (Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) and not drop_down and attack_time <= 0.0 and heavy_attack_time <= 0.0 and heal_time <= 0.0 and not waking_up and not death_active and meditation_state.is_empty()
		if crouch_down:
			is_crouching = true
			crouch_time += delta
			velocity.x = 0.0
		else:
			is_crouching = false
			crouch_time = 0.0
		var direction := 0.0
		if controls_enabled and not is_crouching:
			direction = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		if direction != 0.0:
			var charging_gauntlet := equipped_weapon == "gauntlet" and ability_charge > 0.0
			if not charging_gauntlet:
				facing = 1 if direction > 0 else -1
		var is_walking := controls_enabled and (is_injured or Input.is_physical_key_pressed(KEY_C) or Input.is_physical_key_pressed(KEY_CTRL) or Input.is_physical_key_pressed(KEY_ALT))
		var target_speed := WALK_SPEED if is_walking else SPEED
		var is_charging := heavy_charge > 0.0 or (equipped_weapon == "gauntlet" and ability_charge > 0.0)
		var movement_speed := target_speed * HEAVY_CHARGE_SPEED_MULTIPLIER if is_charging else target_speed
		velocity.x = move_toward(velocity.x, direction * movement_speed, 1700.0 * delta)
		if is_charging or is_walking:
			velocity.x = clampf(velocity.x, -movement_speed, movement_speed)
		velocity.y += GRAVITY * delta
		if is_jumping:
			if not jump_down or jump_hold_timer >= MAX_JUMP_HOLD_TIME or velocity.y >= 0.0:
				is_jumping = false
			else:
				jump_hold_timer += delta
				velocity.y -= JUMP_HOLD_ACCEL * delta
		if jump_buffer > 0.0 and coyote_time > 0.0:
			velocity.y = TAP_JUMP_SPEED
			is_jumping = true
			jump_hold_timer = 0.0
			jumped.emit()
			jump_buffer = 0.0
			coyote_time = 0.0
	move_and_slide()
	_check_enemy_contact_damage()
	if dash_time > 0.0 or was_dashing_start:
		recorded_dash_distance = absf(global_position.x - dash_start_x)
		if dash_time <= 0.0:
			velocity.x = 0.0
	if is_on_floor() or is_on_ceiling() or ledge_grabbed:
		is_jumping = false
		jump_hold_timer = 0.0
	_try_grab_ledge()
	if controls_enabled and is_on_floor() and absf(velocity.x) > 55.0 and dash_time <= 0.0:
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			footstep_audio.pitch_scale = 0.93 if footstep_count % 2 == 0 else 1.05
			footstep_audio.play()
			footstep_count += 1
			footstep_timer = 0.32
	else:
		footstep_timer = 0.0
	queue_redraw()

func _try_grab_ledge() -> void:
	if ledge_grabbed or ledge_climb_time > 0.0 or drop_exception_active or is_on_floor() or not is_on_wall() or not controls_enabled:
		return
	var wall_normal := get_wall_normal()
	if absf(wall_normal.x) < 0.8 or int(signf(-wall_normal.x)) != facing:
		return
	var head_y := global_position.y - 23.0
	var probe_x := global_position.x + facing * 22.0
	var query := PhysicsRayQueryParameters2D.create(Vector2(probe_x, head_y - 22.0), Vector2(probe_x, head_y + 20.0))
	query.exclude = [get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or not hit.collider is StaticBody2D:
		return
	var wall_is_terrain := false
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		if collision.get_collider() == hit.collider and absf(collision.get_normal().x) >= 0.8:
			wall_is_terrain = true
			break
	if not wall_is_terrain:
		return
	var top_y: float = hit.position.y
	if absf(top_y - head_y) > 18.0 or global_position.y <= top_y + 4.0:
		return
	var landing_position := Vector2(global_position.x + facing * 34.0, top_y - 23.0)
	var clearance_shape := RectangleShape2D.new()
	clearance_shape.size = Vector2(26, 44)
	var clearance := PhysicsShapeQueryParameters2D.new()
	clearance.shape = clearance_shape
	clearance.transform = Transform2D(0.0, landing_position + Vector2(0, -1))
	clearance.exclude = [get_rid()]
	if not get_world_2d().direct_space_state.intersect_shape(clearance, 4).is_empty():
		return
	ledge_grabbed = true
	ledge_top = landing_position
	dash_time = 0.0
	velocity = Vector2.ZERO
	queue_redraw()

func combat_bounds() -> Rect2:
	if is_crouching:
		return Rect2(global_position + Vector2(-14.0, 3.0), Vector2(28.0, 20.0))
	return Rect2(global_position - Vector2(14, 23), Vector2(28, 46))

func _check_enemy_contact_damage() -> void:
	if waking_up or invulnerability > 0.0 or health <= 0 or dash_time > 0.0 or is_dashing or death_active or not controls_enabled:
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if is_instance_valid(collider) and (collider.is_in_group("enemies") or collider.is_in_group("combat_targets") or collider.is_in_group("bosses")):
			if not collider.is_visible_in_tree():
				continue
			if collider.get("active") != null and not collider.active:
				continue
			var collider_def = collider.get("defeated")
			if (typeof(collider_def) == TYPE_BOOL and collider_def == true) or collider.get("is_dead") == true or str(collider.get("state")) == "defeated":
				continue
			if collider.get("health") != null and collider.health <= 0:
				continue
			take_damage(1.0, collider.global_position.x, false)
			return
	var player_box := combat_bounds()
	var candidates: Array = []
	if is_inside_tree():
		for group_name in ["combat_targets", "enemies", "bosses"]:
			for node in get_tree().get_nodes_in_group(group_name):
				if is_instance_valid(node) and node != self and not candidates.has(node):
					candidates.append(node)
	for enemy in candidates:
		if not is_instance_valid(enemy):
			continue
		if not enemy.is_visible_in_tree():
			continue
		if enemy.get("active") != null and not enemy.active:
			continue
		var enemy_def = enemy.get("defeated")
		if (typeof(enemy_def) == TYPE_BOOL and enemy_def == true) or enemy.get("is_dead") == true or str(enemy.get("state")) == "defeated":
			continue
		if enemy.get("health") != null and enemy.health <= 0:
			continue
		var enemy_bounds: Rect2
		if enemy.has_method("combat_bounds"):
			enemy_bounds = enemy.combat_bounds()
		elif enemy is CollisionObject2D:
			var col = enemy.get_node_or_null("Collision")
			if col != null and col is CollisionShape2D and col.shape is RectangleShape2D:
				enemy_bounds = Rect2(col.global_position - col.shape.size / 2.0, col.shape.size)
			else:
				enemy_bounds = Rect2(enemy.global_position - Vector2(16, 20), Vector2(32, 40))
		else:
			continue
		if enemy_bounds.intersects(player_box):
			take_damage(1.0, enemy.global_position.x, false)
			break

func take_arrow_chain_damage(amount: float, from_x: float) -> void:
	var before:=health
	take_damage(amount,from_x,true)
	if health<before:
		# Rapid-fire and hostile Flipping Volley sequence
		invulnerability=0.0
		velocity=Vector2.ZERO

func take_damage(amount: float, from_x: float, is_attack: bool = false, impact_profile: Dictionary = {}) -> void:
	if heal_time > 0.0 and amount > 0:
		heal_time = 0.0
		queue_redraw()
	if waking_up or invulnerability > 0.0 or health <= 0 or amount <= 0 or dash_time > 0.0 or is_dashing:
		return
	health -= amount
	_reset_sword_combo()
	if has_wrath: wrath_time=WRATH_DURATION
	volley_time=0
	beam_remaining=0
	ability_charge=0
	heal_time = 0.0
	ledge_grabbed = false
	ledge_climb_time = 0.0
	damaged.emit()
	if is_attack:
		invulnerability = 0.0
		if impact_profile.is_empty():
			velocity = Vector2.ZERO
		else:
			_apply_combat_impact(impact_profile, from_x)
	else:
		invulnerability = 0.8
		velocity = Vector2(260.0 if global_position.x > from_x else -260.0, -260.0)
	if health <= 0:
		died.emit()
	queue_redraw()

func _apply_combat_impact(impact_profile: Dictionary, from_x: float) -> void:
	var direction := int(impact_profile.get("direction", 0))
	if direction == 0:
		direction = 1 if global_position.x >= from_x else -1
	var horizontal := clampf(float(impact_profile.get("horizontal", 0.0)), 0.0, 320.0)
	var upward := clampf(float(impact_profile.get("upward", 0.0)), 0.0, 300.0)
	velocity.x = float(direction) * horizontal
	velocity.y = minf(velocity.y, -upward)
	combat_impact_velocity = velocity
	combat_hitstun = maxf(0.0, float(impact_profile.get("lock", 0.0)))

func set_injured(injured: bool) -> void:
	is_injured = injured
	if is_injured:
		max_health = injured_max_health
		health = minf(health, max_health)
		has_dash = false
	else:
		max_health = base_max_health
		has_dash = true
	queue_redraw()

func heal_full() -> void:
	heal_time = 0.0
	health = max_health
	healing_charges = max_healing_charges
	invulnerability = 0.0
	wrath_time=0
	gauntlet_charges = GAUNTLET_CHARGES_MAX
	queue_redraw()

func reset_movement_state() -> void:
	waking_up=false
	wake_elapsed=0.0
	controls_enabled = true
	_reset_sword_combo()
	heavy_charge = 0.0
	heavy_ready_time = 0.0
	heavy_attack_time = 0.0
	heavy_cooldown = 0.0
	_heavy_was_down = false
	_dash_was_down = false
	_attack_was_down = false
	_jump_was_down = false
	_bow_was_down = false
	_heal_was_down = false
	velocity = Vector2.ZERO
	death_active = false
	death_time = 0.0
	meditation_state = ""
	dash_time = 0.0
	is_dashing = false
	is_ground_dash = false
	is_dash_holding = false
	dash_hold_timer = 0.0
	dash_tap_duration = 0.0
	dash_z = 0.0
	dash_start_x = 0.0
	is_crouching = false
	crouch_time = 0.0
	volley_time=0
	beam_remaining=0
	ability_charge=0
	wrath_time=0
	dash_cooldown = 0.0
	jump_buffer = 0.0
	is_jumping = false
	jump_hold_timer = 0.0
	ledge_grabbed = false
	ledge_climb_time = 0.0
	heal_time = 0.0
	if drop_exception_active and is_instance_valid(drop_platform):
		remove_collision_exception_with(drop_platform)
	drop_exception_active = false
	drop_ignore_timer = 0.0
	floor_block_on_wall = true
	queue_redraw()

func start_death_animation() -> void:
	reset_movement_state()
	controls_enabled = false
	death_active = true
	death_time = DEATH_DURATION
	queue_redraw()

func begin_meditation(chair_position: Vector2) -> void:
	reset_movement_state()
	controls_enabled = false
	meditation_chair = chair_position
	meditation_from = global_position
	meditation_to = chair_position + Vector2(0, -35)
	meditation_duration = 0.36
	meditation_time = meditation_duration
	meditation_state = "enter"
	queue_redraw()

func end_meditation() -> void:
	if meditation_state.is_empty() or meditation_state == "exit":
		return
	meditation_from = global_position
	meditation_to = Vector2(meditation_chair.x + 85.0, 570.0)
	meditation_duration = 0.32
	meditation_time = meditation_duration
	meditation_state = "exit"
	queue_redraw()

func _advance_meditation(delta: float) -> void:
	velocity = Vector2.ZERO
	if meditation_state == "meditate":
		queue_redraw()
		return
	meditation_time = maxf(0.0, meditation_time - delta)
	var progress := 1.0 - meditation_time / meditation_duration
	global_position = meditation_from.lerp(meditation_to, progress) + Vector2(0, -sin(PI * progress) * 20.0)
	if meditation_time <= 0.0:
		if meditation_state == "enter":
			meditation_state = "meditate"
		else:
			meditation_state = ""
			controls_enabled = true
	queue_redraw()

func _draw() -> void:
	material.set_shader_parameter("white_flash", PRESENTATION.charge_flash(self))
	if waking_up:
		PRESENTATION.draw_wake(self)
		return
	if death_active:
		_draw_death_animation()
		return
	var alpha := 0.55 if invulnerability > 0.0 and Engine.get_physics_frames() % 6 < 3 else 1.0
	if not meditation_state.is_empty():
		var pulse := 0.24 + 0.08 * sin(visual_time * 7.2)
		draw_circle(Vector2(0, -4), 30, Color(0.28, 0.95, 0.83, pulse))
		PRESENTATION.draw(self, alpha)
		return
	draw_circle(Vector2(0, -6), 24, Color(0.08, 0.79, 0.82, 0.12 * alpha))
	PRESENTATION.draw(self, alpha)
	if heal_time > 0.0:
		var pulse := 1.0 - heal_time / HEAL_DURATION
		var glow := Color(0.53, 1.0, 0.73, 0.22 + 0.46 * pulse)
		draw_rect(Rect2(-19, -29, 38, 44), glow)
		draw_rect(Rect2(-12, -12, 24, 6), Color(0.71, 1.0, 0.77, alpha))
		draw_rect(Rect2(-3, -21, 6, 24), Color(0.71, 1.0, 0.77, alpha))
		draw_rect(Rect2(-21 - pulse * 8.0, -8, 5, 5), glow)
		draw_rect(Rect2(16 + pulse * 8.0, -17, 5, 5), glow)
	if attack_time > 0.0:
		if attack_style=="thrust":
			draw_line(Vector2(facing*10,-6),Vector2(facing*140,-6),Color("c6f5ff"),3)
		elif attack_style=="punch":
			draw_rect(Rect2(Vector2(15 if facing>0 else -65,-18),Vector2(50,22)),Color("a4c3b9"))
	if ability_charge>0:
		draw_arc(Vector2(0,-7),29,-PI*.5,-PI*.5+TAU*ability_charge,20,Color("ffb773"),4)
	if dash_time > 0.0:
		for i in 3:
			draw_circle(Vector2(-facing * (18 + i * 13), 0), 10 - i * 2, Color(0.13, 0.80, 0.79, 0.25))

func _draw_death_animation() -> void:
	var progress := 1.0 - death_time / DEATH_DURATION
	var collapse := minf(1.0, progress * 2.2)
	var fade := 1.0 - clampf((progress - 0.38) / 0.52, 0.0, 1.0)
	draw_circle(Vector2(0, 2), 22.0 + progress * 20.0, Color(0.20, 0.89, 0.85, 0.24 * fade))
	# The new traveller remains identifiable while folding into the seated pose.
	PRESENTATION.draw(self, fade, 15 if collapse > 0.5 else 0)
	for index in 12:
		var angle := TAU * float(index) / 12.0
		var distance := 8.0 + progress * (18.0 + float(index % 4) * 8.0)
		var fragment := Vector2(cos(angle), sin(angle)) * distance + Vector2(0, -4.0 + progress * 11.0)
		var size := 5.0 if index % 3 == 0 else 3.0
		draw_rect(Rect2(fragment, Vector2(size, size)), Color(0.55, 1.0, 0.88, fade))

func perform_heavy_smash() -> void:
	if not has_heavy_smash:
		return
	heavy_attack_time = 0.3
	heavy_cooldown = 0.65
	var smash_box := Rect2(global_position.x - 70, global_position.y - 20, 140, 80)
	heavy_smashed.emit(smash_box)

func _mcp_state() -> Dictionary:
	return {"health": health, "healing_charges": healing_charges, "has_dash": has_dash, "has_air_dash": has_air_dash, "has_heavy": has_heavy, "has_heavy_smash": has_heavy_smash, "heavy_charge": heavy_charge, "dash_cooldown": dash_cooldown, "on_floor": is_on_floor()}
