extends SceneTree
func _initialize() -> void:
	var source:=Image.load_from_file("res://design/references/cave-boss/cave-boss-effects-matte.png")
	print("Effects source: ",source.get_size())
	assert(source.get_size()==Vector2i(2056,765))
	source.convert(Image.FORMAT_RGBA8)
	for y in source.get_height():
		for x in source.get_width():
			var c:=source.get_pixel(x,y)
			var alpha:=1.0-clampf(minf(c.r-c.g,c.b-c.g)/.7,0,1)
			if alpha<.03: source.set_pixel(x,y,Color.TRANSPARENT)
			else: source.set_pixel(x,y,Color(clampf((c.r-(1-alpha))/alpha,0,1),clampf(c.g/alpha,0,1),clampf((c.b-(1-alpha))/alpha,0,1),alpha))
	var wind:=source.get_region(Rect2i(40,130,930,540))
	wind.resize(310,180,Image.INTERPOLATE_NEAREST)
	assert(wind.save_png("res://assets/effects/goblin_wind.png")==OK)
	var charge:=source.get_region(Rect2i(1020,85,990,620))
	charge.resize(330,207,Image.INTERPOLATE_NEAREST)
	assert(charge.save_png("res://assets/effects/goblin_charge_wake.png")==OK)
	print("GOBLIN_FX_TEXTURES_READY: measured isolated crops, decontaminated magenta matte")
	quit()

