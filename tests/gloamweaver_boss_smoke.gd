extends SceneTree

const SCENE := preload("res://scenes/gloamweaver_boss_test.tscn")
func _initialize() -> void: call_deferred("run")
func fail(message: String) -> void: push_error(message); quit(1)
func frames(count: int) -> void:
	for _frame in count: await physics_frame
func run() -> void:
	var arena := SCENE.instantiate(); root.add_child(arena); await frames(2)
	var boss: CharacterBody2D = arena.get_node("Gloamweaver"); var player: CharacterBody2D = arena.get_node("Player")
	player.controls_enabled = false; player.global_position = Vector2(700.0, 567.0); boss.force_attack("bite"); await frames(20)
	if boss.state != "bite_tell" and boss.state != "bite_active": fail("Gloamweaver did not enter bite tell"); return
	boss.force_attack("charge"); await frames(80)
	if boss.state == "ceiling_ready" or boss.state == "swing_rake": fail("Retired ceiling state became reachable"); return
	boss.force_attack("trap"); await frames(70)
	if arena.get_tree().get_nodes_in_group("gloamweaver_traps").is_empty(): fail("Gloamweaver trap did not arm"); return
	player.global_position = Vector2(560.0, 567.0); await frames(10)
	if player.gloamweaver_slow_until <= Time.get_ticks_msec() / 1000.0: fail("Gloamweaver trap did not apply grounded slow"); return
	boss.take_hit(99.0); await frames(2)
	if boss.active or not arena.get_tree().get_nodes_in_group("gloamweaver_traps").is_empty(): fail("Gloamweaver defeat did not clean owned traps"); return
	print("GLOAMWEAVER_BOSS_SMOKE_PASS"); quit()