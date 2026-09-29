extends Node
var complete := false
func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame
func snap(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/reviews/forest-guardian-%s.png" % label)
func begin() -> void:
	get_tree().set_meta("active_save_slot",0)
	get_tree().set_meta("forest_entry_room",7)
	get_tree().change_scene_to_file("res://scenes/forest_entry.tscn")
	await get_tree().scene_changed
	await frames(15)
	var world := get_tree().current_scene
	var boss = world.bow_boss
	world.player.controls_enabled = false
	world.player.invulnerability = 1000
	for direction in [-1,1]:
		boss.active = true
		boss.facing = direction
		boss.position = Vector2(20200,553)
		world.player.position = Vector2(20200+direction*240,577)
		world._set_camera()
		boss.state="idle"
		boss.state_time=100
		boss.phase={}
		await frames(15)
		await snap("%s-idle" % direction)
		for name in ["charged_arrow","rapid_fire","knife_combo","retreat_dash","flipping_volley","summon"]:
			boss.reset_encounter()
			boss.active = true
			boss.position = Vector2(20200,553)
			world.player.position = Vector2(20200+direction*240,577)
			boss.begin_attack(name)
			var seen := {}
			for i in 260:
				await frames(1)
				var pose: int = boss.sprite_pose()
				if not seen.has(pose):
					seen[pose] = true
					await snap("%s-%s-pose-%s" % [direction,name,pose])
				if boss.state=="idle": break
			if name=="flipping_volley":
				await frames(8)
				await snap("%s-volley-release" % direction)
			if name=="summon":
				await frames(30)
				await snap("%s-allies" % direction)
			for shot in get_tree().get_nodes_in_group("combat_projectiles"): shot.queue_free()
			boss.clear_summons()
	boss.active = false
	complete = true
