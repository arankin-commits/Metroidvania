extends SceneTree

const GUARDIAN = preload("res://scripts/forest_temple_guardian.gd")

func _initialize() -> void: call_deferred("run")

func snap(label: String) -> void:
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://design/reviews/temple-guardian-%s.png" % label)

func run() -> void:
	var gallery: Array[Node2D] = []
	for index in 13:
		var boss := GUARDIAN.new()
		boss.position = Vector2(160+(index%4)*275,130+(index/4)*155)
		root.add_child(boss)
		boss.set_physics_process(false)
		boss.facing=1
		boss.state="review"
		boss.phase={"pose":index}
		boss.queue_redraw()
		gallery.append(boss)
	await snap("poses-right")
	for boss in gallery:
		boss.facing=-1
		boss.queue_redraw()
	await snap("poses-left")
	for boss in gallery: boss.queue_free()
	await process_frame
	set_meta("active_save_slot",0)
	set_meta("forest_entry_room",10)
	change_scene_to_file("res://scenes/forest_entry.tscn")
	for tick in 12: await physics_frame
	var world := current_scene
	world.player.position = Vector2(23700,577)
	world.player.invulnerability=1000
	world._set_camera()
	var boss: Node2D = world.temple_guardian
	boss.active=true
	boss.set_physics_process(false)
	boss.phase={}
	boss.state="idle"
	boss.queue_redraw()
	for tick in 25: await physics_frame
	await snap("arena-idle")
	for direction in [-1,1]:
		world.player.position.x=boss.position.x+direction*250
		world._set_camera()
		for config in [["rocket_punch","rocket_extended"],["fire","charge_fire"],["fire","fire"],["punch_combo","punch"],["slam","slam"]]:
			boss.health=3 if config[0]=="fire" else 6
			boss.begin_attack(config[0])
			for tick in 200:
				boss._physics_process(1.0/60.0)
				await physics_frame
				if boss.state==config[1]: break
			assert(boss.state==config[1])
			await snap("%s-%s" % [config[1],direction])
			for shot in get_nodes_in_group("combat_projectiles"): shot.queue_free()
			await process_frame
	print("TEMPLE_GUARDIAN_VISUAL_PASS: 13 poses in both facings, actual temple arena and all four attacks")
	quit()
