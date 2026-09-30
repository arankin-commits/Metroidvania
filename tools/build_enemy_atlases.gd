extends SceneTree

const CELL := 320
const FOOT := Vector2i(128,224)
const BASE := "res://assets/characters/enemies/"
var masks := {}

func ownership(source: Image, rect: Rect2i, seeds: Array, standing: float) -> Dictionary:
	var image:=source.get_region(rect)
	var width:=image.get_width()
	var height:=image.get_height()
	var result:=PackedInt32Array()
	result.resize(width*height)
	result.fill(-1)
	var queue:=PackedInt32Array()
	for index in seeds.size():
		var preferred:=Vector2i(int(seeds[index][0]),int(seeds[index][1]-standing*.4)-rect.position.y)
		var nearest:=Vector2i.ZERO
		var distance:=INF
		for y in range(maxi(0,preferred.y-30),mini(height,preferred.y+30)):
			for x in range(maxi(0,preferred.x-30),mini(width,preferred.x+30)):
				if image.get_pixel(x,y).a>.85:
					var d:=Vector2i(x,y).distance_squared_to(preferred)
					if d<distance: distance=d; nearest=Vector2i(x,y)
		assert(distance<INF)
		var seed_pixel:=nearest.y*width+nearest.x
		result[seed_pixel]=index
		queue.append(seed_pixel)
	var head:=0
	while head<queue.size():
		var pixel:=queue[head]
		head+=1
		var x:=pixel%width
		var y:=pixel/width
		for offset in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]:
			var p: Vector2i=Vector2i(x,y)+offset
			if p.x<0 or p.x>=width or p.y<0 or p.y>=height: continue
			var next: int=p.y*width+p.x
			if result[next]<0 and image.get_pixelv(p).a>.4:
				result[next]=result[pixel]
				queue.append(next)
	# Give detached effects to their nearest body, and retain soft edge alpha
	# according to the already isolated opaque silhouette.
	var opaque:=result.duplicate()
	var body:=result.duplicate()
	for y in height:
		for x in width:
			var pixel:=y*width+x
			if result[pixel]>=0 or image.get_pixel(x,y).a<.12: continue
			var chosen:=-1
			for oy in range(-2,3):
				for ox in range(-2,3):
					var nx:=x+ox
					var ny:=y+oy
					if nx>=0 and nx<width and ny>=0 and ny<height and opaque[ny*width+nx]>=0: chosen=opaque[ny*width+nx]
			if chosen>=0: body[pixel]=chosen
			if chosen<0:
				var distance:=INF
				for index in seeds.size():
					var d:=absf(x-float(seeds[index][0]))
					if d<distance: distance=d; chosen=index
			result[pixel]=chosen
	return {"all":result,"body":body}

func _initialize() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://design/references/enemies/enemy-source-crops.json"))
	var delivered := {}
	var only_kind := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only="): only_kind=argument.trim_prefix("--only=")
	if not only_kind.is_empty():
		assert(catalog.has(only_kind))
		delivered=JSON.parse_string(FileAccess.get_file_as_string("res://design/references/enemies/enemy-frames.json")).enemies
	var sources := {}
	for kind in catalog:
		if not only_kind.is_empty() and kind!=only_kind: continue
		var config: Dictionary = catalog[kind]
		var count := 0
		for anim in config.animations.values(): count += anim.frames.size()
		var atlas := Image.create(CELL*8,CELL*ceili(count/8.0),false,Image.FORMAT_RGBA8)
		atlas.fill(Color.TRANSPARENT)
		var frame_index := 0
		var sequences := []
		for anim_name in config.animations:
			var anim: Dictionary = config.animations[anim_name]
			var indices := []
			for frame_config in anim.frames:
				var key: String = frame_config.source
				if not sources.has(key):
					sources[key] = Image.load_from_file("res://design/references/enemies/extracted/%s.png" % key)
				var rect := Rect2i(frame_config.rect[0],frame_config.rect[1],frame_config.rect[2],frame_config.rect[3])
				var frame: Image = sources[key].get_region(rect)
				frame.convert(Image.FORMAT_RGBA8)
				var mask_key: String="%s-%s-%s" % [key,rect.position.y,rect.size.y]
				if frame_config.has("owners") and not masks.has(mask_key):
					masks[mask_key]=ownership(sources[key],rect,frame_config.owners,float(config.height)/float(config.scale))
				# Discard only near-transparent background residue; keep weapon/magic alpha.
				for y in frame.get_height():
					for x in frame.get_width():
						var remove:=frame.get_pixel(x,y).a < 0.12
						if frame_config.has("owners"):
							var chosen_mask: PackedInt32Array=masks[mask_key]["body" if frame_config.get("body_only",false) else "all"]
							remove=remove or chosen_mask[y*rect.size.x+x]!=int(frame_config.owner)
						if remove: frame.set_pixel(x,y,Color.TRANSPARENT)
				if frame_config.get("register_body_feet",false):
					var lowest:=0
					for y in frame.get_height():
						for x in range(maxi(0,int(frame_config.pivot[0])-45),mini(frame.get_width(),int(frame_config.pivot[0])+45)):
							var color:=frame.get_pixel(x,y)
							if color.a>.9 and color.v<.3: lowest=maxi(lowest,y)
					frame_config.pivot[1]=lowest+rect.position.y
				var scale_factor: float = frame_config.get("scale",config.scale)
				var original_size := frame.get_size()
				var target_size := Vector2i(roundi(original_size.x*scale_factor),roundi(original_size.y*scale_factor))
				frame.resize(target_size.x,target_size.y,Image.INTERPOLATE_NEAREST)
				# Register the delivered feet after integer resampling.
				var pivot := Vector2i(roundi((frame_config.pivot[0]-rect.position.x)*target_size.x/original_size.x),roundi((frame_config.pivot[1]-rect.position.y)*target_size.y/original_size.y))
				var offset := FOOT-pivot
				var bounds := frame.get_used_rect()
				assert((bounds.position+offset).x>0 and (bounds.position+offset).y>0)
				if (bounds.end+offset).x>=CELL or (bounds.end+offset).y>=CELL:
					push_error("Crop overflow: %s %s %d %s %s" % [kind,anim_name,indices.size(),bounds,offset])
					quit(1)
					return
				atlas.blit_rect(frame,bounds,Vector2i(frame_index%8,frame_index/8)*CELL+offset+bounds.position)
				indices.append(frame_index)
				frame_index += 1
			sequences.append({"name":anim_name,"fps":anim.fps,"loop":anim.loop,"indices":indices})
		assert(atlas.save_png(BASE+kind+".png")==OK)
		# Use external textures rather than embedding a second atlas in SpriteFrames.
		var resource := "[gd_resource type=\"SpriteFrames\" load_steps=%d format=3]\n\n[ext_resource type=\"Texture2D\" path=\"%s%s.png\" id=\"1\"]\n\n" % [count+2,BASE,kind]
		for i in count:
			resource += "[sub_resource type=\"AtlasTexture\" id=\"Frame_%d\"]\natlas = ExtResource(\"1\")\nregion = Rect2(%d, %d, 320, 320)\n\n" % [i,(i%8)*CELL,(i/8)*CELL]
		resource += "[resource]\nanimations = ["
		for s in sequences:
			resource += "{\n\"frames\": ["
			for i in s.indices: resource += "{\"duration\": 1.0, \"texture\": SubResource(\"Frame_%d\")}," % i
			resource = resource.trim_suffix(",") + "],\n\"loop\": %s,\n\"name\": &\"%s\",\n\"speed\": %s\n}," % [str(s.loop),s.name,str(float(s.fps))]
		resource = resource.trim_suffix(",") + "]\n"
		var file := FileAccess.open(BASE+kind+".tres",FileAccess.WRITE)
		file.store_string(resource)
		for effect_name in config.get("effects",{}):
			var effect: Dictionary = config.effects[effect_name]
			var er: Array = effect.rect
			var image: Image = sources[effect.source].get_region(Rect2i(er[0],er[1],er[2],er[3]))
			assert(image.save_png(BASE+kind+"_"+effect_name+".png")==OK)
		delivered[kind]={"count":count,"height":config.height,"collider":config.collider,"sequences":sequences}
	var file := FileAccess.open("res://design/references/enemies/enemy-frames.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"cell":CELL,"foot":[128,224],"enemies":delivered},"\t"))
	print("ENEMY_ATLASES_READY: six types, ", delivered.keys())
	quit()
