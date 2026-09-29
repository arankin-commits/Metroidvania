extends SceneTree
const CELL:=192
const FOOT:=Vector2i(72,128)
const SCALE:=58.0/144.0
# All nine reference frames, including complete crescent and recovery.
const REGIONS:=[Rect2i(7,516,114,148),Rect2i(124,505,124,159),Rect2i(260,476,116,188),Rect2i(383,450,129,214),Rect2i(518,453,132,211),Rect2i(637,426,313,238),Rect2i(950,490,204,174),Rect2i(1155,530,152,134),Rect2i(1316,516,123,148)]
const CENTERS:=[62,197,327,450,588,751,1030,1230,1375]
func _initialize() -> void:
	var source:=Image.load_from_file("res://design/references/player/heavy-attack-matte.png")
	assert(source.get_size()==Vector2i(1448,1086))
	source.convert(Image.FORMAT_RGBA8)
	for y in source.get_height():
		for x in source.get_width():
			var c:=source.get_pixel(x,y)
			var alpha:=1.0-clampf(minf(c.r-c.g,c.b-c.g),0,1)
			if alpha<.08: source.set_pixel(x,y,Color.TRANSPARENT)
			else: source.set_pixel(x,y,Color(clampf((c.r-1+alpha)/alpha,0,1),c.g/alpha,clampf((c.b-1+alpha)/alpha,0,1),alpha))
	var atlas:=Image.create(CELL*3,CELL*3,false,Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	var catalog: Array=[]
	for index in 9:
		var region: Rect2i=REGIONS[index]
		var frame:=source.get_region(region)
		if index==5:
			for y in frame.get_height():
				for x in frame.get_width():
					if x+region.position.x<650 and y+region.position.y>480: frame.set_pixel(x,y,Color.TRANSPARENT)
		var body_scale := SCALE
		if index in [0,8]: body_scale = 58.0 / frame.get_used_rect().size.y
		frame.resize(roundi(frame.get_width()*body_scale),roundi(frame.get_height()*body_scale),Image.INTERPOLATE_NEAREST)
		var offset:=FOOT-Vector2i(roundi((CENTERS[index]-region.position.x)*body_scale),frame.get_used_rect().end.y)
		assert(offset.x>0 and offset.y>0 and offset.x+frame.get_width()<CELL and offset.y+frame.get_height()<CELL)
		var cell:=Vector2i(index%3,index/3)*CELL
		atlas.blit_rect(frame,Rect2i(Vector2i.ZERO,frame.get_size()),cell+offset)
		catalog.append({"index":index,"source_region":[region.position.x,region.position.y,region.size.x,region.size.y],"center_x":CENTERS[index],"floor_y":661,"phase":"charge" if index<5 else "release_recovery"})
	assert(atlas.save_png("res://assets/characters/hooded_player_heavy.png")==OK)
	var file:=FileAccess.open("res://design/references/player/heavy-attack-frames.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"frames":catalog,"cell":CELL,"foot":[72,128],"body_height":58},"\t"))
	print("PLAYER_HEAVY_ATLAS_READY: all nine poses; five charging, four release/recovery with supplied blade effects")
	quit()
