extends SceneTree

const SCENE := preload("res://scenes/gloamweaver_boss_test.tscn")
func _initialize() -> void: call_deferred("run")
func fail(message: String) -> void: push_error(message); quit(1)
func frames(count: int) -> void:
	for _frame in count: await physics_frame
func run() -> void:
	var arena := SCENE.instantiate(); root.add_child(arena); await frames(2)
	var boss: CharacterBody2D = arena.get_node("Gloamweaver"); var player: CharacterBody2D = arena.get_node("Player")
	player.controls_enabled = false; boss.force_attack("swing"); await frames(20)
	if boss.state != "swing_prepare" and boss.state != "swing_hang": fail("Gloamweaver did not enter swing tell"); return
	boss.force_attack("trap"); await frames(70)
	if arena.get_tree().get_nodes_in_group("gloamweaver_traps").is_empty(): fail("Gloamweaver trap did not arm"); return
	boss.take_hit(99.0); await frames(2)
	if boss.active or not arena.get_tree().get_nodes_in_group("gloamweaver_traps").is_empty(): fail("Gloamweaver defeat did not clean owned traps"); return
	print("GLOAMWEAVER_BOSS_SMOKE_PASS"); quit()