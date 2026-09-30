extends Node
var complete:=false

func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame

func snap(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://design/reviews/boss-combat-%s.png"%label)

func until_state(boss: Node2D,value: String) -> void:
	for i in 400:
		await get_tree().physics_frame
		if boss.state==value: return
	set_meta("failure","Never reached "+value)

func begin() -> void:
	get_tree().set_meta("active_save_slot",0)
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")
	await frames(10)
	var w:=get_tree().current_scene
	w.current_room=4
	w.player.position=Vector2(3370,577)
	w.player.invulnerability=1000
	w._set_camera_room()
	w.boss.active=true
	w.boss.begin_attack("overhead_combo")
	await until_state(w.boss,"overhead")
	await snap("goblin-overhead")
	w.boss.begin_attack("charge_swing")
	await until_state(w.boss,"charge")
	await frames(5)
	await snap("goblin-wind")
	w.boss.begin_attack("jump_slam")
	await until_state(w.boss,"jump")
	await frames(25)
	await snap("goblin-jump")
	w._on_boss_defeated()
	get_tree().set_meta("forest_entry_room",7)
	get_tree().change_scene_to_file("res://scenes/forest_entry.tscn")
	await frames(12)
	w=get_tree().current_scene
	w.player.position=Vector2(19920,577)
	w.player.has_scimitar=true
	w.player.has_heavy=true
	w.player.has_wrath=true
	w.player.equipped_weapon="scimitar"
	w.player.invulnerability=1000
	w._set_camera()
	w.bow_boss.active=true
	w.bow_boss.begin_attack("summon")
	await until_state(w.bow_boss,"summon")
	await frames(25)
	await snap("hunter-summons")
	w.bow_boss.begin_attack("rapid_fire")
	await until_state(w.bow_boss,"shoot")
	await frames(27)
	await snap("hunter-rapid")
	w.bow_boss.health=4
	w.bow_boss.begin_attack("flipping_volley")
	await until_state(w.bow_boss,"flipping_volley")
	await frames(42)
	await snap("hunter-volley")
	w._on_hunter_defeated()
	await w._change_room(10,23700)
	w.player.invulnerability=1000
	w.temple_guardian.active=true
	w.temple_guardian.health=3
	w.temple_guardian.begin_attack("fire")
	await frames(35)
	await snap("guardian-charge")
	await until_state(w.temple_guardian,"fire")
	await frames(10)
	await snap("guardian-fire")
	w._on_guardian_defeated()
	await w._change_room(9,24695)
	w.player.equipped_weapon="gauntlet"
	await frames(40)
	await snap("gauntlet-reward")
	complete=true
	set_meta("complete",true)
