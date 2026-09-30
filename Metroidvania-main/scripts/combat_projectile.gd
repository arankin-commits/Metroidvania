extends Node2D

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
var return_time:=-1.0
var elapsed:=0.0
var hit_targets: Array[Node]=[]

func _ready() -> void:
	z_index=6
	add_to_group("combat_projectiles")

func _physics_process(delta: float) -> void:
	if is_instance_valid(owner_actor) and (owner_actor.health<=0 or (not friendly and not owner_actor.active)):
		queue_free()
		return
	elapsed+=delta
	lifetime-=delta
	if lifetime<=0:
		queue_free()
		return
	if return_time>=0 and elapsed>=return_time and is_instance_valid(owner_actor):
		direction=(owner_actor.global_position-global_position).normalized()
		if global_position.distance_to(owner_actor.global_position)<25:
			queue_free()
			return
	elif homing_down and is_instance_valid(target):
		var desired: Vector2=(target.global_position-global_position).normalized()
		desired.y=maxf(0.15,desired.y)
		direction=direction.lerp(desired.normalized(),minf(1.0,delta*3)).normalized()
		direction.y=maxf(0.05,direction.y)
		direction=direction.normalized()
	var previous:=global_position
	global_position+=direction*speed*delta
	var ray:=PhysicsRayQueryParameters2D.create(previous,global_position,1)
	if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
		queue_free()
		return
	var candidates: Array[Node]=[]
	if friendly:
		candidates.assign(get_tree().get_nodes_in_group("combat_targets"))
	elif is_instance_valid(target): candidates.append(target)
	for candidate in candidates:
		if not is_instance_valid(candidate) or candidate in hit_targets or candidate.is_queued_for_deletion(): continue
		if candidate.get("health")!=null and candidate.health<=0: continue
		if candidate.get("active")!=null and not candidate.active: continue
		var bounds: Rect2=candidate.combat_bounds() if candidate.has_method("combat_bounds") else Rect2(candidate.global_position-Vector2(18,28),Vector2(36,56))
		var nearest:=Geometry2D.get_closest_point_to_segment(candidate.global_position,previous,global_position)
		if bounds.grow(radius).has_point(nearest):
			hit_targets.append(candidate)
			if friendly: candidate.take_hit(damage)
			else: candidate.take_damage(damage,previous.x)
			if return_time<0:
				queue_free()
				return
	rotation=direction.angle()
	queue_redraw()

func _draw() -> void:
	var ink:=Color("f3d78a") if friendly else Color("f5ba83")
	match kind:
		"wind":
			draw_arc(Vector2(-8,0),22,-1.1,1.1,12,ink,5)
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
