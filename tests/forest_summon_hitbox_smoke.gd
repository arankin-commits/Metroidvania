extends SceneTree
const WORLD=preload("res://scenes/forest_entry.tscn")
const SHOT=preload("res://scripts/combat_projectile.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	set_meta("active_save_slot",0)
	set_meta("forest_entry_room",7)
	var world=WORLD.instantiate()
	root.add_child(world)
	current_scene=world
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	world.player.controls_enabled=false
	var boss=world.bow_boss
	boss.set_physics_process(false)
	boss.active=false
	boss.summon_marks=boss._summon_positions()
	boss.summon_enemies()
	for enemy in boss.summons: enemy.set_physics_process(false)
	await physics_frame
	for enemy in boss.summons:
		var bounds: Rect2=enemy.combat_bounds()
		var collision: CollisionShape2D=enemy.get_child(0)
		assert(collision.shape.size==bounds.size,"Physics and combat body differ")
		assert(is_equal_approx(bounds.end.y,600),"Feet are not grounded")
		# Body below the old central scout box must accept both melee handlers.
		var low:=Rect2(enemy.global_position+Vector2(-8,35),Vector2(16,10))
		assert(not low.intersects(Rect2(enemy.global_position-Vector2(17,20),Vector2(34,40))))
		enemy.health=10
		world._on_attack(low)
		assert(enemy.health==9,"Normal sword missed enlarged lower body")
		world._on_heavy(low)
		assert(enemy.health==7.5,"Heavy sword missed enlarged lower body")
		var high:=Rect2(enemy.global_position+Vector2(-8,-50),Vector2(16,10))
		world._on_attack(high)
		assert(enemy.health==6.5,"Sword missed enlarged upper body")
		var miss:=Rect2(Vector2(bounds.end.x+10,bounds.position.y+10),Vector2(5,5))
		world._on_attack(miss)
		world._on_heavy(miss)
		assert(enemy.health==6.5,"Melee hit empty space outside body")
		var shot:=SHOT.new()
		shot.friendly=true
		shot.target=enemy
		shot.direction=Vector2.RIGHT
		shot.position=enemy.global_position+Vector2(-20,40)
		world.add_child(shot)
		shot.set_physics_process(false)
		shot._physics_process(.01)
		assert(enemy.health==5.5,"Projectile disagrees with melee on lower body")
		await process_frame
	world.queue_free()
	await process_frame
	print("FOREST_SUMMON_HITBOX_PASS: all three variants, real sword/heavy/projectile handlers, upper/lower body, outside misses, collision alignment")
	quit()
