extends "res://tests/forest_arrival_visual.gd"

const STAIR=preload("res://scripts/forest_stair_layout.gd")

func begin() -> void:
	world=get_tree().current_scene
	assert(world.active_save_slot==0)
	await world._change_room(6,3680)
	for x in [3900,4400,4900,5015,5200,5350,5500,5650,5800,5950,6100,6250,6400,6550,6740]:
		if not await _walk(Vector2(x,STAIR.surface_y(x)-23 if x>=5000 else 577),"live Room 2 stair ascent"): return
		if world.current_room!=6:
			_fail("Section 2 seam changed rooms")
			return
	set_meta("upper_reached",true)
	for x in [6550,6400,6250,6100,5950,5800,5650,5500,5350,5200,5015,4900,4400,3900]:
		if not await _walk(Vector2(x,STAIR.surface_y(x)-23 if x>=5000 else 577),"live Room 2 stair return"): return
	set_meta("complete",true)
