extends "res://scripts/combat_boss.gd"

const ATLAS=preload("res://assets/characters/cave_goblin_atlas.png")
const LEFT_ATLAS=preload("res://assets/characters/cave_goblin_left_atlas.png")
const COMBAT_FX=preload("res://scripts/goblin_combat_fx.gd")
var combat_fx=COMBAT_FX.new()
const FRAME_SIZE=288
const FRAME_RECT=Rect2(-144,-169,288,288)
var visual_clock:=0.0
var recovery_pose:=0
var charge_hit_pause:=0.0

func _ready() -> void:
	super._ready()
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST

func _physics_process(delta: float) -> void:
	if active and health>0: combat_fx.tick(self,delta)
	else: combat_fx.clear()
	if not active or health<=0: charge_hit_pause=0.0
	if charge_hit_pause>0:
		charge_hit_pause=maxf(0,charge_hit_pause-delta)
		queue_redraw()
		return
	var was_struck:=struck
	var was_charge:=state=="charge"
	super._physics_process(delta)
	if was_charge and not was_struck and struck: charge_hit_pause=.055
	if active and health>0 and is_instance_valid(player):
		var player_body:=Rect2(player.global_position-Vector2(14,23),Vector2(28,46))
		if combat_bounds().intersects(player_body):
			if player.get("dash_time") != null and player.dash_time > 0.0:
				pass
			else:
				player.take_damage(1.0,global_position.x)
	visual_clock+=delta
	if phase.has("hit"): recovery_pose=int(phase.get("sprite_pose",0))
	if health>0: queue_redraw()

func begin_attack(name: String) -> void:
	charge_hit_pause=0.0
	super.begin_attack(name)

func reset_encounter() -> void:
	charge_hit_pause=0.0
	combat_fx.clear()
	super.reset_encounter()

func _next_phase() -> void:
	super._next_phase()
	if phase.has("hit") or state=="jump": combat_fx.release(self)

func combat_bounds() -> Rect2:
	return Rect2(global_position-Vector2(66,61),Vector2(132,108))

func limit_ground_motion(destination: Vector2) -> Vector2:
	var query:=PhysicsShapeQueryParameters2D.new()
	var shape:=RectangleShape2D.new()
	# Keep the box one pixel above the standing floor, preserving wall clearance.
	shape.size=Vector2(132,106)
	query.shape=shape
	query.transform=Transform2D(0,global_position+Vector2(0,-8))
	query.motion=destination-position
	query.collision_mask=1
	var exclude: Array[RID] = []
	for node in get_tree().get_nodes_in_group("combat_targets"):
		if node is CollisionObject2D:
			exclude.append(node.get_rid())
	for node in get_tree().get_nodes_in_group("forest_boss_summons"):
		if node is CollisionObject2D:
			exclude.append(node.get_rid())
	query.exclude = exclude
	var result:=get_world_2d().direct_space_state.cast_motion(query)
	if result.size()==2: return position+query.motion*result[0]
	return destination

func choose_attack() -> String:
	var distance:=absf(player.global_position.x-global_position.x)
	if distance>290: return "jump_slam" if attack_count%2==0 else "charge_swing"
	if distance>150: return "mid_combo" if attack_count%2==0 else "charge_swing"
	return ["spin_combo","overhead_combo","charge_swing","one_hit_combo"][randi()%4]

func strike(reach: float,windup: float,style: String,reverse:=false) -> Array[Dictionary]:
	var box:=Rect2(20,-43,reach,86)
	if style=="thrust": box=Rect2(30,-18,reach,28)
	if style=="overhead": box=Rect2(10,-85,reach,132)
	if style=="spin": box=Rect2(-150,-40,300,85)
	var tell_pose:=6 if reverse else 4
	var hit_pose:=7 if reverse else 5
	var advance:=28.0
	var active_time:=.16
	match style:
		"thrust": tell_pose=8; hit_pose=9; advance=140.0; active_time=.22
		"overhead": tell_pose=10; hit_pose=11; advance=44.0
		"spin": tell_pose=6; hit_pose=12; advance=32.0
	var preview:=box.merge(Rect2(box.position+Vector2(advance,0),box.size))
	return [{"state":"tell_"+style,"time":windup,"preview":preview,"style":style,"sprite_pose":tell_pose},
		{"state":style,"time":active_time,"hit":box,"style":style,"sprite_pose":hit_pose,"move":advance},
		{"state":"combo_pause","time":.22}]

func attack_phases(name: String) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	match name:
		"jump_slam":
			return [{"state":"tell_jump","time":.7,"sprite_pose":13},
				{"state":"jump","time":.9,"target_jump":true,"height":210,"sprite_pose":14},
				{"state":"slam","time":.18,"hit":Rect2(-65,0,130,48),"damage":1.0,"sprite_pose":15},
				{"state":"recover","time":1.0}]
		"charge_swing":
			return [{"state":"telegraph","time":1.3,"preview":Rect2(20,-43,234,86),"style":"swing","sprite_pose":4,"cue":"warden_charge_tell"},
				{"state":"charge","time":.12,"hit":Rect2(20,-43,170,86),"projectile":"wind","damage":1.0,"projectile_damage":.5,"style":"swing","sprite_pose":5,"move":64.0,"ease_out":true,"cue":"heavy_attack"},
				{"state":"charge_settle","time":.08,"sprite_pose":5,"cue":""},
				{"state":"charge_followthrough","time":.18,"sprite_pose":11,"cue":""},
				{"state":"recover","time":1.05,"cue":""}]
		"spin_combo":
			result.append_array(strike(120,.6,"swing"))
			result.append_array(strike(130,.25,"swing",true))
			result.append_array(strike(170,.35,"thrust"))
			result.append_array(strike(150,.4,"spin"))
		"overhead_combo":
			for i in 3: result.append_array(strike(120,.6 if i==0 else .25,"swing",i%2==1))
			result.append_array(strike(205,.5,"overhead"))
		"mid_combo":
			result.append_array(strike(190,.65,"thrust"))
			result.append_array(strike(150,.3,"swing",true))
		"one_hit_combo":
			result.append_array(strike(120,.55,"swing"))
			result.append({"state":"recover","time":.45})
			return result
	result.append({"state":"recover","time":.9})
	return result

func visual_pose() -> int:
	if state=="stagger": return recovery_pose
	if phase.has("sprite_pose"): return int(phase.sprite_pose)
	if state=="combo_pause": return recovery_pose
	if state=="recover" and attack_name=="charge_swing" and state_time>phase_length*.3: return 11
	if state=="recover" and state_time>phase_length*.55: return recovery_pose
	return int(visual_clock*2.0)%2

func _draw() -> void:
	if health<=0 or not visible: return
	var index:=visual_pose()
	var source:=Rect2((index%4)*FRAME_SIZE,(index/4)*FRAME_SIZE,FRAME_SIZE,FRAME_SIZE)
	# Feet register at local y47, exactly the existing arena floor at home_y553.
	# Separately authored opposite views preserve anatomical left handedness.
	var tint:=Color(1.65,1.45,1.25) if hurt_flash>0 else Color.WHITE
	combat_fx.draw_behind(self)
	draw_blade_aura()
	draw_texture_rect_region(LEFT_ATLAS if facing<0 else ATLAS,FRAME_RECT,source,tint)
	draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
	draw_set_transform(Vector2.ZERO)

func draw_blade_aura() -> void:
	if state!="telegraph" and state!="charge" and state!="charge_settle": return
	var progress:=clampf(1.0-state_time/phase_length,0,1)
	# Measured steel outlines in registered cells4/5 of each authored view.
	# These coordinates are in actor space, not reflected damage-box space.
	var outline: PackedVector2Array
	if state=="telegraph":
		if facing>0:
			outline=PackedVector2Array([Vector2(10,-86),Vector2(-12,-88),Vector2(-36,-77),Vector2(-53,-53),Vector2(-29,-68),Vector2(-7,-77),Vector2(10,-78)])
		else:
			outline=PackedVector2Array([Vector2(5,-83),Vector2(-18,-84),Vector2(-37,-74),Vector2(-47,-52),Vector2(-24,-68),Vector2(5,-75)])
	elif facing>0:
		outline=PackedVector2Array([Vector2(69,-18),Vector2(88,-18),Vector2(104,-26),Vector2(118,-38),Vector2(111,-11),Vector2(97,-1),Vector2(80,-3),Vector2(69,-10)])
	else:
		outline=PackedVector2Array([Vector2(-38,-16),Vector2(-59,-23),Vector2(-74,-32),Vector2(-83,-41),Vector2(-78,-23),Vector2(-63,-12),Vector2(-38,-8)])
	outline.append(outline[0])
	var strength:=lerpf(.15,1.0,progress*progress) if state=="telegraph" else (lerpf(.6,0.0,progress) if state=="charge_settle" else lerpf(1.3,.6,progress))
	var pulse:=.9+.1*sin(visual_clock*24)
	# Draw behind the steel: a red aura hugs the blade instead of floating
	# over the head or outlining the melee volume. Release briefly flares ivory.
	draw_polyline(outline,Color(1,.08,.035,.22*strength),14)
	draw_polyline(outline,Color(1,.16,.07,.6*strength*pulse),8)
	draw_polyline(outline,Color(1,.48,.29,.85*strength),4)
	if state=="charge": draw_polyline(outline,Color(1,.9,.72,.9*strength),2)
