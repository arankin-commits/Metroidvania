extends SceneTree
const BOSS=preload("res://scripts/goblin_boss.gd")
const PLAYER=preload("res://scripts/player.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var arena:=Node2D.new()
	root.add_child(arena)
	var player:=PLAYER.new()
	player.controls_enabled=false
	player.invulnerability=1000
	arena.add_child(player)
	var boss:=BOSS.new()
	boss.position=Vector2(1000,553)
	boss.player=player
	boss.arena_bounds=Vector2(100,1900)
	arena.add_child(boss)
	boss.active=true
	for direction in [-1,1]:
		for attack in ["mid_combo","spin_combo","overhead_combo","charge_swing"]:
			boss.position=Vector2(1000,553)
			player.position=Vector2(1000+direction*300,577)
			boss.begin_attack(attack)
			var advance:=0.0
			for frame in 600:
				var previous:=boss.position
				var moving:=boss.phase.has("move")
				boss._physics_process(1.0/120.0)
				var step:=boss.position.x-previous.x
				assert(step*direction>=-.001,"Combo moved backward")
				if not moving: assert(absf(step)<.001,"Anticipation/recovery moved")
				advance+=step*direction
				if boss.state=="idle": break
			var expected:=168.0 if attack=="mid_combo" else (228.0 if attack=="spin_combo" else 128.0)
			if attack=="charge_swing": expected=64.0
			assert(absf(advance-expected)<.01,"Combo momentum or thrust missing: %s %s"%[attack,advance])
		# A real charged melee contact pauses only this boss, without repeated
		# damage or freezing world time/player input. Missing attacks do not pause.
		boss.position=Vector2(1000,553)
		player.position=Vector2(1000+direction*80,577)
		player.health=5
		player.invulnerability=0
		boss.begin_attack("charge_swing")
		for frame in 160:
			boss._physics_process(.01)
			if boss.state=="charge": break
		assert(boss.state=="charge" and player.health==5,"Charge anticipation damages")
		boss._physics_process(.01)
		assert(absf(boss.position.x-1000)>12,"Release did not burst forward")
		assert(boss.charge_hit_pause>0 and player.health==4,"Contact pause or melee damage missing")
		var held_position:=boss.position
		var held_time:=boss.state_time
		boss._physics_process(.02)
		assert(boss.position==held_position and boss.state_time==held_time,"Contact pose did not hold")
		assert(player.health==4 and Engine.time_scale==1.0,"Pause repeated damage or changed world time")
		boss.reset_encounter()
		assert(boss.charge_hit_pause==0,"Contact pause survived reset")
		boss.active=true
		boss.state_time=100
		player.invulnerability=1000
		player.position=Vector2(1000+direction*300,577)
		# Grounded lunge must stop before solid walls, in both directions.
		var wall:=StaticBody2D.new()
		wall.position=Vector2(1000+direction*120,530)
		var collider:=CollisionShape2D.new()
		var shape:=RectangleShape2D.new()
		shape.size=Vector2(20,200)
		collider.shape=shape
		wall.add_child(collider)
		arena.add_child(wall)
		await physics_frame
		boss.position=Vector2(1000,553)
		var limited:=boss.limit_ground_motion(Vector2(1000+direction*140,553))
		assert((limited.x-1000)*direction<=44.01,"Lunge penetrates wall")
		assert((limited.x-1000)*direction>40,"Wall test did not allow approach")
		wall.queue_free()
		await physics_frame
	boss.active=false
	print("CAVE_BOSS_MOMENTUM_PASS: bidirectional combo movement, dash thrust, harmless windup/recovery, wall stop")
	quit()
