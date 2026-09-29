extends SceneTree
const CELL := 224
const FOOT := Vector2i(96, 160)
const SCALE := 58.0 / 96.0

func _initialize() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://design/references/player/complete-player-frames.json"))
	var source := Image.load_from_file("res://design/references/player/complete-player-matte.png")
	assert(source.get_size() == Vector2i(1448, 1086))
	source.convert(Image.FORMAT_RGBA8)
	for y in source.get_height():
		for x in source.get_width():
			var color := source.get_pixel(x, y)
			var alpha := 1.0 - clampf(minf(color.r - color.g, color.b - color.g), 0.0, 1.0)
			if alpha < 0.08:
				source.set_pixel(x, y, Color.TRANSPARENT)
			else:
				source.set_pixel(x, y, Color(clampf((color.r - 1.0 + alpha) / alpha, 0, 1), color.g / alpha, clampf((color.b - 1.0 + alpha) / alpha, 0, 1), alpha))
	var atlas := Image.create(CELL * 8, CELL * 9, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	for index in catalog.frames.size():
		var entry: Dictionary = catalog.frames[index]
		var rect: Array = entry.region
		var region := Rect2i(int(rect[0]), int(rect[1]), int(rect[2]), int(rect[3]))
		var frame := source.get_region(region)
		# The attack strip packs swords and trailing capes into overlapping
		# rectangles. Assign those pixels to their own pose, never a neighbor.
		for y in frame.get_height():
			for x in frame.get_width():
				var point := Vector2i(x, y) + region.position
				var remove := false
				match index:
					56: remove = point.x >= 101 and point.y >= 951
					57: remove = (point.x < 119 and point.y < 947) or (point.x >= 209 and point.y >= 949)
					58: remove = point.x < 239 and point.y < 940
					60: remove = point.x >= 747 and point.y >= 928
					61: remove = point.x < 781 and point.y < 914
					64: remove = point.x >= 1152 and point.y < 913
					65: remove = point.x < 1183 and point.y > 916
					66: remove = point.x < 1324 and point.y < 949
				if remove: frame.set_pixel(x, y, Color.TRANSPARENT)
		if "idle" in entry.sequence or "walk" in entry.sequence or "run" in entry.sequence:
			isolate_body(frame)
		var used := frame.get_used_rect()
		assert(used.size.x > 20 and used.size.y > 40, "Missing supplied frame %d" % index)
		var center: int
		if "idle" in entry.sequence:
			var scale := 58.0 / used.size.y
			frame = frame.get_region(used)
			frame.resize(roundi(used.size.x * scale), 58, Image.INTERPOLATE_NEAREST)
			center = roundi((float(entry.center) - region.position.x - used.position.x) * scale)
		else:
			frame.resize(roundi(region.size.x * SCALE), roundi(region.size.y * SCALE), Image.INTERPOLATE_NEAREST)
			center = roundi((float(entry.center) - region.position.x) * SCALE)
		var offset := Vector2i(FOOT.x - center, FOOT.y - frame.get_used_rect().end.y)
		assert(offset.x >= 0 and offset.y >= 0 and offset.x + frame.get_width() < CELL and offset.y + frame.get_height() < CELL, "Clipped frame %d" % index)
		atlas.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(index % 8, index / 8) * CELL + offset)
	assert(atlas.save_png("res://assets/characters/hooded_player_complete.png") == OK)
	print("COMPLETE_PLAYER_ATLAS: all 67 character frames, complete blade/dash wakes, supplied order, registered feet")
	quit()

func isolate_body(frame: Image) -> void:
	# Remove disconnected pieces of neighboring sprites in overlapping crops.
	# Eight-neighbor connectivity retains diagonal sword pixels and boot edges.
	var seen := {}
	var biggest: Array[Vector2i] = []
	for y in frame.get_height():
		for x in frame.get_width():
			var seed := Vector2i(x, y)
			if seen.has(seed) or frame.get_pixelv(seed).a < 0.08: continue
			var component: Array[Vector2i] = [seed]
			seen[seed] = true
			var cursor := 0
			while cursor < component.size():
				var point := component[cursor]
				cursor += 1
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var next := point + Vector2i(dx, dy)
						if next.x < 0 or next.y < 0 or next.x >= frame.get_width() or next.y >= frame.get_height() or seen.has(next): continue
						if frame.get_pixelv(next).a < 0.08: continue
						seen[next] = true
						component.append(next)
			if component.size() > biggest.size(): biggest = component
	var own := {}
	for point in biggest: own[point] = true
	for point in seen:
		if not own.has(point): frame.set_pixelv(point, Color.TRANSPARENT)
