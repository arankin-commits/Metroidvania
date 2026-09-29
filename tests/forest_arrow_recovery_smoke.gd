extends SceneTree
const PLAYER=preload("res://scripts/player.gd")
const BOSS=preload("res://scripts/forest_hunter_combat.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var arena:=Node2D.new()
	root.add_child(arena)
	var player:=PLAYER.new()
	arena.add_child(player)
	player.set_physics_process(false)
	player.health=20
	var boss:=BOSS.new()
	boss.player=player
	arena.add_child(boss)
	boss.set_physics_process(false)
	boss.active=true
	for attack in ["rapid_fire","flipping_volley","charged_arrow"]:
		boss.attack_name=attack
		player.health=20
		player.invulnerability=0
		var count:=3 if attack=="flipping_volley" else 5
		for i in count:
			var shot= boss.fire("arrow",1,attack=="flipping_volley")
			shot.set_physics_process(false)
			shot.hover_time=0
			shot.direction=Vector2.DOWN if shot.homing_down else Vector2.RIGHT
			shot.position=player.position-shot.direction*20
			shot._physics_process(.04)
			assert(shot.is_queued_for_deletion(),"Arrow missed stationary player")
			if attack!="charged_arrow":
				assert(is_equal_approx(player.invulnerability,.1))
				assert(player.velocity==Vector2.ZERO,"Chain hit launched player out of lane")
			player.invulnerability=maxf(0,player.invulnerability-.16)
			await process_frame
		assert(player.health==20-count if attack!="charged_arrow" else player.health==19,"Wrong sequence damage")
	player.invulnerability=0
	player.take_damage(1,-100)
	assert(player.invulnerability==1 and player.velocity.y==-260,"Normal damage response changed")
	player.take_arrow_chain_damage(1,-100)
	assert(player.health==18 and player.invulnerability==1,"Chain arrow bypassed normal immunity")
	arena.queue_free()
	await process_frame
	print("FOREST_ARROW_RECOVERY_PASS: all five rapid arrows and three volley arrows hit stationary player; charged/normal recovery unchanged")
	quit()
