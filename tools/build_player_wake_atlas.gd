extends SceneTree
const EDGES := [0,320,600,880,1155,1410,1640,1905,2172]
const PIVOTS := [220,520,782,1034,1289,1547,1815,2050]
const CELL := 192
const FOOT := Vector2i(96,136)
func _initialize() -> void:
	var source:=Image.load_from_file("res://design/references/cave-room1/wake-blood-cutouts.png")
	var atlas:=Image.create(CELL*4,CELL*2,false,Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	for index in 8:
		var rect:=Rect2i(EDGES[index],199,EDGES[index+1]-EDGES[index],345)
		var image:=source.get_region(rect)
		image.convert(Image.FORMAT_RGBA8)
		for y in image.get_height():
			for x in image.get_width():
				if image.get_pixel(x,y).a<.4: image.set_pixel(x,y,Color.TRANSPARENT)
		var size:=Vector2i(roundi(rect.size.x*58.0/296.0),roundi(rect.size.y*58.0/296.0))
		image.resize(size.x,size.y,Image.INTERPOLATE_NEAREST)
		var pivot:=Vector2i(roundi(float(PIVOTS[index]-rect.position.x)*size.x/rect.size.x),roundi(333.0*size.y/rect.size.y))
		var used:=image.get_used_rect()
		var offset:=FOOT-pivot
		assert((used.position+offset).x>0 and (used.end+offset).x<CELL)
		atlas.blit_rect(image,used,Vector2i(index%4,index/4)*CELL+offset+used.position)
	assert(atlas.save_png("res://assets/characters/hooded_player_wake.png")==OK)
	print("PLAYER_WAKE_ATLAS_READY: eight bloodied poses, registered feet, 58px standing height")
	quit()
