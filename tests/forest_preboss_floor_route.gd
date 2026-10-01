extends "res://tests/forest_upper_gallery_route.gd"
const N=preload("res://scripts/forest_dash_galleries_layout.gd")

func run_route() -> bool:
	world=get_tree().current_scene
	if world.player.has_dash: _fail("Pre-boss fixture has dash upgrade"); return false
	for x in [13850,14300,14800,15300,15800,16120]:
		if not await _walk(Vector2(x,N.FLOOR-23),"pre-boss floor below optional dash galleries"): return false
	set_meta("complete",true)
	return true
