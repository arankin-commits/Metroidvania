extends SceneTree

const INHERITANCE = preload("res://scripts/inheritance_state.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var inherited = INHERITANCE.new()
	if inherited.has_ability("heavy_break"):
		_fail("Heavy break must start locked")
		return
	inherited.on_boss_defeated("unknown_boss")
	if inherited.has_ability("heavy_break"):
		_fail("An unrelated boss granted heavy break")
		return
	change_scene_to_file("res://scenes/tutorial.tscn")
	await process_frame
	await process_frame
	var world = current_scene
	var hitbox := Rect2(3840, 455, 60, 160)
	world.boss_defeated = true
	world._on_player_heavy_attacked(hitbox)
	if world.wall_broken:
		_fail("Boss flag bypassed the inheritance gate")
		return
	world.boss_defeated = false
	world.boss.active = true
	world.boss.take_hit(100)
	if not world.inheritance.has_ability("heavy_break") or not world.player.has_heavy:
		_fail("Warden defeat did not grant heavy break and preserve heavy attack")
		return
	world.boss_defeated = false
	world._on_player_heavy_attacked(hitbox)
	if not world.wall_broken or not world.player.has_dash:
		_fail("Inherited heavy break did not open the wall or starting dash changed")
		return
	print("INHERITANCE_NAVIGATION_SMOKE_PASS")
	world.queue_free()
	await process_frame
	await process_frame
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
