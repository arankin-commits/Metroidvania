extends Node
var complete:=false
func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame
func snap(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/reviews/cave-boss-%s.png"%label)
func until_state(boss: Node2D,value: String) -> void:
	for i in 400:
		await get_tree().physics_frame
		if boss.state==value: return
	assert(false,"Missing phase "+value)
func begin() -> void:
	get_tree().set_meta("active_save_slot",0)
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")
	await get_tree().scene_changed
	await frames(12)
	var w:=get_tree().current_scene
	w.current_room=4
	w.player.invulnerability=1000
	w.player.controls_enabled=false
	for direction in [-1,1]:
		for attack in ["mid_combo","overhead_combo","spin_combo","charge_swing","jump_slam"]:
			for shot in get_tree().get_nodes_in_group("combat_projectiles"): shot.queue_free()
			w.player.position=Vector2(3510+direction*(330 if attack=="charge_swing" else 200),577)
			w.player.reset_movement_state()
			w.boss.position=Vector2(3510,553)
			w.boss.active=true
			w._set_camera_room()
			w.boss.begin_attack(attack)
			if attack=="charge_swing":
				await frames(45)
				await snap("%s-charging"%["left" if direction<0 else "right"])
			var state="thrust" if attack=="mid_combo" else ("overhead" if attack=="overhead_combo" else ("spin" if attack=="spin_combo" else ("charge" if attack=="charge_swing" else "jump")))
			await until_state(w.boss,state)
			await frames(5 if state!="jump" else 25)
			await snap("%s-%s"%["left" if direction<0 else "right",state])
			if attack=="charge_swing":
				await frames(12)
				await snap("%s-wind"%["left" if direction<0 else "right"])
			if attack=="jump_slam":
				await until_state(w.boss,"slam")
				await frames(6)
				await snap("%s-impact"%["left" if direction<0 else "right"])
	w.boss.active=false
	complete=true
