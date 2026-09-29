extends "res://scripts/combat_boss.gd"
const SCOUT=preload("res://scripts/forest_guardian_spirit.gd")
const RIGHT_ATLAS=preload("res://assets/characters/forest_guardian_right.png")
const LEFT_ATLAS=preload("res://assets/characters/forest_guardian_left.png")
const FX=preload("res://scripts/forest_guardian_fx.gd")
const CELL=320
const FRAME_RECT=Rect2(-160,-193,320,320)
var combat_fx=FX.new()
var visual_time:=0.0
var summon_marks: Array[Vector2]=[]
var summons: Array[Node]=[]
var mobility_cooldown:=0.0
var summon_cooldown:=0.0

func combat_bounds() -> Rect2:
	return Rect2(global_position-Vector2(31,52),Vector2(62,99))

func _ready() -> void:
	super._ready()
	arena_bounds=Vector2(19490,20910)
	health=10
	max_health=10
	add_to_group("bow_targets")

func _physics_process(delta: float) -> void:
	visual_time+=delta
	if active and health>0:
		combat_fx.tick(self,delta)
		if is_instance_valid(player):
			if state in ["idle","recover"]: facing=1 if player.global_position.x>global_position.x else -1
			if combat_bounds().intersects(Rect2(player.global_position-Vector2(14,23),Vector2(28,46))):
				player.take_damage(1,global_position.x)
	else: combat_fx.clear()
	mobility_cooldown=maxf(0,mobility_cooldown-delta)
	summon_cooldown=maxf(0,summon_cooldown-delta)
	if not active or health<=0: clear_summons()
	super._physics_process(delta)

func clear_summons() -> void:
	for enemy in summons:
		if is_instance_valid(enemy): enemy.queue_free()
	summons.clear()

func has_living_summons() -> bool:
	for enemy in summons:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.health>0: return true
	return false

func reset_encounter() -> void:
	combat_fx.clear()
	summon_marks.clear()
	clear_summons()
	mobility_cooldown=0
	summon_cooldown=0
	super.reset_encounter()

func choose_attack() -> String:
	var distance:=absf(player.global_position.x-global_position.x)
	if health<max_health*.5 and mobility_cooldown<=0 and distance<450:
		mobility_cooldown=5
		return "flipping_volley"
	if distance<130:
		if attack_count%2==0 and mobility_cooldown<=0:
			mobility_cooldown=4
			return "retreat_dash"
		return "knife_combo"
	if summon_cooldown<=0 and attack_count%3==0 and not has_living_summons():
		summon_cooldown=9
		return "summon"
	return "rapid_fire" if attack_count%2==0 else "charged_arrow"

func begin_attack(name: String) -> void:
	if name=="summon" and has_living_summons(): name="rapid_fire"
	if name=="summon": summon_marks=_summon_positions()
	super.begin_attack(name)

func _next_phase() -> void:
	var was_air:=state in ["air_dash","flipping_volley"]
	super._next_phase()
	if state=="idle" and health<max_health*.5: state_time=.45
	if was_air and state=="recover": combat_fx.land(self)

func fire(kind: String,damage_amount: float,down:=false) -> Node2D:
	var shot:=super.fire(kind,damage_amount,down)
	if kind=="arrow":
		shot.short_hit_recovery=attack_name in ["rapid_fire","flipping_volley"]
		shot.forest_magic=true
		shot.charged_arrow=attack_name=="charged_arrow"
		shot.arrow_frame=int(phase.get("arrow_frame",0))
		if shot.charged_arrow: shot.radius=12
	return shot

func limit_ground_motion(destination: Vector2) -> Vector2:
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(62,97)
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape
	query.transform=Transform2D(0,global_position+Vector2(0,-3.5))
	query.motion=destination-position
	query.collision_mask=1
	var result:=get_world_2d().direct_space_state.cast_motion(query)
	return position+query.motion*result[0] if result.size()==2 else destination

func attack_phases(name: String) -> Array[Dictionary]:
	match name:
		"summon": return [{"state":"tell_summon","time":.9,"sprite_pose":1},{"state":"summon","time":.2,"summon":true,"sprite_pose":2},{"state":"recover","time":.8,"sprite_pose":0}]
		"charged_arrow": return [{"state":"telegraph","time":.6,"cue":"bow_charge","sprite_pose":3},{"state":"telegraph","time":.3,"sprite_pose":4},{"state":"shoot","time":.1,"projectile":"arrow","projectile_damage":2,"sprite_pose":5},{"state":"recover","time":.8,"sprite_pose":3}]
		"retreat_dash": return [{"state":"tell_dash","time":.4,"sprite_pose":14},{"state":"air_dash","time":.55,"retreat":true,"height":90,"sprite_pose":15},{"state":"recover","time":.6,"sprite_pose":16}]
		"flipping_volley": return [{"state":"tell_volley","time":.65,"sprite_pose":18},{"state":"flipping_volley","time":1.2,"over_player":true,"height":200,"volley":true,"sprite_pose":17},{"state":"recover","time":.85,"sprite_pose":19}]
	var result: Array[Dictionary]=[]
	if name=="rapid_fire":
		result.append({"state":"tell_rapid","time":.7,"cue":"bow_charge","sprite_pose":3})
		for i in 5: result.append({"state":"shoot","time":.16,"projectile":"arrow","sprite_pose":6+i,"arrow_frame":i})
	else:
		for i in 3:
			result.append({"state":"tell_knife","time":.5 if i==0 else .2,"sprite_pose":11})
			result.append({"state":"knife","time":.14,"hit":Rect2(10,-27,88,63),"move":12,"sprite_pose":12 if i<2 else 13})
			result.append({"state":"combo_pause","time":.17,"sprite_pose":11})
	result.append({"state":"recover","time":.8,"sprite_pose":0})
	return result

func _summon_positions() -> Array[Vector2]:
	var points: Array[Vector2]=[]
	var padding:=32.0*SCOUT.ART_SCALE/2+12
	for offset in [-260.0,0.0,260.0]:
		var x:=clampf(global_position.x+offset,arena_bounds.x+padding,arena_bounds.y-padding)
		if absf(x-player.global_position.x)<120: x=clampf(x+(-160 if player.global_position.x>x else 160),arena_bounds.x+padding,arena_bounds.y-padding)
		points.append(Vector2(x,home_y+47-SCOUT.HEIGHT/2))
	return points

func summon_enemies() -> void:
	# At most one living wave of three; never spawn into the player's body.
	if has_living_summons(): return
	clear_summons()
	if summon_marks.is_empty(): summon_marks=_summon_positions()
	for index in 3:
		var enemy:=SCOUT.new()
		enemy.variant=index
		enemy.player=player
		enemy.position=summon_marks[index]
		enemy.collision_layer=2
		enemy.collision_mask=1
		enemy.patrol_bounds=arena_bounds
		enemy.spawn_grace=.8
		get_parent().add_child(enemy)
		enemy.add_to_group("combat_targets")
		enemy.add_to_group("forest_boss_summons")
		summons.append(enemy)

func sprite_pose() -> int:
	if state=="flipping_volley":
		var progress:=1.0-state_time/phase_length
		return 17 if progress<.6 else 18
	return int(phase.get("sprite_pose",0))

func sprite_texture() -> Texture2D:
	# The final volley recovery view in the reference faces back toward the
	# player. Its independently authored counterpart therefore faces right.
	var direction:=facing
	if sprite_pose()==19: direction=-direction
	return RIGHT_ATLAS if direction>0 else LEFT_ATLAS

func _draw() -> void:
	if health<=0: return
	combat_fx.draw(self)
	var index:=sprite_pose()
	var tint:=Color.WHITE if hurt_flash<=0 else Color(1.4,1.4,1.4)
	draw_texture_rect_region(sprite_texture(),FRAME_RECT,Rect2(Vector2(index%4,index/4)*CELL,Vector2(CELL,CELL)),tint)
