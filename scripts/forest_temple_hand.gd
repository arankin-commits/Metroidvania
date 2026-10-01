extends "res://scripts/forest_chamber.gd"
const LAYOUT=preload("res://scripts/forest_dash_galleries_layout.gd")

func _ready() -> void:
	name="TempleHandSanctuary"
	art=preload("res://assets/forest_temple_hand_open_environment.png")
	bounds=LAYOUT.HAND_BOUNDS
	source_floor=665
	close_left=true
	close_right=true
	super._ready()
	chair=Sprite2D.new()
	chair.texture=preload("res://assets/hand_chair.png")
	chair.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	chair.scale=Vector2(0.096,0.096)
	chair.position=LAYOUT.HAND-Vector2(0,24)
	chair.z_index=2
	add_child(chair)
