extends "res://scripts/scout.gd"

const TEXTURES := [
	preload("res://assets/characters/summon_bear_atlas.png"),
	preload("res://assets/characters/summon_troll_atlas.png"),
	preload("res://assets/characters/summon_ent_atlas.png")
]
const ROOTS := [
	preload("res://assets/effects/forest_roots_1.png"),
	preload("res://assets/effects/forest_roots_2.png"),
	preload("res://assets/effects/forest_roots_3.png")
]

const FRAME_COUNTS: Array = [
	[6, 8, 8, 8, 6], # Variant 0: Earthen Bear (Idle 6, Walk 8, Run 8, Attack 8, Recoil 6)
	[6, 6, 6, 6, 6], # Variant 1: Earthen Troll (Idle 6, Walk 6, Run 6, Jump Attack 6, Recoil 6)
	[6, 8, 8, 12, 6] # Variant 2: Tree Ent (Idle 6, Walk 8, Run 8, Root Combo 12, Recoil 6)
]

const CELL := 320
const FOOT_Y := 300.0

var variant := 0
var visual_time := 0.0
var anim_time := 0.0
var anim_state := "idle"
var hurt_time := 0.0
var attack_time := 0.0

const HEIGHT := 99.0 * 1.2
const ART_SCALE := HEIGHT / 38.0

func _ready() -> void:
	max_health = 6.0
	health = 6.0
	max_posture = 6.0
	posture = 6.0
	super._ready()

func body_size() -> Vector2:
	return Vector2(32.0 * ART_SCALE, HEIGHT)

func combat_bounds() -> Rect2:
	return Rect2(global_position - body_size() / 2.0, body_size())

func take_hit(amount: float = 1.0, posture_damage: float = -1.0) -> void:
	hurt_time = 0.45
	anim_time = 0.0
	anim_state = "hurt"
	super.take_hit(amount, posture_damage)

func _physics_process(delta: float) -> void:
	visual_time += delta
	anim_time += delta
	if hurt_time > 0.0:
		hurt_time = maxf(0.0, hurt_time - delta)
	if attack_time > 0.0:
		attack_time = maxf(0.0, attack_time - delta)
	elif hit_cooldown > 0.5:
		attack_time = 0.5
		anim_time = 0.0
	elif player != null and spawn_grace <= 0.0 and hit_cooldown <= 0.2:
		var dist := global_position.distance_to(player.global_position)
		if dist < 65.0:
			attack_time = maxf(attack_time, 0.45)

	if hurt_time > 0.0:
		anim_state = "hurt"
	elif attack_time > 0.0:
		anim_state = "attack"
	elif absf(velocity.x) > 20.0:
		if player != null and global_position.distance_to(player.global_position) < 240.0:
			anim_state = "run"
		else:
			anim_state = "walk"
	else:
		anim_state = "idle"

	super._physics_process(delta)

func _draw() -> void:
	var v: int = clampi(variant, 0, 2)
	var counts: Array = FRAME_COUNTS[v]
	var row := 0
	var total_frames := int(counts[0])
	var frame_idx := 0

	if anim_state == "hurt":
		row = 4
		total_frames = int(counts[4])
		var progress := clampf(1.0 - hurt_time / 0.45, 0.0, 0.99)
		frame_idx = int(progress * float(total_frames))
	elif anim_state == "attack":
		row = 3
		total_frames = int(counts[3])
		var progress := clampf(1.0 - attack_time / 0.5, 0.0, 0.99)
		frame_idx = int(progress * float(total_frames))
	elif anim_state == "run":
		row = 2
		total_frames = int(counts[2])
		frame_idx = int(anim_time * 10.0) % total_frames
	elif anim_state == "walk":
		row = 1
		total_frames = int(counts[1])
		frame_idx = int(anim_time * 7.5) % total_frames
	else:
		row = 0
		total_frames = int(counts[0])
		frame_idx = int(anim_time * 6.0) % total_frames

	var src_rect := Rect2(frame_idx * CELL, row * CELL, CELL, CELL)
	var body_height: float = [145.0, 165.0, 165.0][v]
	var draw_scale: float = HEIGHT / body_height
	var dest_size: Vector2 = Vector2.ONE * CELL * draw_scale
	var dest_rect := Rect2(-dest_size.x * 0.5, HEIGHT * 0.5 - FOOT_Y * draw_scale, dest_size.x, dest_size.y)

	var emergence := clampf(1.0 - spawn_grace / 0.8, 0.0, 1.0)
	var bob := absf(sin(visual_time * 12.0)) * 1.5 if (spawn_grace <= 0.0 and anim_state in ["walk", "run"]) else 0.0

	draw_set_transform(Vector2(0, -bob), 0.0, Vector2(facing, 1.0))
	draw_texture_rect_region(TEXTURES[v], dest_rect, src_rect, Color(1, 1, 1, emergence))
	draw_set_transform(Vector2.ZERO)

	draw_rect(Rect2(-30, -HEIGHT / 2.0 - 14.0, 60, 7), Color("092027"))
	draw_rect(Rect2(-28, -HEIGHT / 2.0 - 13.0, 56.0 * clampf(health / max_health, 0.0, 1.0), 3), Color("71e6c5"))
	draw_rect(Rect2(-28, -HEIGHT / 2.0 - 9.0, 56, 1), Color(0.18, 0.22, 0.25))
	draw_rect(Rect2(-28, -HEIGHT / 2.0 - 9.0, 56.0 * clampf(posture / max_posture, 0.0, 1.0), 1), Color.WHITE)
