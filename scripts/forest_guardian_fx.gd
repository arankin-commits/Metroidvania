extends RefCounted
const ROOTS = [preload("res://assets/effects/forest_roots_1.png"), preload("res://assets/effects/forest_roots_2.png"), preload("res://assets/effects/forest_roots_3.png")]
var ghosts: Array[Dictionary] = []
var dust: Array[Dictionary] = []
var emission := 0.0

func clear() -> void:
	ghosts.clear()
	dust.clear()
	emission = 0

func tick(boss: Node2D, delta: float) -> void:
	for ghost in ghosts: ghost.life -= delta
	ghosts = ghosts.filter(func(g: Dictionary): return g.life > 0)
	for mote in dust:
		mote.life -= delta
		mote.velocity.y += 180 * delta
		mote.position += mote.velocity * delta
	dust = dust.filter(func(m: Dictionary): return m.life > 0)
	if boss.state in ["air_dash", "flipping_volley"]:
		emission -= delta
		if emission <= 0:
			emission = 0.05
			if ghosts.size() >= 4: ghosts.pop_front()
			ghosts.append({"position":boss.global_position, "texture":boss.sprite_texture(), "pose":boss.sprite_pose(), "life":0.22})

func land(boss: Node2D) -> void:
	for i in 16:
		dust.append({"position":boss.global_position + Vector2(randf_range(-24,24),47), "velocity":Vector2(randf_range(-95,95),randf_range(-95,-25)), "life":0.4, "size":randf_range(2,5)})

func draw(boss: Node2D) -> void:
	for ghost in ghosts:
		var rect: Rect2 = boss.FRAME_RECT
		rect.position += ghost.position - boss.global_position
		var index: int = ghost.pose
		boss.draw_texture_rect_region(ghost.texture, rect, Rect2(Vector2(index%4,index/4)*boss.CELL,Vector2(boss.CELL,boss.CELL)), Color(0.45,1,0.92,ghost.life/0.22*0.22))
	for mote in dust:
		boss.draw_rect(Rect2(mote.position-boss.global_position,Vector2.ONE*mote.size),Color(0.48,0.68,0.65,mote.life/0.4*0.65))
	if boss.state == "tell_summon":
		var progress: float = clampf(1.0-boss.state_time/boss.phase_length,0,1)
		for i in boss.summon_marks.size():
			var point: Vector2 = boss.summon_marks[i]-boss.global_position+Vector2(0,boss.SCOUT.HEIGHT/2)
			var size := Vector2(120,90)*clampf(progress*1.8,0.2,1)
			boss.draw_texture_rect(ROOTS[i%3],Rect2(point-Vector2(size.x/2,size.y),size),false,Color(0.7,1,0.9,0.7))
