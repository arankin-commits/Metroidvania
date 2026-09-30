extends "res://scripts/combat_boss.gd"
const ATLAS = preload("res://assets/characters/temple_guardian.png")
const TEMPLE_PROJECTILE = preload("res://scripts/temple_guardian_projectile.gd")
const GLOW_SHADER = preload("res://scripts/temple_guardian_glow.gdshader")
const CELL := 384
const FRAME_RECT := Rect2(-160,-225,384,384)
var phase_two_started:=false
var transition_pending := false
var visual_time := 0.0

func combat_bounds() -> Rect2:
	return Rect2(global_position-Vector2(62,97),Vector2(124,144))

func _ready() -> void:
	super._ready()
	arena_bounds=Vector2(22900,23900)
	max_health=6
	health=max_health
	var glow := ShaderMaterial.new()
	glow.shader = GLOW_SHADER
	material = glow

func _physics_process(delta: float) -> void:
	visual_time += delta
	if active and is_instance_valid(player) and state in ["idle","recover"]:
		facing = 1 if player.global_position.x > global_position.x else -1
	super._physics_process(delta)

func frame_index() -> int:
	return int(phase.get("pose",0))

func phase_glow() -> float:
	if state == "phase_transition": return 0.75 + 0.25 * sin(visual_time * 18.0)
	return 0.7 if health <= max_health * 0.5 else 0.0

func rocket_wrist() -> Vector2:
	return global_position + Vector2(attack_direction * (62 if state=="rocket_retract" else 32),-32)

func choose_attack() -> String:
	if health<=max_health*.5 and not phase_two_started:
		phase_two_started=true
		transition_pending=true
		return "fire"
	if absf(player.global_position.x-global_position.x)<175:
		return "punch_combo" if randi()%2==0 else "slam"
	if health<max_health*.5:
		return "fire" if randi()%2==0 else "rocket_punch"
	if health==max_health*.5: return "fire"
	return "rocket_punch"

func reset_encounter() -> void:
	phase_two_started=false
	transition_pending=false
	visual_time=0
	super.reset_encounter()

func attack_phases(name: String) -> Array[Dictionary]:
	match name:
		"rocket_punch":
			return [{"state":"tell_rocket","time":.65,"pose":1},
				{"state":"rocket","time":.08,"pose":2,"projectile":"fist"},
				{"state":"rocket_extended","time":.47,"pose":2},
				{"state":"rocket_retract","time":.55,"pose":3},
				{"state":"recover","time":.33,"pose":0}]
		"fire":
			var shot_phases: Array[Dictionary] = []
			if transition_pending:
				transition_pending=false
				shot_phases.append({"state":"phase_transition","time":.45,"pose":5,"invulnerable":true})
			shot_phases.append_array([
				{"state":"charge_fire","time":.55,"pose":4,"invulnerable":true},
				{"state":"charge_fire","time":.5,"pose":5,"invulnerable":true},
				{"state":"fire","time":.12,"pose":6,"projectile":"beam","damage":2.0},
				{"state":"recover","time":1.0,"pose":7}])
			return shot_phases
		"slam":
			return [{"state":"tell_slam","time":.8,"pose":11,"preview":Rect2(-130,-20,260,67)},
				{"state":"slam","time":.18,"pose":12,"hit":Rect2(-130,-20,260,67)},
				{"state":"recover","time":.9,"pose":7}]
	var result: Array[Dictionary]=[]
	for i in 3:
		var strike := Rect2(20,-35,130 if i==2 else 105,75)
		result.append({"state":"tell_punch","time":.55 if i==0 else .25,"pose":0,"preview":strike})
		result.append({"state":"punch","time":.15,"pose":8+i,"hit":strike})
		result.append({"state":"combo_pause","time":.2,"pose":8+i})
	result.append({"state":"recover","time":.9,"pose":7})
	return result

func fire(kind: String, damage_amount: float, _down := false) -> Node2D:
	var shot := TEMPLE_PROJECTILE.new()
	shot.owner_actor = self
	shot.target = player
	shot.kind = kind
	shot.damage = damage_amount
	shot.global_position = rocket_wrist() if kind=="fist" else global_position+Vector2(attack_direction*58,-38)
	shot.direction = (player.global_position-shot.global_position).normalized()
	if kind == "fist":
		shot.speed = 850
		shot.radius = 15
		shot.return_time = .55
		shot.lifetime = 2.4
	else:
		shot.speed = 600
		shot.radius = 21
	get_parent().add_child(shot)
	return shot

func _draw() -> void:
	if health<=0: return
	material.set_shader_parameter("rune_glow",phase_glow())
	material.set_shader_parameter("hurt_flash",1.0 if hurt_flash > 0 else 0.0)
	material.set_shader_parameter("protected",1.0 if phase.get("invulnerable",false) else 0.0)
	var index := frame_index()
	var bob := roundf(sin(visual_time*3.0)) if state=="idle" else 0.0
	draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
	var rect := FRAME_RECT
	# Breathing compresses the torso without lifting the registered feet.
	if state=="idle":
		rect.position.y += bob
		rect.size.y -= bob * float(CELL) / 272.0
	draw_texture_rect_region(ATLAS,rect,Rect2(Vector2(index%4,index/4)*CELL,Vector2(CELL,CELL)))
	draw_set_transform(Vector2.ZERO)
	if phase.has("preview"):
		var box := attack_box()
		box.position -= global_position
		# A restrained ground tell marks only the real strike lane.
		draw_line(Vector2(box.position.x,47),Vector2(box.end.x,47),Color(.2,.85,1,.45),2)
