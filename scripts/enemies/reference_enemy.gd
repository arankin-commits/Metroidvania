extends CharacterBody2D
## Reference enemy actor used for animations and in-game combat encounters.
signal defeated
signal attack_landed
signal attack_cue(kind: String, origin: Vector2, direction: int)
signal sequence_finished(sequence: StringName)

const LIBRARY = {
	"goblin": preload("res://assets/characters/enemies/goblin.tres"),
	"goblin_dog": preload("res://assets/characters/enemies/goblin_dog.tres"),
	"goblin_sentinel": preload("res://assets/characters/enemies/goblin_sentinel.tres"),
	"kobold_archer": preload("res://assets/characters/enemies/kobold_archer.tres"),
	"kobold_clubber": preload("res://assets/characters/enemies/kobold_clubber.tres"),
	"kobold_summoner": preload("res://assets/characters/enemies/kobold_summoner.tres"),
}
const PROJECTILE = preload("res://scripts/combat_projectile.gd")
const SIZES = {"goblin":Vector2(30,56),"goblin_dog":Vector2(48,36),"goblin_sentinel":Vector2(34,68),"goblin_elite":Vector2(34,68),"kobold_archer":Vector2(32,65),"kobold_clubber":Vector2(42,82),"kobold_summoner":Vector2(34,70)}
const ATTACKS = {"goblin":["horizontal_slash","upward_slash","downward_slam"],"goblin_dog":["jump_attack","bite"],"goblin_sentinel":["thrust","combo"],"goblin_elite":["thrust","combo"],"kobold_archer":["shoot"],"kobold_clubber":["slam","combo"],"kobold_summoner":["summon"]}
const CUES = {"horizontal_slash":[3],"upward_slash":[3],"downward_slam":[2],"jump_attack":[3],"bite":[2,4],"thrust":[2],"combo":[1,4],"slam":[3],"shoot":[4],"summon":[5]}
const HEALTHS = {
	"goblin": 2.0,
	"goblin_dog": 3.0,
	"goblin_sentinel": 8.0,
	"goblin_elite": 8.0,
	"kobold_archer": 4.0,
	"kobold_clubber": 10.0,
	"kobold_summoner": 4.0,
}

static func get_sprite_frames(kind: String) -> SpriteFrames:
	var key := "goblin_sentinel" if kind == "goblin_elite" else kind
	return LIBRARY.get(key, LIBRARY["goblin"])

@export_enum("goblin","goblin_dog","goblin_sentinel","goblin_elite","kobold_archer","kobold_clubber","kobold_summoner") var enemy_kind := "goblin":
	set(value):
		enemy_kind = value
		if HEALTHS.has(value):
			max_health = HEALTHS[value]
			health = max_health
		if collision != null and collision.shape != null and SIZES.has(enemy_kind):
			collision.shape.size = SIZES[enemy_kind]
			_update_collision_position()
			if sprite != null:
				sprite.sprite_frames = get_sprite_frames(enemy_kind)
var facing := 1:
	set(value):
		facing = -1 if value<0 else 1
		if is_instance_valid(visual): visual.scale.x=facing
var visual: Node2D
var sprite: AnimatedSprite2D
var collision: CollisionShape2D
var player: CharacterBody2D:
	set(p):
		player = p
		target = p
var target: Node2D
var active := true
var ai_enabled := false
var locomotion := false
var sequence_time := 0.0
var emitted_frames := {}
var hold_pose := false
var cooldown := 0.0
var attack_index := 0
var jump_pending := false
var active_summon: Node = null
var health := 2.0:
	set(value):
		if value > health:
			posture = maxf(posture, value)
		health = value
var max_health := 2.0
var posture := 2.0
var max_posture := 2.0
var patrol_bounds := Vector2(-INF, INF)
var awareness_height := 450.0
var hit_cooldown := 0.0
var spawn_grace := 0.0
const RUN_SPEED := 115.0
const WALK_SPEED := 57.5 # Exactly 50% slower than running

const RUN_SPEEDS = {
	"goblin_dog": 382.5, # 50% faster than player running speed (255.0 * 1.5)
	"goblin": 115.0,
	"goblin_sentinel": 95.0,
	"goblin_elite": 95.0,
	"kobold_archer": 105.0,
	"kobold_clubber": 90.0,
	"kobold_summoner": 90.0,
}
const ATTACK_DISTANCES = {
	"goblin_dog": 65.0,
	"goblin": 85.0,
	"goblin_sentinel": 95.0,
	"goblin_elite": 95.0,
	"kobold_archer": 380.0,
	"kobold_clubber": 90.0,
	"kobold_summoner": 220.0,
}

func get_run_speed() -> float:
	return RUN_SPEEDS.get(enemy_kind, RUN_SPEED)

func get_walk_speed() -> float:
	return get_run_speed() * 0.5

var ground_origin := true:
	set(val):
		ground_origin = val
		_update_collision_position()

func _init() -> void:
	collision_layer = 2
	collision_mask = 5

func _ready() -> void:
	collision_layer=2
	collision_mask=5
	floor_constant_speed=true
	floor_max_angle=deg_to_rad(65.0)
	floor_snap_length=32.0
	if HEALTHS.has(enemy_kind):
		max_health = HEALTHS[enemy_kind]
		health = max_health
	max_posture = max_health
	posture = max_posture
	add_to_group("combat_targets")
	add_to_group("enemies")
	visual=get_node_or_null("Visual")
	if visual==null:
		visual=Node2D.new()
		visual.name="Visual"
		add_child(visual)
	sprite=visual.get_node_or_null("Sprite")
	if sprite==null:
		sprite=AnimatedSprite2D.new()
		sprite.name="Sprite"
		visual.add_child(sprite)
	sprite.sprite_frames=get_sprite_frames(enemy_kind)
	sprite.centered=false
	sprite.position=Vector2(-128,-224)
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	collision=get_node_or_null("Collision")
	if collision==null:
		collision=CollisionShape2D.new()
		collision.name="Collision"
		add_child(collision)
	var shape:=RectangleShape2D.new()
	shape.size=SIZES[enemy_kind]
	collision.shape=shape
	_update_collision_position()
	facing=facing
	play_sequence("idle")
	queue_redraw()

func _update_collision_position() -> void:
	if collision != null and collision.shape != null:
		var size: Vector2 = SIZES[enemy_kind]
		collision.position.y = -size.y / 2.0 if ground_origin else -(size.y / 2.0 - 17.0)
		if is_instance_valid(visual):
			visual.position.y = 0.0 if ground_origin else 17.0

func animations() -> PackedStringArray: return sprite.sprite_frames.get_animation_names()

func combat_bounds() -> Rect2:
	var size: Vector2 = SIZES[enemy_kind]
	var bottom_y: float = 0.0 if ground_origin else 17.0
	return Rect2(global_position + Vector2(-size.x / 2.0, bottom_y - size.y), size)

func can_see_target(t: Node2D) -> bool:
	if t == null or not is_instance_valid(t):
		return false
	var size: Vector2 = SIZES[enemy_kind]
	var foot_y: float = global_position.y + (0.0 if ground_origin else 17.0)
	var from_pos := Vector2(global_position.x, foot_y - size.y * 0.5)
	var to_pos := t.global_position + Vector2(0, -14)
	var diff := to_pos - from_pos

	# Sight cone covers the entire width of the playable screen (1152.0 px)
	if absf(diff.x) > 1152.0 or absf(diff.y) > 550.0 or absf(diff.y) > awareness_height:
		return false

	# Raycast check: blocked by walls and platforms that you can't pass or shoot through
	var space_state := get_world_2d().direct_space_state
	var exclude_rids: Array[RID] = [get_rid()]
	if t is CollisionObject2D:
		exclude_rids.append((t as CollisionObject2D).get_rid())

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

func is_facing_wall() -> bool:
	if not is_on_wall():
		return false
	var n := get_wall_normal()
	return absf(n.y) < 0.35 and signf(n.x) == -facing

var _edge_cache_frame := -1
var _edge_cache_left := false
var _edge_cache_right := false
var _edge_cached_mask := 0

func is_edge_ahead(dir: int) -> bool:
	if not is_on_floor() or dir == 0:
		return false
	var current_frame := Engine.get_physics_frames()
	if _edge_cache_frame != current_frame:
		_edge_cache_frame = current_frame
		_edge_cached_mask = 0
	if dir < 0 and (_edge_cached_mask & 1) != 0:
		return _edge_cache_left
	if dir > 0 and (_edge_cached_mask & 2) != 0:
		return _edge_cache_right
	var size: Vector2 = SIZES.get(enemy_kind, Vector2(30, 56))
	var half_width: float = size.x * 0.5
	var probe_x: float = global_position.x + dir * (half_width + 8.0)
	var foot_y: float = global_position.y + (0.0 if ground_origin else 17.0)
	var from_pt := Vector2(probe_x, foot_y - size.y * 0.9)
	var to_pt := Vector2(probe_x, foot_y + 110.0)
	var query := PhysicsRayQueryParameters2D.create(from_pt, to_pt)
	query.collision_mask = 5
	query.exclude = [get_rid()]
	query.hit_from_inside = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	var edge := false
	if hit.is_empty():
		edge = true
	else:
		var normal: Vector2 = hit.get("normal", Vector2.UP)
		if normal.y > -0.35:
			edge = true
	if dir < 0:
		_edge_cache_left = edge
		_edge_cached_mask |= 1
	else:
		_edge_cache_right = edge
		_edge_cached_mask |= 2
	return edge

func play_sequence(sequence: StringName, move := false, hold := false) -> void:
	assert(sprite.sprite_frames.has_animation(sequence))
	sprite.animation=sequence
	sprite.frame=0
	sprite.pause()
	sequence_time=0.0
	emitted_frames.clear()
	locomotion=move
	hold_pose=hold
	velocity.x=0
	jump_pending=sequence==&"jump_attack" and is_on_floor()

func take_hit(damage := 1.0, posture_damage := -1.0) -> void:
	var p_dmg := damage if posture_damage < 0.0 else posture_damage
	health -= damage
	posture -= p_dmg
	if health <= 0:
		if is_instance_valid(active_summon):
			active_summon.queue_free()
			active_summon = null
		defeated.emit()
		queue_free()
		return
	if posture <= 0:
		posture = max_posture
		play_sequence("posture_break")
		cooldown = 1.8
		if is_physics_processing():
			velocity.x = -facing * 120.0
	queue_redraw()

func _exit_tree() -> void:
	if is_instance_valid(active_summon):
		active_summon.queue_free()
		active_summon = null

func _spawn_forest_summon() -> void:
	if is_instance_valid(active_summon) and not active_summon.is_queued_for_deletion():
		if active_summon.get("health") != null and active_summon.health > 0:
			return
	var summon_script = load("res://scripts/forest_guardian_spirit.gd")
	if summon_script == null:
		return
	var summon = summon_script.new()
	summon.variant = randi() % 3
	summon.player = target if is_instance_valid(target) else player
	var foot_y: float = global_position.y + (0.0 if ground_origin else 17.0)
	var spawn_pos := Vector2(global_position.x + facing * 44.0, foot_y - summon.HEIGHT / 2.0)
	if patrol_bounds.x != -INF and patrol_bounds.y != INF:
		spawn_pos.x = clampf(spawn_pos.x, patrol_bounds.x + 20.0, patrol_bounds.y - 20.0)
	summon.global_position = spawn_pos
	summon.collision_layer = 2
	summon.collision_mask = 5
	summon.patrol_bounds = patrol_bounds
	summon.spawn_grace = 0.5
	summon.add_to_group("combat_targets")
	summon.add_to_group("forest_boss_summons")
	summon.add_to_group("enemies")
	var parent := get_parent()
	if parent != null:
		parent.add_child(summon)
	active_summon = summon

func _shoot_arrow(origin: Vector2) -> void:
	var shot: Node2D = PROJECTILE.acquire()
	shot.owner_actor = self
	shot.target = target if is_instance_valid(target) else player
	shot.kind = "arrow"
	shot.friendly = false
	shot.damage = 1.0
	shot.speed = 460.0
	shot.radius = 6.0
	shot.lifetime = 3.5
	shot.global_position = origin

	var aim_dir := Vector2(facing, 0.0)
	var current_target: Node2D = target if is_instance_valid(target) else player
	if is_instance_valid(current_target):
		var target_center: Vector2 = current_target.global_position + Vector2(0, -14)
		var diff := target_center - origin
		if absf(diff.x) > 5.0 and signf(diff.x) == facing:
			aim_dir = diff.normalized()
			if absf(aim_dir.y) > 0.86:
				aim_dir.y = signf(aim_dir.y) * 0.86
				aim_dir.x = facing * sqrt(maxf(0.0, 1.0 - aim_dir.y * aim_dir.y))
				aim_dir = aim_dir.normalized()
		elif signf(diff.x) == facing:
			aim_dir = Vector2(facing, signf(diff.y) * 0.5).normalized()
	shot.direction = aim_dir

	var parent := get_parent()
	if parent != null:
		parent.add_child(shot)
	elif get_tree() != null and get_tree().current_scene != null:
		get_tree().current_scene.add_child(shot)

func tick_animation(delta: float) -> void:
	var sequence:=sprite.animation
	var frames:=sprite.sprite_frames.get_frame_count(sequence)
	var fps:=sprite.sprite_frames.get_animation_speed(sequence)
	var is_in_startup := false
	if CUES.has(String(sequence)):
		var cues_list: Array = CUES[String(sequence)]
		if not cues_list.is_empty():
			var first_cue: int = cues_list[0]
			if not emitted_frames.has(first_cue):
				is_in_startup = true
	var is_combo_pause := false
	if enemy_kind == "kobold_clubber" and sequence == &"combo":
		var cues_list: Array = CUES["combo"]
		if cues_list.size() >= 2:
			if emitted_frames.has(cues_list[0]) and not emitted_frames.has(cues_list[1]):
				is_combo_pause = true
	var anim_delta := delta / 3.0 if is_in_startup else (delta / 2.0 if is_combo_pause else delta)
	var old_frame:=int(sequence_time*fps)
	sequence_time+=anim_delta
	var elapsed_frame:=int(sequence_time*fps)
	if CUES.has(String(sequence)):
		for cue in CUES[String(sequence)]:
			if cue>=old_frame and cue<=elapsed_frame and not emitted_frames.has(cue):
				emitted_frames[cue]=true
				var foot_y := global_position.y + (0.0 if ground_origin else 17.0)
				var cue_origin := Vector2(global_position.x + facing * 24, foot_y - SIZES[enemy_kind].y * 0.6)
				attack_cue.emit(String(sequence),cue_origin,facing)
				if (enemy_kind == "kobold_summoner") and sequence == &"summon":
					_spawn_forest_summon()
				elif (enemy_kind == "kobold_archer") and sequence == &"shoot":
					_shoot_arrow(cue_origin)
				# Check attack damage on player for melee attacks (attack string: no i-frames)
				elif is_instance_valid(target) and target.has_method("take_damage"):
					var attack_box := Rect2(global_position + Vector2(10 if facing > 0 else -60, -SIZES[enemy_kind].y), Vector2(50, SIZES[enemy_kind].y))
					var target_body := Rect2(target.global_position - Vector2(14, 23), Vector2(28, 46))
					if attack_box.intersects(target_body):
						if target.get("dash_time") != null and target.dash_time > 0.0:
							pass
						else:
							var health_before: float = target.get("health") if target.get("health") != null else 0.0
							target.take_damage(1.0, global_position.x, true) # attack damage: removes i-frames
							if target.get("health") != null and target.health < health_before:
								attack_landed.emit()
	if sprite.sprite_frames.get_animation_loop(sequence): sprite.frame=elapsed_frame%frames
	else:
		sprite.frame=mini(elapsed_frame,frames-1)
		if elapsed_frame>=frames and not hold_pose:
			sequence_finished.emit(sequence)
			play_sequence("idle")

func _apply_enemy_separation(_delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	cooldown=maxf(0,cooldown-delta)
	hit_cooldown=maxf(0,hit_cooldown-delta)
	spawn_grace=maxf(0,spawn_grace-delta)

	if jump_pending and sequence_time+delta>=2.0/sprite.sprite_frames.get_animation_speed("jump_attack"):
		jump_pending=false
		velocity=Vector2(facing*110,-260)

	var p: Node2D = target if is_instance_valid(target) else player
	var is_off_screen := false
	if is_instance_valid(p):
		var dx := absf(global_position.x - p.global_position.x)
		var dy := absf(global_position.y - p.global_position.y)
		is_off_screen = dx > 1250.0 or dy > 750.0

	var sees_player := false
	if ai_enabled:
		if target == null and is_instance_valid(player):
			target = player
		if not is_off_screen:
			sees_player = can_see_target(target)
		if sees_player and is_instance_valid(target):
			# If chasing the player outside original patrol bounds, expand bounds so enemy can roam freely
			if patrol_bounds.x != -INF and position.x < patrol_bounds.x:
				patrol_bounds.x = position.x - 80.0
			if patrol_bounds.y != INF and position.x > patrol_bounds.y:
				patrol_bounds.y = position.x + 80.0
			var distance:=target.global_position.x-global_position.x
			if sprite.animation==&"idle" or sprite.animation==&"walk" or sprite.animation==&"run":
				facing=int(signf(distance)) if absf(distance)>1 else facing
				var ranged:=enemy_kind=="kobold_archer" or enemy_kind=="kobold_summoner"
				var attack_dist: float = ATTACK_DISTANCES.get(enemy_kind, 380.0 if ranged else 85.0)
				var at_edge := is_edge_ahead(facing)
				if absf(distance) > attack_dist and not (at_edge and ranged and absf(distance) <= 480.0):
					if at_edge:
						velocity.x = 0
						if sprite.animation != &"idle": play_sequence("idle")
					else:
						if sprite.animation!=&"run": play_sequence("run",true)
				elif cooldown<=0:
					if enemy_kind == "kobold_summoner" and is_instance_valid(active_summon) and not active_summon.is_queued_for_deletion() and active_summon.get("health") != null and active_summon.health > 0:
						if sprite.animation != &"idle": play_sequence("idle")
					else:
						var attacks: Array=ATTACKS[enemy_kind]
						play_sequence(attacks[attack_index%attacks.size()])
						attack_index+=1
						var attack_cd := 1.6 if ranged else 1.4
						if enemy_kind == "kobold_clubber":
							attack_cd *= 2.0
						cooldown = attack_cd
				elif sprite.animation!=&"idle": play_sequence("idle")
		else:
			# Patrol mode: turn around before exceeding patrol bounds or at walls/edges
			if position.x <= patrol_bounds.x + 8.0:
				facing = 1
			elif position.x >= patrol_bounds.y - 8.0:
				facing = -1
			elif not is_off_screen:
				if (facing == -1 and is_facing_wall()) or is_edge_ahead(-1):
					facing = 1
				elif (facing == 1 and is_facing_wall()) or is_edge_ahead(1):
					facing = -1
				if is_edge_ahead(facing):
					facing *= -1
			if sprite.animation==&"idle" or sprite.animation==&"run":
				play_sequence("walk", true)

	var cur_run_speed := get_run_speed()
	var cur_walk_speed := get_walk_speed()
	if locomotion:
		if (not is_off_screen or patrol_bounds.x == -INF) and is_edge_ahead(facing):
			if sees_player:
				velocity.x = 0
				if sprite.animation != &"idle": play_sequence("idle")
			else:
				facing *= -1
				if is_edge_ahead(facing): velocity.x = 0
				else: velocity.x = facing * (cur_run_speed if sprite.animation==&"run" else cur_walk_speed)
		else:
			velocity.x=facing*(cur_run_speed if sprite.animation==&"run" else cur_walk_speed)
	elif sprite.animation!=&"jump_attack": velocity.x=move_toward(velocity.x,0,700*delta)
	velocity.y+=(1300.0 if sprite.animation==&"jump_attack" else 900.0)*delta

	if not is_off_screen:
		_apply_enemy_separation(delta)
	move_and_slide()

	# Contact damage with player (preserves player i-frames)
	if not is_off_screen and is_instance_valid(target) and hit_cooldown <= 0 and spawn_grace <= 0 and target.has_method("take_damage"):
		var my_bounds := combat_bounds()
		var player_bounds := Rect2(target.global_position - Vector2(14, 23), Vector2(28, 46))
		if my_bounds.intersects(player_bounds):
			if target.get("dash_time") != null and target.dash_time > 0.0:
				pass
			else:
				var health_before: float = target.get("health") if target.get("health") != null else 0.0
				target.take_damage(1.0, global_position.x, false) # contact damage keeps i-frames
				if target.get("health") != null and target.health < health_before:
					attack_landed.emit()
				hit_cooldown = 0.8

	tick_animation(delta)

func _draw() -> void:
	if health > 0 and ai_enabled:
		var size: Vector2 = SIZES[enemy_kind]
		var top_y: float = (0.0 if ground_origin else 17.0) - size.y
		draw_rect(Rect2(-17, top_y - 14, 34, 7), Color(0.04, 0.10, 0.14))
		draw_rect(Rect2(-16, top_y - 13, 32, 3), Color(0.25, 0.32, 0.36))
		draw_rect(Rect2(-16, top_y - 13, 32.0 * clampf(float(health) / float(max_health), 0.0, 1.0), 3), Color(0.91, 0.44, 0.47))
		draw_rect(Rect2(-16, top_y - 9, 32, 1), Color(0.18, 0.22, 0.25))
		draw_rect(Rect2(-16, top_y - 9, 32.0 * clampf(float(posture) / float(max_posture), 0.0, 1.0), 1), Color.WHITE)
