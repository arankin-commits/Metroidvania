extends "res://tests/forest_upper_gallery_route.gd"

func _new_dash_route() -> Node:
	return load("res://tests/forest_preboss_floor_route.gd").new()
