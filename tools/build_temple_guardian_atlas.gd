extends SceneTree

const CELL := 384
const FOOT := Vector2i(160, 272)
const SCALE := 144.0 / 148.0
# Measured delivered cutouts, not the original storyboard's grid.
const REGIONS := [Rect2i(1488,190,176,162), Rect2i(538,176,190,176),
	Rect2i(735,174,172,178), Rect2i(1230,210,176,142),
	Rect2i(536,425,194,190), Rect2i(740,420,198,196),
	Rect2i(940,418,270,198), Rect2i(1484,430,182,188),
	Rect2i(500,688,232,169), Rect2i(710,695,216,162),
	Rect2i(914,695,265,168), Rect2i(1178,648,188,210),
	Rect2i(1358,640,306,224)]
const CENTERS := [1570,628,820,1312,632,837,1040,1574,601,811,1039,1270,1490]
const BOTTOMS := [344,342,342,344,604,604,604,606,848,848,850,850,850]
const NAMES := ["idle", "rocket_windup", "rocket_launch", "rocket_retract",
	"charge_start", "charge_full", "fire", "recover", "punch_1", "punch_2",
	"punch_3", "slam_raise", "slam_impact"]

func _initialize() -> void:
	var source := Image.load_from_file("res://design/references/temple-boss/temple-guardian-actions.png")
	assert(source != null and source.get_size() == Vector2i(1672,941))
	source.convert(Image.FORMAT_RGBA8)
	var atlas := Image.create(CELL * 4, CELL * 4, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	var catalog: Array = []
	for index in REGIONS.size():
		var region: Rect2i = REGIONS[index]
		var frame := source.get_region(region)
		# Separate the third punch's dust from the second punch's trailing hand,
		# and isolate body recoil from the remote returning fist/chain.
		for y in frame.get_height():
			for x in frame.get_width():
				var point := Vector2i(x,y) + region.position
				var remove := (index == 8 and point.x >= 714) or (index == 9 and point.x < 732 and point.y < 832)
				remove = remove or (index == 10 and point.x < 960 and point.y < 800)
				remove = remove or (index == 9 and point.x >= 914 and point.y >= 795)
				if index == 2 and point.x >= 852: remove = true
				if index == 3 and point.x > 1376 and point.y < 300: remove = true
				if index == 6 and point.x > 1140: remove = true
				if remove: frame.set_pixel(x,y,Color.TRANSPARENT)
				elif index == 6 and point.x > 1108:
					var color := frame.get_pixel(x,y)
					color.a *= clampf(float(1140-point.x)/32.0,0,1)
					frame.set_pixel(x,y,color)
		var size := Vector2i(roundi(region.size.x * SCALE), roundi(region.size.y * SCALE))
		frame.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
		var offset := FOOT - Vector2i(roundi((CENTERS[index]-region.position.x)*SCALE), roundi((BOTTOMS[index]-region.position.y)*SCALE))
		assert(offset.x > 0 and offset.y > 0 and offset.x + size.x < CELL and offset.y + size.y < CELL, "Clipped guardian pose")
		atlas.blit_rect(frame, Rect2i(Vector2i.ZERO,size), Vector2i(index%4,index/4)*CELL+offset)
		catalog.append({"index":index,"name":NAMES[index],"source_region":[region.position.x,region.position.y,region.size.x,region.size.y],"source_center":CENTERS[index],"source_foot":BOTTOMS[index]})
	assert(atlas.save_png("res://assets/characters/temple_guardian.png") == OK)
	for config in [["temple_rocket_fist",Rect2i(1127,222,85,85)], ["temple_charged_shot",Rect2i(1218,435,267,159)]]:
		var effect := source.get_region(config[1])
		assert(effect.get_used_rect().size.x > 40)
		assert(effect.save_png("res://assets/effects/%s.png" % config[0]) == OK)
	var file := FileAccess.open("res://design/references/temple-boss/temple-guardian-frames.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"cell":CELL,"foot":[160,272],"standing_height":144,"frames":catalog},"\t"))
	print("TEMPLE_GUARDIAN_ATLAS_READY: 13 supplied poses, detached rocket fist and charged shot, registered feet")
	quit()
