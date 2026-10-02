extends Node2D

signal defeated
signal attack_cued(cue: String)
const PROJECTILE=preload("res://scripts/combat_projectile.gd")
var player: CharacterBody2D
var health:=40.0:
	set(value):
		if value > health:
			posture = maxf(posture, value)
		health = value
var max_health:=40.0
var posture:=40.0
var max_posture:=40.0
var active:=false
var state:="idle"
var state_time:=0.6
var facing:=-1
var attack_direction:=-1
var attack_count:=0
var hurt_flash:=0.0
var invulnerability:=0.0
var arena_bounds:=Vector2(3150,3760)
var attack_name:=""
var phases: Array[Dictionary]=[]
var phase: Dictionary={}
var phase_length:=1.0
var struck:=false
var home_y:=553.0
var motion_start:=Vector2.ZERO
var motion_end:=Vector2.ZERO
var last_attack:=""
var attacks_used: Dictionary={}

func _ready() -> void:
	add_to_group("mcp_watch")
	add_to_group("combat_targets")
	add_to_group("bosses")
	add_to_group("enemies")
	home_y=position.y

func combat_bounds() -> Rect2:
	return Rect2(global_position-Vector2(48,55),Vector2(96,102))

func choose_attack() -> String:
	return "slam"

func attack_phases(_name: String) -> Array[Dictionary]:
	return []

func limit_ground_motion(destination: Vector2) -> Vector2:
	return destination

func begin_attack(name: String) -> void:
	attack_name=name
	last_attack=name
	attacks_used[name]=int(attacks_used.get(name,0))+1
	attack_direction=1 if player.global_position.x>global_position.x else -1
	facing=attack_direction
	phases=attack_phases(name)
	attack_count+=1
	_next_phase()

func _next_phase() -> void:
	struck=false
	if phases.is_empty():
		phase={}
		state="idle"
		state_time=.325 if attack_name=="one_hit_combo" else .65
		return
	phase=phases.pop_front()
	state=str(phase.get("state","recover"))
	phase_length=float(phase.get("time",.3))
	state_time=phase_length
	motion_start=position
	var reach:=float(phase.get("move",0))
	motion_end=Vector2(clampf(position.x+reach*attack_direction,arena_bounds.x,arena_bounds.y),home_y)
	if phase.get("target_jump",false): motion_end.x=clampf(player.global_position.x,arena_bounds.x,arena_bounds.y)
	if phase.get("retreat",false): motion_end.x=clampf(player.global_position.x-attack_direction*330,arena_bounds.x,arena_bounds.y)
	if phase.get("over_player",false): motion_end.x=clampf(player.global_position.x+attack_direction*220,arena_bounds.x,arena_bounds.y)
	if phase.has("move") and float(phase.get("height",0))==0:
		motion_end=limit_ground_motion(motion_end)
	attack_cued.emit(str(phase.get("cue","enemy_attack")))
	if phase.has("projectile"): fire(str(phase.projectile),float(phase.get("projectile_damage",phase.get("damage",1))),bool(phase.get("down",false)))
	if phase.get("summon",false) and has_method("summon_enemies"): call("summon_enemies")

func _physics_process(delta: float) -> void:
	hurt_flash=maxf(0,hurt_flash-delta)
	invulnerability=maxf(0,invulnerability-delta)
	if health<=0 or not active or not is_instance_valid(player): return
	state_time-=delta
	if state=="idle":
		if state_time<=0: begin_attack(choose_attack())
	elif state=="stagger":
		if state_time<=0:
			state="idle"
			state_time=.5
	else:
		var t:=clampf(1-state_time/phase_length,0,1)
		var previous_position:=global_position
		if phase.has("move") or phase.get("target_jump",false) or phase.get("retreat",false) or phase.get("over_player",false):
			var motion_progress:=1.0-pow(1.0-t,3.0) if phase.get("ease_out",false) else t
			position=motion_start.lerp(motion_end,motion_progress)
			position.y-=sin(t*PI)*float(phase.get("height",0))
		if phase.get("volley",false):
			var next:=int(phase.get("shots",0))
			if next<3 and t>=.3+next*.18:
				fire("arrow",1,true)
				phase["shots"]=next+1
		if phase.has("hit") and not struck:
			var box:=attack_box()
			# Moving melee sweeps its active volume, so a fast lunge cannot skip a
			# player between physics ticks. Anticipation/recovery remain harmless.
			if phase.has("move"): box=box.merge(Rect2(box.position+previous_position-global_position,box.size))
			if box.intersects(Rect2(player.global_position-Vector2(14,23),Vector2(28,46))):
				if player.get("dash_time") != null and player.dash_time > 0.0:
					pass
				else:
					var before: float=player.health
					player.take_damage(float(phase.get("damage",1)),global_position.x,true)
					struck=player.health<before
		if state_time<=0:
			if phase.has("move") or phase.get("target_jump",false) or phase.get("over_player",false) or phase.get("retreat",false): position=motion_end
			_next_phase()
	queue_redraw()

func attack_box() -> Rect2:
	var local: Rect2=phase.get("hit",phase.get("preview",Rect2()))
	if attack_direction<0: local.position.x=-local.end.x
	return Rect2(global_position+local.position,local.size)

func fire(kind: String,damage_amount: float,down:=false) -> Node2D:
	var shot: Node2D = PROJECTILE.acquire()
	shot.owner_actor=self
	shot.target=player
	shot.kind=kind
	shot.damage=damage_amount
	shot.direction=(player.global_position-global_position).normalized()
	shot.global_position=global_position+Vector2(attack_direction*50,-8)
	if kind=="wind":
		shot.direction=Vector2(attack_direction,0)
		shot.speed=440
		shot.radius=PROJECTILE.WIND_RADIUS
	elif kind=="beam":
		shot.speed=600
		shot.radius=21
	elif kind=="fist":
		shot.speed=850
		shot.radius=15
		shot.return_time=.55
		shot.lifetime=2.4
	if down:
		shot.homing_down=true
		shot.hover_time=1.0
		shot.lifetime+=shot.hover_time
		shot.direction=Vector2.DOWN
	get_parent().add_child(shot)
	return shot

func take_hit(amount: float=1.0, posture_damage: float = -1.0) -> void:
	if health<=0 or not active or invulnerability>0 or phase.get("invulnerable",false): return
	var p_dmg := amount if posture_damage < 0.0 else posture_damage
	health=maxf(0,health-amount)
	posture=maxf(0,posture-p_dmg)
	hurt_flash=.16
	invulnerability=.12
	if health<=0:
		active=false
		state="defeated"
		phase={}
		phases.clear()
		defeated.emit()
	elif posture<=0:
		stagger()
	queue_redraw()

func stagger(duration: float = 1.75) -> void:
	state="stagger"
	state_time=duration
	phase={}
	phases.clear()
	struck=false
	posture=max_posture

func reset_encounter() -> void:
	health=max_health
	posture=max_posture
	phase={}
	phases.clear()
	state="idle"
	state_time=.85
	attack_count=0
	invulnerability=0
	active=false
	position.y=home_y

func draw_attack() -> void:
	if phase.has("hit") or phase.has("preview"):
		var box:=attack_box()
		box.position-=global_position
		if phase.has("preview"):
			draw_line(Vector2(box.position.x,box.end.y),box.end,Color("da9272"),3)
			for x in range(int(box.position.x),int(box.end.x),24): draw_line(Vector2(x,box.end.y),Vector2(x+5,box.end.y-5),Color("da9272"),2)
		elif str(phase.get("style",""))=="thrust":
			draw_line(Vector2(box.position.x,box.get_center().y),Vector2(box.end.x,box.get_center().y),Color("f7cf85"),6)
		else:
			# A short impact/sweep silhouette stays inside the actual damaging volume.
			draw_colored_polygon(PackedVector2Array([box.position,Vector2(box.end.x,box.get_center().y),box.end,Vector2(box.position.x,box.end.y-8)]),Color(.97,.81,.52,.3))
	if phase.get("invulnerable",false):
		draw_rect(Rect2(-52,-59,104,110),Color("b4edec"),false,3)

func _mcp_state() -> Dictionary:
	return {"health":health,"posture":posture,"max_health":max_health,"max_posture":max_posture,"active":active,"state":state,"attack":attack_name,"phase_invulnerable":phase.get("invulnerable",false)}
