extends Node2D
const WIND_TEXTURE=preload("res://assets/effects/goblin_wind.png")
const WIND_RADIUS=54.0
const FOREST_CHARGED = preload("res://assets/effects/forest_charged_arrow.png")
const FOREST_RAPID = [preload("res://assets/effects/forest_rapid_arrow_1.png"), preload("res://assets/effects/forest_rapid_arrow_2.png"), preload("res://assets/effects/forest_rapid_arrow_3.png"), preload("res://assets/effects/forest_rapid_arrow_4.png"), preload("res://assets/effects/forest_rapid_arrow_5.png")]
const FOREST_VOLLEY = preload("res://assets/effects/forest_volley_arrow.png")
const FOREST_IMPACT = preload("res://scripts/forest_guardian_impact.gd")

var direction:=Vector2.RIGHT
var speed:=520.0
var damage:=1.0
var radius:=8.0
var lifetime:=3.0
var target: Node
var owner_actor: Node
var kind:="arrow"
var friendly:=false
var homing_down:=false
var hover_time:=0.0
var forest_magic:=false
var charged_arrow:=false
var arrow_frame:=0
var short_hit_recovery:=false
var return_time:=-1.0
var elapsed:=0.0
var hit_targets: Array[Node]=[]

static var _pool: Array = []
const MAX_POOL_SIZE := 48

static func acquire() -> Node2D:
	var proj: Node2D = null
	while not _pool.is_empty():
		var candidate = _pool.pop_back()
		if is_instance_valid(candidate) and not candidate.is_queued_for_deletion():
			proj = candidate
			break
	if proj == null:
		var script = load("res://scripts/combat_projectile.gd")
		proj = script.new()
	else:
		proj.reset_state()
	return proj

static func clear_pool() -> void:
	for item in _pool:
		if is_instance_valid(item):
			item.queue_free()
	_pool.clear()

func reset_state() -> void:
	direction = Vector2.RIGHT
	speed = 520.0
	damage = 1.0
	radius = 8.0
	lifetime = 3.0
	target = null
	owner_actor = null
	kind = "arrow"
	friendly = false
	homing_down = false
	hover_time = 0.0
	forest_magic = false
	charged_arrow = false
	arrow_frame = 0
	short_hit_recovery = false
	return_time = -1.0
	elapsed = 0.0
	hit_targets.clear()
	visible = true
	rotation = 0.0
	set_physics_process(true)
	if not is_in_group("combat_projectiles"):
		add_to_group("combat_projectiles")

func deactivate_and_recycle() -> void:
	if get_script() == load("res://scripts/combat_projectile.gd") and _pool.size() < MAX_POOL_SIZE and is_inside_tree():
		set_physics_process(false)
		visible = false
		hit_targets.clear()
		target = null
		owner_actor = null
		var p := get_parent()
		if p != null:
			p.remove_child(self)
		_pool.append(self)
	else:
		queue_free()

func _ready() -> void:
	z_index=6
	rotation=direction.angle()
	add_to_group("combat_projectiles")

func return_position() -> Vector2:
	return owner_actor.global_position

func _physics_process(delta: float) -> void:
	if is_instance_valid(owner_actor) and ((owner_actor.get("health") != null and owner_actor.health <= 0) or (not friendly and owner_actor.get("active") != null and not owner_actor.active)):
		deactivate_and_recycle()
		return
	elapsed+=delta
	lifetime-=delta
	if lifetime<=0:
		deactivate_and_recycle()
		return
	# Volley arrows telegraph in place before tracking. Use only the part of
	# this tick after release, so movement never starts before one full second.
	if hover_time > 0.0:
		var held:=minf(delta,hover_time)
		hover_time=maxf(0.0,hover_time-held)
		delta-=held
		queue_redraw()
		if delta <= 0.000001: return
	if return_time>=0 and elapsed>=return_time and is_instance_valid(owner_actor):
		var destination := return_position()
		direction=(destination-global_position).normalized()
		if global_position.distance_to(destination)<25:
			deactivate_and_recycle()
			return
	elif homing_down:
		if is_instance_valid(target):
			var desired: Vector2=(target.global_position-global_position).normalized()
			desired.y=maxf(0.15,desired.y)
			direction=direction.lerp(desired.normalized(),minf(1.0,delta*3)).normalized()
		direction.y=maxf(0.05,direction.y)
		direction=direction.normalized()
	var previous:=global_position
	global_position+=direction*speed*delta
	var wall_offset:=direction*radius if kind=="wind" else Vector2.ZERO
	var ray:=PhysicsRayQueryParameters2D.create(previous+wall_offset,global_position+wall_offset,1)
	# Wall probes must not consume target contact before swept check
	var excludes: Array[RID] = []
	if is_instance_valid(owner_actor) and owner_actor is CollisionObject2D:
		excludes.append(owner_actor.get_rid())
	if is_instance_valid(target) and target is CollisionObject2D:
		excludes.append(target.get_rid())
	var p_node := get_tree().get_first_node_in_group("player")
	if is_instance_valid(p_node) and p_node is CollisionObject2D and not excludes.has(p_node.get_rid()):
		excludes.append(p_node.get_rid())
	ray.exclude = excludes
	var wall_hit:=get_world_2d().direct_space_state.intersect_ray(ray)
	if not wall_hit.is_empty():
		forest_impact(wall_hit.position)
		deactivate_and_recycle()
		return
	var candidates: Array = get_tree().get_nodes_in_group("combat_targets") if friendly else ([target] if is_instance_valid(target) else [])
	for candidate in candidates:
		if not is_instance_valid(candidate) or candidate in hit_targets or candidate.is_queued_for_deletion(): continue
		if candidate.get("health")!=null and candidate.health<=0: continue
		if candidate.get("active")!=null and not candidate.active: continue
		var bounds: Rect2=candidate.combat_bounds() if candidate.has_method("combat_bounds") else Rect2(candidate.global_position-Vector2(18,28),Vector2(36,56))
		var nearest:=Geometry2D.get_closest_point_to_segment(candidate.global_position,previous,global_position)
		var touches: bool = bounds.grow(radius).has_point(nearest)
		var candidate_dashing: bool = not friendly and candidate.get("dash_time") != null and (candidate.dash_time > 0.0 or (candidate.get("invulnerability") != null and candidate.invulnerability > 0.0 and candidate.get("dash_cooldown") != null and candidate.dash_cooldown > 0.3))
		if not touches and kind == "wind" and candidate_dashing:
			var wind_min_x := global_position.x - (280.0 if direction.x > 0 else 0.0)
			var wind_rect := Rect2(wind_min_x, global_position.y - radius, 280.0, radius * 2.0)
			touches = bounds.intersects(wind_rect)
		if touches:
			if candidate_dashing:
				hit_targets.append(candidate)
				continue
			forest_impact(nearest)
			hit_targets.append(candidate)
			if friendly: candidate.take_hit(damage)
			elif short_hit_recovery and candidate.has_method("take_arrow_chain_damage"):
				candidate.take_arrow_chain_damage(damage,previous.x)
			else:
				candidate.take_damage(damage,previous.x,false)
				if not friendly and is_instance_valid(owner_actor) and owner_actor.has_signal("attack_landed"):
					owner_actor.attack_landed.emit()
			if return_time<0:
				deactivate_and_recycle()
				return
	rotation=direction.angle()
	queue_redraw()

func forest_impact(point: Vector2) -> void:
	if not forest_magic: return
	var effect:=FOREST_IMPACT.new()
	effect.owner_actor=owner_actor
	effect.variant=arrow_frame%2
	get_parent().add_child(effect)
	effect.global_position=point

func _draw() -> void:
	var ink:=Color("f3d78a") if friendly else Color("f5ba83")
	if homing_down:
		ink=Color("a8faff")
		if hover_time>0:
			draw_circle(Vector2.ZERO,radius+5,Color(0.2,0.9,1.0,0.16+0.08*sin(elapsed*10)))
	if forest_magic and kind=="arrow":
		if homing_down: draw_texture_rect(FOREST_VOLLEY,Rect2(-24,-6,40,12),false)
		elif charged_arrow: draw_texture_rect(FOREST_CHARGED,Rect2(-160,-18,180,36),false)
		else: draw_texture_rect(FOREST_RAPID[clampi(arrow_frame,0,4)],Rect2(-46,-8,62,16),false)
		return
	match kind:
		"wind":
			draw_wind()
		"beam":
			draw_rect(Rect2(-25,-radius,50,radius*2),Color("ee8148"))
			draw_rect(Rect2(-18,-radius*.45,36,radius*.9),Color("fff0ae"))
		"fist":
			draw_rect(Rect2(-15,-14,30,28),Color("9ba99d"))
			for x in [-10,-3,4]: draw_line(Vector2(x,-12),Vector2(x,0),Color("405d60"),3)
			if is_instance_valid(owner_actor):
				var anchor:=to_local(owner_actor.global_position+Vector2(20,0))
				draw_line(Vector2(-15,0),anchor,Color("a2a89a"),3)
				var length:=anchor.length()
				for i in range(1,int(length/16)):
					draw_rect(Rect2(anchor.normalized()*i*16-Vector2(4,3),Vector2(8,6)),Color("c2bda1"),false,2)
		_:
			draw_line(Vector2(-14,0),Vector2(12,0),ink,3)
			draw_colored_polygon(PackedVector2Array([Vector2(16,0),Vector2(8,-5),Vector2(8,5)]),ink)

func draw_wind() -> void:
	# The ivory leading crest stays at the radius54 contact core; smoky
	# trailing curls are translucent decoration, not extra damage range.
	draw_texture_rect(WIND_TEXTURE,Rect2(-273,-54,300,108),false,Color(.63,.66,.69,.25))
	draw_texture_rect(WIND_TEXTURE,Rect2(-141,-54,195,108),false,Color.WHITE)
	for i in 3:
		var y:=sin(elapsed*19+i*2.3)*30
		draw_rect(Rect2(-105-i*15,y,3,2),Color(.91,.89,.82,.3))
