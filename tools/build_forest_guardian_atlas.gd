extends SceneTree
const CELL := 320
const FOOT := Vector2i(160, 240)
const REGIONS := [Rect2i(30,188,610,565), Rect2i(660,55,204,146), Rect2i(910,74,157,128),
	Rect2i(687,267,197,121), Rect2i(966,269,207,121), Rect2i(1244,269,161,121),
	Rect2i(650,450,100,96), Rect2i(832,450,114,96), Rect2i(1040,450,130,96), Rect2i(1250,450,128,96), Rect2i(1440,450,132,96),
	Rect2i(650,600,120,144), Rect2i(770,610,192,134), Rect2i(965,641,193,103),
	Rect2i(1162,602,158,144), Rect2i(1323,603,193,100), Rect2i(1465,649,168,97),
	Rect2i(685,795,260,110), Rect2i(1000,799,98,95), Rect2i(1192,800,105,98)]
const CENTERS := [293,735,986,779,1054,1310,704,887,1100,1309,1500,724,837,1044,1248,1425,1564,827,1053,1248]
const BOTTOMS := [747,193,193,380,380,380,539,539,539,539,539,737,737,737,723,687,737,880,882,889]
const LEFT_REGIONS := [Rect2i(20,188,560,565), Rect2i(634,55,203,146), Rect2i(910,74,157,128),
	Rect2i(661,267,212,121), Rect2i(966,269,207,121), Rect2i(1320,269,190,121),
	Rect2i(661,450,132,96), Rect2i(877,450,130,96), Rect2i(1090,450,130,96), Rect2i(1295,450,145,96), Rect2i(1495,450,138,96),
	Rect2i(628,600,128,144), Rect2i(760,610,164,134), Rect2i(940,641,187,103),
	Rect2i(1143,602,195,144), Rect2i(1323,603,193,100), Rect2i(1457,649,182,97),
	Rect2i(640,795,270,110), Rect2i(966,799,124,99), Rect2i(1188,800,120,102)]
const LEFT_CENTERS := [300,750,996,785,1058,1433,743,949,1160,1370,1585,690,866,1060,1248,1425,1564,754,1032,1248]
const PROPS := {
	"forest_charged_arrow": Rect2i(1400,295,245,82),
	"forest_rapid_arrow_1": Rect2i(750,470,68,60), "forest_rapid_arrow_2": Rect2i(946,470,78,63),
	"forest_rapid_arrow_3": Rect2i(1171,467,70,67), "forest_rapid_arrow_4": Rect2i(1378,468,60,66), "forest_rapid_arrow_5": Rect2i(1572,466,65,66),
	"forest_volley_arrow": Rect2i(1135,801,29,59),
	"forest_volley_impact_1": Rect2i(1375,795,123,124), "forest_volley_impact_2": Rect2i(1500,795,125,124),
	"forest_roots_1": Rect2i(807,122,106,85), "forest_roots_2": Rect2i(1039,79,103,131), "forest_roots_3": Rect2i(1128,69,129,140)}
const ALLIES := [Rect2i(1270,107,126,96), Rect2i(1398,64,121,133), Rect2i(1535,108,101,89)]

func clean(path: String) -> Image:
	var source := Image.load_from_file(path)
	assert(source != null and source.get_size() == Vector2i(1672, 941))
	source.convert(Image.FORMAT_RGBA8)
	for y in source.get_height():
		for x in source.get_width():
			var c := source.get_pixel(x, y)
			var alpha := 1.0 - clampf(minf(c.r - c.g, c.b - c.g), 0, 1)
			if alpha < 0.08: source.set_pixel(x, y, Color.TRANSPARENT)
			else: source.set_pixel(x, y, Color(clampf((c.r - 1 + alpha) / alpha, 0, 1), c.g / alpha, clampf((c.b - 1 + alpha) / alpha, 0, 1), alpha))
	return source

func _initialize() -> void:
	var source := clean("res://design/references/forest-boss/forest-guardian-matte.png")
	for side in ["right", "left"]:
		var path := "res://design/references/forest-boss/forest-guardian-%s-matte.png" % side
		var image := source if side == "right" else clean(path)
		var atlas := Image.create(CELL * 4, CELL * 5, false, Image.FORMAT_RGBA8)
		atlas.fill(Color.TRANSPARENT)
		for index in REGIONS.size():
			var region: Rect2i = REGIONS[index] if side == "right" else LEFT_REGIONS[index]
			var center: int = CENTERS[index] if side == "right" else LEFT_CENTERS[index]
			var pose := image.get_region(region)
			for y in pose.get_height():
				for x in pose.get_width():
					var point := Vector2i(x, y) + region.position
					var remove := false
					if side == "right":
						if index == 1: remove = point.x >= 824 and point.y >= 155
						if index == 2: remove = point.x >= 1040 and point.y >= 129
						if index == 16: remove = point.x < 1500 and point.y < 697
					else:
						if index == 2: remove = point.x >= 1048 and point.y >= 146
						if index == 9: remove = point.x >= 1429 and point.y < 517
						if index == 16: remove = point.x < 1520 and point.y < 700
						if index == 18: remove = point.x >= 1080
						if index == 13 and point.x >= 1110 and point.y > 690:
							var c := pose.get_pixel(x, y)
							remove = c.r > 0.6 and c.g > 0.65 and c.b > 0.65
					if remove: pose.set_pixel(x, y, Color.TRANSPARENT)
			var scale := 99.0 / 510.0 if index == 0 else 1.0
			pose.resize(roundi(region.size.x * scale), roundi(region.size.y * scale), Image.INTERPOLATE_NEAREST)
			var offset := FOOT - Vector2i(roundi((center - region.position.x) * scale), roundi((BOTTOMS[index] - region.position.y) * scale))
			assert(offset.x >= 0 and offset.y >= 0 and offset.x + pose.get_width() < CELL and offset.y + pose.get_height() < CELL, "Clipped Forest Guardian frame %d" % index)
			atlas.blit_rect(pose, Rect2i(Vector2i.ZERO, pose.get_size()), Vector2i(index % 4, index / 4) * CELL + offset)
		assert(atlas.save_png("res://assets/characters/forest_guardian_%s.png" % side) == OK)
	for name in PROPS:
		var prop := source.get_region(PROPS[name])
		assert(prop.get_used_rect().size.x > 5 and prop.get_used_rect().size.y > 5)
		prop = prop.get_region(prop.get_used_rect())
		if name == "forest_volley_arrow": prop.rotate_90(COUNTERCLOCKWISE)
		assert(prop.save_png("res://assets/effects/%s.png" % name) == OK)
	var allies := Image.create(256 * 3, 256, false, Image.FORMAT_RGBA8)
	allies.fill(Color.TRANSPARENT)
	for index in ALLIES.size():
		var sprite := source.get_region(ALLIES[index])
		sprite = sprite.get_region(sprite.get_used_rect())
		var scale := 119.0 / sprite.get_height()
		sprite.resize(roundi(sprite.get_width() * scale), 119, Image.INTERPOLATE_NEAREST)
		allies.blit_rect(sprite, Rect2i(Vector2i.ZERO, sprite.get_size()), Vector2i(index * 256 + 128 - sprite.get_width() / 2, 192 - sprite.get_height()))
	assert(allies.save_png("res://assets/characters/forest_guardian_allies.png") == OK)
	print("FOREST_GUARDIAN_ASSETS_READY: 20 supplied Guardian poses in both authored facings, 3 allies, 12 reference effects")
	quit()
