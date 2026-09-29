extends SceneTree

const CELL := 128
const FOOT := Vector2i(64, 96)
# One scale for the whole body; effects and trailing cloak do not set height.
const SCALE := 58.0 / 226.0
const CENTERS := [190, 500, 802, 1110, 170, 475, 810, 1100, 199, 485, 753, 1122, 168, 466, 812, 1138]
const REGIONS := [Rect2i(90,65,150,240), Rect2i(375,65,175,240), Rect2i(665,65,205,240), Rect2i(985,65,200,240),
	Rect2i(45,385,215,220), Rect2i(350,385,220,220), Rect2i(660,430,260,175), Rect2i(1000,345,180,245),
	Rect2i(100,640,140,275), Rect2i(370,690,215,235), Rect2i(640,735,342,190), Rect2i(982,625,248,300),
	Rect2i(35,970,280,255), Rect2i(335,1045,310,180), Rect2i(720,960,155,265), Rect2i(995,1060,195,165)]

func _initialize() -> void:
	var source := Image.load_from_file("res://design/references/player/hooded-player-matte.png")
	assert(source != null)
	source.convert(Image.FORMAT_RGBA8)
	for y in source.get_height():
		for x in source.get_width():
			var c := source.get_pixel(x, y)
			if c.r > 0.65 and c.b > 0.65 and c.g < 0.4:
				source.set_pixel(x, y, Color.TRANSPARENT)
	var atlas := Image.create(CELL * 4, CELL * 4, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	for index in 16:
		var region: Rect2i = REGIONS[index]
		var pose := source.get_region(region)
		var used := pose.get_used_rect()
		assert(used.size.x > 0 and used.size.y > 0, "Empty player pose")
		var center: int = CENTERS[index] - region.position.x
		# The generated unsheathed idle is slightly shorter; calibrate its body,
		# excluding the blade. Moving/crouching poses retain the shared scale.
		var body_scale := 58.0 / 216.0 if index == 9 else SCALE
		pose.resize(roundi(region.size.x * body_scale), roundi(region.size.y * body_scale), Image.INTERPOLATE_NEAREST)
		var offset := Vector2i(FOOT.x - roundi(center * body_scale), FOOT.y - pose.get_used_rect().end.y)
		assert(offset.x >= 0 and offset.y >= 0 and offset.x + pose.get_width() < CELL and offset.y + pose.get_height() < CELL)
		atlas.blit_rect(pose, Rect2i(Vector2i.ZERO, pose.get_size()), Vector2i(index % 4, index / 4) * CELL + offset)
		print("Pose %d bounds %s" % [index, atlas.get_region(Rect2i(Vector2i(index % 4, index / 4) * CELL, Vector2i(CELL, CELL))).get_used_rect()])
	assert(atlas.save_png("res://assets/characters/hooded_player_atlas.png") == OK)
	print("PLAYER_ATLAS_READY")
	quit()
