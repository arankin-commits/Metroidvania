extends SceneTree
const CELL=288
const FOOT=Vector2i(144,216)
const SCALE=.52
const RIGHT_REGIONS=[Rect2i(25,60,300,228),Rect2i(347,60,300,228),Rect2i(657,60,306,228),Rect2i(975,60,279,228),Rect2i(28,320,261,289),Rect2i(326,370,351,239),Rect2i(657,377,320,232),Rect2i(966,338,263,271),Rect2i(27,687,300,228),Rect2i(310,709,380,206),Rect2i(680,624,242,291),Rect2i(940,709,305,206),Rect2i(15,974,355,237),Rect2i(355,1013,300,198),Rect2i(657,920,233,271),Rect2i(946,1020,287,191)]
const LEFT_REGIONS=[Rect2i(25,60,280,228),Rect2i(337,60,267,228),Rect2i(635,60,270,228),Rect2i(946,60,280,228),Rect2i(28,320,262,289),Rect2i(304,370,307,239),Rect2i(635,377,270,232),Rect2i(946,338,283,271),Rect2i(15,687,270,228),Rect2i(270,709,375,206),Rect2i(657,634,240,281),Rect2i(935,709,300,206),Rect2i(20,974,310,237),Rect2i(350,1013,295,198),Rect2i(650,920,240,271),Rect2i(935,1020,300,191)]
const RIGHT_CENTERS=[148,470,784,1101,150,448,783,1089,148,475,800,1085,153,468,777,1090]
const LEFT_CENTERS=[160,474,786,1094,160,474,786,1094,160,524,786,1094,160,474,786,1094]

func _initialize() -> void:
	for side in ["right","left"]:
		var source:=Image.load_from_file("res://design/references/cave-boss/cave-boss-%s-matte.png"%side)
		assert(source.get_size()==Vector2i(1254,1254))
		source.convert(Image.FORMAT_RGBA8)
		for y in source.get_height():
			for x in source.get_width():
				var c:=source.get_pixel(x,y)
				if c.r>.65 and c.b>.65 and c.g<.35: source.set_pixel(x,y,Color.TRANSPARENT)
		var atlas:=Image.create(CELL*4,CELL*4,false,Image.FORMAT_RGBA8)
		atlas.fill(Color.TRANSPARENT)
		var regions=RIGHT_REGIONS if side=="right" else LEFT_REGIONS
		var centers=RIGHT_CENTERS if side=="right" else LEFT_CENTERS
		for index in 16:
			# Reuse the verified one-handed raised pose for the right overhead
			# windup: the separately generated cell10 used the wrong shoulder.
			var source_index:=4 if side=="right" and index==10 else index
			var region: Rect2i=regions[source_index]
			var pose:=source.get_region(region)
			var bottom:=pose.get_used_rect().end.y-1
			# Airborne feet intentionally remain above the ground registration.
			if index==14: bottom=1203-region.position.y
			pose.resize(roundi(region.size.x*SCALE),roundi(region.size.y*SCALE),Image.INTERPOLATE_NEAREST)
			var offset:=FOOT-Vector2i(roundi((centers[source_index]-region.position.x)*SCALE),roundi(bottom*SCALE))
			assert(offset.x>=0 and offset.y>=0 and offset.x+pose.get_width()<CELL and offset.y+pose.get_height()<CELL,"Pose crosses cell: %s %s"%[side,index])
			atlas.blit_rect(pose,Rect2i(Vector2i.ZERO,pose.get_size()),Vector2i(index%4,index/4)*CELL+offset)
		var target:="res://assets/characters/cave_goblin_atlas.png" if side=="right" else "res://assets/characters/cave_goblin_left_atlas.png"
		assert(atlas.save_png(target)==OK)
	print("CAVE_BOSS_ATLASES_READY: two authored facings, measured crops, transparent gutters, registered feet")
	quit()

