extends "res://tests/forest_smash_corridor_visual.gd"

func begin() -> void:
	world=get_tree().current_scene
	assert(world.active_save_slot==0)
	await world._change_room(6,3690)
	for x in [3900,4500,4980,5350,5800,6250,6740]:
		if not await _walk(Vector2(x,STAIR.surface_y(x)-23 if x>=5000 else 577),"whole-room continuous ascent"): return
	if not await run_route(): return
	set_meta("global_complete",true)
